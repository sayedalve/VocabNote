"""AI quiz generation for VocabNote.

Reads the user's selected vocabulary (meanings, synonyms, antonyms and
examples), asks the configured AI provider for a balanced multiple-choice
quiz, then strictly validates the response before anything reaches the UI.

Transport mirrors api/gemini.py: the same two provider types cover every
preset -- "google" (Gemini generateContent) and "openai_compatible" (chat
completions). Adding a future provider is a one-line API_PRESETS entry in
main.py; nothing changes here.

Stdlib-only (urllib) so the offline-first app gains no new dependencies.
This module is always called from a background thread; it performs no UI
work and no database access.
"""

import json
import random
import re
import urllib.error
import urllib.request

REQUEST_TIMEOUT_SECS = 75
MAX_WORDS_IN_PROMPT = 120   # keeps prompts bounded on very large notebooks
QUESTION_TYPES = ("meaning", "synonym", "antonym")


# =======================================================================
# PUBLIC API
# =======================================================================

def generate_quiz(words, num_questions, question_type, api_key, provider_config):
    """Generates a validated multiple-choice quiz.

    Args:
        words: word dictionaries straight from the database.
        num_questions: requested question count (10/20/30).
        question_type: "Mixed", "Meaning", "Synonym" or "Antonym".
        api_key: the provider's saved API key.
        provider_config: {"type", "base_url", "model"} -- the same shape
            SettingsPage.get_current_provider_config() produces.

    Returns:
        (questions, message). ``questions`` is a list of dicts with keys
        word / question_type / question / options / correct_index /
        explanation, or None on failure. Quality is prioritised over speed:
        a shortfall triggers one top-up request before returning.
    """
    if not api_key or not str(api_key).strip():
        return None, "No API key configured for this provider."

    allowed = _allowed_types(question_type)
    pool = _build_word_pool(words, allowed)
    if len(pool) < 4:
        return None, "Not enough usable words for this question type (need at least 4 with data)."

    target = max(1, min(int(num_questions), len(pool)))
    entries_by_word = {e["word"].lower(): e for e in pool}
    used_words = set()

    prompt_pool = (
        pool if len(pool) <= MAX_WORDS_IN_PROMPT
        else random.sample(pool, MAX_WORDS_IN_PROMPT)
    )

    try:
        raw_text = _request_text(
            _build_prompt(prompt_pool, target, allowed), api_key, provider_config
        )
        questions = _validate_questions(
            _extract_json_array(raw_text), entries_by_word, allowed, used_words
        )

        # Quality over speed: one top-up round for any shortfall, using only
        # words that have not been asked about yet (avoids duplicates).
        if len(questions) < target:
            shortfall = target - len(questions)
            unused = [e for e in prompt_pool if e["word"].lower() not in used_words]
            if unused:
                retry_pool = (
                    unused if len(unused) <= MAX_WORDS_IN_PROMPT
                    else random.sample(unused, MAX_WORDS_IN_PROMPT)
                )
                try:
                    raw_text2 = _request_text(
                        _build_prompt(retry_pool, shortfall, allowed),
                        api_key,
                        provider_config,
                    )
                    questions += _validate_questions(
                        _extract_json_array(raw_text2),
                        entries_by_word,
                        allowed,
                        used_words,
                    )
                except ValueError:
                    pass  # keep the already-validated questions
    except ValueError as e:
        return None, str(e)
    except Exception as e:
        return None, f"Quiz generation failed: {str(e)}"

    if not questions:
        return None, "The AI response could not be validated into usable questions. Please try again."

    questions = questions[:target]
    random.shuffle(questions)
    return questions, f"Generated {len(questions)} questions."


# =======================================================================
# WORD POOL & PROMPT
# =======================================================================

def _allowed_types(question_type):
    qt = (question_type or "Mixed").strip().lower()
    if qt in QUESTION_TYPES:
        return (qt,)
    return QUESTION_TYPES


def _split_list(value):
    """Synonyms/antonyms are stored as comma-separated text in the DB."""
    if not value:
        return []
    if isinstance(value, (list, tuple)):
        items = [str(v) for v in value]
    else:
        items = re.split(r"[,;]", str(value))
    return [i.strip() for i in items if i and i.strip()]


def _build_word_pool(words, allowed_types):
    """Normalises DB word rows and keeps only words that can support at
    least one of the allowed question types."""
    pool = []
    for w in words or []:
        if not isinstance(w, dict):
            continue
        word = str(w.get("word") or "").strip()
        if not word:
            continue
        meaning = str(w.get("meaning") or w.get("english_definition") or "").strip()
        synonyms = _split_list(w.get("synonyms"))
        antonyms = _split_list(w.get("antonyms"))

        types = []
        if "meaning" in allowed_types and meaning:
            types.append("meaning")
        if "synonym" in allowed_types and synonyms:
            types.append("synonym")
        if "antonym" in allowed_types and antonyms:
            types.append("antonym")
        if not types:
            continue

        pool.append(
            {
                "word": word,
                "meaning": meaning,
                "part_of_speech": str(w.get("part_of_speech") or "").strip(),
                "example": str(w.get("example_sentence") or "").strip(),
                "synonyms": synonyms,
                "antonyms": antonyms,
                "types": types,
            }
        )
    return pool


def _build_prompt(pool_entries, count, allowed_types):
    payload = [
        {
            "word": e["word"],
            "part_of_speech": e["part_of_speech"],
            "meaning": e["meaning"],
            "example": e["example"],
            "synonyms": e["synonyms"],
            "antonyms": e["antonyms"],
            "allowed_question_types": e["types"],
        }
        for e in pool_entries
    ]
    words_json = json.dumps(payload, ensure_ascii=False)
    types_txt = ", ".join(allowed_types)
    mix_rule = (
        "- Balance the mix of question types roughly evenly across the quiz.\n"
        if len(allowed_types) > 1
        else ""
    )
    return (
        "You are an expert English vocabulary quiz writer.\n"
        "First carefully read and understand the VOCABULARY data below, then "
        f"create exactly {count} high-quality multiple-choice questions from it.\n"
        "\n"
        "RULES:\n"
        f"- Allowed question types: {types_txt}. Only use a type listed in that "
        "word's allowed_question_types.\n"
        f"{mix_rule}"
        '- "meaning": ask which option best describes the meaning of the word. '
        "Distractors must be plausible but clearly wrong definitions.\n"
        '- "synonym": ask which option is a synonym of the word. Exactly one '
        "option may be a true synonym (use the provided synonyms).\n"
        '- "antonym": ask which option is an antonym of the word. Exactly one '
        "option may be a true antonym (use the provided antonyms).\n"
        "- Exactly 4 options per question with exactly one correct answer "
        "(0-based correct_index).\n"
        "- Distractors must be believable: same part of speech and register; "
        "prefer drawing them from other words in the vocabulary list.\n"
        "- Never reuse the same word for more than one question. No duplicate "
        "questions and no duplicate options within a question.\n"
        "- Base every question strictly on the provided data; do not invent "
        "different senses of a word.\n"
        '- Add a one-sentence "explanation" of why the correct answer is right.\n'
        "\n"
        "OUTPUT: respond with ONLY a JSON array (no markdown fences, no "
        "commentary). Each element must be exactly:\n"
        '{"word": "...", "question_type": "meaning|synonym|antonym", '
        '"question": "...", "options": ["...", "...", "...", "..."], '
        '"correct_index": 0, "explanation": "..."}\n'
        "\n"
        f"VOCABULARY:\n{words_json}\n"
    )


# =======================================================================
# TRANSPORT (mirrors api/gemini.py provider types)
# =======================================================================

def _request_text(prompt, api_key, provider_config):
    config = provider_config or {}
    ptype = config.get("type", "openai_compatible")
    base_url = str(config.get("base_url") or "").strip().rstrip("/")
    model = str(config.get("model") or "").strip()
    if not base_url or not model:
        raise ValueError("Provider Base URL or Model is missing. Check Settings.")
    if ptype == "google":
        return _call_google(prompt, api_key, base_url, model)
    return _call_openai_compatible(prompt, api_key, base_url, model)


def _http_post_json(url, payload, headers):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json", **headers},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT_SECS) as resp:
            return json.loads(resp.read().decode("utf-8", "replace"))
    except urllib.error.HTTPError as e:
        detail = ""
        try:
            detail = e.read().decode("utf-8", "replace")
        except Exception:
            pass
        raise ValueError(f"API error {e.code}: {_short_api_error(detail) or e.reason}")
    except urllib.error.URLError as e:
        raise ValueError(f"Network error: {getattr(e, 'reason', e)}")


def _short_api_error(body):
    """Extracts a compact human-readable message from an API error body."""
    if not body:
        return ""
    try:
        parsed = json.loads(body)
        err = parsed.get("error")
        if isinstance(err, dict) and err.get("message"):
            return str(err["message"])[:200]
        if isinstance(err, str):
            return err[:200]
    except Exception:
        pass
    return body.strip()[:200]


def _call_google(prompt, api_key, base_url, model):
    # Key travels in the URL query string, matching api/gemini.py's proven
    # transport exactly.
    url = f"{base_url}/{model}:generateContent?key={str(api_key).strip()}"
    payload = {
        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.6,
            "responseMimeType": "application/json",
        },
    }
    try:
        data = _http_post_json(url, payload, {})
    except ValueError as e:
        # Some Gemini model versions reject responseMimeType; retry without it.
        if "mime" not in str(e).lower():
            raise
        payload["generationConfig"].pop("responseMimeType", None)
        data = _http_post_json(url, payload, {})

    candidates = data.get("candidates") or []
    if not candidates:
        raise ValueError("The AI returned no candidates. Please try again.")
    parts = (candidates[0].get("content") or {}).get("parts") or []
    text = "".join(p.get("text", "") for p in parts if isinstance(p, dict))
    if not text.strip():
        raise ValueError("The AI returned an empty response. Please try again.")
    return text


def _call_openai_compatible(prompt, api_key, base_url, model):
    url = f"{base_url}/chat/completions"
    payload = {
        "model": model,
        "temperature": 0.6,
        "messages": [
            {
                "role": "system",
                "content": "You write high-quality vocabulary quizzes and reply with valid JSON only.",
            },
            {"role": "user", "content": prompt},
        ],
    }
    data = _http_post_json(url, payload, {"Authorization": f"Bearer {str(api_key).strip()}"})
    choices = data.get("choices") or []
    if not choices:
        raise ValueError("The AI returned no choices. Please try again.")
    content = (choices[0].get("message") or {}).get("content")
    if isinstance(content, list):  # some providers return content parts
        content = "".join(
            p.get("text", "") for p in content if isinstance(p, dict)
        )
    if not content or not str(content).strip():
        raise ValueError("The AI returned an empty response. Please try again.")
    return str(content)


# =======================================================================
# PARSING & VALIDATION
# =======================================================================

def _extract_json_array(text):
    """Best-effort extraction of a JSON array from a model response,
    tolerating markdown fences, prose wrappers, and trailing commas."""
    text = (text or "").strip()
    text = re.sub(r"^```(?:json)?\s*", "", text)
    text = re.sub(r"\s*```$", "", text)

    parsed = None
    try:
        parsed = json.loads(text)
    except Exception:
        start = text.find("[")
        end = text.rfind("]")
        if start == -1 or end <= start:
            return []
        chunk = text[start : end + 1]
        try:
            parsed = json.loads(chunk)
        except Exception:
            chunk = re.sub(r",\s*([\]}])", r"\1", chunk)  # trailing commas
            try:
                parsed = json.loads(chunk)
            except Exception:
                return []

    if isinstance(parsed, dict):  # e.g. {"questions": [...]}
        for v in parsed.values():
            if isinstance(v, list):
                parsed = v
                break
    return parsed if isinstance(parsed, list) else []


def _validate_questions(raw_items, entries_by_word, allowed_types, used_words):
    """Keeps only structurally perfect questions:
    known word, allowed + supported type, 4 unique non-empty options,
    a valid correct_index, no word reuse. Options are shuffled so the
    correct answer's position is unbiased."""
    valid = []
    for item in raw_items or []:
        if not isinstance(item, dict):
            continue
        word = str(item.get("word", "")).strip()
        qtype = str(item.get("question_type", "")).strip().lower()
        question = str(item.get("question", "")).strip()
        options = item.get("options")

        entry = entries_by_word.get(word.lower())
        if not word or entry is None or word.lower() in used_words:
            continue
        if qtype not in allowed_types or qtype not in entry["types"]:
            continue
        if not question:
            continue
        if not isinstance(options, list) or len(options) != 4:
            continue
        opts = [str(o).strip() for o in options]
        if any(not o for o in opts):
            continue
        if len({o.lower() for o in opts}) != 4:
            continue
        try:
            correct_index = int(item.get("correct_index"))
        except (TypeError, ValueError):
            continue
        if not (0 <= correct_index <= 3):
            continue

        correct_text = opts[correct_index]
        random.shuffle(opts)
        correct_index = opts.index(correct_text)

        used_words.add(word.lower())
        valid.append(
            {
                "word": entry["word"],
                "question_type": qtype,
                "question": question,
                "options": opts,
                "correct_index": correct_index,
                "explanation": str(item.get("explanation") or "").strip(),
            }
        )
    return valid

import json
import re
import time
import requests

# --- Locked configuration -----------------------------------------------
MODEL_NAME = "gemini-3.1-flash-lite"
API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"

REQUEST_TIMEOUT_SECONDS = 15
MAX_RETRIES = 2          # retries for transient errors only (429 / 5xx)
RETRY_BACKOFF_SECONDS = 2  # multiplied by attempt number

def _build_url():
    """Builds the fixed, locked-model endpoint. One line, no surprises."""
    return f"{API_BASE_URL}/{MODEL_NAME}:generateContent"

def _call_gemini_api(prompt_text, api_key, timeout=REQUEST_TIMEOUT_SECONDS):
    if not api_key or not api_key.strip():
        return None, "Missing API key. Please add your Gemini API key in Settings."

    url = _build_url()
    payload = {"contents": [{"parts": [{"text": prompt_text}]}]}
    
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": api_key.strip(),
    }

    last_error = "Gemini request failed for an unknown reason."

    for attempt in range(MAX_RETRIES + 1):
        try:
            response = requests.post(
                url, headers=headers, json=payload, timeout=timeout
            )
        except requests.exceptions.Timeout:
            last_error = "The request to Gemini timed out. Check your internet connection and try again."
            if attempt < MAX_RETRIES:
                time.sleep(RETRY_BACKOFF_SECONDS * (attempt + 1))
                continue
            return None, last_error
        except requests.exceptions.ConnectionError:
            return None, "Could not reach Gemini's servers. Please check your internet connection."
        except requests.exceptions.RequestException as e:
            return None, f"Network error while contacting Gemini: {str(e)}"

        if response.status_code == 200:
            return response, None

        google_msg = ""
        try:
            google_msg = response.json().get("error", {}).get("message", "")
        except (ValueError, AttributeError):
            pass

        if response.status_code == 429:
            last_error = f"Free-tier quota exceeded for {MODEL_NAME}. Wait a minute and try again. ({google_msg})"
            if attempt < MAX_RETRIES:
                time.sleep(RETRY_BACKOFF_SECONDS * (attempt + 1))
                continue
            return None, last_error

        if response.status_code in (401, 403):
            return None, f"API key rejected ({response.status_code}). Double-check the key in Settings. ({google_msg})"

        if response.status_code == 404:
            return None, f"Model '{MODEL_NAME}' returned 404. Google retires Gemini models on a rolling basis. Check documentation and update MODEL_NAME."

        if response.status_code >= 500:
            last_error = f"Gemini server error ({response.status_code}). Retrying..."
            if attempt < MAX_RETRIES:
                time.sleep(RETRY_BACKOFF_SECONDS * (attempt + 1))
                continue
            return None, f"Gemini server error ({response.status_code}). Please try again shortly."

        return None, f"API Error ({response.status_code}): {google_msg or 'Unknown error.'}"

    return None, last_error

def _clean_json_response(raw_text):
    text = raw_text.strip()
    fence_match = re.search(r"```(?:json)?\s*(.*?)\s*```", text, re.DOTALL)
    if fence_match:
        text = fence_match.group(1).strip()

    if not text.startswith("{"):
        brace_match = re.search(r"\{.*\}", text, re.DOTALL)
        if brace_match:
            text = brace_match.group(0)

    return text

def test_gemini_connection(api_key):
    response, error = _call_gemini_api("Respond with the single word: OK", api_key, timeout=10)
    if error:
        return False, error
    return True, f"Connection successful! ({MODEL_NAME})"

def fetch_word_details(word, api_key):
    prompt = f"""
        Analyze the English word: "{word}".
        Return ONLY a valid JSON object with the following keys. Do not include markdown code blocks like ```json.
        Do NOT wrap any synonyms or antonyms in double quotes. Just return them separated by commas.

        {{
            "meaning": "Short concise English meaning",
            "bangla_meaning": "Meaning in Bengali script",
            "english_definition": "A more detailed English definition",
            "ipa": "Simple intuitive English pronunciation spelling (e.g. a-bate, ze-nith)",
            "part_of_speech": "e.g. noun, verb, adjective",
            "example_sentence": "A clear, natural example sentence",
            "synonyms": "3-5 synonyms, comma-separated.",
            "antonyms": "3-5 antonyms, comma-separated.",
            "exam_history": "If this word frequently appears in Bangladesh competitive exams (e.g., BCS, Bangladesh Bank, IBA MBA, DU Admission, BUET, Medical), return a short badge string like '(BCS 44)'. If NEVER appeared, return \\"\\""
        }}
        """

    response, error = _call_gemini_api(prompt, api_key)
    if error:
        return None, error

    try:
        raw_text = response.json()["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError, TypeError, ValueError):
        return None, "Gemini returned an unexpected response format. Try a different word or rephrase."

    cleaned = _clean_json_response(raw_text)

    try:
        data = json.loads(cleaned)
    except json.JSONDecodeError:
        return None, "Gemini's response wasn't valid JSON. Please try refreshing this word again."

    if not isinstance(data, dict):
        return None, "Gemini's response wasn't in the expected format. Please try again."

    return data, "Success"
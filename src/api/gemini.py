import json
import re
import time
import requests

REQUEST_TIMEOUT_SECONDS = 15
MAX_RETRIES = 2
RETRY_BACKOFF_SECONDS = 2

def _call_llm_api(prompt_text, api_key, provider_config, timeout=REQUEST_TIMEOUT_SECONDS):
    if not api_key or not api_key.strip():
        return None, "Missing API key. Please check your settings.", None

    provider_type = provider_config.get("type", "google")
    base_url = provider_config.get("base_url", "https://generativelanguage.googleapis.com/v1beta/models")
    model_name = provider_config.get("model", "gemini-3.1-flash-lite")

    # Route 1: Native Google Gemini API
    if provider_type == "google":
        url = f"{base_url.rstrip('/')}/{model_name}:generateContent?key={api_key.strip()}"
        headers = {"Content-Type": "application/json"}
        payload = {
            "contents": [{"parts": [{"text": prompt_text}]}],
            "generationConfig": {"temperature": 0.0}
        }
    
    # Route 2: OpenAI-Compatible Proxies (Agent Router, Groq, Mistral, OpenRouter, etc.)
    else: 
        url = f"{base_url.rstrip('/')}/chat/completions"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key.strip()}"
        }
        payload = {
            "model": model_name,
            "messages": [{"role": "user", "content": prompt_text}],
            "temperature": 0.0
        }

    last_error = "API request failed."

    for attempt in range(MAX_RETRIES + 1):
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=timeout)
        except requests.exceptions.RequestException as e:
            last_error = f"Network error: {str(e)}"
            if attempt < MAX_RETRIES:
                time.sleep(RETRY_BACKOFF_SECONDS * (attempt + 1))
                continue
            return None, last_error, provider_type

        if response.status_code == 200:
            return response, None, provider_type

        # Extract Error Message safely across platforms
        msg_details = ""
        try:
            resp_json = response.json()
            if "error" in resp_json:
                msg_details = resp_json.get("error", {}).get("message", "")
            elif "message" in resp_json:
                msg_details = resp_json.get("message", "")
        except Exception:
            msg_details = response.text
        
        last_error = f"API Error ({response.status_code}): {msg_details or 'Unknown vendor error.'}"
        
        if response.status_code in [429, 500, 502, 503, 504] and attempt < MAX_RETRIES:
            time.sleep(RETRY_BACKOFF_SECONDS * (attempt + 1))
            continue
            
        return None, last_error, provider_type

    return None, last_error, provider_type

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

def test_connection(api_key, provider_config):
    response, error, _ = _call_llm_api("Respond with the single word: OK", api_key, provider_config, timeout=10)
    if error: 
        return False, error
    return True, f"Connected successfully to {provider_config.get('model')}!"

def fetch_word_details(word, api_key, provider_config):
    prompt = f"""
        Analyze the English word: "{word}".
        Return ONLY a valid JSON object with the following keys. Do not include markdown code blocks like ```json.
        Do NOT wrap any synonyms or antonyms in double quotes. Just return them separated by commas.

        CRITICAL RULE FOR 'exam_history':
        Do NOT guess or hallucinate. If you do not have definitive, undeniable proof that this word appeared in a specific past Bangladesh competitive exam (like BCS 35th, 41st, Bank jobs, DU Admission, BUET, Medical, etc.), you MUST return an empty string "". False exam data is strictly prohibited.

        {{
            "meaning": "Short concise English meaning",
            "bangla_meaning": "Meaning in Bengali script",
            "english_definition": "A more detailed English definition",
            "ipa": "Simple intuitive English pronunciation spelling (e.g. a-bate, ze-nith)",
            "part_of_speech": "e.g. noun, verb, adjective",
            "example_sentence": "A clear, natural example sentence",
            "synonyms": "3-5 synonyms, comma-separated.",
            "antonyms": "3-5 antonyms, comma-separated.",
            "exam_history": "Exam names (e.g., BCS 35) OR empty string \"\" if unsure"
        }}
    """
    
    response, error, p_type = _call_llm_api(prompt, api_key, provider_config)
    if error: 
        return None, error

    try:
        if p_type == "google":
            raw_text = response.json()["candidates"][0]["content"]["parts"][0]["text"]
        else:
            raw_text = response.json()["choices"][0]["message"]["content"]
    except Exception:
        return None, "Unexpected structural format from API response."

    cleaned = _clean_json_response(raw_text)
    
    try:
        data = json.loads(cleaned)
    except json.JSONDecodeError:
        return None, "Response structural block wasn't valid JSON format."
    
    if not isinstance(data, dict):
        return None, "Response content parsed successfully but failed validation check."
        
    return data, "Success"
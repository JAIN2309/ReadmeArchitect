import os
from google import genai

_gemini_client = None

def get_gemini_client() -> genai.Client:
    global _gemini_client
    if _gemini_client is None:
        api_key = os.getenv("GEMINI_API_KEY", "")
        if not api_key:
            raise RuntimeError(
                "GEMINI_API_KEY is not set. "
                "Copy .env.example → .env and add your key from https://aistudio.google.com/apikey"
            )
        _gemini_client = genai.Client(api_key=api_key)
    return _gemini_client

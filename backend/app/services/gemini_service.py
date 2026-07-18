"""Gemini text-generation fallback for the /ask answer cascade.

This reuses the *same free Gemini tier* already used for OCR (ocr_service.py) --
no paid API. Here it is the quality backstop: when the local models (fine-tuned
T5 and Phi-3) both produce a poor answer, Gemini is called to rescue the reply.
It fires only on escalation (see answer_service.answer_question), so the free
tier's quota isn't spent on every question.
"""

import os

import requests

GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "{model}:generateContent"
)
REQUEST_TIMEOUT = 30


class GeminiServiceError(RuntimeError):
    """Raised when the Gemini text fallback is unreachable, misconfigured
    (no key), or returns nothing usable. The caller treats it as 'no answer
    from Gemini' and keeps whatever the local models produced."""


def gemini_available() -> bool:
    """True only when a free API key is configured (backend/.env). Lets the
    cascade skip the Gemini tier cleanly on a key-less dev machine."""
    return bool(os.getenv("GEMINI_API_KEY"))


def gemini_generate(prompt: str) -> str:
    """Send the tutor prompt to Gemini and return the answer text."""
    if not gemini_available():
        raise GeminiServiceError("GEMINI_API_KEY not set")

    body = {
        "contents": [{"parts": [{"text": prompt}]}],
        # Slightly above zero: a tutoring answer benefits from a little fluency,
        # but we still want it grounded and repeatable.
        "generationConfig": {"temperature": 0.2},
    }

    try:
        response = requests.post(
            GEMINI_URL.format(model=GEMINI_MODEL),
            params={"key": os.getenv("GEMINI_API_KEY")},
            json=body,
            timeout=REQUEST_TIMEOUT,
        )
    except requests.RequestException as e:
        raise GeminiServiceError(f"Could not reach Gemini: {e}") from e

    try:
        payload = response.json()
    except ValueError as e:
        raise GeminiServiceError("Gemini returned a non-JSON response") from e

    # Gemini reports auth/quota errors in an `error` object.
    if isinstance(payload.get("error"), dict):
        raise GeminiServiceError(payload["error"].get("message", "Gemini error"))

    try:
        text = payload["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError, TypeError):
        raise GeminiServiceError("Gemini returned no usable completion")

    return text.strip()

"""Gemini text-generation fallback for the /ask answer cascade.

This reuses the *same free Gemini tier* already used for OCR (ocr_service.py) --
no paid API. Here it is the quality backstop: when the local models (fine-tuned
T5 and Phi-3) both produce a poor answer, Gemini is called to rescue the reply.
It fires only on escalation (see answer_service.answer_question), so the free
tier's quota isn't spent on every question.
"""

import requests

from app.config import settings

GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "{model}:generateContent"
)
REQUEST_TIMEOUT = 30


class GeminiServiceError(RuntimeError):
    """Raised when the Gemini text fallback is unreachable, misconfigured
    (no key), or returns nothing usable. The caller treats it as 'no answer
    from Gemini' and keeps whatever the local models produced."""


class GeminiRateLimitError(GeminiServiceError):
    """Raised specifically on a 429 / quota-exceeded from Gemini -- a *temporary*
    condition, distinct from a hard failure. Carries the server's suggested retry
    delay (seconds) so the caller can hand the user a Retry-After."""

    def __init__(self, message: str, retry_after: int = 30):
        super().__init__(message)
        self.retry_after = retry_after


def _retry_after_seconds(payload: dict) -> int:
    """Gemini's suggested wait from a 429 body (RetryInfo detail), else 30s."""
    try:
        for detail in payload.get("error", {}).get("details", []):
            if "RetryInfo" in detail.get("@type", "") and detail.get("retryDelay"):
                return max(1, int(float(str(detail["retryDelay"]).rstrip("s"))))
    except Exception:
        pass
    return 30


def gemini_available() -> bool:
    """True only when a free API key is configured (backend/.env). Lets the
    cascade skip the Gemini tier cleanly on a key-less dev machine."""
    return bool(settings.gemini_api_key)


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
            GEMINI_URL.format(model=settings.gemini_model),
            params={"key": settings.gemini_api_key},
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
        err = payload["error"]
        # A 429 / RESOURCE_EXHAUSTED is a temporary rate limit, not a hard error;
        # surface it distinctly so the caller can tell the user to retry shortly.
        if response.status_code == 429 or err.get("status") == "RESOURCE_EXHAUSTED":
            raise GeminiRateLimitError(
                err.get("message", "Gemini rate limit reached"),
                _retry_after_seconds(payload),
            )
        raise GeminiServiceError(err.get("message", "Gemini error"))

    try:
        text = payload["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError, TypeError):
        raise GeminiServiceError("Gemini returned no usable completion")

    return text.strip()

"""Second cloud fallback (OpenAI-compatible) for the /ask answer cascade.

Backstop behind Gemini: when the local models are weak AND Gemini is
rate-limited (its free-tier daily quota resets only once a day) or failing, the
cascade tries this provider before giving up.

The service speaks the OpenAI chat-completions dialect, so FALLBACK_BASE_URL /
FALLBACK_MODEL / FALLBACK_API_KEY in backend/.env can point it at any
compatible provider without touching code. Currently: Cerebras' free tier
(1M tokens/day, no card -- fits the project's no-paid-APIs policy) serving
gpt-oss-120b.
"""

import requests

from app.config import settings

REQUEST_TIMEOUT = 30


class FallbackLLMError(RuntimeError):
    """Raised when the fallback provider is unreachable, misconfigured (no
    key), or returns nothing usable. The caller treats it as 'no answer from
    the fallback' and keeps whatever the earlier tiers produced."""


class FallbackLLMRateLimitError(FallbackLLMError):
    """Raised on a 429 from the provider -- temporary, distinct from a hard
    failure. Carries the server's Retry-After (seconds) when it sends one."""

    def __init__(self, message: str, retry_after: int = 30):
        super().__init__(message)
        self.retry_after = retry_after


def fallback_available() -> bool:
    """True only when an API key is configured (backend/.env). Lets the cascade
    skip this tier cleanly on a key-less dev machine."""
    return bool(settings.fallback_api_key)


def fallback_generate(prompt: str) -> str:
    """Send the tutor prompt to the fallback provider, return the answer text."""
    if not fallback_available():
        raise FallbackLLMError("FALLBACK_API_KEY not set")

    body = {
        "model": settings.fallback_model,
        "messages": [{"role": "user", "content": prompt}],
        # Slightly above zero, same rationale as the Gemini tier: a tutoring
        # answer benefits from a little fluency but should stay grounded.
        "temperature": 0.2,
    }

    try:
        response = requests.post(
            f"{settings.fallback_base_url.rstrip('/')}/chat/completions",
            headers={"Authorization": f"Bearer {settings.fallback_api_key}"},
            json=body,
            timeout=REQUEST_TIMEOUT,
        )
    except requests.RequestException as e:
        raise FallbackLLMError(f"Could not reach fallback provider: {e}") from e

    if response.status_code == 429:
        # OpenAI-dialect servers put the suggested wait in a Retry-After header.
        try:
            retry_after = max(1, int(float(response.headers.get("Retry-After", 30))))
        except (TypeError, ValueError):
            retry_after = 30
        raise FallbackLLMRateLimitError("Fallback provider rate limit reached", retry_after)

    try:
        payload = response.json()
    except ValueError as e:
        raise FallbackLLMError("Fallback provider returned a non-JSON response") from e

    if response.status_code != 200:
        message = "Fallback provider error"
        if isinstance(payload.get("error"), dict):
            message = payload["error"].get("message", message)
        raise FallbackLLMError(message)

    try:
        text = payload["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError):
        raise FallbackLLMError("Fallback provider returned no usable completion")

    if not isinstance(text, str) or not text.strip():
        raise FallbackLLMError("Fallback provider returned no usable completion")

    return text.strip()

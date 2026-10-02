"""OpenAI Responses API client used by Mathiva's chat and image workflows."""

import base64
from email.utils import parsedate_to_datetime
from datetime import datetime, timezone

import requests

from app.config import settings

REQUEST_TIMEOUT = 45


class OpenAIServiceError(RuntimeError):
    """The OpenAI request was misconfigured, unreachable, or unusable."""


class OpenAIRateLimitError(OpenAIServiceError):
    def __init__(self, message: str, retry_after: int = 30):
        super().__init__(message)
        self.retry_after = retry_after


def openai_available() -> bool:
    return bool(settings.openai_api_key)


def _retry_after_seconds(response) -> int:
    value = getattr(response, "headers", {}).get("retry-after")
    if not value:
        return 30
    try:
        return max(1, int(float(value)))
    except (TypeError, ValueError):
        try:
            target = parsedate_to_datetime(value)
            return max(1, int((target - datetime.now(timezone.utc)).total_seconds()))
        except (TypeError, ValueError, OverflowError):
            return 30


def _extract_output_text(payload: dict) -> str:
    direct = payload.get("output_text")
    if isinstance(direct, str) and direct.strip():
        return direct.strip()

    texts = []
    for item in payload.get("output", []):
        if not isinstance(item, dict) or item.get("type") != "message":
            continue
        for content in item.get("content", []):
            if isinstance(content, dict) and content.get("type") == "output_text":
                text = content.get("text")
                if isinstance(text, str):
                    texts.append(text)
    result = "\n".join(texts).strip()
    if not result:
        raise OpenAIServiceError("OpenAI returned no usable completion")
    return result


def _create_response(
    input_data, *, timeout: int = REQUEST_TIMEOUT, reasoning_effort: str = "low"
) -> str:
    if not openai_available():
        raise OpenAIServiceError("OPENAI_API_KEY not set")

    try:
        response = requests.post(
            f"{settings.openai_base_url.rstrip('/')}/responses",
            headers={
                "Authorization": f"Bearer {settings.openai_api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": settings.openai_model,
                "input": input_data,
                # GPT-5.4 only supports temperature when reasoning is disabled.
                # Low effort gives math questions useful reasoning while keeping
                # latency and token spend below the medium/high settings.
                "reasoning": {"effort": reasoning_effort},
                "text": {"verbosity": "low"},
                "max_output_tokens": 700,
            },
            timeout=timeout,
        )
    except requests.RequestException as exc:
        raise OpenAIServiceError(f"Could not reach OpenAI: {exc}") from exc

    try:
        payload = response.json()
    except ValueError as exc:
        raise OpenAIServiceError("OpenAI returned a non-JSON response") from exc

    if response.status_code == 429:
        message = payload.get("error", {}).get("message", "OpenAI rate limit reached")
        raise OpenAIRateLimitError(message, _retry_after_seconds(response))
    if response.status_code >= 400 or isinstance(payload.get("error"), dict):
        message = payload.get("error", {}).get("message", "OpenAI request failed")
        raise OpenAIServiceError(message)
    return _extract_output_text(payload)


def generate_text(prompt: str) -> str:
    """Generate a tutor response from text."""
    return _create_response(prompt, timeout=20)


def analyze_image(image_bytes: bytes, mime_type: str, prompt: str) -> str:
    """Analyze a camera/gallery image using a base64 data URL."""
    data_url = f"data:{mime_type};base64,{base64.b64encode(image_bytes).decode('ascii')}"
    return _create_response(
        [{
            "role": "user",
            "content": [
                {"type": "input_text", "text": prompt},
                {"type": "input_image", "image_url": data_url, "detail": "high"},
            ],
        }],
        reasoning_effort="low",
    )

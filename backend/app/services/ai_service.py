import requests

OLLAMA_URL = "http://localhost:11434/api/generate"


class AIServiceError(RuntimeError):
    """Raised when Ollama is unreachable or returns something that isn't a
    usable completion. Callers can catch this to give a clear "the tutor is
    unavailable" message instead of leaking a raw KeyError/ConnectionError."""


def generate_answer(prompt: str):

    try:
        response = requests.post(
            OLLAMA_URL,
            json={
                "model": "phi",
                "prompt": prompt,
                "stream": False,
                # Keep the model resident in VRAM between requests so sporadic
                # testing/demo usage doesn't repeatedly pay Ollama's cold-load
                # cost (its default keep_alive unloads after 5 minutes idle).
                "keep_alive": "30m",
                "options": {
                    # Hard cap on generated tokens. Phi (a base-ish model) tends
                    # to answer correctly in ~40 tokens then keep rambling for
                    # hundreds more -- measured 537 tokens (~8s) for a one-line
                    # answer. A concise tutor reply fits well under this, so the
                    # cap trims the wasted tail (roughly halving latency) without
                    # truncating real answers. Tune down if replies stay long.
                    "num_predict": 300,
                },
            },
            # Generation itself takes ~1-3s once the model is warm; this only
            # guards against Ollama being genuinely stuck (e.g. GPU contention),
            # so it fails predictably instead of hanging the request forever.
            timeout=90
        )
    except requests.RequestException as e:
        # Ollama not running / connection refused / timed out.
        raise AIServiceError(f"Could not reach the language model: {e}") from e

    # A non-2xx from Ollama (e.g. model not pulled) returns a JSON body with an
    # "error" key and no "response" -- surface it instead of KeyError-ing.
    try:
        payload = response.json()
    except ValueError as e:
        raise AIServiceError("Language model returned a non-JSON response") from e

    if "response" not in payload:
        raise AIServiceError(
            payload.get("error", "Language model returned no completion")
        )

    return payload["response"]
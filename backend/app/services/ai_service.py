import json

import requests

OLLAMA_URL = "http://localhost:11434/api/generate"

# Model + generation options shared by the streaming and non-streaming paths so
# the two can't drift apart (same model, same length cap).
MODEL = "phi"
GEN_OPTIONS = {
    # Hard cap on generated tokens. Phi (a base-ish model) tends to answer
    # correctly in ~40 tokens then keep rambling for hundreds more -- measured
    # 537 tokens (~8s) for a one-line answer. A concise tutor reply fits well
    # under this, so the cap trims the wasted tail (roughly halving latency)
    # without truncating real answers. Tune down if replies stay long.
    "num_predict": 300,
}
# Keep the model resident in VRAM between requests so sporadic testing/demo
# usage doesn't repeatedly pay Ollama's cold-load cost (its default keep_alive
# unloads after 5 minutes idle).
KEEP_ALIVE = "30m"
# Generation takes ~1-3s once the model is warm; this only guards against Ollama
# being genuinely stuck (e.g. GPU contention) so requests fail predictably
# instead of hanging forever.
REQUEST_TIMEOUT = 90


class AIServiceError(RuntimeError):
    """Raised when Ollama is unreachable or returns something that isn't a
    usable completion. Callers can catch this to give a clear "the tutor is
    unavailable" message instead of leaking a raw KeyError/ConnectionError."""


def generate_answer(prompt: str):

    try:
        response = requests.post(
            OLLAMA_URL,
            json={
                "model": MODEL,
                "prompt": prompt,
                "stream": False,
                "keep_alive": KEEP_ALIVE,
                "options": GEN_OPTIONS,
            },
            timeout=REQUEST_TIMEOUT,
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


def stream_answer(prompt: str):
    """Yield the completion incrementally as Ollama generates it.

    Same request as generate_answer but with stream=True: Ollama replies with
    newline-delimited JSON, one object per chunk ({"response": "...",
    "done": false}), then a final {"done": true}. We yield each text piece so the
    /api/ask/stream endpoint can forward tokens to the student as they arrive
    instead of making them wait ~seconds for the whole answer.

    Raises AIServiceError if Ollama can't be reached (before the first chunk).
    Once streaming has started a mid-stream drop just ends the generator -- the
    caller keeps whatever text arrived.
    """
    try:
        response = requests.post(
            OLLAMA_URL,
            json={
                "model": MODEL,
                "prompt": prompt,
                "stream": True,
                "keep_alive": KEEP_ALIVE,
                "options": GEN_OPTIONS,
            },
            stream=True,
            timeout=REQUEST_TIMEOUT,
        )
    except requests.RequestException as e:
        raise AIServiceError(f"Could not reach the language model: {e}") from e

    for line in response.iter_lines():
        if not line:
            continue
        try:
            payload = json.loads(line)
        except ValueError:
            continue  # skip a malformed line rather than abort the whole answer
        if payload.get("done"):
            break
        piece = payload.get("response")
        if piece:
            yield piece
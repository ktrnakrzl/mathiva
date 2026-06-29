import requests

OLLAMA_URL = "http://localhost:11434/api/generate"


def generate_answer(prompt: str):

    response = requests.post(
        OLLAMA_URL,
        json={
            "model": "phi",
            "prompt": prompt,
            "stream": False,
            # Keep the model resident in VRAM between requests so sporadic
            # testing/demo usage doesn't repeatedly pay Ollama's cold-load
            # cost (its default keep_alive unloads after 5 minutes idle).
            "keep_alive": "30m"
        },
        # Generation itself takes ~1-3s once the model is warm; this only
        # guards against Ollama being genuinely stuck (e.g. GPU contention),
        # so it fails predictably instead of hanging the request forever.
        timeout=90
    )

    return response.json()["response"]
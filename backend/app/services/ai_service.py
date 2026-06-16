import requests

OLLAMA_URL = "http://localhost:11434/api/generate"


def generate_answer(prompt: str):

    response = requests.post(
        OLLAMA_URL,
        json={
            "model": "phi",
            "prompt": prompt,
            "stream": False
        }
    )

    return response.json()["response"]
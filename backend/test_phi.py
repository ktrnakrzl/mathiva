import requests
import json

url = "http://localhost:11434/api/generate"

prompt = "What is 2 + 2?"

response = requests.post(url, json={
    "model": "phi",
    "prompt": prompt,
    "stream": False
})

result = response.json()
print(result["response"])
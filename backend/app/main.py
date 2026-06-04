from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import requests
import sys
import os

# Add ML path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../ml"))

from retrieval.test_retrieval import load_index_and_chunks

app = FastAPI(title="Mathiva API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/ask")
def ask(question: str):
    try:
        index, chunks = load_index_and_chunks()
        from sentence_transformers import SentenceTransformer
        model = SentenceTransformer("all-MiniLM-L6-v2")
        query_embedding = model.encode(question).astype("float32").reshape(1, -1)
        distances, indices = index.search(query_embedding, k=5)
        
        context = "\n\n".join([chunks[idx]["content"] for idx in indices[0]])
        
        prompt = f"""Based on this math content, answer the student's question clearly and concisely.

Content:
{context}

Student Question: {question}

Answer:"""
        
        response = requests.post("http://localhost:11434/api/generate", json={
            "model": "phi",
            "prompt": prompt,
            "stream": False
        })
        
        return {
            "question": question,
            "answer": response.json()["response"]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
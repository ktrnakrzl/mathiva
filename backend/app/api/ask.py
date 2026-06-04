from fastapi import APIRouter, HTTPException
import requests
import json
import sys
sys.path.insert(0, "../../ml")

from retrieval.test_retrieval import load_index_and_chunks

router = APIRouter(prefix="/api", tags=["ask"])

@router.post("/ask")
def ask(question: str):
    """
    Ask a question, retrieve relevant chunks, generate answer with Phi-3
    """
    try:
        # Load FAISS index and chunks
        index, chunks = load_index_and_chunks()
        
        # Retrieve relevant chunks
        from sentence_transformers import SentenceTransformer
        model = SentenceTransformer("all-MiniLM-L6-v2")
        query_embedding = model.encode(question).astype("float32").reshape(1, -1)
        distances, indices = index.search(query_embedding, k=5)
        
        # Get chunk content
        retrieved_chunks = [chunks[idx]["content"] for idx in indices[0]]
        context = "\n\n".join(retrieved_chunks)
        
        # Generate answer with Phi-3
        prompt = f"""Based on this math content, answer the student's question.

Content:
{context}

Student Question: {question}

Answer:"""
        
        response = requests.post("http://localhost:11434/api/generate", json={
            "model": "phi",
            "prompt": prompt,
            "stream": False
        })
        
        answer = response.json()["response"]
        
        return {
            "question": question,
            "answer": answer,
            "sources": [{"chunk_id": idx, "content": chunks[idx]["content"][:200]} for idx in indices[0]]
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
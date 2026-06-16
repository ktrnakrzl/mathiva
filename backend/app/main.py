from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import requests
import sys
import os
import json
import random

# Add ML path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../ml"))

# Safely import retrieval
try:
    from retrieval.test_retrieval import load_index_and_chunks
except Exception as e:
    print(f"Warning: Could not import retrieval: {e}")
    load_index_and_chunks = None

app = FastAPI(title="Mathiva API")

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/ask")
def ask(question: str):
    try:
        if load_index_and_chunks is None:
            raise HTTPException(status_code=500, detail="Retrieval module not loaded")
        
        index, chunks = load_index_and_chunks()
        from sentence_transformers import SentenceTransformer
        model = SentenceTransformer("all-MiniLM-L6-v2")
        query_embedding = model.encode(question).astype("float32").reshape(1, -1)
        distances, indices = index.search(query_embedding, k=5)
        
        context = "\n\n".join([chunks[idx]["content"] for idx in indices[0]])
        
        prompt = f"""You are a helpful math tutor. Answer the student's question clearly.

Relevant course material:
{context}

Student Question: {question}

If the question is covered in the course material above, use that. Otherwise, use your general knowledge to help.

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

@app.post("/solve")
def solve(equation: str, variable: str = "x"):
    """Solve a math equation"""
    try:
        from solver.math_solver import solve_equation
        result = solve_equation(equation, variable)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/quiz")
def quiz(subject: str = "General Mathematics", difficulty: str = "Easy", count: int = 5):
    """Generate quiz questions from Q&A pairs"""
    try:
        qa_path = os.path.join(os.path.dirname(__file__), "../../ml/retrieval/genmath_qa_pairs.json")
        with open(qa_path, 'r') as f:
            all_qa = json.load(f)
        
        if not all_qa:
            raise HTTPException(status_code=404, detail="No Q&A pairs found")
        
        selected = random.sample(all_qa, min(count, len(all_qa)))
        
        questions = []
        for i, qa in enumerate(selected):
            questions.append({
                "id": i + 1,
                "question": qa.get("question"),
                "answer": qa.get("answer"),
                "topic": qa.get("topic", "Unknown"),
                "difficulty": difficulty,
                "chunk_id": qa.get("chunk_id")
            })
        
        return {"subject": subject, "difficulty": difficulty, "questions": questions}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
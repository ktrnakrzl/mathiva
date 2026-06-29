from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import sys
import os
import json
import random

# Load backend/.env FIRST -- DATABASE_URL and JWT_SECRET are read from
# os.environ at import time by app.database.db / app.services.auth_service,
# so this must run before any app.* module is imported below.
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), "../.env"))

# Create app FIRST
app = FastAPI(title="Mathiva API")

# Add CORS Middleware SECOND
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Add ML path THIRD (before importing routers/modules that depend on it)
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../ml"))

# Now import and include routers FOURTH
from app.api.solve import router as solve_router
app.include_router(solve_router)

from app.api.ocr import router as ocr_router
app.include_router(ocr_router)

from app.api.ask import router as ask_router
app.include_router(ask_router)

from app.api.auth import router as auth_router
app.include_router(auth_router)

from app.api.quiz import router as quiz_router
app.include_router(quiz_router)

from app.database.db import Base, engine
# app.api.auth/app.api.quiz (imported above) already import
# app.database.models, which registers User/QuizAttempt on Base -- so
# create_all below picks both up.
Base.metadata.create_all(bind=engine)


@app.on_event("startup")
def warm_up_ollama():
    # Pay Ollama's model-load-into-VRAM cost once at server startup instead
    # of on a real user's first /api/ask request — without this, the first
    # request after any 5+ minute gap (Ollama's default keep_alive) can take
    # minutes instead of seconds.
    from app.services.ai_service import generate_answer
    try:
        generate_answer("Say OK.")
    except Exception as e:
        print(f"Warning: Ollama warm-up failed (is Ollama running?): {e}")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/quiz")
def quiz(subject: str = "General Mathematics", difficulty: str = "Easy", count: int = 5):
    """Generate quiz questions from Q&A pairs. Unrelated to the
    /api/quiz/submit and /api/user/progress routes (app.api.quiz) -- this
    is the older Q&A-sampling endpoint, different path prefix, no overlap."""
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
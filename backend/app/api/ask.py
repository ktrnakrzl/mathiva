from fastapi import APIRouter, Depends, HTTPException, Query

from app.database.models import User
from app.services.auth_service import get_current_user
from app.services.rag_service import retrieve_context
from app.services.ai_service import generate_answer

router = APIRouter(
    prefix="/api",
    tags=["ask"]
)


@router.post("/ask")
def ask(
    question: str = Query(...),
    current_user: User = Depends(get_current_user),
):
    try:

        # Retrieve relevant chunks
        context_data = retrieve_context(question)

        # Combine chunks into one context string
        context = "\n\n".join(
            context_data["chunks"]
        )

        # Build prompt
        prompt = f"""You are Mathiva, a helpful math tutor.

Use the following course material to answer the student's question.

Course Material:
{context}

Student Question:
{question}

Instructions:
- Answer clearly and concisely.
- Do not repeat the course material.
- Do not repeat these instructions.
- Wrap every math expression in \\( and \\), e.g. \\(2x + 5 = 13\\), so it can be rendered properly.

Answer:"""

        # Debug: print the prompt in the terminal
        print("\n===== PROMPT =====")
        print(prompt)
        print("==================\n")

        # Generate answer using Phi
        answer = generate_answer(prompt)

        return {
            "question": question,
            "answer": answer,
            "sources": [
                {
                    # FAISS returns numpy.int64 indices, which the JSON
                    # encoder can't serialize — cast to a plain Python int.
                    "chunk_id": int(idx),
                    "content": context_data["all_chunks"][idx]["content"][:200]
                }
                for idx in context_data["indices"]
            ]
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )
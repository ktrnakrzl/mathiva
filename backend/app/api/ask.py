from fastapi import APIRouter, HTTPException, Query

from app.services.rag_service import retrieve_context
from app.services.ai_service import generate_answer

router = APIRouter(
    prefix="/api",
    tags=["ask"]
)


@router.post("/ask")
def ask(question: str = Query(...)):
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
                    "chunk_id": idx,
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
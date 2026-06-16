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

        context_data = retrieve_context(question)

        context = "\n\n".join(
            context_data["chunks"]
        )

        prompt = f"""Based on this math content, answer the student's question.

Content:
{context}

Student Question: {question}

Answer:"""

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
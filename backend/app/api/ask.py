from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse

from app.database.models import User
from app.services.auth_service import get_current_user
from app.services.rag_service import retrieve_context
from app.services.ai_service import AIServiceError, generate_answer, stream_answer

router = APIRouter(
    prefix="/api",
    tags=["ask"]
)


def _retrieve_and_build_prompt(question: str):
    """Run RAG retrieval and assemble the tutor prompt. Shared by the JSON and
    streaming endpoints so both feed Phi exactly the same context + prompt."""
    context_data = retrieve_context(question)
    context = "\n\n".join(context_data["chunks"])

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

    return prompt, context_data


@router.post("/ask")
def ask(
    question: str = Query(...),
    current_user: User = Depends(get_current_user),
):
    try:
        prompt, context_data = _retrieve_and_build_prompt(question)

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


@router.post("/ask/stream")
def ask_stream(
    question: str = Query(...),
    current_user: User = Depends(get_current_user),
):
    """Same RAG + Phi answer as /ask, streamed token-by-token as plain text so
    the chat UI can render it as it arrives (the useful answer lands in the
    first ~40 tokens, so this makes the tutor feel near-instant)."""
    prompt, _ = _retrieve_and_build_prompt(question)

    # Prime the generator so a can't-reach-Ollama failure becomes a clean 503
    # *before* we commit to a 200 streaming response. Once the first chunk is
    # out, a mid-stream drop simply ends the stream with whatever arrived.
    generator = stream_answer(prompt)
    try:
        first_chunk = next(generator)
    except AIServiceError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except StopIteration:
        first_chunk = None

    def body():
        if first_chunk is not None:
            yield first_chunk
        yield from generator

    return StreamingResponse(body(), media_type="text/plain")
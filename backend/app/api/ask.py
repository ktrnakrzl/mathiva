from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import StreamingResponse

from app.database.models import User
from app.rate_limit import limiter
from app.services.auth_service import get_current_user
from app.services.rag_service import retrieve_context
from app.services.ai_service import AIServiceError, stream_answer
from app.services.answer_service import answer_question, build_tutor_prompt

router = APIRouter(
    prefix="/api",
    tags=["ask"]
)


def _retrieve_and_build_prompt(question: str):
    """Run RAG retrieval and assemble the tutor prompt. Used by the streaming
    endpoint (the non-streaming /ask goes through the full answer cascade in
    answer_service instead)."""
    context_data = retrieve_context(question)
    context = "\n\n".join(context_data["chunks"])
    return build_tutor_prompt(context, question), context_data


# `request: Request` is required by slowapi's limiter. The limit protects the
# free-tier Gemini quota this cascade can reach; per client IP.
@router.post("/ask")
@limiter.limit("20/minute")
def ask(
    request: Request,
    question: str = Query(...),
    current_user: User = Depends(get_current_user),
):
    # Full answer cascade: RAG context -> T5 + Phi-3 (local combination) ->
    # Gemini only if the local answer is still weak. Returns `model_used` so the
    # UI can show which tier answered.
    try:
        return answer_question(question)
    except AIServiceError as e:
        # Every model tier was unavailable / produced junk.
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/ask/stream")
@limiter.limit("20/minute")
def ask_stream(
    request: Request,
    question: str = Query(...),
    current_user: User = Depends(get_current_user),
):
    """Same RAG + Phi answer as /ask, streamed token-by-token as plain text so
    the chat UI can render it as it arrives (the useful answer lands in the
    first ~40 tokens, so this makes the tutor feel near-instant).

    When Ollama isn't reachable -- e.g. the hosted, Gemini-backed deployment has
    no local LLM -- true token streaming isn't possible, so we fall back to the
    full /ask cascade (which escalates to Gemini) and deliver its answer as a
    single chunk. The client consumes the same text/plain stream either way; it
    just arrives all at once instead of token-by-token."""
    prompt, _ = _retrieve_and_build_prompt(question)

    # Prime the generator so a can't-reach-Ollama failure is caught here, before
    # we commit to a 200 streaming response. Once the first chunk is out, a
    # mid-stream drop simply ends the stream with whatever arrived.
    generator = stream_answer(prompt)
    try:
        first_chunk = next(generator)
    except AIServiceError:
        # No local Ollama -> answer via the cascade (Gemini) instead of 503ing.
        try:
            result = answer_question(question)
        except AIServiceError as e:
            # Every tier is down (no Ollama, no T5, no Gemini) -> genuine 503.
            raise HTTPException(status_code=503, detail=str(e))

        def cascade_body():
            yield result["answer"]

        return StreamingResponse(cascade_body(), media_type="text/plain")
    except StopIteration:
        first_chunk = None

    def body():
        if first_chunk is not None:
            yield first_chunk
        yield from generator

    return StreamingResponse(body(), media_type="text/plain")
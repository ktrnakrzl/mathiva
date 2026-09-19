import logging
import time

from fastapi import APIRouter, Body, Depends, HTTPException, Query, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from app.database.models import User
from app.rate_limit import limiter
from app.config import settings
from app.services.auth_service import get_current_user
from app.services.rag_service import retrieve_context
from app.services.ai_service import AIServiceError, stream_answer
from app.services.answer_service import (
    TutorBusyError,
    answer_question,
    build_tutor_prompt,
    try_symbolic_math_answer,
)

router = APIRouter(
    prefix="/api",
    tags=["ask"]
)
logger = logging.getLogger(__name__)


class ChatTurn(BaseModel):
    role: str
    text: str


class AskRequest(BaseModel):
    question: str
    history: list[ChatTurn] = Field(default_factory=list)


def _format_history(history: list[ChatTurn]) -> str:
    lines = []
    for turn in history[-8:]:
        text = " ".join(turn.text.split())
        if not text:
            continue
        role = "Student" if turn.role == "user" else "Tutor"
        lines.append(f"{role}: {text[:1200]}")
    return "\n".join(lines)


def _resolve_ask_payload(payload: AskRequest | None, question: str | None):
    if payload is not None:
        clean_question = payload.question.strip()
        if clean_question:
            return clean_question, _format_history(payload.history)
    if question is not None and question.strip():
        return question.strip(), ""
    raise HTTPException(status_code=422, detail="Question is required.")


def _retrieve_and_build_prompt(question: str, history: str = ""):
    """Run RAG retrieval and assemble the tutor prompt. Used by the streaming
    endpoint (the non-streaming /ask goes through the full answer cascade in
    answer_service instead)."""
    context_data = retrieve_context(question)
    context = "\n\n".join(context_data["chunks"])
    return build_tutor_prompt(context, question, history), context_data


# `request: Request` is required by slowapi's limiter. The limit protects the
# free-tier Gemini quota this cascade can reach; per client IP.
@router.post("/ask")
@limiter.limit("20/minute")
def ask(
    request: Request,
    payload: AskRequest | None = Body(default=None),
    question: str | None = Query(default=None),
    current_user: User = Depends(get_current_user),
):
    # Full answer cascade: RAG context -> T5 + Phi-3 (local combination) ->
    # Gemini only if the local answer is still weak. Returns `model_used` so the
    # UI can show which tier answered.
    resolved_question, history = _resolve_ask_payload(payload, question)
    try:
        return answer_question(resolved_question, history)
    except TutorBusyError as e:
        # Temporary rate limit -- tell the client to retry shortly.
        raise HTTPException(status_code=503, detail=str(e),
                            headers={"Retry-After": str(e.retry_after)})
    except AIServiceError as e:
        # Every model tier was unavailable / produced junk.
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/ask/stream")
@limiter.limit("20/minute")
def ask_stream(
    request: Request,
    payload: AskRequest | None = Body(default=None),
    question: str | None = Query(default=None),
    current_user: User = Depends(get_current_user),
):
    """Same RAG + Phi answer as /ask, streamed token-by-token as plain text so
    the chat UI can render it as it arrives (the useful answer lands in the
    first ~40 tokens, so this makes the tutor feel near-instant).

    True token streaming is only attempted when ENABLE_OLLAMA_STREAM=true and
    Ollama is not disabled. Hosted deployments use the full /ask cascade
    (Gemini/fallback) and deliver its answer as a single chunk; the client
    consumes the same text/plain stream either way."""
    started = time.perf_counter()
    resolved_question, history = _resolve_ask_payload(payload, question)
    symbolic_answer = try_symbolic_math_answer(resolved_question)
    if symbolic_answer:
        def symbolic_body():
            logger.info(
                "ask_stream model_used=symbolic elapsed_ms=%d",
                int((time.perf_counter() - started) * 1000),
            )
            yield symbolic_answer

        return StreamingResponse(symbolic_body(), media_type="text/plain")

    if settings.disable_ollama or not settings.enable_ollama_stream:
        try:
            result = answer_question(resolved_question, history)
        except TutorBusyError as e:
            raise HTTPException(status_code=503, detail=str(e),
                                headers={"Retry-After": str(e.retry_after)})
        except AIServiceError as e:
            raise HTTPException(status_code=503, detail=str(e))

        def cascade_body():
            logger.info(
                "ask_stream model_used=%s elapsed_ms=%d",
                result.get("model_used", "cascade"),
                int((time.perf_counter() - started) * 1000),
            )
            yield result["answer"]

        return StreamingResponse(cascade_body(), media_type="text/plain")

    prompt, _ = _retrieve_and_build_prompt(resolved_question, history)

    # Prime the generator so a can't-reach-Ollama failure is caught here, before
    # we commit to a 200 streaming response. Once the first chunk is out, a
    # mid-stream drop simply ends the stream with whatever arrived.
    generator = stream_answer(prompt)
    try:
        first_chunk = next(generator)
    except AIServiceError:
        # No local Ollama -> answer via the cascade (Gemini) instead of 503ing.
        try:
            result = answer_question(resolved_question, history)
        except TutorBusyError as e:
            raise HTTPException(status_code=503, detail=str(e),
                                headers={"Retry-After": str(e.retry_after)})
        except AIServiceError as e:
            # Every tier is down (no Ollama, no T5, no Gemini) -> genuine 503.
            raise HTTPException(status_code=503, detail=str(e))

        def cascade_body():
            logger.info(
                "ask_stream model_used=%s elapsed_ms=%d",
                result.get("model_used", "cascade"),
                int((time.perf_counter() - started) * 1000),
            )
            yield result["answer"]

        return StreamingResponse(cascade_body(), media_type="text/plain")
    except StopIteration:
        first_chunk = None

    def body():
        logger.info(
            "ask_stream model_used=ollama-stream elapsed_ms=%d",
            int((time.perf_counter() - started) * 1000),
        )
        if first_chunk is not None:
            yield first_chunk
        yield from generator

    return StreamingResponse(body(), media_type="text/plain")

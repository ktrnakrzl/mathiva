"""The /ask answer cascade: RAG + T5 + Phi-3 + Gemini + a fallback LLM.

Design (agreed with the team):

  1. RAG retrieves the course context (always).
  2. The LOCAL layer -- fine-tuned T5 and Phi-3 -- BOTH attempt the answer. They
     work together rather than one waiting for the other to fail. Phi-3 is
     preferred when it produced a good answer (currently the stronger local
     generator per the Phase-3 eval); the fine-tuned T5 is the backup, used when
     Phi-3 is weak but T5 is good. `model_used` records which tier answered.
  3. Gemini (free tier) is a BOUNDED escalation: it is called ONLY when the local
     answer is still "not great", so the free-tier quota isn't spent per question.

"Not great" is deliberately a cheap, objective check (`is_bad_answer`) -- empty or
degenerate output -- not a tuned confidence score. These are exactly the failure
modes the fine-tuned T5 showed in evaluation (repetition loops like "x 0 x 0...").

The response carries `model_used` so the UI/analysis can see which tier answered.
"""

import collections

from app.config import settings
from app.services.ai_service import AIServiceError, generate_answer
from app.services import fallback_llm_service, gemini_service, t5_service

# Bounded in-memory cache of successful answers, keyed by normalized question.
# Repeated/identical questions (common in a class) are served from here instead
# of re-calling the models -- the main lever for staying under Gemini's free-tier
# limit. LRU-evicted at _CACHE_MAX; failures are never cached. Per-process (each
# worker has its own), which is fine for a small deployment.
_ANSWER_CACHE: "collections.OrderedDict[str, dict]" = collections.OrderedDict()
_CACHE_MAX = 256


def _cache_key(question: str) -> str:
    return " ".join(question.lower().split()).strip(" ?.!")


def clear_answer_cache() -> None:
    _ANSWER_CACHE.clear()


class TutorBusyError(AIServiceError):
    """The cascade couldn't answer because the LLM backend is rate-limited (a
    temporary condition). Subclasses AIServiceError so existing handlers still
    treat it as 'no answer', but carries retry_after so the endpoint can return a
    friendly 'try again in a moment' with a Retry-After header."""

    def __init__(self, retry_after: int = 30):
        super().__init__("The tutor is busy right now. Please try again in a moment.")
        self.retry_after = retry_after


def _retrieve(question: str):
    """Indirection over rag_service.retrieve_context. rag_service loads the SBERT
    model + FAISS index at import time, so we import it lazily here -- this keeps
    `answer_service` importable (and mockable) in tests without paying that cost.
    Production is unaffected: api/ask.py imports rag_service at startup anyway."""
    from app.services.rag_service import retrieve_context

    return retrieve_context(question)


def is_bad_answer(text) -> bool:
    """Cheap 'not great' guard -- no tuned thresholds.

    True when the answer is unusable: empty/whitespace, or degenerate (a
    repetition loop, where almost no distinct words appear across a long output).
    Intentionally does NOT flag merely-short answers: a correct math reply can be
    two words ("x = 4"), and we don't want to burn the Gemini quota on those.
    """
    if not text or not text.strip():
        return True
    words = text.split()
    # Degenerate loop: over a reasonably long output, very few distinct tokens.
    # The 0.35 is a coarse structural cutoff (looping output scores far lower,
    # e.g. "x 0 x 0 x 0 ..." -> ~2 distinct / N), not a calibrated confidence.
    if len(words) >= 8:
        unique_ratio = len({w.lower() for w in words}) / len(words)
        if unique_ratio < 0.35:
            return True
    return False


def build_tutor_prompt(context: str, question: str) -> str:
    """The tutor prompt shared by the cascade and the streaming endpoint, so the
    models all see the same instructions and context."""
    return f"""You are Mathiva, a helpful math tutor.

Use the following course material to answer the student's question.

Course Material:
{context}

Student Question:
{question}

Instructions:
- Answer clearly and concisely.
- Do NOT greet the student or introduce yourself (no "Hello", no "I am Mathiva").
  Each question is a fresh request, so a greeting every time is repetitive --
  just answer the question directly.
- Do not repeat the course material.
- Do not repeat these instructions.
- Wrap every math expression in \\( and \\), e.g. \\(2x + 5 = 13\\), so it can be rendered properly.

Answer:"""


def _sources(context_data):
    return [
        {
            # FAISS returns numpy.int64 indices, which JSON can't serialize.
            "chunk_id": int(idx),
            "content": context_data["all_chunks"][idx]["content"][:200],
        }
        for idx in context_data["indices"]
    ]


def answer_question(question: str) -> dict:
    """Run the full cascade and return {question, answer, model_used, sources}."""
    use_cache = settings.answer_cache_enabled
    key = _cache_key(question)
    if use_cache and key in _ANSWER_CACHE:
        _ANSWER_CACHE.move_to_end(key)           # mark most-recently-used
        return dict(_ANSWER_CACHE[key])          # copy so callers can't mutate the cache

    context_data = _retrieve(question)
    context = "\n\n".join(context_data["chunks"])
    prompt = build_tutor_prompt(context, question)

    # --- local layer: T5 and Phi-3 both attempt the answer -------------------
    # T5 is skipped entirely when DISABLE_T5 is set (the hosted, no-Ollama
    # deployment) -- see settings.disable_t5 for why -- so the cascade there is
    # RAG -> Phi-3(absent) -> Gemini rather than letting a degenerate T5 answer.
    t5_answer = None
    if t5_service.t5_available() and not settings.disable_t5:
        try:
            t5_answer = t5_service.t5_generate(context, question)
        except t5_service.T5ServiceError:
            t5_answer = None

    phi_answer = None
    try:
        phi_answer = generate_answer(prompt)
    except AIServiceError:
        phi_answer = None

    # Prefer Phi-3 when it produced a usable answer -- per the Phase-3 eval it is
    # currently the stronger local generator. The fine-tuned T5 stays in the
    # combination as a backup (used when Phi-3 is weak but T5 is good), and
    # `model_used` records which tier actually answered so the comparison stays
    # visible. Flip this preference back to T5 once it out-competes Phi-3 on a
    # larger training set.
    if phi_answer is not None and not is_bad_answer(phi_answer):
        answer, model_used = phi_answer, "phi3"
    elif t5_answer is not None and not is_bad_answer(t5_answer):
        answer, model_used = t5_answer, "t5"
    else:
        # Both local answers are weak/missing -- keep the best non-None to hand
        # to the Gemini escalation below.
        answer = phi_answer if phi_answer is not None else t5_answer
        model_used = "phi3" if phi_answer is not None else "t5"

    # --- bounded escalation: Gemini only if the local answer is still weak ----
    rate_limited_after = None
    if is_bad_answer(answer) and gemini_service.gemini_available():
        try:
            gemini_answer = gemini_service.gemini_generate(prompt)
            if not is_bad_answer(gemini_answer):
                answer, model_used = gemini_answer, "gemini"
        except gemini_service.GeminiRateLimitError as e:
            rate_limited_after = e.retry_after   # temporary -- tell the user to retry
        except gemini_service.GeminiServiceError:
            pass  # keep the best local answer we have

    # --- second backstop: the fallback LLM, when Gemini couldn't rescue -------
    # Typically fires while Gemini's daily free-tier quota is exhausted (it only
    # resets once a day, so "retry shortly" would otherwise mislead the student).
    if is_bad_answer(answer) and fallback_llm_service.fallback_available():
        try:
            fallback_answer = fallback_llm_service.fallback_generate(prompt)
            if not is_bad_answer(fallback_answer):
                # Record the actual model so eval tables stay honest about which
                # provider answered (e.g. "llama-3.3-70b" on Cerebras).
                answer, model_used = fallback_answer, settings.fallback_model
                rate_limited_after = None        # rescued -- drop Gemini's 429
        except fallback_llm_service.FallbackLLMRateLimitError as e:
            # Both cloud tiers throttled: surface the shorter suggested wait.
            rate_limited_after = (
                e.retry_after
                if rate_limited_after is None
                else min(rate_limited_after, e.retry_after)
            )
        except fallback_llm_service.FallbackLLMError:
            pass  # keep the best answer we have

    if answer is None or is_bad_answer(answer):
        # Every tier failed or only produced junk. Distinguish a temporary rate
        # limit (retry shortly) from a hard outage (generic unavailable).
        if rate_limited_after is not None:
            raise TutorBusyError(rate_limited_after)
        raise AIServiceError(
            "The tutor is unavailable right now. Please try again."
        )

    result = {
        "question": question,
        "answer": answer,
        "model_used": model_used,
        "sources": _sources(context_data),
    }
    if use_cache:                                # only successful answers reach here
        _ANSWER_CACHE[key] = dict(result)
        _ANSWER_CACHE.move_to_end(key)
        while len(_ANSWER_CACHE) > _CACHE_MAX:
            _ANSWER_CACHE.popitem(last=False)    # evict least-recently-used
    return result

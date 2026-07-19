"""The /ask answer cascade: RAG + T5 + Phi-3 + Gemini, working as a combination.

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

from app.config import settings
from app.services.ai_service import AIServiceError, generate_answer
from app.services import gemini_service, t5_service


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
    if is_bad_answer(answer) and gemini_service.gemini_available():
        try:
            gemini_answer = gemini_service.gemini_generate(prompt)
            if not is_bad_answer(gemini_answer):
                answer, model_used = gemini_answer, "gemini"
        except gemini_service.GeminiServiceError:
            pass  # keep the best local answer we have

    if answer is None or is_bad_answer(answer):
        # Every tier failed or only produced junk.
        raise AIServiceError(
            "The tutor is unavailable right now. Please try again."
        )

    return {
        "question": question,
        "answer": answer,
        "model_used": model_used,
        "sources": _sources(context_data),
    }

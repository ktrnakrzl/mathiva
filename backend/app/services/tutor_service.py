from app.services import gemini_service
from app.services.ai_service import AIServiceError, generate_answer


def _plain_explanation(problem: str, solution_text: str) -> str:
    """Last-resort explanation when no LLM explainer is reachable.

    The symbolic solver has *already* found the correct answer -- that's the
    valuable part -- so a missing tutor model must not sink the whole solve.
    We return a clear statement of the result instead of raising."""
    return f"The solution to \\({problem}\\) is \\({solution_text}\\)."


def explain_solution(problem: str, solutions: list[str]):
    solution_text = ", ".join(solutions)

    prompt = f"""
You are a mathematics tutor for Senior High School students.

Problem:
{problem}

The symbolic solver found: {solution_text}

Write the worked solution as a list of clear steps. Follow these rules exactly:
- Output ONLY the steps. No greeting, no introduction, and no closing remark.
- Put each step on its OWN line. Do not number the steps yourself -- they are
  numbered automatically in the app.
- Each line is one step that states, in plain language, what you do AND why you
  do it (e.g. "Subtract 3 from both sides to isolate the term with x").
- Show the math for the step and wrap every math expression in \\( and \\),
  e.g. \\(2x + 5 = 13\\).
- Make the LAST line state the final answer.
"""

    # Same cascade as the /ask path: prefer the local model (Ollama) when it's
    # running, fall back to the free Gemini tier otherwise. Without this the OCR
    # solver was dead in the hosted, no-Ollama deployment -- every successfully
    # read+solved equation crashed here on the unreachable Ollama call. If
    # neither explainer is reachable, degrade to a plain statement of the
    # already-correct answer rather than failing the solve.
    try:
        return generate_answer(prompt)
    except AIServiceError:
        pass

    if gemini_service.gemini_available():
        try:
            return gemini_service.gemini_generate(prompt)
        except gemini_service.GeminiServiceError:
            pass

    return _plain_explanation(problem, solution_text)
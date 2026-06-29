from app.services.ai_service import generate_answer


def explain_solution(problem: str, solutions: list[str]):

    solution_text = ", ".join(solutions)

    prompt = f"""
You are a mathematics tutor for Senior High School students.

Problem:
{problem}

The symbolic solver found these solutions:
{solution_text}

Explain how to solve this problem step-by-step in simple language.
Show the mathematical process and conclude with the final answer.
Wrap every math expression in \\( and \\), e.g. \\(2x + 5 = 13\\), so it can be rendered properly.
"""

    explanation = generate_answer(prompt)

    return explanation
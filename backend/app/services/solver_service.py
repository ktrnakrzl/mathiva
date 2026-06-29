from solver.math_solver import solve_equation, solve_latex
from app.services.tutor_service import explain_solution


def solve_problem(equation: str):
    result = solve_equation(equation)

    if not result["success"]:
        return result

    explanation = explain_solution(
        equation,
        result["solutions"]
    )

    return {
        "problem": equation,
        "solutions": result["solutions"],
        "answer": result["answer"],
        "explanation": explanation,
        "success": True
    }


def solve_problem_from_latex(latex: str):
    result = solve_latex(latex)

    if not result["success"]:
        return result

    explanation = explain_solution(
        latex,
        result["solutions"]
    )

    return {
        "problem": latex,
        "variable": result["variable"],
        "solutions": result["solutions"],
        "answer": result["answer"],
        "explanation": explanation,
        "success": True
    }
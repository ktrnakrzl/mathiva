from solver.math_solver import solve_equation
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
        "explanation": explanation,
        "success": True
    }
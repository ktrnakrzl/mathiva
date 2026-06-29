from sympy import latex, symbols, solve, diff, integrate, simplify
from sympy.parsing.sympy_parser import parse_expr
from sympy.parsing.latex import parse_latex


def _build_answer(variable, solutions):
    """Builds a single ready-to-render answer string, e.g.
    "\\(x = 4\\)" or "\\(x = -1\\) or \\(x = -3/2\\)" for multiple roots --
    using real LaTeX (sympy.latex) rather than plain str() so fractions,
    roots, etc. render as actual math notation on the frontend."""
    if variable is None:
        return " or ".join(f"\\({latex(sol)}\\)" for sol in solutions)
    return " or ".join(f"\\({variable} = {latex(sol)}\\)" for sol in solutions)

def solve_latex(latex_str):
    """
    Solve an equation given as a LaTeX string (e.g. output from pix2tex OCR).
    Input: "2x + 5 = 13" or "x^2 - 4 = 0"

    Solves for whichever variable the OCR'd expression actually contains
    rather than assuming "x" — OCR output can render the variable as a
    different case (e.g. "X") than expected.
    """
    try:
        expr = parse_latex(latex_str)

        # parse_latex returns an Eq for "=" expressions, otherwise a bare expression
        solutions = solve(expr)
        variable = next(iter(expr.free_symbols), None)
        variable_str = str(variable) if variable is not None else None

        return {
            "expression": latex_str,
            "variable": variable_str,
            "solutions": [str(sol) for sol in solutions],
            "answer": _build_answer(variable_str, solutions),
            "success": True
        }
    except Exception as e:
        return {
            "error": str(e),
            "success": False
        }

def solve_equation(equation_str, variable="x"):
    """
    Solve an equation. Input: "x**2 - 4" or "x**2 - 4 = 0"
    """
    try:
        x = symbols(variable)
        
        # Handle "=" in equation
        if "=" in equation_str:
            left, right = equation_str.split("=")
            expr = parse_expr(left) - parse_expr(right)
        else:
            expr = parse_expr(equation_str)
        
        # Solve
        solutions = solve(expr, x)

        return {
            "expression": equation_str,
            "variable": variable,
            "solutions": [str(sol) for sol in solutions],
            "answer": _build_answer(variable, solutions),
            "success": True
        }
    except Exception as e:
        return {
            "error": str(e),
            "success": False
        }

def get_derivative(expr_str, variable="x"):
    """Return the derivative of an expression."""
    try:
        x = symbols(variable)
        expr = parse_expr(expr_str)
        derivative = diff(expr, x)
        return {
            "expression": expr_str,
            "variable": variable,
            "derivative": str(derivative),
            "success": True
        }
    except Exception as e:
        return {
            "error": str(e),
            "success": False
        }

# Test
if __name__ == "__main__":
    print(solve_equation("x**2 - 4"))
    print(solve_equation("2*x + 3 = 7"))
    print(get_derivative("x**3 + 2*x**2"))

    

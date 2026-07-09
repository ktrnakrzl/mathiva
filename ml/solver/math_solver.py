from sympy import Basic, latex, symbols, solve, diff, integrate, simplify
from sympy.parsing.sympy_parser import parse_expr
from sympy.parsing.latex import parse_latex


# Student-facing message for when a scanned photo can't be turned into a
# solvable equation. Deliberately generic -- the raw parser/OCR error ("I don't
# understand this", stray-symbol names) is not something a Grade 11 student can
# act on. The actionable advice is "retake the photo."
UNREADABLE_MESSAGE = (
    "Sorry, I couldn't read a clear equation from that image. Try retaking the "
    "photo with good lighting and only the equation in the frame."
)
NO_REAL_SOLUTION_MESSAGE = "This equation has no real-number solution."


def _is_real_number(sol):
    """True only for a concrete, finite, real numeric solution (e.g. 2, -3/2).

    Rejects the shapes garbled OCR tends to produce: dict solutions from
    underdetermined systems (multiple stray symbols), purely symbolic answers,
    and complex/infinite roots. This is the guard that stops a nonsense scan
    from being reported as a confident, wrong answer."""
    return (
        isinstance(sol, Basic)
        and sol.is_number
        and bool(sol.is_real)
        and bool(sol.is_finite)
    )


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

    OCR output is untrusted: a blurry or handwritten photo can yield LaTeX that
    still *parses* into a SymPy object but is mathematical nonsense (stray
    symbols like "mathbf", no real roots, etc.). Each step below is guarded so
    such input returns an honest failure instead of a confidently-wrong answer.
    """
    try:
        expr = parse_latex(latex_str)
    except Exception:
        return {"expression": latex_str, "error": UNREADABLE_MESSAGE, "success": False}

    # A real scanned equation solves for exactly one unknown. Zero free symbols
    # means no variable was read; more than one almost always means OCR invented
    # junk symbols (e.g. "\mathbf{x}" -> a stray "mathbf" symbol).
    variables = sorted(expr.free_symbols, key=str)
    if len(variables) != 1:
        return {"expression": latex_str, "error": UNREADABLE_MESSAGE, "success": False}

    variable = variables[0]
    try:
        raw_solutions = solve(expr, variable)
    except Exception:
        return {"expression": latex_str, "error": UNREADABLE_MESSAGE, "success": False}

    solutions = [sol for sol in raw_solutions if _is_real_number(sol)]
    if not solutions:
        # Distinguish "read fine but genuinely has no real answer" (e.g.
        # x^2 + 4 = 0) from "couldn't make sense of the scan" -- the former is
        # an honest math result, the latter tells the student to retake the photo.
        concrete = raw_solutions and all(
            isinstance(sol, Basic) and sol.is_number for sol in raw_solutions
        )
        message = NO_REAL_SOLUTION_MESSAGE if concrete else UNREADABLE_MESSAGE
        return {"expression": latex_str, "error": message, "success": False}

    variable_str = str(variable)
    return {
        "expression": latex_str,
        "variable": variable_str,
        "solutions": [str(sol) for sol in solutions],
        "answer": _build_answer(variable_str, solutions),
        "success": True,
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

    

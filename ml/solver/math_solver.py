import re

from sympy import Basic, latex, symbols, solve, diff, integrate, simplify
from sympy.parsing.sympy_parser import (
    parse_expr,
    standard_transformations,
    implicit_multiplication_application,
    convert_xor,
)
from sympy.parsing.latex import parse_latex

# Accept the notation students actually type, not strict Python syntax:
#   "2x"  -> 2*x   (implicit multiplication)
#   "x^2" -> x**2  (caret as exponent)
# Without these, parse_expr rejects "2x + 3 = 13" with "invalid syntax".
_TRANSFORMS = standard_transformations + (
    implicit_multiplication_application,
    convert_xor,
)


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


def _evaluate_arithmetic(display, expr):
    """Evaluate a variable-free scan/expression -- plain arithmetic like
    "89 + 82" or "1/2 + 1/3" -- to a single number.

    The solver is built around solving *equations* for an unknown, so an
    expression with no variable used to be rejected as "not a clear equation".
    But a student photographs (or types) arithmetic too, so we compute it
    instead. Guarded exactly like the equation path: only a concrete, finite,
    real value is returned, so a garbled numeric scan still fails safe rather
    than reporting a confident, wrong number."""
    try:
        value = simplify(expr)
    except Exception:
        return {"expression": display, "error": UNREADABLE_MESSAGE, "success": False}
    if not _is_real_number(value):
        return {"expression": display, "error": UNREADABLE_MESSAGE, "success": False}
    return {
        "expression": display,
        "variable": None,
        "solutions": [str(value)],
        "answer": _build_answer(None, [value]),
        "success": True,
    }


# Pure styling commands pix2tex wraps around perfectly readable variables --
# it renders letters in bold, so "x" comes back as "\mathbf{x}". These carry no
# mathematical meaning; left in, they parse into a stray "mathbf" symbol and get
# an otherwise-correct equation wrongly rejected as garbled.
_FORMAT_CMDS = (
    "mathbf", "mathrm", "mathit", "mathsf", "mathtt", "mathcal",
    "textbf", "textrm", "text", "operatorname", "bf", "rm", "it", "displaystyle",
)

# LaTeX commands that can legitimately appear in a Grade-11 scanned equation.
# After we strip the formatting above, ANY other surviving command is treated
# as a garbled-scan signal (see _has_unreadable_command): removing \mathbf also
# removed the extra free symbol the old guard relied on, so junk like a stray
# "\times" in an exponent would otherwise slip through as a confident wrong
# answer. Failing safe (ask for a clearer photo) is the whole module's posture.
_SAFE_COMMANDS = frozenset({"frac", "sqrt", "cdot", "left", "right"})


def _normalize_ocr_latex(latex_str):
    """Strip pix2tex's formatting-only wrappers, e.g. '\\mathbf{x}' -> 'x'.

    Handles both the braced form (\\mathbf{x}) and the bare group form
    ({\\bf x}); loops until stable so nested wrappers are fully removed."""
    prev = None
    while prev != latex_str:
        prev = latex_str
        for cmd in _FORMAT_CMDS:
            latex_str = re.sub(r"\\" + cmd + r"\s*\{([^{}]*)\}", r"\1", latex_str)
            latex_str = re.sub(r"\\" + cmd + r"(?![a-zA-Z])", "", latex_str)
    return latex_str


def _has_unreadable_command(latex_str):
    """True if a non-math LaTeX command survives normalization -- a reliable
    signal the scan was garbled rather than a solvable equation."""
    return any(
        m.group(1) not in _SAFE_COMMANDS
        for m in re.finditer(r"\\([a-zA-Z]+)", latex_str)
    )


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
    # Drop pix2tex's cosmetic bolding first (so a correctly-read equation isn't
    # rejected), then bail if any non-math command remains (so garbled scans
    # that were only being caught *by* that bolding are still rejected).
    latex_str = _normalize_ocr_latex(latex_str)
    if _has_unreadable_command(latex_str):
        return {"expression": latex_str, "error": UNREADABLE_MESSAGE, "success": False}

    try:
        expr = parse_latex(latex_str)
    except Exception:
        return {"expression": latex_str, "error": UNREADABLE_MESSAGE, "success": False}

    variables = sorted(expr.free_symbols, key=str)

    # No variable -> the scan is plain arithmetic (e.g. "89 + 82"), not an
    # equation. Evaluate it rather than rejecting it, so the scanner handles the
    # arithmetic a student photographs too. (An equation with no unknown, like a
    # relational that simplified to True/False, isn't a real number and so still
    # fails safe inside the evaluator.)
    if len(variables) == 0:
        return _evaluate_arithmetic(latex_str, expr)

    # A real scanned equation solves for exactly one unknown. More than one
    # almost always means OCR invented junk symbols (e.g. "\mathbf{x}" -> a
    # stray "mathbf" symbol).
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
            expr = parse_expr(left, transformations=_TRANSFORMS) - parse_expr(
                right, transformations=_TRANSFORMS
            )
        else:
            expr = parse_expr(equation_str, transformations=_TRANSFORMS)

        # Variable-free input (e.g. "89 + 82") is arithmetic, not an equation:
        # evaluate it to a number instead of solving for x -- which would find
        # no solution and return an empty answer.
        if not expr.free_symbols and "=" not in equation_str:
            return _evaluate_arithmetic(equation_str, expr)

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
        expr = parse_expr(expr_str, transformations=_TRANSFORMS)
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

    

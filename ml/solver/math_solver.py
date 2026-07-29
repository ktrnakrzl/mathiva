import re

from sympy import (
    Basic,
    Eq,
    Ge,
    Gt,
    Le,
    Lt,
    latex,
    oo,
    symbols,
    solve,
    diff,
    integrate,
    simplify,
)
from sympy.core.relational import Equality, Relational
from sympy.logic.boolalg import BooleanAtom
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
NO_INEQUALITY_SOLUTION_MESSAGE = "This inequality has no solution."
ALL_REALS_MESSAGE = "This holds for every real number."
NO_SYSTEM_SOLUTION_MESSAGE = "This system has no solution."


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


def _format_inequality(sol, variable):
    """Render solve()'s inequality result as clean LaTeX, dropping the trivial
    +/-oo bounds SymPy tacks on: (2 < x) & (x < oo) -> "2 < x", and
    (-2 <= x) & (x <= 2) -> "-2 \\le x \\le 2" (chained when both bounds exist)."""
    if not isinstance(sol, BooleanAtom) and sol.func.__name__ == "And":
        finite = [a for a in sol.args if not (a.has(oo) or a.has(-oo))]
        lowers = [a for a in finite if a.args[1] == variable]  # e.g. 2 < x
        uppers = [a for a in finite if a.args[0] == variable]  # e.g. x < 5
        if len(lowers) == 1 and len(uppers) == 1:
            lo, up = lowers[0], uppers[0]
            lo_op = "\\le" if lo.rel_op in ("<=", ">=") else "<"
            up_op = "\\le" if up.rel_op in ("<=", ">=") else "<"
            return (f"{latex(lo.args[0])} {lo_op} {latex(variable)} "
                    f"{up_op} {latex(up.args[1])}")
        if len(finite) == 1:
            return latex(finite[0])
        if finite:
            return " \\text{ and } ".join(latex(a) for a in finite)
    return latex(sol)


def _solve_inequality(display, expr, variable):
    """Solve a single-variable inequality (2x + 3 > 7 -> x > 2)."""
    try:
        sol = solve(expr, variable)
    except Exception:
        return {"expression": display, "error": UNREADABLE_MESSAGE, "success": False}
    # solve() returns a boolean when the inequality is always/never true.
    if sol is False or (isinstance(sol, BooleanAtom) and not bool(sol)):
        return {"expression": display, "error": NO_INEQUALITY_SOLUTION_MESSAGE,
                "success": False}
    if sol is True or (isinstance(sol, BooleanAtom) and bool(sol)):
        return {"expression": display, "error": ALL_REALS_MESSAGE, "success": False}
    body = _format_inequality(sol, variable)
    return {
        "expression": display,
        "variable": str(variable),
        "solutions": [str(sol)],
        "answer": f"\\({body}\\)",
        "success": True,
    }


def _solve_system(display, equations):
    """Solve a system of equations (a list of SymPy Equality objects).

    Returns only concrete, finite, real solutions so an under-determined or
    garbled scan (which yields symbolic/partial solutions) still fails safe
    rather than reporting nonsense."""
    if not equations or not all(isinstance(e, Equality) for e in equations):
        return {"expression": display, "error": UNREADABLE_MESSAGE, "success": False}
    variables = sorted(set().union(*[e.free_symbols for e in equations]), key=str)
    # A well-posed system needs 2..N unknowns and at least as many equations, so
    # a single garbled equation with stray symbols isn't mistaken for a system.
    if not (2 <= len(variables) <= len(equations)):
        return {"expression": display, "error": UNREADABLE_MESSAGE, "success": False}
    try:
        solutions = solve(equations, variables, dict=True)
    except Exception:
        return {"expression": display, "error": UNREADABLE_MESSAGE, "success": False}
    if not solutions:
        return {"expression": display, "error": NO_SYSTEM_SOLUTION_MESSAGE,
                "success": False}
    solmap = solutions[0]
    if len(solmap) != len(variables) or not all(
        _is_real_number(v) for v in solmap.values()
    ):
        return {"expression": display, "error": UNREADABLE_MESSAGE, "success": False}
    ordered = sorted(solmap.items(), key=lambda kv: str(kv[0]))
    return {
        "expression": display,
        "variable": None,
        "solutions": [f"{k} = {v}" for k, v in ordered],
        "answer": ", ".join(f"\\({latex(k)} = {latex(v)}\\)" for k, v in ordered),
        "success": True,
    }


def _split_equation_parts(text, latex_breaks=False):
    """Split a possibly-multi-equation string into its equation parts so a
    *system* can be solved together. For typed input, equations are separated by
    commas / newlines / semicolons; for scanned LaTeX, by `\\\\` line breaks or a
    cases environment. A single equation yields a one-element list."""
    if latex_breaks:
        text = re.sub(r"\\(begin|end)\s*\{[a-zA-Z]+\}", " ", text)
        pieces = re.split(r"\\\\|\n|;", text)
    else:
        pieces = re.split(r"[,\n;]", text)
    return [p.strip() for p in pieces if p.strip()]


def _parse_typed_inequality(text):
    """Build a SymPy relational from typed input like "2x + 3 >= 7", or return
    None when there's no inequality operator (so the caller solves it as an
    equation/expression). `<=`/`>=` are checked before `<`/`>`."""
    for op, ctor in (("<=", Le), (">=", Ge), ("<", Lt), (">", Gt)):
        if op in text:
            left, right = text.split(op, 1)
            return ctor(
                parse_expr(left, transformations=_TRANSFORMS),
                parse_expr(right, transformations=_TRANSFORMS),
            )
    return None


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
_SAFE_COMMANDS = frozenset({
    "frac", "sqrt", "cdot", "left", "right",
    # Inequality relations that legitimately appear in a Grade-11 problem.
    "leq", "geq", "le", "ge", "neq", "ne",
})


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
    return _expand_mixed_numbers(latex_str)


def _expand_mixed_numbers(latex_str):
    """Rewrite mixed numbers as explicit sums: '2\\frac{5}{16}' -> '(2+\\frac{5}{16})'.

    parse_latex treats a digit adjacent to \\frac as multiplication (2*(5/16)),
    but on a scanned school worksheet an integer immediately followed by a
    *numeric* fraction is a mixed number (2 + 5/16). Only all-digit fractions
    are rewritten -- '2\\frac{x}{3}' really is a coefficient times a fraction
    and stays multiplication. The (?<![.\\d]) guard keeps a decimal like
    '1.5\\frac{...}' (already unambiguous multiplication) untouched."""
    return re.sub(
        r"(?<![.\d])(\d+)\s*(\\frac\s*\{\s*\d+\s*\}\s*\{\s*\d+\s*\})",
        r"(\1+\2)",
        latex_str,
    )


def _has_unreadable_command(latex_str):
    """True if a non-math LaTeX command survives normalization -- a reliable
    signal the scan was garbled rather than a solvable equation."""
    return any(
        m.group(1) not in _SAFE_COMMANDS
        for m in re.finditer(r"\\([a-zA-Z]+)", latex_str)
    )


def solve_latex(latex_str):
    """
    Solve a math problem given as a LaTeX string (e.g. output from OCR).

    Handles, in order: a *system* of equations (multiple equations separated by
    `\\\\` or a cases environment), a single *equation* ("2x + 5 = 13"), an
    *inequality* ("2x + 3 > 7"), and plain *arithmetic* ("89 + 82"). A bare
    single-variable expression is solved against zero (roots).

    Solves for whichever variable the OCR'd expression actually contains rather
    than assuming "x" — OCR output can render the variable as a different case.

    OCR output is untrusted: a blurry or handwritten photo can yield LaTeX that
    still *parses* into a SymPy object but is mathematical nonsense (stray
    symbols like "mathbf", no real roots, etc.). Each step below is guarded so
    such input returns an honest failure instead of a confidently-wrong answer.
    """
    # Split into equation parts BEFORE normalizing -- normalization can consume
    # the `\\` line breaks that separate a system's equations. Each part is then
    # normalized, guarded, and parsed on its own.
    raw_parts = _split_equation_parts(latex_str, latex_breaks=True)

    # System of equations: 2+ parts, each a real equation, solved together.
    if len(raw_parts) >= 2:
        parts = [_normalize_ocr_latex(p) for p in raw_parts]
        if any(_has_unreadable_command(p) for p in parts):
            return {"expression": latex_str, "error": UNREADABLE_MESSAGE,
                    "success": False}
        try:
            equations = [parse_latex(p) for p in parts]
        except Exception:
            return {"expression": latex_str, "error": UNREADABLE_MESSAGE,
                    "success": False}
        return _solve_system(latex_str, equations)

    # Drop pix2tex's cosmetic bolding (so a correctly-read equation isn't
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

    # A real scanned equation/inequality solves for exactly one unknown. More
    # than one almost always means OCR invented junk symbols (e.g. "\mathbf{x}"
    # -> a stray "mathbf" symbol).
    if len(variables) != 1:
        return {"expression": latex_str, "error": UNREADABLE_MESSAGE, "success": False}

    variable = variables[0]

    # Inequality (a relation that isn't an equation): solve for the range.
    if isinstance(expr, Relational) and not isinstance(expr, Equality):
        return _solve_inequality(latex_str, expr, variable)
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
    Solve a typed problem. Handles a system of equations (comma/newline
    separated, e.g. "x + y = 5, x - y = 1"), a single equation ("2x + 3 = 13"
    or "x**2 - 4"), an inequality ("2x + 3 > 7"), and arithmetic ("89 + 82").
    """
    try:
        # System of equations: 2+ parts separated by , / newline / ;.
        parts = _split_equation_parts(equation_str, latex_breaks=False)
        if len(parts) >= 2:
            equations = []
            for part in parts:
                if "=" in part:
                    left, right = part.split("=", 1)
                    equations.append(Eq(
                        parse_expr(left, transformations=_TRANSFORMS),
                        parse_expr(right, transformations=_TRANSFORMS),
                    ))
                else:
                    equations.append(
                        Eq(parse_expr(part, transformations=_TRANSFORMS), 0))
            return _solve_system(equation_str, equations)

        # Inequality: a single relation with <, >, <=, or >=.
        relation = _parse_typed_inequality(equation_str)
        if relation is not None:
            ineq_vars = sorted(relation.free_symbols, key=str)
            if len(ineq_vars) != 1:
                return {"expression": equation_str, "error": UNREADABLE_MESSAGE,
                        "success": False}
            return _solve_inequality(equation_str, relation, ineq_vars[0])

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

    

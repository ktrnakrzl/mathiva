"""Tests for the LaTeX/OCR solve path (`solver.math_solver.solve_latex`).

This is the camera-scanner path: pix2tex turns a photo into a LaTeX string,
which is untrusted. A garbled scan can still *parse* into a SymPy object, so the
solver must validate the result and fail honestly rather than surface a
confidently-wrong "answer" (the bug these tests lock down).

The solver package lives under ml/, which the running app puts on sys.path in
app.main; we replicate that here so the test can import it directly without
pulling in the OCR/RAG models.
"""

import os
import sys

import pytest

_ML_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "ml"))
if _ML_DIR not in sys.path:
    sys.path.insert(0, _ML_DIR)

from solver.math_solver import solve_latex  # noqa: E402


# --- valid equations: should solve and report success -----------------------

def test_linear_equation_solves():
    result = solve_latex("2x + 5 = 13")
    assert result["success"] is True
    assert result["variable"] == "x"
    assert result["solutions"] == ["4"]


def test_quadratic_equation_solves():
    result = solve_latex("x^2 - 4 = 0")
    assert result["success"] is True
    assert sorted(result["solutions"], key=int) == ["-2", "2"]


# --- pix2tex cosmetic formatting: strip it, then solve normally -------------

def test_bolded_variable_still_solves():
    # pix2tex renders variables in bold, so a correctly-read "2x + 5 = 13"
    # comes back as this. The \mathbf wrapper must not get it rejected.
    result = solve_latex(r"2\mathbf{x}+5=13")
    assert result["success"] is True
    assert result["variable"] == "x"
    assert result["solutions"] == ["4"]


def test_bolded_variables_on_both_sides_solve():
    result = solve_latex(r"3\mathbf{x}-7=2\mathbf{x}+1")
    assert result["success"] is True
    assert result["solutions"] == ["8"]


def test_bare_bold_group_form_solves():
    # The other bold form pix2tex emits: {\bf x} instead of \mathbf{x}.
    result = solve_latex(r"{\bf x}^2-4=0")
    assert result["success"] is True
    assert sorted(result["solutions"], key=int) == ["-2", "2"]


def test_garbled_scan_under_bold_is_still_rejected():
    # Stripping \mathbf must NOT rescue a genuinely garbled scan: the leftover
    # stray "\times" in the exponent means this is not a real equation, so it
    # must fail rather than surface a confident wrong answer.
    result = solve_latex(r"\mathbf{x}^{\times}2-4=0")
    assert result["success"] is False
    assert "answer" not in result


# --- untrusted / garbled OCR: must fail honestly, never fake-succeed --------

def test_garbled_ocr_with_stray_symbols_is_rejected():
    # Real pix2tex output observed for a photo of "x^2 - 4 = 0"; the stray
    # "mathbf" symbol previously produced a nonsense {mathbf: 0} "answer".
    result = solve_latex(r"\mathbf{x}^{\times}2-4=0")
    assert result["success"] is False
    assert "answer" not in result


def test_unparseable_ocr_noise_is_rejected():
    # Real pix2tex output for a photo it couldn't read at all -- formatting
    # commands with no actual equation.
    result = solve_latex(r"\mathrm{\Large~\left[~\right]~}_{\mathrm{\tiny~C~}}")
    assert result["success"] is False


def test_numeric_equation_without_unknown_is_rejected():
    # A relational with no variable ("2 + 3 = 5") isn't something to solve or a
    # number to report -- it simplifies to a boolean -- so it still fails safe.
    # (A bare arithmetic *expression* like "89 + 82" is evaluated instead; see
    # test_arithmetic_expression_is_evaluated.)
    result = solve_latex("2 + 3 = 5")
    assert result["success"] is False


def test_arithmetic_expression_is_evaluated():
    # A scanned/typed expression with no unknown is plain arithmetic: evaluate
    # it to a number rather than rejecting it as "not an equation".
    result = solve_latex("89 + 82")
    assert result["success"] is True
    assert result["variable"] is None
    assert result["solutions"] == ["171"]
    assert "171" in result["answer"]


def test_fraction_arithmetic_is_evaluated_exactly():
    # Exact rational arithmetic, rendered as a real fraction (not a decimal).
    result = solve_latex(r"\frac{1}{2} + \frac{1}{3}")
    assert result["success"] is True
    assert result["solutions"] == ["5/6"]


def test_no_real_solution_is_reported_as_such():
    result = solve_latex("x^2 + 4 = 0")
    assert result["success"] is False
    # Read fine, just no real answer -- distinct from an unreadable scan.
    assert "no real" in result["error"].lower()


# --- inequalities -----------------------------------------------------------

# A real LaTeX line break is two backslash characters; built via chr(92) so the
# test source itself is unambiguous about how many backslashes it contains.
_BR = chr(92) * 2


def test_strict_inequality_solves():
    result = solve_latex("2x + 3 > 7")
    assert result["success"] is True
    assert result["variable"] == "x"
    assert "x" in result["answer"] and ("<" in result["answer"])


def test_bounded_inequality_gives_a_range():
    # x^2 - 4 <= 0  ->  -2 <= x <= 2 (chained, trivial +/-oo bounds dropped).
    result = solve_latex("x^2 - 4 " + chr(92) + "leq 0")
    assert result["success"] is True
    assert result["answer"] == r"\(-2 \le x \le 2\)"


# --- systems of equations ---------------------------------------------------

def test_system_of_equations_solves():
    result = solve_latex(f"x + y = 5 {_BR} x - y = 1")
    assert result["success"] is True
    assert result["variable"] is None
    assert result["solutions"] == ["x = 3", "y = 2"]


def test_system_in_cases_environment_solves():
    latex = f"{chr(92)}begin{{cases}} 2a + b = 7 {_BR} a - b = 2 {chr(92)}end{{cases}}"
    result = solve_latex(latex)
    assert result["success"] is True
    assert result["solutions"] == ["a = 3", "b = 1"]


def test_underdetermined_system_is_rejected():
    # Infinitely many solutions (second equation is a multiple of the first):
    # no unique real answer, so fail safe rather than invent one.
    result = solve_latex(f"x + y = 5 {_BR} 2x + 2y = 10")
    assert result["success"] is False


def test_garbled_multipart_scan_is_rejected():
    # Two "parts" of OCR noise must not be mistaken for a solvable system.
    latex = f"{chr(92)}mathbf{{Q}}^{{{chr(92)}times}} {_BR} {chr(92)}operatorname{{zz}}"
    result = solve_latex(latex)
    assert result["success"] is False

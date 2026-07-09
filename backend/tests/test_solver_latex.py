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


def test_no_variable_is_rejected():
    result = solve_latex("2 + 3 = 5")
    assert result["success"] is False


def test_no_real_solution_is_reported_as_such():
    result = solve_latex("x^2 + 4 = 0")
    assert result["success"] is False
    # Read fine, just no real answer -- distinct from an unreadable scan.
    assert "no real" in result["error"].lower()

"""Tests for the typed-equation solver's input parsing (solver.math_solver).

Students type natural notation -- "2x + 3 = 13", "x^2 - 4 = 0", "3(x + 1) = 12"
-- not strict Python ("2*x", "x**2"). These pin the implicit-multiplication and
caret-as-exponent support so a bare "2x" never regresses to an "invalid syntax"
failure again.
"""

from solver.math_solver import solve_equation


def _solve(eq):
    r = solve_equation(eq)
    assert r["success"], r
    return r


def test_implicit_multiplication_linear():
    assert _solve("2x + 3 = 13")["solutions"] == ["5"]


def test_caret_as_exponent():
    assert set(_solve("x^2 - 4 = 0")["solutions"]) == {"-2", "2"}


def test_implicit_multiplication_with_caret():
    assert set(_solve("2x^2 - 8 = 0")["solutions"]) == {"-2", "2"}


def test_implicit_multiplication_with_parentheses():
    assert _solve("3(x + 1) = 12")["solutions"] == ["3"]


def test_explicit_python_syntax_still_works():
    assert _solve("2*x + 3 = 13")["solutions"] == ["5"]


def test_expression_without_equals_solves_against_zero():
    assert set(_solve("x^2 - 4")["solutions"]) == {"-2", "2"}


def test_typed_system_of_equations():
    r = _solve("x + y = 5, x - y = 1")
    assert r["variable"] is None
    assert r["solutions"] == ["x = 3", "y = 2"]


def test_typed_inequality():
    r = _solve("2x + 3 >= 7")
    assert r["variable"] == "x"
    assert "x" in r["answer"]


def test_typed_arithmetic_is_evaluated():
    assert _solve("89 + 82")["solutions"] == ["171"]

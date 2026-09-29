"""Tests for the typed-equation solver's input parsing (solver.math_solver).

Students type natural notation -- "2x + 3 = 13", "x^2 - 4 = 0", "3(x + 1) = 12"
-- not strict Python ("2*x", "x**2"). These pin the implicit-multiplication and
caret-as-exponent support so a bare "2x" never regresses to an "invalid syntax"
failure again.
"""

from solver.math_solver import solve_equation

import pytest


@pytest.mark.parametrize("expression, expected", [
    ("1.5 + 2.3", 3.8),
    (".5 + .25", .75),
    ("1.5 / .5", 3),
    (".5x = 1.25", 2.5),
])
def test_typed_decimals(expression, expected):
    assert float(_solve(expression)["solutions"][0]) == pytest.approx(expected)


@pytest.mark.parametrize("expression, expected", [
    ("√9", "3"), ("√(9 + 7)", "4"), ("√9 + 7", "10"),
    ("2√9", "6"), ("√√16", "2"), ("√(.25)", "0.500000000000000"),
    ("√9 + √16", "7"), ("6 × 3 ÷ 2", "9"),
    ("5 − 8", "-3"), ("3² + 2³", "17"), ("2π", "2*pi"),
    ("√(x + 1) = 3", "8"),
])
def test_keyboard_math(expression, expected):
    assert _solve(expression)["solutions"] == [expected]


@pytest.mark.parametrize("expression", ["√", "√(9 + 7", "√ + 2"])
def test_incomplete_keyboard_root_is_rejected(expression):
    assert not solve_equation(expression)["success"]


def test_keyboard_inequality():
    assert _solve("2x ≤ 6")["answer"] == r"\(x \leq 3\)"


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

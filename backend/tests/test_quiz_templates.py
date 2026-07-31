"""Tests for the parametric question templates.

These are the "guaranteed-correct" half of the generator, so the invariants
here are the load-bearing ones: every template must return exactly four
distinct choices with the correct answer among them, must keep its required
numbers, and must be deterministic under a seeded RNG. A handful of templates
also get an *independent* correctness check (the answer is re-derived here from
the rendered question, not trusted from the template) since a wrong computed
answer would silently mis-grade students.
"""

import random
import re

import pytest
import sympy
from sympy.parsing.sympy_parser import (
    implicit_multiplication_application,
    parse_expr,
    standard_transformations,
)

from app.services import quiz_templates
from app.services.quiz_templates import GeneratedQuestion, TEMPLATES

ALL_CONCEPTS = sorted(TEMPLATES.keys())
DIFFICULTIES = ["Easy", "Medium", "Hard"]
# Enough seeds to exercise the randomization (distractor collisions, padding,
# retry loops) without making the suite slow.
SEEDS = range(25)


def _generate(concept_id, difficulty, seed):
    return quiz_templates.generate(concept_id, difficulty, random.Random(seed))


@pytest.mark.parametrize("concept_id", ALL_CONCEPTS)
@pytest.mark.parametrize("difficulty", DIFFICULTIES)
def test_structural_invariants(concept_id, difficulty):
    for seed in SEEDS:
        q = _generate(concept_id, difficulty, seed)

        assert isinstance(q, GeneratedQuestion)
        assert q.template_id == concept_id
        assert q.question.strip(), "question text must be non-empty"

        # Exactly four options, all distinct, with the correct answer present.
        assert len(q.choices) == 4, f"{concept_id}/{difficulty}/{seed}: not 4 choices"
        assert len(set(q.choices)) == 4, f"{concept_id}/{difficulty}/{seed}: duplicate choices"
        assert q.answer in q.choices, f"{concept_id}/{difficulty}/{seed}: answer not among choices"

        # Every required token survives verbatim in the question (this is what
        # the LLM-rephrase guard later relies on).
        for token in q.must_keep:
            assert token in q.question, (
                f"{concept_id}/{difficulty}/{seed}: must_keep '{token}' missing from question"
            )

        assert q.steps, "a worked solution (steps) must be provided"


@pytest.mark.parametrize("concept_id", ALL_CONCEPTS)
def test_determinism(concept_id):
    """Same concept + difficulty + seed must reproduce an identical question."""
    a = _generate(concept_id, "Medium", 7)
    b = _generate(concept_id, "Medium", 7)
    assert a == b


@pytest.mark.parametrize("concept_id", ALL_CONCEPTS)
def test_seeded_generation_varies_question_wording(concept_id):
    """A concept should not be locked to one visible question stem."""
    questions = {_generate(concept_id, "Medium", seed).question for seed in range(40)}
    assert len(questions) > 1


# ---------------------------------------------------------------------------
# Independent correctness checks -- the answer is re-derived here, not trusted.
# ---------------------------------------------------------------------------

def test_mean_answer_is_correct():
    for seed in SEEDS:
        q = _generate("mean", "Hard", seed)
        expected = re.findall(r"-?\d+", q.steps[-1])[-1]
        assert q.answer == expected


def test_function_definition_answer_is_correct():
    # Re-derive from the stable worked steps, not from one specific question stem.
    for seed in SEEDS:
        q = _generate("function_definition", "Hard", seed)
        nums = [int(n) for n in re.findall(r"-?\d+", " ".join(q.steps))]
        if q.answer.startswith("f("):
            c, a, b = (int(n) for n in re.findall(r"-?\d+", q.steps[0]))
            assert q.answer == f"f({c}) = {a * c + b}"
        else:
            m = re.search(r"(\d+)x \+ (\d+) = (\d+)", q.steps[0])
            assert m
            a, b, y = (int(n) for n in m.groups())
            rhs = int(re.findall(r"-?\d+", q.steps[1])[-1])
            x_val = int(re.findall(r"-?\d+", q.steps[2])[-1])
            assert rhs == y - b
            assert q.answer == f"x = {x_val}"
            assert a * x_val + b == y


def test_limit_meaning_answer_is_correct():
    for seed in SEEDS:
        q = _generate("limit_meaning", "Hard", seed)
        assert q.answer == re.findall(r"-?\d+", q.steps[-1])[-1]


def test_factoring_roots_actually_solve_the_equation():
    """Re-derive: substitute the answer's roots back into the equation and
    confirm each yields zero (using sympy, independent of the template's math)."""
    x = sympy.Symbol("x")
    for seed in SEEDS:
        q = _generate("factoring", "Hard", seed)
        lhs_match = re.search(r"((?:x\^2|\(x).*?) = 0", q.question)
        assert lhs_match, f"could not find equation lhs in: {q.question}"
        lhs = lhs_match.group(1).strip()
        # parse_expr with implicit multiplication so "3x" is read as "3*x".
        transformations = standard_transformations + (
            implicit_multiplication_application,
        )
        expr = parse_expr(lhs.replace("^", "**"), transformations=transformations)
        roots = [int(n) for n in re.findall(r"-?\d+", q.answer)]
        assert roots, "factoring answer must contain at least one root"
        for r in roots:
            assert expr.subs(x, r) == 0, f"root {r} does not satisfy {lhs} (seed {seed})"


def test_circle_standard_radius_is_correct():
    for seed in SEEDS:
        q = _generate("circle_standard", "Hard", seed)
        if q.answer.startswith("("):
            assert q.answer in q.steps[-1]
        else:
            r2 = int(re.findall(r"r\^2 = (\d+)", q.steps[1])[0])
            assert q.answer == str(int(round(r2 ** 0.5)))
            assert int(q.answer) ** 2 == r2, "r^2 must be a perfect square by construction"


def test_unknown_concept_raises_keyerror():
    with pytest.raises(KeyError):
        quiz_templates.generate("no_such_concept", "Easy", random.Random(0))


def test_has_template_matches_registry():
    assert quiz_templates.has_template("mean") is True
    assert quiz_templates.has_template("no_such_concept") is False

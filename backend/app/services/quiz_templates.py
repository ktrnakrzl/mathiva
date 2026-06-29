"""Parametric question templates -- the "guaranteed-correct" half of the
hybrid generator.

Each template takes a difficulty and a seeded RNG and returns a fully-formed
question whose answer is COMPUTED in Python, never guessed. That is what lets
the server grade trustworthily: the LLM (see question_generator.py) only ever
rephrases the wording on top of what these produce -- it never decides the
numbers or the answer.

To add a concept: write a `_xxx_template(difficulty, rng)` returning a
`GeneratedQuestion` and register it in `TEMPLATES` under its concept_id.
"""

from __future__ import annotations

import random
from dataclasses import dataclass, field
from math import gcd
from typing import Callable, Dict, List


@dataclass
class GeneratedQuestion:
    template_id: str
    question: str
    answer: str
    # Distractors + the correct answer, NOT yet shuffled. The generator
    # shuffles before storing/serving so position carries no signal.
    choices: List[str]
    steps: List[str]
    # Literal substrings (usually the randomized numbers) that MUST still
    # appear verbatim in any LLM-rephrased version of `question`; if the
    # rephrase drops one, we fall back to this raw text. See question_generator.
    must_keep: List[str] = field(default_factory=list)


# Difficulty knobs shared across numeric templates. Kept in one place so
# "Hard" means roughly the same jump everywhere.
_DIFFICULTY_RANK = {"Easy": 0, "Medium": 1, "Hard": 2}


def _rank(difficulty: str) -> int:
    return _DIFFICULTY_RANK.get(difficulty, 0)


def _unique_choices(answer: str, distractors: List[str], rng: random.Random) -> List[str]:
    """Build a 4-option list: the answer plus 3 distinct distractors that
    differ from the answer and each other. Pads with simple fallbacks if a
    template didn't supply enough usable distractors."""
    seen = {answer}
    out: List[str] = [answer]
    for d in distractors:
        if d not in seen:
            seen.add(d)
            out.append(d)
        if len(out) == 4:
            break
    # Pad defensively so we always return exactly 4 options.
    pad = 1
    while len(out) < 4:
        candidate = f"{answer} + {pad}"
        if candidate not in seen:
            seen.add(candidate)
            out.append(candidate)
        pad += 1
    return out


def _frac(num: int, den: int) -> str:
    """Format num/den in lowest terms, collapsing to a whole number when the
    denominator divides out. Keeps answer strings canonical so grading is an
    exact match."""
    if den == 0:
        return str(num)
    g = gcd(abs(num), abs(den)) or 1
    num, den = num // g, den // g
    if den < 0:  # keep the sign on the numerator
        num, den = -num, -den
    return str(num) if den == 1 else f"{num}/{den}"


def _pow_term(coef: int, power: int) -> str:
    """Render a single polynomial term, e.g. (4, 3) -> '4x^3', (1, 1) -> 'x',
    (5, 0) -> '5'."""
    if power == 0:
        return str(coef)
    base = "x" if power == 1 else f"x^{power}"
    return base if coef == 1 else f"{coef}{base}"


def _signed_term(coef: int, var: str) -> str:
    """Render ' + 6' / ' - 5x' for chaining after a leading term. Empty string
    when the coefficient is zero (term dropped)."""
    if coef == 0:
        return ""
    sign = "-" if coef < 0 else "+"
    body = _pow_term(abs(coef), 1 if var else 0) if var else str(abs(coef))
    return f" {sign} {body}"


def _shift(var: str, val: int) -> str:
    """Render '(x - 2)' / '(x + 3)' for circle/center expressions."""
    return f"({var} - {val})" if val >= 0 else f"({var} + {-val})"


# --------------------------------------------------------------------------
# mean  (Statistics & Probability -> Measures of Central Tendency)
# --------------------------------------------------------------------------
def _mean_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    """Find the mean of a list of integers. The list is built so the mean is
    always a whole number, which keeps the answer string unambiguous (no
    rounding/fraction-formatting mismatch when grading)."""
    rank = _rank(difficulty)
    count = (4, 5, 6)[rank]
    hi = (9, 20, 40)[rank]

    target_mean = rng.randint(3, hi // 2)
    # Generate count-1 values, then set the last so the total is exactly
    # target_mean * count -> integer mean by construction.
    values = [rng.randint(1, hi) for _ in range(count - 1)]
    last = target_mean * count - sum(values)
    # Keep the forced last value in a sane range; retry a few times if not.
    tries = 0
    while not (1 <= last <= hi) and tries < 20:
        values = [rng.randint(1, hi) for _ in range(count - 1)]
        last = target_mean * count - sum(values)
        tries += 1
    if not (1 <= last <= hi):
        last = max(1, last)  # accept a slightly out-of-band value rather than loop forever
        target_mean = (sum(values) + last) // count
        # recompute exact integer mean for safety
        total = sum(values) + last
        target_mean = total // count
        # nudge last so the mean is exact
        last += total - target_mean * count
    values.append(last)
    rng.shuffle(values)

    total = sum(values)
    mean = total // count  # exact by construction
    answer = str(mean)
    values_str = ", ".join(str(v) for v in values)

    distractors = [
        str(total),          # forgot to divide
        str(mean + 1),
        str(mean - 1),
        str(round(total / (count - 1))) if count > 1 else str(mean + 2),  # divided by wrong count
    ]
    distractors = [d for d in distractors if d != answer]

    steps = [
        f"Add the values: {' + '.join(str(v) for v in values)} = {total}.",
        f"Count how many values there are: {count}.",
        f"Divide the sum by the count: {total} / {count} = {mean}.",
    ]

    return GeneratedQuestion(
        template_id="mean",
        question=f"Find the mean of {values_str}.",
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(v) for v in values],
    )


# --------------------------------------------------------------------------
# function_definition  (General Math -> Functions)
# --------------------------------------------------------------------------
def _function_definition_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    """Evaluate a linear function f(x) = ax + b at x = c."""
    hi = (5, 9, 12)[_rank(difficulty)]
    a = rng.randint(2, hi)
    b = rng.randint(1, hi)
    c = rng.randint(2, hi)
    val = a * c + b
    answer = f"f({c}) = {val}"
    distractors = [
        f"f({c}) = {a * c}",          # forgot to add b
        f"f({c}) = {a + c + b}",      # added instead of multiplied
        f"f({c}) = {a * (c + b)}",    # multiplied the sum
        f"f({c}) = {val + a}",
    ]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"Substitute x = {c} into f(x) = {a}x + {b}.",
        f"Compute {a}({c}) + {b} = {a * c} + {b}.",
        f"The value is {val}.",
    ]
    return GeneratedQuestion(
        template_id="function_definition",
        question=f"If f(x) = {a}x + {b}, find f({c}).",
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(a), str(b), str(c)],
    )


# --------------------------------------------------------------------------
# quadratic_form  (General Math -> Quadratic Equations): identify coefficients
# --------------------------------------------------------------------------
def _quadratic_form_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    hi = (4, 7, 9)[_rank(difficulty)]
    a = rng.randint(2, hi)
    b = rng.randint(1, 9)
    c = rng.randint(1, 9)
    answer = str(a)
    equation = f"{a}x^2{_signed_term(b, 'x')}{_signed_term(c, '')} = 0"
    distractors = [str(b), str(c), str(a + b), str(a * 2)]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"Compare {equation} with the standard form ax^2 + bx + c = 0.",
        "The leading coefficient a is the number multiplying x^2.",
        f"So a = {a}.",
    ]
    return GeneratedQuestion(
        template_id="quadratic_form",
        question=f"In the quadratic equation {equation}, what is the value of the leading coefficient a?",
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(a), str(b), str(c)],
    )


# --------------------------------------------------------------------------
# factoring  (General Math -> Quadratic Equations): solve with integer roots
# --------------------------------------------------------------------------
def _factoring_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    """Build x^2 + bx + c from two integer roots so factoring always yields
    clean integer solutions."""
    lim = (5, 8, 11)[_rank(difficulty)]
    p = rng.randint(-lim, lim) or 1
    q = rng.randint(-lim, lim) or 1
    b = -(p + q)
    c = p * q
    equation = f"x^2{_signed_term(b, 'x')}{_signed_term(c, '')} = 0"

    roots = sorted({p, q})
    if len(roots) == 1:
        answer = f"x = {roots[0]}"
    else:
        answer = f"x = {roots[0]} and x = {roots[1]}"

    distractors = [
        f"x = {-roots[0]} and x = {-roots[-1]}",   # sign error
        f"x = {b} and x = {c}",                     # read coefficients as roots
        f"x = {roots[0]}",
    ]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"Factor the left side: {equation.replace(' = 0', '')} = (x {('-' if roots[0] >= 0 else '+')} {abs(roots[0])})(x {('-' if roots[-1] >= 0 else '+')} {abs(roots[-1])}).",
        "Set each factor equal to zero.",
        f"Solve to get {answer}.",
    ]
    must_keep = [str(abs(c))]
    if b != 0:
        must_keep.append(str(abs(b)))
    return GeneratedQuestion(
        template_id="factoring",
        question=f"Solve by factoring: {equation}",
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=must_keep,
    )


# --------------------------------------------------------------------------
# simplify_rational  (General Math): difference of squares cancellation
# --------------------------------------------------------------------------
def _simplify_rational_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    k = rng.randint(1, (4, 7, 10)[_rank(difficulty)])
    k2 = k * k
    answer = f"x + {k}"
    distractors = [f"x - {k}", f"x + {k2}", f"x^2 + {k}", str(k)]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"Factor the numerator as a difference of squares: x^2 - {k2} = (x - {k})(x + {k}).",
        f"Cancel the common factor (x - {k}).",
        f"The simplified form is x + {k}.",
    ]
    return GeneratedQuestion(
        template_id="simplify_rational",
        question=f"Simplify (x^2 - {k2}) / (x - {k}).",
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(k2), str(k)],
    )


# --------------------------------------------------------------------------
# degree_terms  (General Math -> Polynomials)
# --------------------------------------------------------------------------
def _degree_terms_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    deg = rng.randint(2, (3, 5, 7)[_rank(difficulty)])
    lead = rng.randint(2, 9)
    midpow = rng.randint(1, deg - 1)
    mid = rng.randint(1, 9)
    const = rng.randint(1, 9)
    poly = f"{_pow_term(lead, deg)} + {_pow_term(mid, midpow)} - {const}"
    answer = str(deg)
    distractors = [str(deg - 1), str(deg + 1), str(lead), str(midpow)]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"The degree is the highest exponent of the variable in {poly}.",
        f"The highest exponent is {deg}.",
        f"So the degree is {deg}.",
    ]
    return GeneratedQuestion(
        template_id="degree_terms",
        question=f"What is the degree of {poly}?",
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(deg)],
    )


# --------------------------------------------------------------------------
# probability_formula  (Statistics & Probability)
# --------------------------------------------------------------------------
def _probability_formula_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    total = rng.randint(4, (6, 10, 12)[_rank(difficulty)])
    fav = rng.randint(1, total - 1)
    answer = _frac(fav, total)
    distractors = [
        f"{fav}/{total}" if "/" not in answer or f"{fav}/{total}" != answer else _frac(total, fav),
        _frac(total - fav, total),   # probability of the complement
        _frac(total, fav),           # reciprocal
        str(fav),
    ]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"Use P(event) = favorable outcomes / total outcomes.",
        f"Substitute {fav}/{total}.",
        f"Simplify to {answer}.",
    ]
    return GeneratedQuestion(
        template_id="probability_formula",
        question=(
            f"An event has {fav} favorable outcomes out of {total} equally likely "
            f"total outcomes. What is the probability of the event?"
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(fav), str(total)],
    )


# --------------------------------------------------------------------------
# sine_cosine  (Pre-Calculus -> Trigonometry)
# --------------------------------------------------------------------------
def _sine_cosine_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    opp = rng.randint(1, (6, 9, 12)[_rank(difficulty)])
    hyp = opp + rng.randint(1, 6)  # hypotenuse is always the longest side
    answer = _frac(opp, hyp)
    distractors = [
        _frac(hyp, opp),                 # inverted ratio
        f"{opp}/{hyp}" if f"{opp}/{hyp}" != answer else _frac(opp, hyp - opp),  # unsimplified
        _frac(hyp - opp, hyp),
        _frac(opp, hyp - opp),
    ]
    distractors = [d for d in distractors if d != answer]
    steps = [
        "Use sin(theta) = opposite / hypotenuse.",
        f"Substitute {opp}/{hyp}.",
        f"Simplify to {answer}.",
    ]
    return GeneratedQuestion(
        template_id="sine_cosine",
        question=(
            f"In a right triangle, the side opposite angle theta is {opp} and the "
            f"hypotenuse is {hyp}. Find sin(theta)."
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(opp), str(hyp)],
    )


# --------------------------------------------------------------------------
# circle_standard  (Pre-Calculus -> Conic Sections)
# --------------------------------------------------------------------------
def _circle_standard_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    r = rng.randint(2, (6, 9, 12)[_rank(difficulty)])
    r2 = r * r
    h = rng.randint(-5, 5)
    k = rng.randint(-5, 5)
    equation = f"{_shift('x', h)}^2 + {_shift('y', k)}^2 = {r2}"
    answer = str(r)
    distractors = [str(r2), str(r * 2), str(r + 1), str(max(1, r2 // 2))]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"Compare {equation} with the standard form (x - h)^2 + (y - k)^2 = r^2.",
        f"Here r^2 = {r2}.",
        f"So r = {r}.",
    ]
    return GeneratedQuestion(
        template_id="circle_standard",
        question=f"Find the radius of the circle {equation}.",
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(r2)],
    )


# --------------------------------------------------------------------------
# limit_meaning  (Basic Calculus -> Limits): direct substitution on a linear fn
# --------------------------------------------------------------------------
def _limit_meaning_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    hi = (5, 9, 12)[_rank(difficulty)]
    a = rng.randint(1, hi)
    b = rng.randint(1, 9)
    c = rng.randint(1, hi)
    val = a * c + b
    answer = str(val)
    distractors = [str(a * c), str(a + b + c), str(val + 1), str(b)]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"Substitute x = {c} into {a}x + {b}.",
        f"Compute {a}({c}) + {b} = {a * c} + {b}.",
        f"The limit is {val}.",
    ]
    return GeneratedQuestion(
        template_id="limit_meaning",
        question=f"Evaluate the limit of ({a}x + {b}) as x approaches {c}.",
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(a), str(b), str(c)],
    )


# --------------------------------------------------------------------------
# basic_power_rule  (Basic Calculus -> Derivatives)
# --------------------------------------------------------------------------
def _basic_power_rule_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    n = rng.randint((2, 4, 6)[_rank(difficulty)], (4, 6, 9)[_rank(difficulty)])
    answer = _pow_term(n, n - 1)
    distractors = [
        _pow_term(n, n),              # forgot to drop the exponent
        _pow_term(n - 1, n - 1),      # subtracted from the coefficient too
        f"{n}x^{n}",
        _pow_term(n, max(0, n - 2)),
    ]
    distractors = [d for d in distractors if d != answer]
    steps = [
        "Apply the power rule: d/dx x^n = n*x^(n-1).",
        f"Here n = {n}.",
        f"The derivative is {answer}.",
    ]
    return GeneratedQuestion(
        template_id="basic_power_rule",
        question=f"Find the derivative of x^{n}.",
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(n)],
    )


# Registry: concept_id -> template function. Concepts without a template yet
# are simply absent; the generator raises a clear error for those.
TEMPLATES: Dict[str, Callable[[str, random.Random], GeneratedQuestion]] = {
    "mean": _mean_template,
    "function_definition": _function_definition_template,
    "quadratic_form": _quadratic_form_template,
    "factoring": _factoring_template,
    "simplify_rational": _simplify_rational_template,
    "degree_terms": _degree_terms_template,
    "probability_formula": _probability_formula_template,
    "sine_cosine": _sine_cosine_template,
    "circle_standard": _circle_standard_template,
    "limit_meaning": _limit_meaning_template,
    "basic_power_rule": _basic_power_rule_template,
}


def has_template(concept_id: str) -> bool:
    return concept_id in TEMPLATES


def generate(concept_id: str, difficulty: str, rng: random.Random) -> GeneratedQuestion:
    template = TEMPLATES.get(concept_id)
    if template is None:
        raise KeyError(concept_id)
    return template(difficulty, rng)

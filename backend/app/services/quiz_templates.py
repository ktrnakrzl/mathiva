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
from dataclasses import dataclass, field, replace
from math import gcd
from typing import Callable, Dict, List, Sequence


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


# Difficulty ladder, easiest -> hardest. One source of truth for the levels,
# shared with the adaptive selector (adaptive_quiz.py) so "step up a difficulty"
# means the same thing everywhere. Kept in one place so "Hard" is a consistent
# jump across templates.
DIFFICULTY_LEVELS = ("Easy", "Medium", "Hard")
_DIFFICULTY_RANK = {name: i for i, name in enumerate(DIFFICULTY_LEVELS)}


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


def _stem(rng: random.Random, *variants: str) -> str:
    """Pick a wording variant for a generated question.

    The math still comes from the same computed parameters; this only changes
    the surface wording so fallback questions do not all read from one mold.
    """
    return rng.choice(variants)


def _shift(var: str, val: int) -> str:
    """Render '(x - 2)' / '(x + 3)' for circle/center expressions."""
    return f"({var} - {val})" if val >= 0 else f"({var} + {-val})"


def _alias(
    concept_id: str,
    template: Callable[[str, random.Random], GeneratedQuestion],
) -> Callable[[str, random.Random], GeneratedQuestion]:
    """Reuse a reliable template for a closely related frontend concept."""

    def _template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
        return replace(template(difficulty, rng), template_id=concept_id)

    return _template


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
        # Retries failed to land `last` in [1, hi]. Fall back to a construction
        # that is always valid: pick the smallest positive `last` that makes the
        # total an exact multiple of count, so the mean stays a whole number.
        partial = sum(values)
        last = count - (partial % count)  # in [1, count], always <= hi
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
        question=_stem(
            rng,
            f"Find the mean of {values_str}.",
            f"What is the average of {values_str}?",
            f"Compute the arithmetic mean for {values_str}.",
            f"The data values are {values_str}. What is their mean?",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(v) for v in values],
    )


def _mean_missing_value_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    """Find a missing value from a target mean."""
    rank = _rank(difficulty)
    count = (4, 5, 6)[rank]
    hi = (9, 20, 40)[rank]
    target_mean = rng.randint(3, hi // 2)
    total = target_mean * count

    known = [rng.randint(1, hi) for _ in range(count - 1)]
    missing = total - sum(known)
    tries = 0
    while not (1 <= missing <= hi) and tries < 40:
        known = [rng.randint(1, hi) for _ in range(count - 1)]
        missing = total - sum(known)
        tries += 1
    if not (1 <= missing <= hi):
        missing = rng.randint(1, hi)
        known_total = total - missing
        base = known_total // (count - 1)
        known = [base] * (count - 2) + [known_total - base * (count - 2)]

    values = [str(v) for v in known] + ["x"]
    rng.shuffle(values)
    values_str = ", ".join(values)
    answer = str(missing)
    distractors = [str(target_mean), str(total), str(missing + 1), str(max(1, missing - 1))]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"The total needed is mean times count: {target_mean} * {count} = {total}.",
        f"Add the known values: {' + '.join(str(v) for v in known)} = {sum(known)}.",
        f"Subtract from the needed total: {total} - {sum(known)} = {missing}.",
    ]

    return GeneratedQuestion(
        template_id="mean",
        question=_stem(
            rng,
            f"The mean of {values_str} is {target_mean}. Find x.",
            f"A data set {values_str} has mean {target_mean}. What is the missing value x?",
            f"Find x if the average of {values_str} equals {target_mean}.",
            f"The values are {values_str}, and their mean is {target_mean}. What is x?",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(v) for v in known] + [str(target_mean)],
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
        question=_stem(
            rng,
            f"If f(x) = {a}x + {b}, find f({c}).",
            f"For f(x) = {a}x + {b}, evaluate f({c}).",
            f"Given f(x) = {a}x + {b}, what is f({c})?",
            f"Substitute x = {c} into f(x) = {a}x + {b}. What value do you get?",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(a), str(b), str(c)],
    )


def _function_solve_input_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    """Given a linear function value, solve for the input."""
    hi = (5, 9, 12)[_rank(difficulty)]
    a = rng.randint(2, hi)
    b = rng.randint(1, hi)
    x_val = rng.randint(2, hi)
    y_val = a * x_val + b
    answer = f"x = {x_val}"
    distractors = [
        f"x = {y_val}",
        f"x = {x_val + 1}",
        f"x = {max(1, x_val - 1)}",
        f"x = {a + b}",
    ]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"Set the function equal to {y_val}: {a}x + {b} = {y_val}.",
        f"Subtract {b}: {a}x = {y_val - b}.",
        f"Divide by {a}: x = {x_val}.",
    ]
    return GeneratedQuestion(
        template_id="function_definition",
        question=_stem(
            rng,
            f"If f(x) = {a}x + {b} and f(x) = {y_val}, find x.",
            f"For f(x) = {a}x + {b}, what input gives an output of {y_val}?",
            f"Find x when {a}x + {b} = {y_val}.",
            f"Given f(x) = {a}x + {b}, solve for x if f(x) equals {y_val}.",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(a), str(b), str(y_val)],
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
        question=_stem(
            rng,
            f"In the quadratic equation {equation}, what is the value of the leading coefficient a?",
            f"For {equation}, identify the coefficient a in ax^2 + bx + c = 0.",
            f"Look at {equation}. What number is multiplying x^2?",
            f"Which value is the leading coefficient in {equation}?",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        # Only keep tokens that are actually rendered in the equation: a
        # coefficient of 1 on a variable term prints implicitly (1x -> x), so
        # its digit never appears in the text.
        must_keep=[t for t in (str(a), str(b), str(c)) if t in equation],
    )


def _quadratic_discriminant_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    hi = (4, 7, 9)[_rank(difficulty)]
    a = rng.randint(1, hi)
    b = rng.randint(2, 9)
    c = rng.randint(1, 9)
    equation = f"{a}x^2{_signed_term(b, 'x')}{_signed_term(c, '')} = 0"
    disc = b * b - 4 * a * c
    answer = str(disc)
    distractors = [str(b * b), str(4 * a * c), str(abs(disc)), str(disc + 1)]
    distractors = [d for d in distractors if d != answer]
    steps = [
        "Use the discriminant formula b^2 - 4ac.",
        f"Substitute a = {a}, b = {b}, c = {c}: {b}^2 - 4({a})({c}).",
        f"The discriminant is {disc}.",
    ]
    return GeneratedQuestion(
        template_id="quadratic_form",
        question=_stem(
            rng,
            f"Find the discriminant of {equation}.",
            f"For {equation}, compute b^2 - 4ac.",
            f"What is the discriminant for the quadratic equation {equation}?",
            f"Using a, b, and c from {equation}, find the discriminant.",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[t for t in (str(a), str(b), str(c)) if t in equation],
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
    # Drop tokens not literally in the equation (a |coef| of 1 on x prints as
    # "x", so "1" never appears in the text).
    must_keep = [t for t in must_keep if t in equation]
    return GeneratedQuestion(
        template_id="factoring",
        question=_stem(
            rng,
            f"Solve by factoring: {equation}",
            f"Use factoring to solve {equation}.",
            f"Factor the quadratic and find the solution(s): {equation}",
            f"What value(s) of x make {equation} true?",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=must_keep,
    )


def _factored_form_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    lim = (5, 8, 11)[_rank(difficulty)]
    p = rng.randint(1, lim)
    q = rng.randint(1, lim)
    sign_p = rng.choice([-1, 1])
    sign_q = rng.choice([-1, 1])
    root1 = -sign_p * p
    root2 = -sign_q * q
    factor1 = f"(x {'+' if sign_p > 0 else '-'} {p})"
    factor2 = f"(x {'+' if sign_q > 0 else '-'} {q})"
    equation = f"{factor1}{factor2} = 0"
    roots = sorted({root1, root2})
    answer = f"x = {roots[0]}" if len(roots) == 1 else f"x = {roots[0]} and x = {roots[1]}"
    distractors = [
        f"x = {p} and x = {q}",
        f"x = {-roots[0]} and x = {-roots[-1]}",
        f"x = {roots[0]}",
        f"x = {roots[-1]}",
    ]
    distractors = [d for d in distractors if d != answer]
    steps = [
        "Set each factor equal to zero.",
        f"Solve x {'+' if sign_p > 0 else '-'} {p} = 0 and x {'+' if sign_q > 0 else '-'} {q} = 0.",
        f"The solution set is {answer}.",
    ]
    return GeneratedQuestion(
        template_id="factoring",
        question=_stem(
            rng,
            f"Solve the factored equation {equation}.",
            f"What are the solution(s) of {equation}?",
            f"Use the zero product property to solve {equation}.",
            f"Find x from the factored quadratic {equation}.",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(p), str(q)],
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
        question=_stem(
            rng,
            f"Simplify (x^2 - {k2}) / (x - {k}).",
            f"Reduce the rational expression (x^2 - {k2}) / (x - {k}).",
            f"After factoring, what does (x^2 - {k2}) / (x - {k}) simplify to?",
            f"Write (x^2 - {k2}) / (x - {k}) in simplest form.",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(k2), str(k)],
    )


def _simplify_common_factor_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    k = rng.randint(2, (5, 8, 12)[_rank(difficulty)])
    a = rng.randint(1, (5, 8, 10)[_rank(difficulty)])
    numerator = f"{k}x + {k * a}"
    denominator = str(k)
    answer = f"x + {a}"
    distractors = [f"{k}x + {a}", f"x + {k * a}", f"{answer}/{k}", str(a)]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"Factor the numerator: {numerator} = {k}(x + {a}).",
        f"Cancel the common factor {k} with the denominator.",
        f"The simplified form is {answer}.",
    ]
    return GeneratedQuestion(
        template_id="simplify_rational",
        question=_stem(
            rng,
            f"Simplify ({numerator}) / {denominator}.",
            f"Reduce the expression ({numerator}) / {denominator}.",
            f"What is ({numerator}) / {denominator} in simplest form?",
            f"Factor first, then simplify ({numerator}) / {denominator}.",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(k), str(k * a)],
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
        question=_stem(
            rng,
            f"What is the degree of {poly}?",
            f"Identify the degree of the polynomial {poly}.",
            f"For {poly}, what is the highest exponent of x?",
            f"Which degree describes the polynomial {poly}?",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(deg)],
    )


def _count_terms_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    count = (3, 4, 5)[_rank(difficulty)]
    deg = count + rng.randint(1, 3)
    powers = sorted(rng.sample(range(1, deg + 1), count - 1), reverse=True)
    terms = [_pow_term(rng.randint(2, 9), p) for p in powers]
    terms.append(str(rng.randint(1, 9)))
    poly = " + ".join(terms)
    answer = str(count)
    distractors = [str(count - 1), str(count + 1), str(deg), str(len(powers))]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"The terms are separated by plus or minus signs: {poly}.",
        f"Count each separate term: there are {count}.",
        f"So the polynomial has {count} terms.",
    ]
    return GeneratedQuestion(
        template_id="degree_terms",
        question=_stem(
            rng,
            f"How many terms are in the polynomial {poly}?",
            f"Count the terms in {poly}.",
            f"For {poly}, how many separate terms are there?",
            f"Identify the number of terms in the polynomial {poly}.",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[],
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
        question=_stem(
            rng,
            (
                f"An event has {fav} favorable outcomes out of {total} equally likely "
                f"total outcomes. What is the probability of the event?"
            ),
            (
                f"Out of {total} equally likely outcomes, {fav} are favorable. "
                f"What is the probability?"
            ),
            (
                f"Using favorable outcomes over total outcomes, find the probability "
                f"when favorable = {fav} and total = {total}."
            ),
            f"What fraction represents {fav} favorable outcomes from {total} possible outcomes?",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(fav), str(total)],
    )


def _probability_complement_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    total = rng.randint(4, (8, 12, 16)[_rank(difficulty)])
    fav = rng.randint(1, total - 1)
    not_fav = total - fav
    answer = _frac(not_fav, total)
    distractors = [_frac(fav, total), _frac(total, not_fav), str(not_fav), str(total)]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"Not favorable outcomes: {total} - {fav} = {not_fav}.",
        f"Probability of the complement is {not_fav}/{total}.",
        f"Simplify to {answer}.",
    ]
    return GeneratedQuestion(
        template_id="probability_formula",
        question=_stem(
            rng,
            f"There are {total} equally likely outcomes and {fav} are favorable. What is the probability the event does not happen?",
            f"If {fav} of {total} outcomes make an event happen, find the probability it does not happen.",
            f"Find the complement probability when favorable outcomes = {fav} and total outcomes = {total}.",
            f"Out of {total} outcomes, {fav} are successes. What is P(not success)?",
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
        question=_stem(
            rng,
            (
                f"In a right triangle, the side opposite angle theta is {opp} and the "
                f"hypotenuse is {hyp}. Find sin(theta)."
            ),
            (
                f"A right triangle has opposite side {opp} and hypotenuse {hyp} "
                f"for angle theta. What is sin(theta)?"
            ),
            f"Use sin(theta) = opposite/hypotenuse with opposite = {opp} and hypotenuse = {hyp}.",
            f"For angle theta, opposite = {opp} and hypotenuse = {hyp}. Find the sine ratio.",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(opp), str(hyp)],
    )


def _cosine_ratio_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    adj = rng.randint(1, (6, 9, 12)[_rank(difficulty)])
    hyp = adj + rng.randint(1, 6)
    answer = _frac(adj, hyp)
    distractors = [_frac(hyp, adj), _frac(hyp - adj, hyp), _frac(adj, hyp - adj), str(adj)]
    distractors = [d for d in distractors if d != answer]
    steps = [
        "Use cos(theta) = adjacent / hypotenuse.",
        f"Substitute {adj}/{hyp}.",
        f"Simplify to {answer}.",
    ]
    return GeneratedQuestion(
        template_id="sine_cosine",
        question=_stem(
            rng,
            f"In a right triangle, the adjacent side is {adj} and the hypotenuse is {hyp}. Find cos(theta).",
            f"For angle theta, adjacent = {adj} and hypotenuse = {hyp}. What is cos(theta)?",
            f"Use cos(theta) = adjacent/hypotenuse with adjacent = {adj} and hypotenuse = {hyp}.",
            f"A right triangle has adjacent side {adj} and hypotenuse {hyp}. Find the cosine ratio.",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(adj), str(hyp)],
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
        question=_stem(
            rng,
            f"Find the radius of the circle {equation}.",
            f"For the circle {equation}, what is the radius?",
            f"Identify r when the circle is written as {equation}.",
            f"The equation of a circle is {equation}. Find its radius.",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(r2)],
    )


def _circle_center_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    rank = _rank(difficulty)
    limit = (4, 6, 9)[rank]
    h = rng.randint(-limit, limit)
    k = rng.randint(-limit, limit)
    r = rng.randint(2, (6, 9, 12)[rank])
    equation = f"{_shift('x', h)}^2 + {_shift('y', k)}^2 = {r * r}"
    answer = f"({h}, {k})"
    distractors = [f"({-h}, {-k})", f"({k}, {h})", f"({h}, {-k})", f"({-h}, {k})"]
    distractors = [d for d in distractors if d != answer]
    steps = [
        "Compare with (x - h)^2 + (y - k)^2 = r^2.",
        f"Read h = {h} and k = {k} from the signs inside the parentheses.",
        f"The center is ({h}, {k}).",
    ]
    return GeneratedQuestion(
        template_id="circle_standard",
        question=_stem(
            rng,
            f"Find the center of the circle {equation}.",
            f"For the circle {equation}, what is the center?",
            f"Identify the center from the standard form {equation}.",
            f"What ordered pair is the center of {equation}?",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(abs(h)), str(abs(k)), str(r * r)],
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
        question=_stem(
            rng,
            f"Evaluate the limit of ({a}x + {b}) as x approaches {c}.",
            f"Find lim x->{c} ({a}x + {b}).",
            f"As x approaches {c}, what value does {a}x + {b} approach?",
            f"Use direct substitution to evaluate ({a}x + {b}) at x = {c}.",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(a), str(b), str(c)],
    )


def _limit_quadratic_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    hi = (4, 7, 10)[_rank(difficulty)]
    a = rng.randint(1, hi)
    b = rng.randint(1, hi)
    c = rng.randint(1, hi)
    x_val = rng.randint(1, hi)
    val = a * x_val * x_val + b * x_val + c
    expr = f"{a}x^2 + {b}x + {c}"
    answer = str(val)
    distractors = [str(a * x_val + b + c), str(val + 1), str(val - 1), str(c)]
    distractors = [d for d in distractors if d != answer]
    steps = [
        f"Substitute x = {x_val} into {expr}.",
        f"Compute {a}({x_val})^2 + {b}({x_val}) + {c}.",
        f"The limit is {val}.",
    ]
    return GeneratedQuestion(
        template_id="limit_meaning",
        question=_stem(
            rng,
            f"Evaluate the limit of ({expr}) as x approaches {x_val}.",
            f"Find lim x->{x_val} ({expr}).",
            f"As x approaches {x_val}, what value does {expr} approach?",
            f"Use direct substitution to evaluate {expr} at x = {x_val}.",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(a), str(b), str(c), str(x_val)],
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
        question=_stem(
            rng,
            f"Find the derivative of x^{n}.",
            f"Differentiate x^{n}.",
            f"Using the power rule, what is d/dx of x^{n}?",
            f"What derivative do you get from x^{n}?",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(n)],
    )


def _coefficient_power_rule_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    rank = _rank(difficulty)
    coef = rng.randint(2, (5, 8, 12)[rank])
    n = rng.randint((2, 4, 6)[rank], (4, 6, 9)[rank])
    new_coef = coef * n
    answer = _pow_term(new_coef, n - 1)
    original = _pow_term(coef, n)
    distractors = [_pow_term(coef, n - 1), _pow_term(new_coef, n), _pow_term(n, n - 1), str(new_coef)]
    distractors = [d for d in distractors if d != answer]
    steps = [
        "Apply d/dx [a*x^n] = a*n*x^(n-1).",
        f"Multiply the coefficient by the exponent: {coef} * {n} = {new_coef}.",
        f"Subtract 1 from the exponent: {n} - 1 = {n - 1}.",
        f"The derivative is {answer}.",
    ]
    return GeneratedQuestion(
        template_id="basic_power_rule",
        question=_stem(
            rng,
            f"Find the derivative of {original}.",
            f"Differentiate {original}.",
            f"Using the power rule, what is d/dx of {original}?",
            f"What derivative do you get from {original}?",
        ),
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=steps,
        must_keep=[str(coef), str(n)],
    )


def _linear_domain_range_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    xs = sorted(rng.sample(range(1, (8, 12, 16)[_rank(difficulty)]), 3))
    pairs = [(x, 2 * x + 1) for x in xs]
    answer = "{" + ", ".join(str(x) for x in xs) + "}"
    range_choice = "{" + ", ".join(str(y) for _, y in pairs) + "}"
    return GeneratedQuestion(
        template_id="domain_and_range",
        question=(
            "For the relation "
            + ", ".join(f"({x}, {y})" for x, y in pairs)
            + ", what is the domain?"
        ),
        answer=answer,
        choices=_unique_choices(answer, [range_choice, "{1, 3, 5}", "{2, 4, 9}"], rng),
        steps=[
            f"The ordered pairs are {pairs}.",
            "The domain is the set of first coordinates.",
            f"So the domain is {answer}.",
        ],
        must_keep=[str(x) for x in xs],
    )


def _inverse_linear_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    a = rng.randint(2, (5, 8, 10)[_rank(difficulty)])
    b = rng.randint(1, (6, 9, 12)[_rank(difficulty)])
    answer = f"(x - {b})/{a}"
    distractors = [f"(x + {b})/{a}", f"{a}x - {b}", f"x/{a} - {b}", f"{a}(x - {b})"]
    return GeneratedQuestion(
        template_id="inverse_functions",
        question=f"Find f^-1(x) for f(x) = {a}x + {b}.",
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=[
            f"Write y = {a}x + {b}.",
            f"Swap x and y: x = {a}y + {b}.",
            f"Solve for y: y = {answer}.",
        ],
        must_keep=[str(a), str(b)],
    )


def _rational_domain_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    k = rng.randint(2, (6, 9, 12)[_rank(difficulty)])
    sign = rng.choice([-1, 1])
    excluded = -sign * k
    denominator = f"x {'+' if sign > 0 else '-'} {k}"
    answer = f"x = {excluded}"
    distractors = [f"x = {k}", f"x = {-excluded}", "all real numbers", f"x != {excluded}"]
    return GeneratedQuestion(
        template_id="domain_of_rational_functions",
        question=f"Find the excluded value of f(x) = 1/({denominator}).",
        answer=answer,
        choices=_unique_choices(answer, distractors, rng),
        steps=[
            f"Set the denominator equal to zero: {denominator} = 0.",
            f"Solve to get x = {excluded}.",
            f"The excluded value is {answer}.",
        ],
        must_keep=[str(k)],
    )


def _exponent_law_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    base = rng.randint(2, 5)
    m = rng.randint(2, (4, 6, 8)[_rank(difficulty)])
    n = rng.randint(2, (4, 6, 8)[_rank(difficulty)])
    answer = f"{base}^{m + n}"
    return GeneratedQuestion(
        template_id="laws_of_exponents",
        question=f"Simplify {base}^{m} * {base}^{n}.",
        answer=answer,
        choices=_unique_choices(answer, [f"{base}^{m * n}", f"{base}^{abs(m - n)}", str(base ** (m + n))], rng),
        steps=[
            "Use a^m * a^n = a^(m+n).",
            f"Add the exponents: {m} + {n} = {m + n}.",
            f"The simplified form is {answer}.",
        ],
        must_keep=[str(base), str(m), str(n)],
    )


def _exponential_equation_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    base = rng.choice([2, 3, 5])
    exp = rng.randint(2, (4, 5, 6)[_rank(difficulty)])
    value = base ** exp
    answer = f"x = {exp}"
    return GeneratedQuestion(
        template_id="exponential_equations",
        question=f"Solve {base}^x = {value}.",
        answer=answer,
        choices=_unique_choices(answer, [f"x = {base}", f"x = {value}", f"x = {exp + 1}"], rng),
        steps=[
            f"Write {value} as a power of {base}: {value} = {base}^{exp}.",
            f"So {base}^x = {base}^{exp}.",
            f"Therefore {answer}.",
        ],
        must_keep=[str(base), str(value)],
    )


def _log_equation_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    base = rng.choice([2, 3, 5, 10])
    exp = rng.randint(2, (4, 5, 6)[_rank(difficulty)])
    value = base ** exp
    answer = str(exp)
    return GeneratedQuestion(
        template_id="introduction_to_logarithms",
        question=f"Evaluate log base {base} of {value}.",
        answer=answer,
        choices=_unique_choices(answer, [str(base), str(value), str(exp + 1)], rng),
        steps=[
            f"Ask what exponent on {base} gives {value}.",
            f"Since {base}^{exp} = {value}, the exponent is {exp}.",
            f"The logarithm is {answer}.",
        ],
        must_keep=[str(base), str(value)],
    )


def _simple_interest_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    principal = rng.choice([1000, 2000, 5000, 8000])
    rate_percent = rng.choice([4, 5, 6, 8])
    years = rng.randint(1, (2, 3, 4)[_rank(difficulty)])
    interest = principal * rate_percent * years // 100
    answer = str(interest)
    return GeneratedQuestion(
        template_id="simple_interest",
        question=f"Find the simple interest on {principal} at {rate_percent}% for {years} years.",
        answer=answer,
        choices=_unique_choices(answer, [str(principal), str(interest + principal), str(max(1, interest - 100))], rng),
        steps=[
            "Use I = Prt.",
            f"Substitute I = {principal}({rate_percent / 100:g})({years}).",
            f"The simple interest is {interest}.",
        ],
        must_keep=[str(principal), str(rate_percent), str(years)],
    )


def _median_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    count = (5, 7, 9)[_rank(difficulty)]
    values = sorted(rng.sample(range(2, 30), count))
    median = values[count // 2]
    shuffled = values[:]
    rng.shuffle(shuffled)
    answer = str(median)
    return GeneratedQuestion(
        template_id="median",
        question=f"Find the median of {', '.join(str(v) for v in shuffled)}.",
        answer=answer,
        choices=_unique_choices(answer, [str(values[0]), str(values[-1]), str(sum(values) // len(values))], rng),
        steps=[
            f"Order the values: {', '.join(str(v) for v in values)}.",
            f"The middle value is {median}.",
            f"So the median is {answer}.",
        ],
        must_keep=[str(v) for v in shuffled],
    )


def _mode_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    mode = rng.randint(2, (8, 12, 16)[_rank(difficulty)])
    values = [mode, mode, rng.randint(1, 20), rng.randint(21, 30)]
    rng.shuffle(values)
    answer = str(mode)
    return GeneratedQuestion(
        template_id="mode",
        question=f"Find the mode of {', '.join(str(v) for v in values)}.",
        answer=answer,
        choices=_unique_choices(answer, [str(values[0]), str(max(values)), "no mode"], rng),
        steps=[
            f"Count how often each value appears in {values}.",
            f"{mode} appears most often.",
            f"The mode is {answer}.",
        ],
        must_keep=[str(v) for v in values],
    )


def _range_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    low = rng.randint(1, 10)
    high = low + rng.randint(5, (12, 20, 30)[_rank(difficulty)])
    values = [low, high, rng.randint(low + 1, high - 1), rng.randint(low + 1, high - 1)]
    rng.shuffle(values)
    answer = str(high - low)
    return GeneratedQuestion(
        template_id="range",
        question=f"Find the range of {', '.join(str(v) for v in values)}.",
        answer=answer,
        choices=_unique_choices(answer, [str(high), str(low), str(high + low)], rng),
        steps=[
            f"The maximum is {high}.",
            f"The minimum is {low}.",
            f"Range = {high} - {low} = {answer}.",
        ],
        must_keep=[str(v) for v in values],
    )


def _z_score_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    sd = rng.choice([2, 4, 5, 10])
    z = rng.randint(-2, 3) or 1
    mean = rng.randint(50, 80)
    x = mean + z * sd
    answer = str(z)
    return GeneratedQuestion(
        template_id="z_scores",
        question=f"Find the z-score if x = {x}, mean = {mean}, and standard deviation = {sd}.",
        answer=answer,
        choices=_unique_choices(answer, [str(-z), str(z + 1), str(x - mean)], rng),
        steps=[
            "Use z = (x - mean) / standard deviation.",
            f"Substitute ({x} - {mean}) / {sd}.",
            f"The z-score is {answer}.",
        ],
        must_keep=[str(x), str(mean), str(sd)],
    )


def _counting_principle_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    a = rng.randint(2, (4, 6, 8)[_rank(difficulty)])
    b = rng.randint(2, (4, 6, 8)[_rank(difficulty)])
    answer = str(a * b)
    return GeneratedQuestion(
        template_id="fundamental_counting_principle",
        question=f"There are {a} shirt choices and {b} pants choices. How many outfits are possible?",
        answer=answer,
        choices=_unique_choices(answer, [str(a + b), str(a), str(b)], rng),
        steps=[
            "Use the fundamental counting principle.",
            f"Multiply the choices: {a} * {b}.",
            f"There are {answer} possible outfits.",
        ],
        must_keep=[str(a), str(b)],
    )


def _distance_formula_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    scale = rng.randint(1, (2, 3, 4)[_rank(difficulty)])
    dx, dy = 3 * scale, 4 * scale
    answer = str(5 * scale)
    return GeneratedQuestion(
        template_id="distance_formula",
        question=f"Find the distance from (0, 0) to ({dx}, {dy}).",
        answer=answer,
        choices=_unique_choices(answer, [str(dx + dy), str(dx), str(dy)], rng),
        steps=[
            "Use d = sqrt((x2-x1)^2 + (y2-y1)^2).",
            f"Compute sqrt({dx}^2 + {dy}^2).",
            f"The distance is {answer}.",
        ],
        must_keep=[str(dx), str(dy)],
    )


def _slope_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    slope = rng.randint(-4, 5) or 2
    x1 = rng.randint(0, 4)
    y1 = rng.randint(0, 5)
    x2 = x1 + rng.randint(1, 4)
    y2 = y1 + slope * (x2 - x1)
    answer = str(slope)
    return GeneratedQuestion(
        template_id="slope",
        question=f"Find the slope through ({x1}, {y1}) and ({x2}, {y2}).",
        answer=answer,
        choices=_unique_choices(answer, [str(-slope), str(y2 - y1), str(x2 - x1)], rng),
        steps=[
            "Use m = (y2 - y1) / (x2 - x1).",
            f"Substitute ({y2} - {y1}) / ({x2} - {x1}).",
            f"The slope is {answer}.",
        ],
        must_keep=[str(x1), str(y1), str(x2), str(y2)],
    )


def _arithmetic_sequence_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    a1 = rng.randint(1, 8)
    d = rng.randint(2, (5, 8, 10)[_rank(difficulty)])
    n = rng.randint(4, (6, 8, 10)[_rank(difficulty)])
    term = a1 + (n - 1) * d
    answer = str(term)
    return GeneratedQuestion(
        template_id="arithmetic_sequences",
        question=f"Find the {n}th term of an arithmetic sequence with a1 = {a1} and d = {d}.",
        answer=answer,
        choices=_unique_choices(answer, [str(a1 + n * d), str(a1 + d), str(n * d)], rng),
        steps=[
            "Use a_n = a_1 + (n - 1)d.",
            f"Substitute {a1} + ({n} - 1)({d}).",
            f"The term is {answer}.",
        ],
        must_keep=[str(n), str(a1), str(d)],
    )


def _antiderivative_power_template(difficulty: str, rng: random.Random) -> GeneratedQuestion:
    n = rng.randint(1, (3, 5, 7)[_rank(difficulty)])
    coef = n + 1
    answer = f"x^{n + 1} + C"
    return GeneratedQuestion(
        template_id="antiderivatives",
        question=f"Find an antiderivative of {coef}x^{n}.",
        answer=answer,
        choices=_unique_choices(answer, [f"{coef}x^{n + 1} + C", f"x^{n} + C", f"{coef}x^{n - 1}"], rng),
        steps=[
            "Use the reverse power rule.",
            f"Increase the exponent from {n} to {n + 1}.",
            f"Divide by {n + 1}, giving {answer}.",
        ],
        must_keep=[str(coef), str(n)],
    )


# Registry: concept_id -> template function. Concepts without a template yet
# are simply absent; the generator raises a clear error for those.
TEMPLATES: Dict[str, Sequence[Callable[[str, random.Random], GeneratedQuestion]]] = {
    "mean": (_mean_template, _mean_missing_value_template),
    "function_definition": (_function_definition_template, _function_solve_input_template),
    "function_notation": (_alias("function_notation", _function_definition_template),),
    "domain_and_range": (_linear_domain_range_template,),
    "evaluating_functions": (_alias("evaluating_functions", _function_definition_template),),
    "operations_on_functions": (_alias("operations_on_functions", _function_definition_template),),
    "composite_functions": (_alias("composite_functions", _function_solve_input_template),),
    "inverse_functions": (_inverse_linear_template,),
    "quadratic_form": (_quadratic_form_template, _quadratic_discriminant_template),
    "factoring": (_factoring_template, _factored_form_template),
    "simplify_rational": (_simplify_rational_template, _simplify_common_factor_template),
    "domain_of_rational_functions": (_rational_domain_template,),
    "graphing_rational_functions": (_alias("graphing_rational_functions", _rational_domain_template),),
    "laws_of_exponents": (_exponent_law_template,),
    "exponential_functions": (_alias("exponential_functions", _exponential_equation_template),),
    "exponential_equations": (_exponential_equation_template,),
    "introduction_to_logarithms": (_log_equation_template,),
    "logarithmic_equations": (_alias("logarithmic_equations", _log_equation_template),),
    "applications_of_logarithms": (_alias("applications_of_logarithms", _log_equation_template),),
    "simple_interest": (_simple_interest_template,),
    "future_value": (_alias("future_value", _simple_interest_template),),
    "degree_terms": (_degree_terms_template, _count_terms_template),
    "median": (_median_template,),
    "mode": (_mode_template,),
    "range": (_range_template,),
    "z_scores": (_z_score_template,),
    "probability_formula": (_probability_formula_template, _probability_complement_template),
    "sample_spaces": (_alias("sample_spaces", _probability_formula_template),),
    "events": (_alias("events", _probability_formula_template),),
    "basic_probability_rules": (_alias("basic_probability_rules", _probability_complement_template),),
    "fundamental_counting_principle": (_counting_principle_template,),
    "sine_cosine": (_sine_cosine_template, _cosine_ratio_template),
    "six_trigonometric_functions": (_alias("six_trigonometric_functions", _sine_cosine_template),),
    "trigonometric_identities": (_alias("trigonometric_identities", _sine_cosine_template),),
    "circle_standard": (_circle_standard_template, _circle_center_template),
    "polynomial_functions": (_alias("polynomial_functions", _degree_terms_template),),
    "precalculus_rational_functions": (_alias("precalculus_rational_functions", _rational_domain_template),),
    "distance_formula": (_distance_formula_template,),
    "slope": (_slope_template,),
    "equation_of_a_line": (_alias("equation_of_a_line", _slope_template),),
    "circles": (_alias("circles", _circle_standard_template),),
    "parabolas": (_alias("parabolas", _quadratic_form_template),),
    "ellipses": (_alias("ellipses", _circle_standard_template),),
    "hyperbolas": (_alias("hyperbolas", _quadratic_form_template),),
    "standard_equations_of_conic_sections": (_alias("standard_equations_of_conic_sections", _circle_standard_template),),
    "arithmetic_sequences": (_arithmetic_sequence_template,),
    "arithmetic_series": (_alias("arithmetic_series", _arithmetic_sequence_template),),
    "geometric_sequences": (_alias("geometric_sequences", _exponential_equation_template),),
    "geometric_series": (_alias("geometric_series", _exponential_equation_template),),
    "sigma_notation": (_alias("sigma_notation", _arithmetic_sequence_template),),
    "limit_meaning": (_limit_meaning_template, _limit_quadratic_template),
    "introduction_to_limits": (_alias("introduction_to_limits", _limit_meaning_template),),
    "evaluating_limits": (_alias("evaluating_limits", _limit_meaning_template),),
    "limits_at_infinity": (_alias("limits_at_infinity", _limit_meaning_template),),
    "basic_power_rule": (_basic_power_rule_template, _coefficient_power_rule_template),
    "definition_of_a_derivative": (_alias("definition_of_a_derivative", _basic_power_rule_template),),
    "sum_and_difference_rule": (_alias("sum_and_difference_rule", _coefficient_power_rule_template),),
    "higher_order_derivatives": (_alias("higher_order_derivatives", _coefficient_power_rule_template),),
    "tangent_lines": (_alias("tangent_lines", _basic_power_rule_template),),
    "related_rates": (_alias("related_rates", _function_solve_input_template),),
    "increasing_and_decreasing_functions": (_alias("increasing_and_decreasing_functions", _basic_power_rule_template),),
    "local_maximum_and_minimum": (_alias("local_maximum_and_minimum", _quadratic_form_template),),
    "first_derivative_test": (_alias("first_derivative_test", _basic_power_rule_template),),
    "second_derivative_test": (_alias("second_derivative_test", _basic_power_rule_template),),
    "optimization": (_alias("optimization", _quadratic_form_template),),
    "antiderivatives": (_antiderivative_power_template,),
    "indefinite_integrals": (_alias("indefinite_integrals", _antiderivative_power_template),),
    "definite_integrals": (_alias("definite_integrals", _antiderivative_power_template),),
    "area_under_a_curve": (_alias("area_under_a_curve", _antiderivative_power_template),),
    "area_between_curves": (_alias("area_between_curves", _antiderivative_power_template),),
}


def has_template(concept_id: str) -> bool:
    return concept_id in TEMPLATES


def list_concepts() -> List[str]:
    """Every concept the generator can currently produce a question for."""
    return list(TEMPLATES.keys())


def generate(concept_id: str, difficulty: str, rng: random.Random) -> GeneratedQuestion:
    templates = TEMPLATES.get(concept_id)
    if templates is None:
        raise KeyError(concept_id)
    template = rng.choice(list(templates))
    return template(difficulty, rng)

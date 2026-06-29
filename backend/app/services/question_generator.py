"""The hybrid generator: parametric template (provably-correct math) + an
optional LLM rephrase of the wording for variety.

Flow per call:
  1. A template randomizes the numbers and computes the answer/choices/steps.
  2. Ollama/phi is asked to reword ONLY the question sentence -- same numbers,
     same task, no solving.
  3. The rephrase is accepted only if every required number survived verbatim;
     otherwise we keep the raw template text. So the LLM can make the wording
     nicer but can never change what's being asked or the right answer.
  4. Choices are shuffled so position carries no signal.

The caller (api/quiz.py) stores the result and serves everything EXCEPT
`correct_answer` to the client.
"""

from __future__ import annotations

import random
import re
from collections import Counter
from dataclasses import dataclass
from typing import Dict, List

from app.services import quiz_templates
from app.services.ai_service import generate_answer

# Bounds on an acceptable rephrase, so a runaway/garbled LLM response can't
# become the question shown to a student.
_MIN_LEN = 8
_MAX_LEN = 300

# phi often answers with a label like "Reworded Question: ..." or "Sure! Here
# is the question: ..." -- strip a short leading "<label>:" when the label
# looks like a preamble rather than part of the math.
# A short leading "<label>: ..." clause, only stripped when the label looks
# like a preamble (gate below) -- so "Solve by factoring: ..." is left intact
# while "Sure! Here is the question: ..." is not.
_PREAMBLE_RE = re.compile(r"^\s*([^:]{1,40}):\s+(.*)$", re.S)
_PREAMBLE_WORDS = re.compile(r"question|reword|rephrase|sure|here", re.I)

# Unicode super/subscripts (x², x₁ ...). The app renders math in "x^2" form,
# so a rephrase that introduces these is rejected in favour of the clean
# template wording rather than shown as-is.
_UNICODE_MATH_RE = re.compile("[²³¹⁰-₟]")

# Numeric tokens (ints, negatives, fractions, decimals). Used to confirm a
# reword preserved every number -- including duplicates -- by multiset.
_NUMBER_RE = re.compile(r"-?\d+(?:/\d+)?(?:\.\d+)?")


def _number_counts(text: str) -> Dict[str, int]:
    return Counter(_NUMBER_RE.findall(text))


def _strip_preamble(text: str) -> str:
    m = _PREAMBLE_RE.match(text)
    if m and _PREAMBLE_WORDS.search(m.group(1)):
        return m.group(2).strip()
    return text


@dataclass
class ServedQuestion:
    template_id: str
    question_text: str
    choices: List[str]      # shuffled
    correct_answer: str
    steps: List[str]


def _rephrase(question: str, must_keep: List[str]) -> str:
    """Ask the LLM to reword the question; return the original on any doubt.

    Conservative on purpose -- a boring-but-correct question beats a
    creatively-reworded one that changed a number."""
    prompt = (
        "Reword the following math question using different wording, but keep "
        "every number and the mathematical task EXACTLY the same. Do NOT solve "
        "it, do NOT add an answer, and reply with ONLY the reworded question on "
        "a single line.\n\n"
        f"Question: {question}"
    )
    try:
        raw = (generate_answer(prompt) or "").strip()
    except Exception:
        # Ollama down/slow/erroring -- the raw template question is a fine
        # fallback, so generation never fails just because the LLM is unhappy.
        return question

    # phi sometimes prepends "Sure! ..."/"Reworded Question: ..." or wraps in
    # quotes -- prefer a single line that survives cleaning and still contains
    # all the required numbers.
    orig_nums = _number_counts(question)
    candidates = [raw] + [ln.strip() for ln in raw.splitlines()]
    for cand in candidates:
        cleaned = cand.strip().strip('"').strip("'").strip()
        cleaned = _strip_preamble(cleaned)
        if not (_MIN_LEN <= len(cleaned) <= _MAX_LEN):
            continue
        # Reject Unicode super/subscripts (x²) -- they don't match the app's
        # "x^2" rendering, so fall back to the clean template wording instead.
        if _UNICODE_MATH_RE.search(cleaned):
            continue
        # Every number in the original must survive, counting duplicates --
        # this catches a reword that quietly drops a repeated value (e.g.
        # "1, 9, 1, 1" -> "1, 9, 1, and another number"), which would make the
        # question unanswerable even though the answer is still computed here.
        cand_nums = _number_counts(cleaned)
        if any(cand_nums[n] < count for n, count in orig_nums.items()):
            continue
        if all(token in cleaned for token in must_keep):
            return cleaned
    return question


def generate_question(concept_id: str, difficulty: str, *, rephrase: bool = True) -> ServedQuestion:
    """Generate one personalized question for a concept at a difficulty.

    Raises KeyError if the concept has no template yet (caller maps that to a
    clear 4xx)."""
    rng = random.Random()  # system entropy -> different question each call
    q = quiz_templates.generate(concept_id, difficulty, rng)

    question_text = _rephrase(q.question, q.must_keep) if rephrase else q.question

    choices = list(q.choices)
    rng.shuffle(choices)

    return ServedQuestion(
        template_id=q.template_id,
        question_text=question_text,
        choices=choices,
        correct_answer=q.answer,
        steps=q.steps,
    )

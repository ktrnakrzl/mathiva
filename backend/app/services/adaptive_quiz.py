"""Server-side adaptive selection for personalized practice.

The old `/quiz/next` let the *client* dictate which concept and difficulty to
serve, so nothing about a question depended on the individual student. These
functions move that decision to the server and base it on the STUDENT'S OWN
attempt history:

  - **concept**: weighted toward the concepts they are weakest at (low accuracy)
    or have never tried, so practice targets gaps instead of whatever the client
    happened to request.
  - **difficulty**: adapts to recent performance on the chosen concept -- step up
    when they are doing well, step down when they are struggling.

Everything here is a pure function over a list of attempt rows (anything with
`concept_id`, `difficulty`, `is_correct`, `created_at`), so the policy is
unit-testable without a database and the pedagogy is easy to read and defend.
The real caller (api/quiz.py) passes the student's `QuizAttempt` rows.
"""

from __future__ import annotations

import random
from typing import List, Optional, Sequence

from app.services import quiz_templates

# Ordered easiest -> hardest; the single source of truth lives in quiz_templates.
DIFFICULTY_LEVELS = quiz_templates.DIFFICULTY_LEVELS

# How many of the most recent attempts on a concept count as "recent" when
# deciding whether to move the difficulty up or down.
_RECENT_WINDOW = 4

# Priority for a concept the student has never attempted: high enough to be
# introduced ahead of concepts they already handle well, but below a concept
# they are actively failing (which should be drilled first). accuracy-based
# scores range 0..1, so 0.7 sits above "70%+ accuracy" concepts.
_UNSEEN_SCORE = 0.7

# A concept never drops fully to zero priority, so even a mastered one keeps a
# small chance of resurfacing (light spaced repetition) instead of vanishing.
_MASTERED_FLOOR = 0.05

_STEP_UP_ACCURACY = 0.75    # recent accuracy at/above this -> offer a harder one
_STEP_DOWN_ACCURACY = 0.40  # recent accuracy below this   -> ease back down


def _concept_attempts(attempts: Sequence, concept_id: str) -> List:
    return [a for a in attempts if a.concept_id == concept_id]


def concept_score(attempts: Sequence, concept_id: str) -> float:
    """How much this student needs to practice a concept: higher = more needed.

    Unseen concepts get a fixed medium-high score; seen concepts score by how
    much the student struggles with them (1 - accuracy), floored so a mastered
    concept still resurfaces occasionally.
    """
    ca = _concept_attempts(attempts, concept_id)
    if not ca:
        return _UNSEEN_SCORE
    accuracy = sum(1 for a in ca if a.is_correct) / len(ca)
    return max(1.0 - accuracy, _MASTERED_FLOOR)


def select_concept(
    attempts: Sequence, candidates: Sequence[str], rng: random.Random
) -> str:
    """Pick the next concept, weighted by how much practice each needs.

    Weighted-random (not strict "always the weakest") so a session has variety
    while still favouring weak spots: a concept twice as weak is roughly twice as
    likely to come up. `candidates` must be non-empty.
    """
    candidates = list(candidates)
    scores = [concept_score(attempts, c) for c in candidates]
    total = sum(scores)
    if total <= 0:
        return rng.choice(candidates)
    r = rng.uniform(0, total)
    upto = 0.0
    for concept_id, score in zip(candidates, scores):
        upto += score
        if r <= upto:
            return concept_id
    return candidates[-1]  # float-rounding guard


def select_difficulty(attempts: Sequence, concept_id: str) -> str:
    """Adapt difficulty to recent performance on this concept.

    A brand-new concept starts at the easiest level. Otherwise we take the
    student's most recent difficulty on it and step up when they are getting the
    last few right, step down when they are mostly getting them wrong.
    """
    ca = _concept_attempts(attempts, concept_id)
    if not ca:
        return DIFFICULTY_LEVELS[0]

    recent = sorted(ca, key=lambda a: a.created_at)[-_RECENT_WINDOW:]
    current = recent[-1].difficulty
    idx = DIFFICULTY_LEVELS.index(current) if current in DIFFICULTY_LEVELS else 0
    accuracy = sum(1 for a in recent if a.is_correct) / len(recent)

    if accuracy >= _STEP_UP_ACCURACY and len(recent) >= 2:
        idx = min(idx + 1, len(DIFFICULTY_LEVELS) - 1)
    elif accuracy < _STEP_DOWN_ACCURACY:
        idx = max(idx - 1, 0)
    return DIFFICULTY_LEVELS[idx]


# A concept counts as "reviewed enough" once recent accuracy reaches this, so it
# drops out of the review queue (spaced-repetition-lite: master it and it stops
# resurfacing until the record slips again).
_MASTERY_THRESHOLD = 0.8


def review_pool(
    attempts: Sequence, candidates: Sequence[str], mastery_threshold: float = _MASTERY_THRESHOLD
) -> List[str]:
    """The concepts worth REVIEWING: ones the student has attempted but not yet
    mastered (recent accuracy below the threshold).

    Differs from the practice pool in two ways: unseen concepts are excluded
    (there's nothing to review in something never studied), and concepts the
    student is currently getting right are excluded (recent accuracy tracks the
    latest window, so a concept they've since mastered leaves the queue).
    """
    due: List[str] = []
    for concept_id in candidates:
        ca = _concept_attempts(attempts, concept_id)
        if not ca:
            continue  # never attempted -> not review material
        recent = sorted(ca, key=lambda a: a.created_at)[-_RECENT_WINDOW:]
        accuracy = sum(1 for a in recent if a.is_correct) / len(recent)
        if accuracy < mastery_threshold:
            due.append(concept_id)
    return due


def choose_next(
    attempts: Sequence,
    candidates: Sequence[str],
    rng: Optional[random.Random] = None,
) -> tuple[str, str]:
    """Return (concept_id, difficulty) personalized to the student's history.

    `candidates` is the pool to choose from (e.g. the concepts in the lesson the
    student is studying). Only concepts the generator has a template for are
    considered; raises ValueError if none of the candidates are usable.
    """
    rng = rng or random.Random()
    usable = [c for c in candidates if quiz_templates.has_template(c)]
    if not usable:
        raise ValueError("no template-backed candidate concepts to choose from")
    concept_id = select_concept(attempts, usable, rng)
    difficulty = select_difficulty(attempts, concept_id)
    return concept_id, difficulty

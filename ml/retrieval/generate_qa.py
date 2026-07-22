"""Generate the RAG QA dataset from the General Mathematics corpus.

This feeds the T5 fine-tune (ml/t5/prepare_dataset.py reads the output). Each
chunk of the textbook is turned into 2-3 self-contained question/answer pairs by
a language model. The default backend is the free Gemini tier (better, more
self-contained pairs than local llama3, and no Ollama required); set USE_OLLAMA=1
for the offline llama3 path. Data generation is a one-time, offline dev step, so
using Gemini here does not make the shipped app depend on a cloud model.

Why this is a rewrite. The old version silently dropped any chunk whose model
output wasn't already clean JSON (`json.loads` in a bare try/except), so llama3's
habit of wrapping JSON in prose meant only 157 of 1108 chunks ever produced
pairs -- 373 total. This version:

  * asks Ollama for strict JSON (`format:"json"`) and still parses defensively
    (`_extract_pairs`) so prose-wrapped output is recovered, not discarded;
  * cleans each chunk first and skips pure front matter (text_clean.py), so we
    don't mint QA from copyright pages;
  * validates every pair and de-dups questions globally;
  * saves incrementally and resumes, so a long run survives interruption.

Run:   python generate_qa.py            # resumes if a partial run exists
       FRESH=1 python generate_qa.py    # back up any old output, start clean
"""

import json
import os
import re
import time

import requests

from text_clean import clean_chunk_text, is_low_content

HERE = os.path.dirname(os.path.abspath(__file__))
CHUNKS_PATH = os.path.join(HERE, "output_chunks.json")
OUT_PATH = os.path.join(HERE, "genmath_qa_pairs.json")
PROGRESS_PATH = os.path.join(HERE, "_qa_progress.json")
EXTRA_PROGRESS_PATH = os.path.join(HERE, "_qa_progress_extra.json")

# Model backend. Gemini (free tier) by default -- it writes noticeably better,
# more self-contained pairs than local llama3. Set USE_OLLAMA=1 to fall back to
# the offline llama3 path (e.g. no key / no network).
USE_OLLAMA = bool(os.environ.get("USE_OLLAMA"))

OLLAMA_URL = "http://localhost:11434/api/generate"
OLLAMA_MODEL = "llama3"

GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-flash-latest")
GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    "{model}:generateContent"
)
# Stay under the free tier's ~20 requests/minute: keep >= this many seconds
# between calls. Override with GEMINI_MIN_INTERVAL for a paid key.
GEMINI_MIN_INTERVAL = float(os.environ.get("GEMINI_MIN_INTERVAL", "3.5"))

# Anthropic Claude backend (BACKEND=claude): a paid API, but no daily-quota wall
# and the best-quality pairs. Uses the official `anthropic` SDK; the key comes
# from ANTHROPIC_API_KEY. Haiku is the cost pick for this one-time bulk job.
CLAUDE_MODEL = os.environ.get("CLAUDE_MODEL", "claude-haiku-4-5")

# Which model backend to use: "gemini" (default, free tier), "claude" (Anthropic
# API), or "ollama" (local llama3). USE_OLLAMA=1 is kept as a shorthand.
BACKEND = os.environ.get("BACKEND", "ollama" if USE_OLLAMA else "gemini").strip().lower()

SAVE_EVERY = 20            # flush to disk every N processed chunks
REQUEST_TIMEOUT = 120


def _gemini_key():
    """The free Gemini API key, from the environment or backend/.env (where the
    app keeps it), so this script needs no separate configuration."""
    key = os.environ.get("GEMINI_API_KEY")
    if key:
        return key
    env_path = os.path.join(HERE, "..", "..", "backend", ".env")
    if os.path.exists(env_path):
        with open(env_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("GEMINI_API_KEY="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    return None

_RULES = """CRITICAL rules:
- The content must be actual MATHEMATICS instruction. If it is NOT -- e.g. a
  copyright page, contact/publisher information, a table of contents, credits,
  or a foreword -- return an empty JSON array [] and nothing else. Do not invent
  math from non-math text, and never ask about names, emails, phone numbers,
  page numbers, or publication details.
- Each question must be SELF-CONTAINED. A student must be able to answer it
  WITHOUT seeing the lesson, so put the actual equation, numbers, or function
  INSIDE the question.
    GOOD: "Solve 3(x - 1) = 2(x + 3) for x."
    BAD:  "What is the value of x?"        (which x? they can't see the lesson)
    GOOD: "What is the degree of f(x) = 2x^3 - x + 5?"
    BAD:  "What is the degree of the polynomial?"
- Never refer to "the lesson", "the example", "this problem", "the passage",
  "the solution", or any figure/table/graph the student cannot see.
- Only ask about content that is actually present. The source is extracted from
  a PDF and some equations came out BLANK or missing -- if the equation or
  expression you would need is not shown, do NOT invent one; skip that question.
- Give a complete, correct answer, showing the working for any calculation."""

PROMPT_TEMPLATE = """You are writing study questions for a Grade 11 General \
Mathematics student, based only on the lesson content below.

Lesson content:
\"\"\"
{content}
\"\"\"

Write 2-3 question/answer pairs. {rules}

Return ONLY a JSON array, no prose:
[
  {{"question": "...", "answer": "..."}},
  {{"question": "...", "answer": "..."}}
]""".replace("{rules}", _RULES)

# The EXTRA pass revisits the same chunks asking for *different kinds* of
# questions, so the global de-dup keeps genuinely new pairs instead of
# rephrasings of pass 1.
PROMPT_VARIED = """You are writing study questions for a Grade 11 General \
Mathematics student, based only on the lesson content below.

Lesson content:
\"\"\"
{content}
\"\"\"

Write 4-6 question/answer pairs, covering a MIX of these different types (only
those the content supports):
- a worked computational problem (show every step);
- a real-world / word-problem application;
- a conceptual "why" or "what is the difference" question;
- a common-mistake or "is this correct?" question.

{rules}

Return ONLY a JSON array, no prose:
[
  {{"question": "...", "answer": "..."}},
  {{"question": "...", "answer": "..."}}
]""".replace("{rules}", _RULES)

# Reject questions/answers that lean on the source instead of standing alone.
# The spot-check showed the main junk mode is context-dependent wording -- a
# question a student couldn't answer without seeing this exact chunk ("these
# x-values", "in this lesson", "our solution", "according to the example").
_META_REF = re.compile(
    r"\b("
    # demonstrative / possessive + a structural noun from the source
    r"(this|that|these|those|our|the given|the following|the above|the previous)\s+"
    r"(passage|text|excerpt|content|context|material|chunk|lesson|solution|"
    r"example|examples|exercise|item|items|problem|figure|graph|table|equation|"
    r"section|part|activity|values?|x-values?)"
    # explicit pointers back into the source
    r"|according to the\s+(lesson|text|passage|content|solution|example|problem)"
    r"|(given|shown|listed|defined|described|mentioned|provided|discussed)\s+"
    r"(above|below|earlier|previously|in the (lesson|text|solution|example))"
    r"|in (our|the) solution|the solution (provided|given|above)"
    r")\b",
    re.IGNORECASE,
)

# Degenerate answers that admit the content wasn't actually there.
_NON_ANSWER = re.compile(
    r"\bnot\s+(defined|mentioned|given|provided|specified|stated|included|"
    r"available|shown|discussed)\s+in\s+the\s+(lesson|text|passage|content|"
    r"material|solution|example)",
    re.IGNORECASE,
)


def _load_json(path, default):
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return default


def _extract_pairs(raw):
    """Pull a list of {question, answer} dicts out of a model response.

    Handles: a bare JSON array, a `{"pairs": [...]}`-style object, markdown code
    fences, and trailing prose. Returns [] if nothing parses.
    """
    if not raw:
        return []
    text = raw.strip()
    # Drop ``` / ```json fences if present.
    if text.startswith("```"):
        text = re.sub(r"^```[a-zA-Z]*\n?|\n?```$", "", text).strip()

    def _coerce(obj):
        if isinstance(obj, list):
            return obj
        if isinstance(obj, dict):
            # {"pairs": [...]} or {"qa": [...]}: take the first list value, or
            # treat the dict itself as a single pair.
            for v in obj.values():
                if isinstance(v, list):
                    return v
            if "question" in obj and "answer" in obj:
                return [obj]
        return []

    # First try the whole thing.
    try:
        return _coerce(json.loads(text))
    except json.JSONDecodeError:
        pass
    # Fall back to the outermost [...] slice, tolerating a trailing comma.
    start, end = text.find("["), text.rfind("]")
    if start != -1 and end > start:
        candidate = text[start : end + 1]
        candidate = re.sub(r",\s*]", "]", candidate)
        try:
            return _coerce(json.loads(candidate))
        except json.JSONDecodeError:
            pass
    return []


def _valid_pair(q, a):
    if not isinstance(q, str) or not isinstance(a, str):
        return False
    q, a = q.strip(), a.strip()
    if not q or not a:
        return False
    if not q.endswith("?"):
        return False
    if len(q.split()) < 3 or len(a.split()) < 2:
        return False
    if len(a) > 1200:
        return False
    if q.lower() == a.lower():
        return False
    if _META_REF.search(q) or _META_REF.search(a):
        return False
    if _NON_ANSWER.search(a):
        return False
    return True


def _norm_q(q):
    return re.sub(r"\s+", " ", q.lower()).strip(" ?.!")


class ModelError(RuntimeError):
    """A transient backend failure (network, quota) -- the chunk is left
    unprocessed so a resume retries it, instead of being silently dropped."""


def _call_ollama(prompt, temperature):
    try:
        resp = requests.post(
            OLLAMA_URL,
            json={
                "model": OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False,
                "format": "json",        # bias toward syntactically valid JSON
                "options": {"temperature": temperature, "num_predict": 512},
            },
            timeout=REQUEST_TIMEOUT,
        )
        resp.raise_for_status()
    except requests.RequestException as exc:
        raise ModelError(f"ollama request failed: {exc}") from exc
    return resp.json().get("response", "")


def _retry_delay(resp):
    """Gemini's suggested wait from a 429 body, if present (else None)."""
    try:
        for detail in resp.json().get("error", {}).get("details", []):
            if "RetryInfo" in detail.get("@type", "") and detail.get("retryDelay"):
                return float(str(detail["retryDelay"]).rstrip("s"))
    except Exception:
        pass
    return None


_last_gemini_call = 0.0


def _call_gemini(prompt, temperature):
    global _last_gemini_call
    key = _gemini_key()
    if not key:
        raise ModelError("GEMINI_API_KEY not set (env or backend/.env)")

    # Throttle to respect the free-tier per-minute cap.
    wait = GEMINI_MIN_INTERVAL - (time.time() - _last_gemini_call)
    if wait > 0:
        time.sleep(wait)

    body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": temperature,
            # Force a JSON body (Gemini's analogue of Ollama's format:"json").
            "response_mime_type": "application/json",
        },
    }
    for attempt in range(3):
        try:
            resp = requests.post(
                GEMINI_URL.format(model=GEMINI_MODEL),
                params={"key": key},
                json=body,
                timeout=REQUEST_TIMEOUT,
            )
        except requests.RequestException as exc:
            raise ModelError(f"gemini request failed: {exc}") from exc
        finally:
            _last_gemini_call = time.time()

        if resp.status_code == 429:       # rate/quota limited -> back off, retry
            delay = _retry_delay(resp) or 10 * (attempt + 1)
            print(f"    gemini 429 (quota) -- waiting {min(delay, 60):.0f}s")
            time.sleep(min(delay, 60))
            continue

        try:
            payload = resp.json()
        except ValueError as exc:
            raise ModelError("gemini returned a non-JSON response") from exc
        if isinstance(payload.get("error"), dict):
            raise ModelError(payload["error"].get("message", "gemini error"))
        try:
            return payload["candidates"][0]["content"]["parts"][0]["text"]
        except (KeyError, IndexError, TypeError):
            return ""                     # blocked/empty -> treat as "no pairs"

    raise ModelError("gemini rate-limited after retries")


_claude = None


def _anthropic_key():
    """ANTHROPIC_API_KEY from the environment or backend/.env, so the key can
    live in the gitignored .env rather than being exported (or pasted anywhere)."""
    key = os.environ.get("ANTHROPIC_API_KEY")
    if key:
        return key
    env_path = os.path.join(HERE, "..", "..", "backend", ".env")
    if os.path.exists(env_path):
        with open(env_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("ANTHROPIC_API_KEY="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    return None


def _claude_client():
    global _claude
    if _claude is None:
        try:
            import anthropic
        except ImportError as exc:
            raise ModelError(
                "the `anthropic` package is not installed (pip install anthropic)"
            ) from exc
        key = _anthropic_key()
        if not key:
            raise ModelError("ANTHROPIC_API_KEY not set (env or backend/.env)")
        _claude = anthropic.Anthropic(api_key=key)
    return _claude


def _call_claude(prompt, temperature):
    import anthropic

    try:
        message = _claude_client().messages.create(
            model=CLAUDE_MODEL,
            max_tokens=2048,               # ample for 2-6 pairs of JSON
            temperature=temperature,
            # The prompt already says "Return ONLY a JSON array"; the shared
            # _extract_pairs parser tolerates any stray prose/fences either way.
            messages=[{"role": "user", "content": prompt}],
        )
    except anthropic.APIError as exc:      # network / rate-limit / auth / server
        raise ModelError(f"claude request failed: {exc}") from exc
    return "".join(b.text for b in message.content if b.type == "text")


def _call_model(content, temperature, template):
    prompt = template.format(content=content)
    if BACKEND == "claude":
        return _call_claude(prompt, temperature)
    if BACKEND == "ollama":
        return _call_ollama(prompt, temperature)
    return _call_gemini(prompt, temperature)


def _pairs_for_chunk(content, template):
    """Generate + validate pairs for one chunk, with one low-temp retry."""
    for temperature in (0.3, 0.0):
        try:
            raw = _call_model(content, temperature, template)
        except ModelError as exc:
            print(f"    model error: {exc}")
            return None                  # signal: don't mark processed, let resume retry
        good = [
            {"question": p["question"].strip(), "answer": p["answer"].strip()}
            for p in _extract_pairs(raw)
            if isinstance(p, dict)
            and _valid_pair(p.get("question", ""), p.get("answer", ""))
        ]
        if good:
            return good
    return []                            # parsed fine but nothing usable


def _save(qa_pairs, processed, progress_path):
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(qa_pairs, f, ensure_ascii=False, indent=2)
    with open(progress_path, "w", encoding="utf-8") as f:
        json.dump(sorted(processed), f)


def main():
    # Two modes. Base pass: FRESH starts clean, otherwise resumes. EXTRA pass:
    # revisits every content chunk with the varied prompt to add new question
    # types on top of an existing dataset (its own checkpoint, appends + dedups).
    extra = bool(os.environ.get("EXTRA"))
    fresh = bool(os.environ.get("FRESH"))
    chunks = _load_json(CHUNKS_PATH, [])

    if extra:
        template = PROMPT_VARIED
        progress_path = EXTRA_PROGRESS_PATH
        qa_pairs = _load_json(OUT_PATH, [])
        if not qa_pairs:
            raise SystemExit("EXTRA pass needs an existing genmath_qa_pairs.json")
        processed = set(_load_json(progress_path, []))
        print(
            f"EXTRA pass: {len(qa_pairs)} existing pairs, "
            f"{len(processed)} chunks already revisited"
        )
    else:
        template = PROMPT_TEMPLATE
        progress_path = PROGRESS_PATH
        if fresh:
            if os.path.exists(OUT_PATH):
                os.replace(OUT_PATH, OUT_PATH.replace(".json", ".backup.json"))
                print(f"backed up old output -> {os.path.basename(OUT_PATH)}.backup.json")
            qa_pairs, processed = [], set()
        else:
            qa_pairs = _load_json(OUT_PATH, [])
            processed = set(_load_json(progress_path, []))
            if qa_pairs or processed:
                print(f"resuming: {len(qa_pairs)} pairs, {len(processed)} chunks done")

    seen_q = {_norm_q(p["question"]) for p in qa_pairs}
    skipped_low = 0
    t0 = time.time()

    # Circuit breaker: if the backend fails repeatedly in a row (usually the free
    # tier's *daily* quota, not a per-minute blip), stop and save rather than
    # spinning for hours backing off on every remaining chunk. Rerun to resume.
    consecutive_fail = 0
    stop_after = int(os.environ.get("STOP_AFTER_FAILS", "6"))

    for i, chunk in enumerate(chunks):
        idx = chunk["chunk_index"]
        if idx in processed:
            continue

        content = clean_chunk_text(chunk["content"])
        if is_low_content(content):
            skipped_low += 1
            processed.add(idx)
            continue

        pairs = _pairs_for_chunk(content, template)
        if pairs is None:                # transient failure: retry on a later run
            consecutive_fail += 1
            if consecutive_fail >= stop_after:
                print(
                    f"\n{consecutive_fail} model failures in a row (quota/network?)"
                    " -- saving and stopping. Rerun to resume where this left off."
                )
                break
            continue
        consecutive_fail = 0

        added = 0
        for p in pairs:
            key = _norm_q(p["question"])
            if key in seen_q:
                continue
            seen_q.add(key)
            p["chunk_id"] = idx          # prepare_dataset.py maps chunk_id -> chunk_index
            qa_pairs.append(p)
            added += 1
        processed.add(idx)

        print(
            f"[{i + 1}/{len(chunks)}] chunk {idx}: +{added} pairs "
            f"(total {len(qa_pairs)})"
        )
        if len(processed) % SAVE_EVERY == 0:
            _save(qa_pairs, processed, progress_path)

    _save(qa_pairs, processed, progress_path)
    print(
        f"\nDone. {len(qa_pairs)} QA pairs from "
        f"{len(processed) - skipped_low} content chunks "
        f"({skipped_low} low-content chunks skipped) in {time.time() - t0:.0f}s."
    )


if __name__ == "__main__":
    main()

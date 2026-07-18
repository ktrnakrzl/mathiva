"""Quality-judge pass over the generated QA pairs.

The spot-check showed that regex validation (in generate_qa.py) removes the
obviously-junk pairs but cannot catch the two dominant failure modes:

  * underspecified questions -- "What is the value of x?" reads fine but is
    unanswerable on its own (and is a terrible retrieval query);
  * ungrounded answers -- the source PDF lost some equations to image
    extraction, so the model sometimes invents or half-answers.

Neither is catchable by rules, so we ask llama3 to judge each pair against the
chunk it was generated from. A pair is kept only if it is self-contained,
grounded in that chunk, and correct. This is the quality backstop before the
pairs become T5 training data.

Run:   python judge_qa.py             # resumes if interrupted
Outputs:
    genmath_qa_pairs.judged.json      # kept pairs (drop-in for prepare_dataset)
    genmath_qa_rejected.json          # dropped pairs + the judge's reason
"""

import json
import os
import re

import requests

from text_clean import clean_chunk_text

HERE = os.path.dirname(os.path.abspath(__file__))
PAIRS_PATH = os.path.join(HERE, "genmath_qa_pairs.json")
CHUNKS_PATH = os.path.join(HERE, "output_chunks.json")
KEPT_PATH = os.path.join(HERE, "genmath_qa_pairs.judged.json")
REJECTED_PATH = os.path.join(HERE, "genmath_qa_rejected.json")
VERDICTS_PATH = os.path.join(HERE, "_judge_verdicts.json")

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "llama3"
SAVE_EVERY = 25
REQUEST_TIMEOUT = 120

JUDGE_PROMPT = """You are checking the quality of ONE study question/answer pair \
for a Grade 11 General Mathematics dataset. Judge strictly.

Reference material the pair should be based on:
\"\"\"
{context}
\"\"\"

Question: {question}
Answer: {answer}

Decide three things:
1. self_contained -- can a student answer the question WITHOUT seeing the
   reference? The question must itself contain any equation or numbers needed.
   "What is the value of x?" with no equation shown is NOT self-contained.
2. grounded -- is the answer actually supported by the reference material above,
   rather than invented or guessed?
3. correct -- is the answer mathematically correct?

Return ONLY this JSON object:
{{"self_contained": true/false, "grounded": true/false, "correct": true/false, "reason": "a few words"}}"""


def _load_json(path, default):
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return default


def _extract_obj(raw):
    """Parse the judge's JSON object out of the model response."""
    if not raw:
        return None
    text = raw.strip()
    if text.startswith("```"):
        text = re.sub(r"^```[a-zA-Z]*\n?|\n?```$", "", text).strip()
    try:
        obj = json.loads(text)
    except json.JSONDecodeError:
        start, end = text.find("{"), text.rfind("}")
        if start == -1 or end <= start:
            return None
        try:
            obj = json.loads(text[start : end + 1])
        except json.JSONDecodeError:
            return None
    return obj if isinstance(obj, dict) else None


def _judge(context, question, answer):
    """Return (keep: bool|None, verdict_dict). keep=None means judge failed."""
    prompt = JUDGE_PROMPT.format(context=context, question=question, answer=answer)
    try:
        resp = requests.post(
            OLLAMA_URL,
            json={
                "model": MODEL,
                "prompt": prompt,
                "stream": False,
                "format": "json",
                "options": {"temperature": 0.0, "num_predict": 128},
            },
            timeout=REQUEST_TIMEOUT,
        )
        resp.raise_for_status()
    except requests.RequestException as exc:
        return None, {"error": str(exc)}

    obj = _extract_obj(resp.json().get("response", ""))
    if obj is None:
        return None, {"error": "unparseable judge output"}
    keep = bool(
        obj.get("self_contained") and obj.get("grounded") and obj.get("correct")
    )
    return keep, obj


def main():
    pairs = _load_json(PAIRS_PATH, [])
    if not pairs:
        raise SystemExit("no genmath_qa_pairs.json to judge")
    chunks = {c["chunk_index"]: c["content"] for c in _load_json(CHUNKS_PATH, [])}

    verdicts = _load_json(VERDICTS_PATH, [])
    if verdicts:
        print(f"resuming judge: {len(verdicts)}/{len(pairs)} already judged")

    for i in range(len(verdicts), len(pairs)):
        p = pairs[i]
        context = clean_chunk_text(chunks.get(p["chunk_id"], ""))
        keep, verdict = _judge(context, p["question"], p["answer"])
        verdict["keep"] = keep
        verdicts.append(verdict)

        if (i + 1) % SAVE_EVERY == 0:
            with open(VERDICTS_PATH, "w", encoding="utf-8") as f:
                json.dump(verdicts, f)
            kept = sum(1 for v in verdicts if v.get("keep"))
            print(f"[{i + 1}/{len(pairs)}] kept {kept} so far")

    with open(VERDICTS_PATH, "w", encoding="utf-8") as f:
        json.dump(verdicts, f)

    # keep=None (judge failed) is kept conservatively so transient errors don't
    # silently discard good pairs; count them separately.
    kept, rejected, unjudged = [], [], 0
    for p, v in zip(pairs, verdicts):
        if v.get("keep") is None:
            unjudged += 1
            kept.append(p)
        elif v["keep"]:
            kept.append(p)
        else:
            rejected.append({**p, "reason": v.get("reason", "")})

    with open(KEPT_PATH, "w", encoding="utf-8") as f:
        json.dump(kept, f, ensure_ascii=False, indent=2)
    with open(REJECTED_PATH, "w", encoding="utf-8") as f:
        json.dump(rejected, f, ensure_ascii=False, indent=2)

    total = len(pairs)
    print(
        f"\nJudged {total}. Kept {len(kept)} "
        f"({100 * len(kept) / total:.0f}%), rejected {len(rejected)} "
        f"({100 * len(rejected) / total:.0f}%), unjudged-kept {unjudged}."
    )
    print(f"  kept    -> {os.path.basename(KEPT_PATH)}")
    print(f"  rejected-> {os.path.basename(REJECTED_PATH)}")


if __name__ == "__main__":
    main()

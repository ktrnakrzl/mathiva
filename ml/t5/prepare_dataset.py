"""Phase 1 of the T5 fine-tune: build the train/val/test dataset.

Two modes (DATASET_MODE):

* "tutor" (default) -- a standalone Senior High School math tutor. Each example is

      input  = "<instruction>\nQuestion: <q>"
      target = "<answer>"

  built from topic-based question/answer pairs (no retrieved context, not tied to
  any single corpus). Sources: ml/retrieval/topic_qa_pairs.json (the pairs
  generated per topic across all four SHS subjects) plus the hand-authored
  ml/retrieval/authored_qa_pairs.json. RAG still serves the live /ask path as a
  separate retrieval layer; here T5 learns to answer curriculum questions
  directly. Split is stratified by topic, so every topic appears in each split.

* "rag" -- the original corpus-grounded design. Each example is
      input = "<instruction>\nContext: <top-k retrieved chunks>\nQuestion: <q>"
  built from the judged pairs in genmath_qa_pairs.judged.json, with the same
  SBERT->FAISS retrieval the /ask path uses, split grouped by source chunk.

Run:   python ml/t5/prepare_dataset.py                 # tutor mode (default)
       DATASET_MODE=rag python ml/t5/prepare_dataset.py # corpus-grounded mode
Outputs: ml/t5/data/{train,val,test}.jsonl  +  manifest.json
"""

import collections
import json
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))          # ml/t5
ML_DIR = os.path.dirname(HERE)                              # ml
sys.path.insert(0, ML_DIR)                                  # so `retrieval` imports

MODE = os.environ.get("DATASET_MODE", "tutor").strip().lower()

SEED = 42
VAL_FRAC = 0.10
TEST_FRAC = 0.10

# --- tutor mode -------------------------------------------------------------
TUTOR_INSTRUCTION = "Answer the Senior High School mathematics question."
TOPIC_QA_PATH = os.path.join(ML_DIR, "retrieval", "topic_qa_pairs.json")
AUTHORED_QA_PATH = os.path.join(ML_DIR, "retrieval", "authored_qa_pairs.json")

# --- rag mode ---------------------------------------------------------------
TOP_K = 3            # matches flan-t5-base's 512-token input budget (3*~500 chars)
RAG_INSTRUCTION = "Answer the Grade 11 General Mathematics question using the context."
QA_PATH = os.path.join(ML_DIR, "retrieval", "genmath_qa_pairs.judged.json")
CHUNKS_PATH = os.path.join(ML_DIR, "retrieval", "output_chunks.json")

OUT_DIR = os.path.join(HERE, "data")


def _load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _load_json_lenient(path):
    """Load a JSON list, or return [] if the file is absent -- so topic_qa_pairs
    (which you build up incrementally) doesn't have to exist yet."""
    if not os.path.exists(path):
        return []
    try:
        data = _load_json(path)
        return data if isinstance(data, list) else []
    except (json.JSONDecodeError, OSError):
        return []


def _norm_q(q):
    return " ".join(q.lower().split()).strip(" ?.!")


# --- tutor mode -------------------------------------------------------------

def build_tutor_examples():
    """Topic-based question -> answer examples from the generated topic pairs and
    the hand-authored pairs, de-duplicated by question."""
    raw = _load_json_lenient(TOPIC_QA_PATH) + _load_json_lenient(AUTHORED_QA_PATH)
    if not raw:
        raise SystemExit(
            "No tutor pairs found. Generate topic pairs into\n  "
            f"{TOPIC_QA_PATH}\n(a JSON list of {{topic, question, answer}}), "
            "or run with DATASET_MODE=rag."
        )

    seen, examples = set(), []
    for p in raw:
        question = (p.get("question") or "").strip()
        answer = (p.get("answer") or "").strip()
        if not question or not answer:
            continue
        key = _norm_q(question)
        if key in seen:
            continue
        seen.add(key)
        topic = (p.get("topic") or "general").strip().lower() or "general"
        examples.append(
            {
                "input": f"{TUTOR_INSTRUCTION}\nQuestion: {question}",
                "target": answer,
                "question": question,
                "topic": topic,
            }
        )
    return examples


def stratified_split(examples):
    """Split each topic's pairs proportionally, so every topic appears in
    train/val/test (the right split for a tutor: new questions on known topics)."""
    by_topic = collections.defaultdict(list)
    for ex in examples:
        by_topic[ex["topic"]].append(ex)

    rng = random.Random(SEED)
    splits = {"train": [], "val": [], "test": []}
    for rows in by_topic.values():
        rows = rows[:]
        rng.shuffle(rows)
        n = len(rows)
        # Only carve val/test out of topics with enough pairs to spare; tiny
        # topics go entirely to train rather than starving it.
        n_test = max(1, round(TEST_FRAC * n)) if n >= 5 else 0
        n_val = max(1, round(VAL_FRAC * n)) if n >= 5 else 0
        splits["test"].extend(rows[:n_test])
        splits["val"].extend(rows[n_test : n_test + n_val])
        splits["train"].extend(rows[n_test + n_val :])

    for rows in splits.values():
        rng.shuffle(rows)
    return splits


# --- rag mode ---------------------------------------------------------------

def _build_retriever():
    """Reuse the exact retrieval mechanics of app/services/rag_service.py."""
    from sentence_transformers import SentenceTransformer
    from retrieval.test_retrieval import load_index_and_chunks

    model = SentenceTransformer("all-MiniLM-L6-v2")
    index, chunks = load_index_and_chunks()

    def retrieve(question, k):
        emb = (
            model.encode(question, normalize_embeddings=True)
            .astype("float32")
            .reshape(1, -1)
        )
        _, idxs = index.search(emb, k)
        return [chunks[i] for i in idxs[0]]

    return retrieve


def build_rag_examples():
    qa_pairs = _load_json(QA_PATH)
    chunks = _load_json(CHUNKS_PATH)
    by_index = {c["chunk_index"]: c for c in chunks}
    retrieve = _build_retriever()

    examples = []
    gold_hits = 0
    for pair in qa_pairs:
        gold_idx = pair["chunk_id"]
        gold_chunk = by_index[gold_idx]

        retrieved = retrieve(pair["question"], TOP_K)
        retrieved_idxs = [c["chunk_index"] for c in retrieved]
        gold_retrieved = gold_idx in retrieved_idxs
        gold_hits += gold_retrieved

        if gold_retrieved:
            context_chunks = retrieved
        else:
            context_chunks = [gold_chunk] + retrieved[: TOP_K - 1]

        context = "\n\n".join(c["content"].strip() for c in context_chunks)
        examples.append(
            {
                "input": f"{RAG_INSTRUCTION}\nContext: {context}\nQuestion: {pair['question']}",
                "target": pair["answer"].strip(),
                "question": pair["question"],
                "topic": gold_idx,                 # group key for the split
                "gold_retrieved": gold_retrieved,
            }
        )
    return examples, gold_hits


def grouped_split(examples):
    """Split by source chunk so no chunk's context leaks across splits."""
    groups = collections.defaultdict(list)
    for ex in examples:
        groups[ex["topic"]].append(ex)

    group_ids = list(groups)
    random.Random(SEED).shuffle(group_ids)

    n = len(group_ids)
    n_test = max(1, round(TEST_FRAC * n))
    n_val = max(1, round(VAL_FRAC * n))
    test_ids = set(group_ids[:n_test])
    val_ids = set(group_ids[n_test : n_test + n_val])

    splits = {"train": [], "val": [], "test": []}
    for gid in group_ids:
        name = "test" if gid in test_ids else "val" if gid in val_ids else "train"
        splits[name].extend(groups[gid])

    for rows in splits.values():
        random.Random(SEED).shuffle(rows)
    return splits


# --- shared output ----------------------------------------------------------

def _words(text):
    return len(text.split())


def write_splits(splits, manifest_extra):
    os.makedirs(OUT_DIR, exist_ok=True)
    total = sum(len(rows) for rows in splits.values())
    manifest = {
        "mode": MODE,
        "seed": SEED,
        "total_examples": total,
        **manifest_extra,
        "splits": {},
    }
    for name, rows in splits.items():
        path = os.path.join(OUT_DIR, f"{name}.jsonl")
        with open(path, "w", encoding="utf-8") as f:
            for row in rows:
                f.write(json.dumps(row, ensure_ascii=False) + "\n")
        manifest["splits"][name] = {
            "examples": len(rows),
            "topics": len({r["topic"] for r in rows}),
            "avg_input_words": round(sum(_words(r["input"]) for r in rows) / max(len(rows), 1), 1),
            "avg_target_words": round(sum(_words(r["target"]) for r in rows) / max(len(rows), 1), 1),
        }

    with open(os.path.join(OUT_DIR, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    return manifest


def main():
    if MODE == "rag":
        examples, gold_hits = build_rag_examples()
        splits = grouped_split(examples)
        extra = {
            "instruction": RAG_INSTRUCTION,
            "top_k": TOP_K,
            "gold_retrieved_rate": round(gold_hits / max(len(examples), 1), 3),
            "split_strategy": "grouped by source chunk (no context leakage)",
        }
    else:
        examples = build_tutor_examples()
        splits = stratified_split(examples)
        extra = {
            "instruction": TUTOR_INSTRUCTION,
            "split_strategy": "stratified by topic (every topic in each split)",
        }

    manifest = write_splits(splits, extra)

    print(f"[{MODE}] built {manifest['total_examples']} examples -> {OUT_DIR}")
    if "gold_retrieved_rate" in manifest:
        print(f"  gold chunk retrieved for {manifest['gold_retrieved_rate']:.0%}")
    for name, info in manifest["splits"].items():
        print(f"  {name:5}: {info['examples']:4} ex  "
              f"from {info['topics']:3} topics  "
              f"| in ~{info['avg_input_words']}w  out ~{info['avg_target_words']}w")


if __name__ == "__main__":
    main()

"""Phase 1 of the T5 fine-tune: build the RAG-augmented train/val/test dataset.

The confidence-routing design (RAG + T5 + Phi-3) means T5 is trained to do
exactly what it does at inference: read the *retrieved* context for a question
and generate the answer. So each training example is

    input  = "<instruction>\nContext: <top-k retrieved chunks>\nQuestion: <q>"
    target = "<reference answer>"

built from the 373 pairs in ml/retrieval/genmath_qa_pairs.json.

Two deliberate choices worth defending at review:

1. Retrieved (not gold-only) context, gold guaranteed. We run the *same* SBERT
   -> FAISS retrieval the live /ask path uses, so the training distribution
   matches inference. When retrieval misses the pair's own source chunk, we
   prepend it so the target answer is always supported. `gold_retrieved` is
   recorded per example so retrieval quality is measurable.

2. Grouped split by source chunk. The 373 pairs come from only ~157 chunks
   (~2.4 questions each). A naive per-question split would put a chunk's context
   in train and another of its questions in test -- context leakage that
   inflates scores. We split by source chunk instead, so no chunk is seen in
   training and evaluated on.

Run from anywhere:  python ml/t5/prepare_dataset.py
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

SEED = 42
TOP_K = 3            # matches flan-t5-base's 512-token input budget (3*~500 chars)
VAL_FRAC = 0.10
TEST_FRAC = 0.10
INSTRUCTION = "Answer the Grade 11 General Mathematics question using the context."

QA_PATH = os.path.join(ML_DIR, "retrieval", "genmath_qa_pairs.json")
CHUNKS_PATH = os.path.join(ML_DIR, "retrieval", "output_chunks.json")
OUT_DIR = os.path.join(HERE, "data")


def _load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


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


def build_examples():
    qa_pairs = _load_json(QA_PATH)
    chunks = _load_json(CHUNKS_PATH)
    by_index = {c["chunk_index"]: c for c in chunks}
    retrieve = _build_retriever()

    examples = []
    gold_hits = 0
    for pair in qa_pairs:
        gold_idx = pair["chunk_id"]                 # maps to chunk_index
        gold_chunk = by_index[gold_idx]

        retrieved = retrieve(pair["question"], TOP_K)
        retrieved_idxs = [c["chunk_index"] for c in retrieved]
        gold_retrieved = gold_idx in retrieved_idxs
        gold_hits += gold_retrieved

        if gold_retrieved:
            context_chunks = retrieved
        else:
            # Guarantee the answer is supported: prepend gold, keep TOP_K chunks.
            context_chunks = [gold_chunk] + retrieved[: TOP_K - 1]

        context = "\n\n".join(c["content"].strip() for c in context_chunks)
        examples.append(
            {
                "input": f"{INSTRUCTION}\nContext: {context}\nQuestion: {pair['question']}",
                "target": pair["answer"].strip(),
                "question": pair["question"],
                "source_chunk_index": gold_idx,
                "gold_retrieved": gold_retrieved,
            }
        )

    return examples, gold_hits


def grouped_split(examples):
    """Split by source chunk so no chunk's context leaks across splits."""
    groups = collections.defaultdict(list)
    for ex in examples:
        groups[ex["source_chunk_index"]].append(ex)

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


def _words(text):
    return len(text.split())


def write_splits(splits, gold_hits, total):
    os.makedirs(OUT_DIR, exist_ok=True)
    manifest = {
        "seed": SEED,
        "top_k": TOP_K,
        "instruction": INSTRUCTION,
        "total_examples": total,
        "gold_retrieved_rate": round(gold_hits / total, 3),
        "split_strategy": "grouped by source_chunk_index (no context leakage)",
        "splits": {},
    }
    for name, rows in splits.items():
        path = os.path.join(OUT_DIR, f"{name}.jsonl")
        with open(path, "w", encoding="utf-8") as f:
            for row in rows:
                f.write(json.dumps(row, ensure_ascii=False) + "\n")
        manifest["splits"][name] = {
            "examples": len(rows),
            "source_chunks": len({r["source_chunk_index"] for r in rows}),
            "avg_input_words": round(sum(_words(r["input"]) for r in rows) / len(rows), 1),
            "avg_target_words": round(sum(_words(r["target"]) for r in rows) / len(rows), 1),
        }

    with open(os.path.join(OUT_DIR, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    return manifest


def main():
    examples, gold_hits = build_examples()
    splits = grouped_split(examples)
    manifest = write_splits(splits, gold_hits, len(examples))

    print(f"Built {manifest['total_examples']} examples "
          f"(gold chunk retrieved for {manifest['gold_retrieved_rate']:.0%})")
    print(f"Split by source chunk -> {OUT_DIR}")
    for name, info in manifest["splits"].items():
        print(f"  {name:5}: {info['examples']:3} ex  "
              f"from {info['source_chunks']:3} chunks  "
              f"| in ~{info['avg_input_words']}w  out ~{info['avg_target_words']}w")


if __name__ == "__main__":
    main()

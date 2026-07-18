# T5 fine-tune for MATHIVA `/ask`

MATHIVA's abstract promises *"RAG with fine-tuned transformer models."* This
directory is that fine-tuned model: a `flan-t5` trained to answer Grade-11
General-Mathematics questions from RAG-retrieved context, plus the evaluation
that compares it against the general-purpose Phi-3 the app ships today.

> **New to this? Read [`HOW_TRAINING_WORKS.md`](./HOW_TRAINING_WORKS.md) first** —
> a plain-language walkthrough of what fine-tuning is, where the data comes from,
> and how the training runs. This README is the command reference.

## Why a fine-tuned model at all

The live `/ask` path retrieves course context and hands it to Phi-3 (via Ollama).
Phi-3 is a capable generalist but was never specialized to this corpus. The thesis
claim is that a small model *fine-tuned on in-domain (context → answer) pairs* can
match or beat it on this narrow task. Phase 3 measures whether that holds; the
result — either way — is the contribution. The intended end state (Phase 4, later)
is a simple cascade: **RAG → try T5 → fall back to Phi-3** if T5's output is empty
or degenerate.

## The four phases

| Phase | What | Where | Status |
|-------|------|-------|--------|
| 1 | Build RAG-augmented dataset | local | ✅ `prepare_dataset.py` → `data/` |
| 2 | Fine-tune flan-t5-base | **Colab (T4)** | `train.py` / `train_flan_t5.ipynb` |
| 3 | Evaluate T5 vs Phi-3 | **local** | `eval.py` |
| 4 | Wire cascade into `/ask` | local backend | deferred |

## Run order

### Phase 1 — data (already done)

```
python prepare_dataset.py        # -> data/{train,val,test}.jsonl + manifest.json
```

`prepare_dataset.py` reads the **quality-judged** pairs
(`../retrieval/genmath_qa_pairs.judged.json` — the survivors of the
`generate_qa.py` → `judge_qa.py` pipeline). Each row:
`input = instruction + top-3 retrieved chunks + question`,
`target = reference answer`. Split is grouped by source chunk so no chunk's
context appears in both train and test. **50 / 7 / 5 examples** (from 62 judged
pairs; gold source chunk retrieved in top-3 only 48% of the time).

There is also a large generic **warm-up** dataset in `deepmind/` (100k symbolic-
math Q&A) for optional Stage-A pre-training before the curriculum set — see
`train_flan_t5_deepmind.ipynb` and [`HOW_TRAINING_WORKS.md`](./HOW_TRAINING_WORKS.md) §5.

### Phase 2 — fine-tune (Colab)

The real `flan-t5-base` run uses Colab's free T4 (a 4 GB laptop GPU is too small
for base in fp32).

1. Open `train_flan_t5.ipynb` in Colab, set the runtime to **T4 GPU**.
2. Upload `data/train.jsonl`, `data/val.jsonl`, and `train.py` when prompted.
3. Run all cells. It trains up to 20 epochs with **early stopping on validation
   loss** (overfitting is the real risk with only ~50 examples) and downloads
   `mathiva_t5_model.zip`.
4. Unzip it into `ml/t5/model/` locally.

`train.py` is parameterized, so the same script trains the CPU-friendly fallback
locally — and this now works in the repo venv (Python 3.14) after installing the
deps (`datasets>=4`, `accelerate`); a 1-epoch smoke test runs end-to-end:

```
python train.py --model_name google/flan-t5-small --batch_size 8
```

Note on `datasets`: training needs `datasets>=4` (v3 crashes on Python 3.14), but
`deepmind/load_data.py`'s *download* needs `datasets<4`. See
`requirements-train.txt` — the download is a one-time step whose output is
committed, so keep `datasets>=4` for training.

Notes: trained in **fp32** (flan-t5 produces NaN logits in fp16); flan-t5's fast
tokenizer means `sentencepiece` isn't actually required.

### Phase 3 — evaluate (local)

```
pip install -r requirements-eval.txt        # rouge_score, sacrebleu, bert_score
# make sure Ollama is running the `phi` model (same as the live app)
python eval.py
```

`eval.py` runs the fine-tuned T5 (CPU, only 5 test examples) and Phi-3 on the
**same context+question** from `test.jsonl`, scores both against the gold answer
with ROUGE-L / BLEU / BERTScore, prints a comparison table, and writes
`eval_report.json`. Use `--skip_phi` to score only T5 if Ollama isn't up, and
`--bertscore_model distilbert-base-uncased` if `roberta-large` is too heavy to
download.

**Reading the numbers:** on short, free-form math answers BLEU/ROUGE are noisy
(two correct answers can be worded very differently), so **BERTScore is the more
meaningful signal**. The T5-vs-Phi-3 gap is also what tells us whether Phase 4's
cheap output guards are sufficient.

## Phase 4 hand-off notes (not built yet)

- Insert the cascade in `backend/app/api/ask.py`, between `retrieve_context()` and
  `generate_answer()`; add a `"model_used"` field to the response.
- The backend already has torch + transformers (via `sentence-transformers`), so
  it can load `ml/t5/model/` directly. Import it the same way `rag_service` imports
  `retrieval` (the `sys.path.insert(.../ml)` in `backend/app/main.py`).
- **Retrieval-`k` mismatch to reconcile:** live `/ask` retrieves `k=5`, but T5 was
  trained on **top-3** context (its 512-token budget). Feed the T5 path top-3 so
  inference matches its training distribution.

## Files

```
prepare_dataset.py       Phase 1 — build the dataset (done)
data/                    train/val/test.jsonl + manifest.json (committed)
train.py                 Phase 2 — fine-tune script (Colab or local)
train_flan_t5.ipynb      Phase 2 — Colab notebook wrapper
eval.py                  Phase 3 — T5-vs-Phi-3 evaluation
requirements-train.txt   Colab training deps
requirements-eval.txt    local evaluation deps
model/                   fine-tuned model (git-ignored; from Colab)
eval_report.json         Phase 3 output (generated)
```

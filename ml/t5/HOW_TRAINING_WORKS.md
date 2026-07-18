# How the T5 Model Is Trained — a plain-language walkthrough

This explains, step by step and in plain terms, how MATHIVA's fine-tuned model
is built — what each piece does and *why*. It's written to be understood, and it
doubles as a draft for your methodology chapter. For the exact commands, see
[`README.md`](./README.md).

---

## 1. What "fine-tuning" even means

A language model like **T5** already knows English and a lot of general math —
it was pre-trained by Google on huge amounts of text. **Fine-tuning** means we
take that already-smart model and give it extra, focused practice on *our*
specific task, so it stops being a generalist and becomes good at the one thing
we need: **answering Grade-11 General Mathematics questions using retrieved
course material.**

Think of it like hiring a smart college graduate (the pre-trained model) and
then training them for two weeks on your exact job (fine-tuning). They don't
learn to read during those two weeks — they learn *your* way of doing things.

**Why this model specifically:** we use `flan-t5` (an instruction-following
version of T5). Two sizes:
- **`flan-t5-base`** (~250M parameters) — the real model, trained on a free
  Google Colab T4 GPU.
- **`flan-t5-small`** (~80M) — a lighter version that can train on a normal
  laptop CPU, kept as an offline backup.

---

## 2. The task we train it to do

This is the most important idea. The app already works like this when a student
asks a question:

1. The question is used to **search** the course material (RAG retrieval) and
   pull the 3 most relevant textbook chunks.
2. Those chunks + the question are handed to a model, which **writes the answer**.

So we train T5 to do *exactly that second step*. Every training example looks
like:

```
INPUT:   Answer the Grade 11 General Mathematics question using the context.
         Context: <the 3 retrieved textbook chunks>
         Question: <the student's question>

TARGET:  <the correct answer>
```

The model reads the input and learns to produce the target. Because we train it
on the **same shape** of data it will see in the real app (context + question →
answer), it doesn't get surprised at inference time. This is a deliberate design
choice, not an accident.

---

## 3. Where the training data comes from (the hard part)

A model is only as good as its examples. We built the curriculum training data
in a small assembly line, each stage cleaning up after the last:

**Step A — Turn the textbook into searchable pieces.**
The DepEd *General Mathematics* PDF is split into **1,108 chunks** of text
(`chunk_pdf.py`), each turned into a numeric "fingerprint" (an embedding) and
stored in a FAISS index so we can search it. (This is the same index the live
app uses.)

**Step B — Write question–answer pairs from those chunks.**
`generate_qa.py` feeds each chunk to a **local AI model (llama3, running free and
offline via Ollama)** and asks it to write 2–3 question–answer pairs about that
chunk. Rules are enforced so the questions are **self-contained** — the equation
or numbers must be *inside* the question. ("Solve 3x = 12" is good; "What is the
value of x?" is useless because the model can't see which x.)

**Step C — Judge the quality (this is a key contribution).**
The AI in Step B still makes mistakes — vague questions, or answers it invented
because the PDF text was garbled. So `judge_qa.py` runs a **second AI pass**: for
every pair, it shows llama3 the pair *and* the source chunk and asks three yes/no
questions — is it self-contained? is the answer actually supported by the source?
is it mathematically correct? **Only pairs that pass all three are kept.** This
is called "LLM-as-judge." Result so far: **74 pairs in → 62 kept (84%), 12
thrown out.**

**Step D — Hand-written top-ups.**
The textbook extraction under-covers some topics (logic, stocks & bonds,
exponential/logarithmic), so **51 pairs were written by hand** to fill those gaps
(`authored_qa_pairs.json`). These are kept separate for now.

**Step E — Assemble into the training format.**
`prepare_dataset.py` takes the kept pairs and, for each one, runs the real search
to grab the top-3 context, then builds the `input`/`target` rows from Section 2.
The final curriculum set is currently **62 examples**.

---

## 4. Two things we do so the model can't "cheat"

**Grouped split (no leakage).** We divide the data into *train* (practice),
*validation* (a progress check during training), and *test* (the final exam the
model never sees while learning). Normally you'd split randomly — but several
questions can come from the *same* textbook chunk. If one question from a chunk
is in "train" and another from the same chunk is in "test," the model has already
seen that context and the test score is fake. So we split **by chunk**: all
questions from a chunk go to the same side. Current split: **50 train / 7 val /
5 test.**

**Honesty about retrieval.** We measured how often the search actually finds the
"correct" source chunk in its top 3: only **48%** of the time. That's a real,
reportable weakness of the retrieval step (the corpus has some PDF-extraction
junk). When the search misses, we prepend the correct chunk so the answer is
always supported — but we *record* the miss instead of hiding it.

---

## 5. The generic "warm-up" dataset

62 curriculum examples is **very few** to fine-tune on. So we add a first stage:
a big, generic math dataset — the **DeepMind Mathematics** set, **100,000**
question–answer pairs (solve equations, arithmetic, GCD) downloaded from Hugging
Face and stored in `ml/t5/deepmind/`.

This gives a **two-stage training plan**:
- **Stage A — warm-up:** train on the 100,000 generic problems so the model gets
  generally good at *doing math*.
- **Stage B — specialize:** continue training that same model on our 62
  curriculum examples, so it learns *our* task (read course context, answer in
  our style).

Important honesty: the generic set is pure symbolic math — it has **no** jeepney
fares, annuities, or logic, and no retrieved context. It builds general ability;
it does **not** teach the DepEd curriculum. Stage B is what does that.

---

## 6. How the training actually runs

The script is `train.py`, and it uses Hugging Face's `Seq2SeqTrainer` (a
ready-made training loop). Plain-language version of the settings:

- **fp32 (full precision).** There's a faster "half precision" (fp16) mode, but
  flan-t5 breaks in it (produces `NaN` — "not a number" — garbage). So we use the
  slower-but-safe full precision.
- **Input up to 512 words, output up to 256.** Enough for the instruction + 3
  chunks + question in, and a worked answer out.
- **Early stopping.** With so few examples the danger is **overfitting** —
  memorizing the training answers instead of learning to generalize. So after
  each pass ("epoch") we check the validation score, keep the best version, and
  **stop automatically** once it stops improving, instead of over-training.
- **Where it runs.** The real `flan-t5-base` run happens on a **free Colab T4
  GPU** (your laptop's 4 GB GPU is too small for it). The notebooks
  `train_flan_t5.ipynb` (curriculum) and `train_flan_t5_deepmind.ipynb` (warm-up)
  wrap this. `flan-t5-small` can run locally on CPU — a 1-epoch test of the whole
  pipeline (load data → train → save) has been confirmed working end-to-end.

The output is a saved `model/` folder that can be loaded to answer questions.

---

## 7. How we check whether it worked

Training produces a model; **evaluation** tells us if it's any good. `eval.py`
takes the 5 held-out test questions and runs **two** models on the exact same
context+question:
1. our fine-tuned **T5**, and
2. **Phi-3** (the general model the app ships today).

Both answers are scored against the correct answer using standard metrics
(**ROUGE-L**, **BLEU** — word-overlap scores; and **BERTScore** — a
meaning-similarity score). Then it prints a side-by-side comparison.

**This comparison is the whole point of the thesis contribution:** it's the
evidence for whether a small *fine-tuned* model can match or beat a general one
on this narrow task. (Note: with only 5 test examples and short math answers,
these numbers are rough — a bigger curriculum set would make them more
trustworthy.)

---

## 8. Where it stands right now (2026-07-18)

| Stage | Status |
|---|---|
| Dataset pipeline (generate → judge → assemble) | ✅ Built; 62 curriculum examples |
| DeepMind 100k warm-up set | ✅ Downloaded & split |
| `train.py` pipeline | ✅ Verified end-to-end (small model, 1 epoch) |
| Real `flan-t5-base` training on Colab | ⏳ In progress |
| Evaluation (T5 vs Phi-3) | ⏳ After training finishes |
| Wiring T5 into the live `/ask` | 📋 Later |

**The honest limitation to keep repeating:** the curriculum set is small (62).
The way to grow it is to finish the textbook question-generation pass — only
**40 of 1,108 chunks** have been processed so far. Everything else is ready to
scale the moment there's more data.

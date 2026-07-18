"""Download the DeepMind Mathematics dataset and export it for T5 training.

The dataset (deepmind/math_dataset on Hugging Face) is a *script-based* dataset:
it needs `trust_remote_code=True`, and the `datasets` library must be < 4.0
because v4 removed script-dataset loading entirely. This script pins that for
you. It also has no "all topics" config -- each config is a single problem type
-- so to get varied T5 training data we round-robin across several modules
instead of pulling 100k of the same kind of problem.

We STREAM the data (streaming=True) so we never download the full ~2 GB archive:
we stop as soon as we have collected enough examples.

Outputs (written next to this script):
    math_qa_pairs.csv   columns: question, answer
    math_qa.jsonl       one JSON object per line: {"input", "target"}  (T5 format)

Run:  python load_data.py      # self-installs missing packages, then runs
"""

import importlib
import json
import os
import subprocess
import sys

# --- config -----------------------------------------------------------------
# Diverse modules so the 100k examples cover several problem types rather than
# one. Total collected = len(MODULES) * PER_MODULE (capped at TARGET_TOTAL).
MODULES = [
    "algebra__linear_1d",
    "algebra__linear_2d",
    "arithmetic__add_or_sub",
    "arithmetic__mul",
    "numbers__gcd",
]
TARGET_TOTAL = 100_000
PER_MODULE = TARGET_TOTAL // len(MODULES)

HERE = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(HERE, "math_qa_pairs.csv")
JSONL_PATH = os.path.join(HERE, "math_qa.jsonl")

# Quieter logs on Windows (no symlink support in the HF cache).
os.environ.setdefault("HF_HUB_DISABLE_SYMLINKS_WARNING", "1")


# --- step 1: ensure required packages --------------------------------------
def _pip_install(spec):
    print(f"  installing {spec} ...")
    subprocess.check_call(
        [sys.executable, "-m", "pip", "install", "-q", spec]
    )


def ensure_packages():
    """Install datasets (<4, for script-dataset support), transformers, pandas."""
    print("Checking required packages...")

    # datasets must be present AND < 4.0 (v4 dropped script-based datasets).
    need_datasets = True
    try:
        import datasets  # noqa: F401

        major = int(datasets.__version__.split(".")[0])
        if major < 4:
            need_datasets = False
            print(f"  datasets {datasets.__version__} OK")
        else:
            print(f"  datasets {datasets.__version__} is too new (need < 4.0)")
    except ImportError:
        print("  datasets missing")
    if need_datasets:
        print(
            "  WARNING: downgrading datasets to <4 for the script-based download. "
            "The ml/t5 training env needs datasets>=4 on Python 3.14 -- reinstall "
            "it (pip install -U datasets) after this download if you train here."
        )
        _pip_install("datasets>=2.16,<4")

    for pkg in ("transformers", "pandas"):
        try:
            importlib.import_module(pkg)
            print(f"  {pkg} OK")
        except ImportError:
            _pip_install(pkg)

    # Invalidate caches so freshly installed packages import in this process.
    importlib.invalidate_caches()


# --- step 2: download + collect --------------------------------------------
def _decode(value):
    """DeepMind's dataset can yield bytes; normalise to a clean string."""
    if isinstance(value, bytes):
        value = value.decode("utf-8")
    return value.strip()


def collect_examples():
    """Stream PER_MODULE examples from each module; return list of (q, a)."""
    from datasets import load_dataset

    pairs = []
    for module in MODULES:
        print(f"\nStreaming '{module}' (up to {PER_MODULE:,})...")
        stream = load_dataset(
            "deepmind/math_dataset",
            module,
            split="train",
            streaming=True,
            trust_remote_code=True,
        )
        taken = 0
        for ex in stream:
            q = _decode(ex["question"])
            a = _decode(ex["answer"])
            if not q or not a:
                continue
            pairs.append((q, a))
            taken += 1
            if taken >= PER_MODULE:
                break
            if len(pairs) >= TARGET_TOTAL:
                break
        print(f"  collected {taken:,} from '{module}' (running total {len(pairs):,})")
        if len(pairs) >= TARGET_TOTAL:
            break

    return pairs[:TARGET_TOTAL]


# --- step 3: write outputs --------------------------------------------------
def write_outputs(pairs):
    import pandas as pd

    df = pd.DataFrame(pairs, columns=["question", "answer"])
    df.to_csv(CSV_PATH, index=False, encoding="utf-8")
    print(f"\nWrote {CSV_PATH}  ({len(df):,} rows)")

    with open(JSONL_PATH, "w", encoding="utf-8") as f:
        for q, a in pairs:
            f.write(json.dumps({"input": q, "target": a}, ensure_ascii=False) + "\n")
    print(f"Wrote {JSONL_PATH}  ({len(pairs):,} lines)")


def main():
    # The download is a one-time step and its output is committed as files. Skip
    # by default so a rerun doesn't re-download AND doesn't downgrade `datasets`
    # to <4 (which would break the ml/t5 training env on Python 3.14). Force with
    # FORCE=1 in a throwaway env if you really need to regenerate.
    if os.path.exists(CSV_PATH) and os.path.exists(JSONL_PATH) and not os.environ.get("FORCE"):
        print(f"Data already present ({CSV_PATH}, {JSONL_PATH}); nothing to do.")
        print("Set FORCE=1 to re-download (needs datasets<4 -- see file header).")
        return

    ensure_packages()
    pairs = collect_examples()
    if not pairs:
        raise SystemExit("No examples collected -- check network / dataset access.")
    write_outputs(pairs)

    print("\nSample Q&A pairs:")
    for q, a in pairs[:5]:
        print(f"  Q: {q}")
        print(f"  A: {a}\n")

    print(f"Total examples saved: {len(pairs):,}")


if __name__ == "__main__":
    main()

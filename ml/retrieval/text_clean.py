"""Shared text cleaning for the General Mathematics corpus.

Two kinds of noise came out of the PDF extraction and hurt both retrieval and
T5 training:

1. Adobe *Symbol*-font glyphs that were extracted into the Unicode Private Use
   Area (U+F0xx) instead of real characters. The low byte is the Symbol-font
   code point, so e.g. U+F03D is Symbol 0x3D = "=", U+F02D is "minus", U+F070
   is the Greek letter pi, U+F0A3 is "<=". These land *inside equations* -- the
   corpus has 294 broken "=" signs alone -- so recovering them is the single
   biggest quality win. `SYMBOL_MAP` covers every PUA code point that actually
   occurs in output_chunks.json (see the audit in the module test); anything
   else in the PUA range is a big-delimiter drawing artifact and is dropped.

2. Running page furniture repeated mid-chunk: the DepEd copyright / "DEPED COPY"
   / reproduction notice / page numbers. 470 of 1108 chunks carry it. It is not
   math, it pollutes retrieval, and it teaches T5 nothing.

Both `clean_chunk_text` (used to scrub output_chunks.json in place and to feed
the QA generator) and `is_low_content` (used to skip pure front-matter chunks)
live here so the generator and the corpus-cleaning step can't drift apart.
"""

import re

# --- Symbol-font PUA recovery -------------------------------------------------
# Keyed by PUA code point (0xF000 + Symbol-font byte). Values are the real
# Unicode characters, per the standard Adobe Symbol encoding. Only the code
# points that appear in the corpus are listed; unmapped PUA chars are dropped.
_SYMBOL_LOW = {
    # ASCII-range operators that got symbol-encoded
    0x28: "(", 0x29: ")", 0x2B: "+", 0x2D: "-", 0x3D: "=", 0x3E: ">",
    0x70: "π",   # pi
    # math relations / operators
    0xA3: "≤",   # <=
    0xA5: "∞",   # infinity
    0xAE: "→",   # right arrow
    0xB0: "°",   # degree
    0xB3: "≥",   # >=
    0xB4: "×",   # multiply
    0xB7: "·",   # middle dot (multiplication)
    0xB9: "≠",   # not equal
    0xBB: "≈",   # approx equal
    0xBC: "…",   # ellipsis
    0xD7: "·",   # dot operator
    0xDE: "⇒",   # double right arrow (implies)
    # big-delimiter pieces: keep one bracket for the "top" piece, drop the
    # "extension"/"bottom" strokes so a multi-row "(" collapses to a single "(".
    0xE6: "(", 0xE7: "", 0xE8: "",
    0xE9: "[", 0xEA: "", 0xEB: "",
    0xF6: ")", 0xF7: "", 0xF8: "",
    0xF9: "]", 0xFA: "", 0xFB: "",
}
SYMBOL_MAP = {chr(0xF000 + low): repl for low, repl in _SYMBOL_LOW.items()}


def fix_symbol_pua(text):
    """Recover Symbol-font glyphs; drop any other Private Use Area character."""
    out = []
    for ch in text:
        o = ord(ch)
        if 0xE000 <= o <= 0xF8FF:          # Private Use Area
            out.append(SYMBOL_MAP.get(ch, ""))
        else:
            out.append(ch)
    return "".join(out)


# --- Typography normalization (legit chars -> plain ASCII where harmless) -----
_TYPO = {
    "–": "-", "—": "-", "−": "-",   # en/em dash, minus
    "‘": "'", "’": "'",                    # single quotes
    "“": '"', "”": '"',                    # double quotes
    "…": "...",                                  # ellipsis
}


def normalize_typography(text):
    for bad, good in _TYPO.items():
        text = text.replace(bad, good)
    return text


# --- Boilerplate / page-furniture removal -------------------------------------
# The reproduction notice is one fixed template, but the 500-char chunking
# splits it at arbitrary points, so a chunk may hold only a tail fragment
# ("electronic or mechanical ..."). We strip each fragment independently so
# partial notices are caught regardless of where the boundary fell.
_BOILERPLATE = [
    re.compile(r"All rights reserved\.?", re.IGNORECASE),
    re.compile(
        r"No part of this material may be reproduced or transmitted"
        r"\s+in any form or by any means\s*-?",
        re.IGNORECASE,
    ),
    re.compile(
        r"electronic or mechanical including photocopying\s*-?\s*", re.IGNORECASE
    ),
    re.compile(
        r"without written permission from the DepEd Central Office\.?",
        re.IGNORECASE,
    ),
    re.compile(r"First Edition,?\s*2016\.?", re.IGNORECASE),
    re.compile(r"DEPED COPY", re.IGNORECASE),
    re.compile(r"Department of Education", re.IGNORECASE),
    re.compile(r"Republic of the Philippines", re.IGNORECASE),
    re.compile(r"We value your feedback and recommendations\.?", re.IGNORECASE),
    # Standalone page-number lines.
    re.compile(r"^\s*\d{1,3}\s*$", re.MULTILINE),
]


def strip_boilerplate(text):
    for pat in _BOILERPLATE:
        text = pat.sub(" ", text)
    return text


def _collapse_ws(text):
    text = re.sub(r"[ \t]+", " ", text)
    # Drop lines left holding only stray punctuation after boilerplate removal.
    text = re.sub(r"\n[ \t]*[.\-]+[ \t]*(?=\n)", "\n", text)
    text = re.sub(r"\n[ \t]*\n[ \t\n]*", "\n\n", text)
    return text.strip()


def clean_chunk_text(text):
    """Full pipeline: recover symbols, normalize punctuation, strip furniture."""
    text = fix_symbol_pua(text)
    text = normalize_typography(text)
    text = strip_boilerplate(text)
    return _collapse_ws(text)


# --- Low-content / front-matter detection -------------------------------------
_FRONT_MATTER_MARKERS = (
    "learner's material",
    "table of contents",
    "this learning resource",
    "development team of",
    "management team of",
    "writers:",
    "reviewers:",
    "illustrator",
    "layout artist",
)
_MIN_WORDS = 12


def is_low_content(text):
    """True if `text` (already cleaned) is too thin or is front matter to skip.

    We generate QA only from chunks with real instructional content; copyright
    pages, the TOC, and the credits pages produce nonsense pairs.
    """
    words = text.split()
    if len(words) < _MIN_WORDS:
        return True
    low = text.lower()
    if any(marker in low for marker in _FRONT_MATTER_MARKERS):
        return True
    # A short chunk that's mostly competency codes (e.g. "M11GM-Ia-1") is a
    # curriculum-guide listing, not a lesson.
    if len(words) < 40 and re.search(r"M11GM-[IVX]", text):
        return True
    return False

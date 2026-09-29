"""Build the AstroLex word database (WP-1.1).

Sources (see ``data/words/LICENCES.md``): ENABLE (public domain) for the word list,
wordfreq (build-time only) for a frequency-based difficulty tier, WordNet for a
draft definition and a "has a common sense" flag.

Output: ``data/words/words.sqlite`` (not committed; rebuilt by CI and by
``python -m astrolex_tools.words.build``).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sqlite3
import string
import sys
import time
from pathlib import Path

from astrolex_tools import data_dir, load_tunables

LETTERS = set(string.ascii_lowercase)

# Letter rarity weights (Scrabble-like, used only as a relative "how awkward are these letters" signal).
LETTER_WEIGHT = {
    **{c: 1 for c in "aeilnorstu"},
    **{c: 2 for c in "dg"},
    **{c: 3 for c in "bcmp"},
    **{c: 4 for c in "fhvwy"},
    "k": 5, "j": 8, "x": 8, "q": 10, "z": 10,
}

SCHEMA = """
CREATE TABLE IF NOT EXISTS words (
  word TEXT PRIMARY KEY,
  length INTEGER NOT NULL,
  zipf REAL NOT NULL,
  tier TEXT NOT NULL CHECK (tier IN ('easy','medium','hard')),
  rarity REAL NOT NULL,
  in_wordnet INTEGER NOT NULL,
  pos TEXT,
  definition TEXT,
  blocked INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_words_length ON words(length);
CREATE INDEX IF NOT EXISTS idx_words_tier ON words(tier);
CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
"""


def source_path() -> Path:
    return data_dir() / "words" / "sources" / "enable1.txt"


def db_path() -> Path:
    return data_dir() / "words" / "words.sqlite"


def load_enable(min_len: int = 3, max_len: int = 12) -> list[str]:
    words = []
    for line in source_path().read_text().splitlines():
        w = line.strip().lower()
        if min_len <= len(w) <= max_len and set(w) <= LETTERS:
            words.append(w)
    return words


def rarity(word: str) -> float:
    return sum(LETTER_WEIGHT[c] for c in word) / len(word)


def tier_for(zipf: float, length: int, t: dict) -> str:
    if zipf >= t["difficulty.zipf.easyMin"] and length <= 6:
        return "easy"
    if zipf < t["difficulty.zipf.mediumMin"] or length >= 9:
        return "hard"
    return "medium"


def wordnet_info(word: str):
    """Return (in_wordnet, pos, definition) using the first synset. Lazy import so tests can skip WordNet."""
    from nltk.corpus import wordnet as wn  # noqa: WPS433

    syns = wn.synsets(word)
    if not syns:
        return 0, None, None
    s = syns[0]
    return 1, s.pos(), s.definition()


def build(limit: int | None = None, with_wordnet: bool = True, verbose: bool = True) -> Path:
    from wordfreq import zipf_frequency  # build-time only, see LICENCES.md

    from astrolex_tools.words.blocklist import Blocklist

    t = load_tunables("spike")
    words = load_enable()
    if limit:
        words = words[:limit]
    blocklist = Blocklist.load()

    out = db_path()
    if out.exists():
        out.unlink()
    con = sqlite3.connect(out)
    con.executescript(SCHEMA)

    started = time.time()
    rows = []
    for i, w in enumerate(words):
        z = zipf_frequency(w, "en")
        in_wn, pos, definition = wordnet_info(w) if with_wordnet else (0, None, None)
        rows.append((w, len(w), z, tier_for(z, len(w), t), rarity(w), in_wn, pos, definition, int(blocklist.is_blocked(w))))
        if verbose and i and i % 25000 == 0:
            print(f"  {i}/{len(words)} words, {time.time() - started:.0f}s", file=sys.stderr)
    con.executemany("INSERT INTO words VALUES (?,?,?,?,?,?,?,?,?)", rows)

    src_hash = hashlib.sha256(source_path().read_bytes()).hexdigest()[:16]
    meta = {
        "source": "ENABLE enable1.txt",
        "source_sha256_16": src_hash,
        "built_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "word_count": str(len(rows)),
        "with_wordnet": str(int(with_wordnet)),
        "tunables": json.dumps({k: v for k, v in t.items() if k.startswith("difficulty.")}),
    }
    con.executemany("INSERT INTO meta VALUES (?,?)", meta.items())
    con.commit()
    con.close()
    if verbose:
        print(f"built {out} with {len(rows)} words in {time.time() - started:.1f}s", file=sys.stderr)
    return out


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--limit", type=int, default=None, help="only the first N words (tests)")
    p.add_argument("--no-wordnet", action="store_true")
    a = p.parse_args(argv)
    build(limit=a.limit, with_wordnet=not a.no_wordnet)
    return 0


if __name__ == "__main__":
    sys.exit(main())

"""Validate a Babel line against a pool (the CI check for STORY-004) and the family-safe filter."""
from __future__ import annotations

import re
from collections import Counter

from astrolex_tools.words.blocklist import Blocklist
from astrolex_tools.words.db import WordDB, fits


def tokenize(text: str) -> list[str]:
    return [t for t in re.findall(r"[A-Za-z']+", text)]


def validate_line(text: str, pool: Counter, require_dictionary: bool = True) -> list[str]:
    """Return a list of problems; empty means valid."""
    problems = []
    words = [w.lower() for w in tokenize(text)]
    if not words:
        return ["empty line"]
    need = Counter("".join(words))
    if not fits(need, pool):
        missing = {c: n - pool.get(c, 0) for c, n in need.items() if pool.get(c, 0) < n}
        problems.append(f"letters not in pool: {missing}")
    bl = Blocklist.load()
    bad = bl.contains_blocked(text)
    if bad:
        problems.append(f"blocked tokens: {bad}")
    if require_dictionary:
        db = WordDB.shared()
        unknown = [w for w in words if len(w) > 1 and not db.is_word(w) and w not in {"i", "so", "no", "or", "if", "me", "we", "am", "be", "do", "is", "it", "yes", "you"}]
        if unknown:
            problems.append(f"not dictionary words: {unknown}")
    return problems

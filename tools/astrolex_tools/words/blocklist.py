"""Blocklist and allowlist (WP-1.2).

``data/words/blocklist.txt``: one lowercase token per line, ``#`` comments allowed. Seeded from the
LDNOOBW English list (CC BY 4.0) and curated; every removal or addition is logged in
``data/words/blocklist_changes.md`` with a reason.
``data/words/allowlist.txt``: tokens that must never be treated as blocked even if a future seed
contains them (ordinary words the game needs).
"""
from __future__ import annotations

from collections import Counter
from functools import lru_cache
from pathlib import Path

from astrolex_tools import data_dir
from astrolex_tools.words.db import fits


def _read(path: Path) -> set[str]:
    out = set()
    if not path.exists():
        return out
    for line in path.read_text().splitlines():
        line = line.split("#", 1)[0].strip().lower()
        if line:
            out.add(line)
    return out


class Blocklist:
    def __init__(self, blocked: set[str], allowed: set[str]):
        self.allowed = set(allowed)
        self.blocked = {w for w in blocked if w not in self.allowed}
        self._counters = [(w, Counter(w)) for w in sorted(self.blocked) if w.isalpha()]

    @staticmethod
    @lru_cache(maxsize=1)
    def load() -> "Blocklist":
        d = data_dir() / "words"
        return Blocklist(_read(d / "blocklist.txt"), _read(d / "allowlist.txt"))

    def is_blocked(self, word: str) -> bool:
        return word.lower() in self.blocked

    def contains_blocked(self, text: str) -> list[str]:
        """Blocked tokens appearing as whole words in ``text`` (case-insensitive)."""
        tokens = {t.strip(".,!?;:'\"").lower() for t in text.split()}
        return sorted(t for t in tokens if t in self.blocked)

    def formable(self, pool: Counter, max_len: int = 6) -> list[str]:
        """Blocked words of length <= max_len that can be spelled from the multiset ``pool``."""
        return [w for w, c in self._counters if len(w) <= max_len and fits(c, pool)]

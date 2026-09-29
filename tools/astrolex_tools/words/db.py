"""Read access to the built word database."""
from __future__ import annotations

import sqlite3
from collections import Counter, defaultdict
from functools import lru_cache

from astrolex_tools.words.build import build, db_path


class WordDB:
    def __init__(self, path=None):
        path = path or db_path()
        if not path.exists():
            build(verbose=False)
        self.con = sqlite3.connect(path)
        self.con.row_factory = sqlite3.Row

    @staticmethod
    @lru_cache(maxsize=1)
    def shared() -> "WordDB":
        return WordDB()

    def meta(self) -> dict:
        return {r["key"]: r["value"] for r in self.con.execute("SELECT key, value FROM meta")}

    def is_word(self, w: str) -> bool:
        return self.con.execute("SELECT 1 FROM words WHERE word=?", (w.lower(),)).fetchone() is not None

    def row(self, w: str):
        return self.con.execute("SELECT * FROM words WHERE word=?", (w.lower(),)).fetchone()

    def words(self, min_len=3, max_len=12, tiers=("easy", "medium", "hard"), unblocked_only=True) -> list[str]:
        q = "SELECT word FROM words WHERE length BETWEEN ? AND ? AND tier IN (%s)" % ",".join("?" * len(tiers))
        args = [min_len, max_len, *tiers]
        if unblocked_only:
            q += " AND blocked=0"
        return [r[0] for r in self.con.execute(q, args)]

    @lru_cache(maxsize=4)
    def by_length(self, max_len: int = 8, unblocked_only: bool = True) -> dict[int, list[str]]:
        out = defaultdict(list)
        for w in self.words(3, max_len, unblocked_only=unblocked_only):
            out[len(w)].append(w)
        return out

    @lru_cache(maxsize=8)
    def counters(self, max_len: int = 8, unblocked_only: bool = True, min_zipf: float = 0.0) -> list[tuple[str, Counter]]:
        zm = self.zipf_map()
        return [(w, Counter(w)) for w in self.words(3, max_len, unblocked_only=unblocked_only) if zm[w] >= min_zipf]

    @lru_cache(maxsize=1)
    def zipf_map(self) -> dict[str, float]:
        return {r[0]: r[1] for r in self.con.execute("SELECT word, zipf FROM words")}


def fits(word_counter: Counter, pool: Counter) -> bool:
    """True if every letter of ``word_counter`` is available in ``pool`` with enough multiplicity."""
    for c, n in word_counter.items():
        if pool.get(c, 0) < n:
            return False
    return True

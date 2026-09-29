"""Decoy letter selection with a family-safe guarantee (WP-1.2, feeds CORE-006).

Rule: decoys may never make a blocked word formable that the target letters alone could not
already form. Targets themselves are ordinary words, and any multiset of ordinary letters can
spell something rude if you try hard enough (``this`` contains the letters of a blocked word),
so the honest guarantee is *no new* formable blocked word, plus blocklist checks on every
authored arrangement (Babel lines, traps) elsewhere.
"""
from __future__ import annotations

import random
from collections import Counter

from astrolex_tools.words.blocklist import Blocklist

# English letter frequencies (approximate, per mille), used to draw plausible decoys.
LETTER_FREQ = {
    "e": 127, "t": 91, "a": 82, "o": 75, "i": 70, "n": 67, "s": 63, "h": 61, "r": 60, "d": 43,
    "l": 40, "c": 28, "u": 28, "m": 24, "w": 24, "f": 22, "g": 20, "y": 20, "p": 19, "b": 15,
    "v": 10, "k": 8, "j": 2, "x": 2, "q": 1, "z": 1,
}
_LETTERS = list(LETTER_FREQ)
_WEIGHTS = [LETTER_FREQ[c] for c in _LETTERS]


def draw_decoys(rng: random.Random, n: int) -> list[str]:
    return rng.choices(_LETTERS, weights=_WEIGHTS, k=n)


def choose_decoys(targets: list[str], n: int, rng: random.Random, blocklist: Blocklist | None = None,
                  max_len: int = 6, max_tries: int = 26) -> tuple[list[str], int]:
    """Return (decoys, tries).

    Letters are added one at a time. A candidate letter is rejected if it makes a blocked word
    formable that was not formable before it was added. Each position tries up to ``max_tries``
    weighted draws; if every draw fails (rare), the letter that adds the fewest new blocked words
    is taken and the caller can detect it because the guarantee check will flag the board.
    """
    blocklist = blocklist or Blocklist.load()
    pool = Counter("".join(targets))
    baseline = set(blocklist.formable(pool, max_len))
    decoys: list[str] = []
    tries = 0
    for _ in range(n):
        best, best_new = None, None
        for _attempt in range(max_tries):
            tries += 1
            c = draw_decoys(rng, 1)[0]
            new = set(blocklist.formable(pool + Counter(c), max_len)) - baseline
            if not new:
                best, best_new = c, set()
                break
            if best_new is None or len(new) < len(best_new):
                best, best_new = c, new
        decoys.append(best)
        pool[best] += 1
        baseline |= best_new or set()
    return decoys, tries

"""Act word lists (WP-1.3): ``data/words/acts/<act>.txt``, one word per line, ``#`` comments.

Status is tracked per file in the header comment (``# status: draft | approved``); the owner flips it.
"""
from __future__ import annotations

from functools import lru_cache

from astrolex_tools import data_dir

ACT_FILES = {
    "act1_low_orbit": "Act I, Low Orbit: concrete nouns",
    "act2_nebula": "Act II, The Nebula: emotions",
    "act3_tower": "Act III, The Tower: abstract ideas",
    "act4_core": "Act IV, Babel Core: mixed",
}


@lru_cache(maxsize=1)
def load_acts() -> dict[str, list[str]]:
    out = {}
    for name in ACT_FILES:
        path = data_dir() / "words" / "acts" / f"{name}.txt"
        words = []
        for line in path.read_text().splitlines():
            line = line.split("#", 1)[0].strip().lower()
            if line:
                words.append(line)
        out[name] = words
    return out

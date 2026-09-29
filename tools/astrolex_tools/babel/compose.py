"""Compose Babel lines from a letter pool (WP-1.4, STORY-004).

A line is valid only if every letter of every token (literal glue words included) is available in
the pool with enough multiplicity. Slots are filled from the lexicon; ``{T}`` from the level's
restored words; ``{ANAGRAM_T}`` from dictionary anagrams of a restored word.
"""
from __future__ import annotations

import json
import re
from collections import Counter
from dataclasses import dataclass
from functools import lru_cache
from itertools import product

from astrolex_tools import data_dir, load_tunables
from astrolex_tools.babel.lexicon import LexWord, load_lexicon
from astrolex_tools.words.blocklist import Blocklist
from astrolex_tools.words.db import WordDB, fits

SLOT_RE = re.compile(r"\{([A-Z_]+)\}")
MAX_FILLS_PER_TEMPLATE = 400  # cap enumeration per template per pool; feasibility counts saturate well before this


@dataclass(frozen=True)
class Template:
    id: str
    pattern: str

    @property
    def tokens(self) -> list[str]:
        return self.pattern.split(" ")


@dataclass(frozen=True)
class Line:
    text: str
    template_id: str
    words: tuple[str, ...]

    @property
    def letters(self) -> int:
        return sum(len(w) for w in self.words)


@lru_cache(maxsize=1)
def load_templates() -> list[Template]:
    doc = json.loads((data_dir() / "babel" / "templates.json").read_text())
    return [Template(t["id"], t["pattern"]) for t in doc["templates"]]


def _strip(tok: str) -> tuple[str, str]:
    """Split a token into (core, trailing punctuation)."""
    m = re.match(r"^(\{[A-Z_]+\}|[A-Za-z']+)([.,?!]*)$", tok)
    if not m:
        raise ValueError(f"bad template token: {tok}")
    return m.group(1), m.group(2)


@lru_cache(maxsize=1)
def _theme_words() -> set[str]:
    path = data_dir() / "babel" / "theme.txt"
    return {ln.split("#", 1)[0].strip().lower() for ln in path.read_text().splitlines() if ln.split("#", 1)[0].strip()}


def anagrams_of(word: str, db: WordDB | None = None, min_zipf: float | None = None) -> list[str]:
    """Dictionary words (not blocked, at least ``babel.anagramZipfMin`` common) that are exact anagrams of ``word``."""
    db = db or WordDB.shared()
    if min_zipf is None:
        min_zipf = load_tunables("spike")["babel.anagramZipfMin"]
    key = "".join(sorted(word))
    zm = db.zipf_map()
    return [w for w in db.by_length(12).get(len(word), []) if w != word and zm[w] >= min_zipf and "".join(sorted(w)) == key]


def _candidates_for_slot(slot: str, pool: Counter, targets: list[str], lexicon: list[LexWord], db: WordDB) -> list[str]:
    if slot == "T":
        return [t for t in targets if fits(Counter(t), pool)]
    if slot == "ANAGRAM_T":
        out = []
        for t in targets:
            out += [a for a in anagrams_of(t, db) if fits(Counter(a), pool)]
        return out
    if slot == "THEME":
        return [lw.word for lw in lexicon if lw.word in _theme_words() and fits(lw.counter, pool)]
    if slot == "W":
        return [lw.word for lw in lexicon if fits(lw.counter, pool)]
    return [lw.word for lw in lexicon if lw.pos == slot and fits(lw.counter, pool)]


def compose(pool: Counter, targets: list[str], templates: list[Template] | None = None, min_letters: int | None = None,
            max_per_template: int = MAX_FILLS_PER_TEMPLATE) -> list[Line]:
    """All valid lines for this pool (capped per template), family-safe and validated."""
    t = load_tunables("spike")
    min_letters = t["babel.minLineLetters"] if min_letters is None else min_letters
    templates = templates or load_templates()
    lexicon = load_lexicon()
    db = WordDB.shared()
    bl = Blocklist.load()
    lines: list[Line] = []
    for tpl in templates:
        parts = [_strip(tok) for tok in tpl.tokens]
        literals = [core.lower() for core, _ in parts if not core.startswith("{")]
        remaining = pool - Counter("".join(literals))
        if any(remaining[c] < 0 for c in remaining):  # a literal did not fit
            continue
        if sum(remaining.values()) < 0:
            continue
        slot_opts = []
        ok = True
        for core, _ in parts:
            if core.startswith("{"):
                opts = _candidates_for_slot(core[1:-1], remaining, targets, lexicon, db)
                if not opts:
                    ok = False
                    break
                slot_opts.append(opts)
        if not ok:
            continue
        n = 0
        for fill in product(*slot_opts):
            if n >= max_per_template:
                break
            words = []
            fi = iter(fill)
            for core, _ in parts:
                words.append(next(fi) if core.startswith("{") else core.lower())
            if len(set(words)) < len(words):  # no repeated word in one line
                continue
            if not fits(Counter("".join(words)), pool):
                continue
            if sum(len(w) for w in words) < min_letters:
                continue
            text = " ".join((w.upper() + p) for w, (_, p) in zip(words, parts))
            if bl.contains_blocked(text):
                continue
            lines.append(Line(text, tpl.id, tuple(words)))
            n += 1
    return lines

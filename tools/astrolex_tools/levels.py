"""Act level files (WP-4.5a): ``data/levels/<act>.json`` checked against ``levels.schema.json``.

Usage: ``python -m astrolex_tools.levels`` checks every ``data/levels/*.json`` (not schemas).
"""
from __future__ import annotations

import json
import re
import sys

from jsonschema import Draft202012Validator

from astrolex_tools import data_dir
from astrolex_tools.words.acts import load_acts
from astrolex_tools.words.blocklist import Blocklist
from astrolex_tools.words.db import WordDB

MAX_COMMS_WORDS = 60


def _tokens(text: str) -> set[str]:
    """Lower-case words of a line, each with a plain plural form folded too (cups -> cup)."""
    out = set()
    for t in re.findall(r"[a-z]+", text.lower()):
        out.add(t)
        if len(t) > 3 and t.endswith("s"):
            out.add(t[:-1])
            if t.endswith("es"):
                out.add(t[:-2])
    return out


def spoiler_problems(levels: list[dict]) -> list[str]:
    """Text shown before or between rounds must not give away a word still to be caught.

    The title and commsBefore of a level may not name its own words or a later level's;
    commsAfter may name the words just restored but not a later level's.
    """
    problems = []
    for i, lv in enumerate(levels):
        ahead = {w for later in levels[i + 1:] for w in later["words"]}
        here = set(lv["words"]) | ahead
        shown = [("title", lv["title"], here)]
        shown += [("commsBefore", c["text"], here) for c in lv["commsBefore"]]
        shown += [("commsAfter", c["text"], ahead) for c in lv["commsAfter"]]
        for key, text, banned in shown:
            for w in sorted(_tokens(text) & banned):
                problems.append(f"{lv['id']}: {key} gives away '{w}' before it is caught")
    return problems


def levels_dir():
    return data_dir() / "levels"


def level_files() -> list:
    d = levels_dir()
    return sorted(p for p in d.glob("*.json") if not p.name.endswith(".schema.json")) if d.exists() else []


def load_schema() -> dict:
    return json.loads((levels_dir() / "levels.schema.json").read_text())


def load_levels(act: str) -> list[dict]:
    """Level dicts of one act, as written in the file, in file order. Empty if no file."""
    path = levels_dir() / f"{act}.json"
    if not path.exists():
        return []
    return json.loads(path.read_text())["levels"]


def schema_errors(doc: dict) -> list[str]:
    return [
        f"schema: {'/'.join(str(p) for p in e.absolute_path) or '<root>'}: {e.message}"
        for e in Draft202012Validator(load_schema()).iter_errors(doc)
    ]


def check_levels(doc: dict, act_words, blocklist: Blocklist, db: WordDB | None = None) -> list[str]:
    """Problems in one level file; empty list means good."""
    problems = schema_errors(doc)
    if problems:  # structure is unreliable, stop here
        return problems
    db = db or WordDB.shared()
    act_set = set(act_words)
    seen: dict[str, str] = {}
    ids: set[str] = set()
    for i, lv in enumerate(doc["levels"], start=1):
        lid = lv["id"]
        if lid in ids:
            problems.append(f"{lid}: duplicate id")
        ids.add(lid)
        if lv["order"] != i:
            problems.append(f"{lid}: order {lv['order']} expected {i} (must run 1..n without gaps)")
        for w in lv["words"]:
            if w not in act_set:
                problems.append(f"{lid}: '{w}' is not in the act word list")
            if not db.is_word(w):
                problems.append(f"{lid}: '{w}' is not in the word database")
            if blocklist.is_blocked(w):
                problems.append(f"{lid}: '{w}' is blocked")
            if w in seen:
                problems.append(f"{lid}: '{w}' repeated (already in {seen[w]})")
            seen.setdefault(w, lid)
        for key in ("commsBefore", "commsAfter"):
            n = sum(len(c["text"].split()) for c in lv[key])
            if n > MAX_COMMS_WORDS:
                problems.append(f"{lid}: {key} has {n} words (max {MAX_COMMS_WORDS})")
    problems += spoiler_problems(doc["levels"])
    return problems


def check_file(path) -> list[str]:
    doc = json.loads(path.read_text())
    act = doc.get("act") if isinstance(doc, dict) else None
    acts = load_acts()
    if act not in acts:
        return [f"unknown act '{act}'"]
    return [f"{path.name}: {p}" for p in check_levels(doc, acts[act], Blocklist.load())]


def check_all() -> list[str]:
    out: list[str] = []
    for p in level_files():
        out += check_file(p)
    return out


def main() -> int:
    problems = check_all()
    for p in problems:
        print("ERROR", p)
    print("levels:", "ok" if not problems else f"{len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())

"""Level curve report (WP-F.9): an analytic difficulty model per level, read from data/levels + game.json.

Usage: ``python -m astrolex_tools.curve --out reports/ci/curve.md``
Exit code 1 when a level or act is flagged.

Model (constants are modelling assumptions, not player-facing numbers; the real knobs are the tunables):
  letters = sum of word lengths;  word = letters / words
  decoys  = min(ramp.decoyMax, max(spawner.decoys, ceil(spawner.decoyRatio * word)))   (round.gd _ensure_decoys, round 1)
  tiles   = word + decoys                                  (tiles in play for the word being caught)
  est/letter = BASE_SEC + SEARCH_SEC * tiles + SPEED_SEC * drift.speed
  est = letters * est/letter + thief + hazard losses, where
    thief  = stealCost * STEAL_SHARE * n_thieves,  n = (est - firstAt) / interval + 1 (fixed point, 0 when interval is 0)
    hazard = counterfeit: letters * counterfeitRatio * FORGE_HIT * wrongCost;  trap: TRAP_HIT * trapCost;
             stroop: base * (stroopSec / stroopEverySec) * STROOP_SLOW
  slack = 1 - est / burst.seconds
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

from astrolex_tools import data_dir, repo_root
from astrolex_tools.levels import level_files, load_levels

BASE_SEC = 0.45
SEARCH_SEC = 0.03
SPEED_SEC = 2.0
STEAL_SHARE = 0.5
FORGE_HIT = 0.15
TRAP_HIT = 0.25
STROOP_SLOW = 0.3
SLACK_MIN, SLACK_MAX = 0.10, 0.85


def game_tunables() -> dict:
    return json.loads((data_dir() / "tunables" / "game.json").read_text())


def estimate(words: list[str], tuning: dict) -> dict:
    """The whole model, in one place. `tuning` is game.json overlaid with the level's tuning."""
    letters = sum(len(w) for w in words)
    word = letters / len(words)
    decoys = min(tuning["ramp.decoyMax"], max(tuning["spawner.decoys"], math.ceil(tuning["spawner.decoyRatio"] * word)))
    tiles = word + decoys
    per_letter = BASE_SEC + SEARCH_SEC * tiles + SPEED_SEC * tuning["drift.speed"]
    base = letters * per_letter
    forged = letters * tuning["hazard.counterfeitRatio"] * FORGE_HIT * tuning["burst.wrongCost"]
    trap = TRAP_HIT * tuning["hazard.trapCost"] if tuning["hazard.traps"] >= 1 else 0.0
    stroop = 0.0
    if tuning["hazard.stroop"] >= 1 and tuning["hazard.stroopEverySec"] > 0:
        stroop = base * tuning["hazard.stroopSec"] / tuning["hazard.stroopEverySec"] * STROOP_SLOW
    hazards = forged + trap + stroop
    est = base + hazards
    thief = 0.0
    interval = tuning["thief.interval"]
    if interval > 0:
        for _ in range(8):
            n = max(0.0, (est - tuning["thief.firstAt"]) / interval + 1)
            thief = tuning["thief.stealCost"] * STEAL_SHARE * n
            est = base + hazards + thief
    burst = tuning["burst.seconds"]
    return {"letters": letters, "tiles": round(tiles, 1), "est": est, "burst": burst,
            "slack": 1 - est / burst, "hazards": hazards + thief}


def build() -> tuple[list[dict], list[str]]:
    base = game_tunables()
    rows, flags = [], []
    for p in level_files():
        act_rows = []
        for lv in load_levels(p.stem):
            r = estimate(lv["words"], {**base, **lv["tuning"]})
            r.update(act=p.stem, id=lv["id"], words=len(lv["words"]))
            act_rows.append(r)
            if not SLACK_MIN <= r["slack"] <= SLACK_MAX:
                flags.append(f"{lv['id']}: slack {r['slack']:.0%} outside {SLACK_MIN:.0%}-{SLACK_MAX:.0%}")
        s = [r["slack"] for r in act_rows]
        h = len(s) // 2
        if s and (sum(s[h:]) / len(s[h:]) >= sum(s[:h]) / h or s[-1] >= s[0]):
            flags.append(f"{p.stem}: slack does not trend down ({s[0]:.0%} -> {s[-1]:.0%})")
        rows += act_rows
    return rows, flags


def render(rows: list[dict], flags: list[str]) -> str:
    out = ["# Level curve (WP-F.9)", "",
           "Analytic model in `tools/astrolex_tools/curve.py`; slack = 1 - est. seconds / burst seconds.", "",
           "| act | level | words | letters | tiles | est. s | burst | slack | hazard s |",
           "|---|---|---|---|---|---|---|---|---|"]
    for r in rows:
        out.append(f"| {r['act']} | {r['id']} | {r['words']} | {r['letters']} | {r['tiles']} | {r['est']:.1f} "
                   f"| {r['burst']:g} | {r['slack']:.0%} | {r['hazards']:.1f} |")
    out += ["", "## Flags", ""] + ([f"- {f}" for f in flags] or ["none"])
    return "\n".join(out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="WP-F.9/curve.md")
    a = ap.parse_args()
    rows, flags = build()
    p = Path(a.out)
    if not p.is_absolute():
        p = repo_root() / (p if p.parts[0] == "reports" else Path("reports") / p)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(render(rows, flags))
    for f in flags:
        print("FLAG", f)
    print(f"curve: {len(rows)} levels, {len(flags)} flag(s)")
    return 1 if flags else 0


if __name__ == "__main__":
    sys.exit(main())

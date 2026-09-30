"""Blocklist board scan (WP-1.2, the CONT-001 automated test).

Generates N boards (``spawner.wordsPerLevel`` words from the act lists plus ``spawner.decoysPerLevel``
decoys) and reports:

* the share of boards where a blocked word is formable from the **target letters alone**
  (the floor nobody can remove without changing the words),
* the share where naive random decoys make a **new** blocked word formable,
* the share where the rejection-sampling selector does (must be 0).
"""
from __future__ import annotations

import argparse
import random
import sys
import time
from collections import Counter

from astrolex_tools import load_tunables, report_path
from astrolex_tools.words.acts import load_acts
from astrolex_tools.words.blocklist import Blocklist
from astrolex_tools.words.decoys import choose_decoys, draw_decoys


def scan(boards: int, seed: int | None = None) -> dict:
    t = load_tunables("spike")
    seed = t["feasibility.seed"] if seed is None else seed
    rng = random.Random(seed)
    bl = Blocklist.load()
    acts = load_acts()
    all_words = [w for words in acts.values() for w in words]
    n_words, n_decoys, max_len = t["spawner.wordsPerLevel"], t["spawner.decoysPerLevel"], t["blocklist.maxFormableLength"]

    floor = naive_new = safe_new = 0
    tries_total = 0
    examples: list[str] = []
    for _ in range(boards):
        targets = rng.sample(all_words, n_words)
        base = Counter("".join(targets))
        baseline = set(bl.formable(base, max_len))
        if baseline:
            floor += 1
        naive = set(bl.formable(base + Counter(draw_decoys(rng, n_decoys)), max_len)) - baseline
        if naive:
            naive_new += 1
            if len(examples) < 5:
                examples.append(f"{'+'.join(targets)} + naive decoys -> {sorted(naive)[:3]}")
        decoys, tries = choose_decoys(targets, n_decoys, rng, bl, max_len)
        tries_total += tries
        safe = set(bl.formable(base + Counter(decoys), max_len)) - baseline
        if safe:
            safe_new += 1
    return {
        "boards": boards, "seed": seed, "wordsPerLevel": n_words, "decoysPerLevel": n_decoys, "maxFormableLength": max_len,
        "floor_share": floor / boards, "naive_new_share": naive_new / boards, "safe_new_share": safe_new / boards,
        "mean_tries": tries_total / boards, "examples": examples,
    }


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--boards", type=int, default=None)
    p.add_argument("--out", default=None, help="markdown report path (default reports/WP-1.2/scan.md)")
    a = p.parse_args(argv)
    t = load_tunables("spike")
    started = time.time()
    r = scan(a.boards or t["blocklist.scanBoards"])
    out = report_path(a.out or "WP-1.2/scan.md")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(
        "# Blocklist board scan (CONT-001)\n\n"
        f"Boards: {r['boards']} · seed {r['seed']} · {r['wordsPerLevel']} words + {r['decoysPerLevel']} decoys per board · "
        f"blocked words up to length {r['maxFormableLength']} · {time.time() - started:.1f}s\n\n"
        "| Measure | Share of boards |\n|---|---:|\n"
        f"| Blocked word formable from target letters alone (floor) | {r['floor_share']:.1%} |\n"
        f"| Naive random decoys add a new formable blocked word | {r['naive_new_share']:.1%} |\n"
        f"| Rejection-sampled decoys add a new formable blocked word | {r['safe_new_share']:.1%} |\n\n"
        f"Mean decoy draws per board with rejection: {r['mean_tries']:.2f}\n\n"
        "Examples of naive failures:\n\n" + "\n".join(f"- `{e}`" for e in r["examples"]) + "\n"
    )
    print(f"floor {r['floor_share']:.1%}, naive new {r['naive_new_share']:.1%}, safe new {r['safe_new_share']:.1%} -> {out}")
    return 0 if r["safe_new_share"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())

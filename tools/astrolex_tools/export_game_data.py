"""Export the data the Godot client needs to ``game/data/`` (milestone first-draft, "Data contract").

Writes two files, both generated and never edited by hand:

- ``tunables.json``: every key of ``data/tunables/game.json`` except ``$schema``, same values.
- ``content.json``: act word lists, Babel lexicon, theme words, templates and precomputed
  common anagrams for every act word. Same shape and values as the toy's
  ``window.ASTROLEX_DATA`` (see ``export_toy_data.py``) minus its tunables.

Each file starts with a ``_generated`` key naming this command.
Regenerate with ``python -m astrolex_tools.export_game_data``.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from astrolex_tools import load_tunables, repo_root
from astrolex_tools.babel.compose import anagrams_of, load_templates
from astrolex_tools.babel.lexicon import load_lexicon
from astrolex_tools.words.acts import ACT_FILES, load_acts

GENERATED = "by python -m astrolex_tools.export_game_data; do not edit"


def load_theme() -> list[str]:
    """Theme words from ``data/babel/theme.txt``, parsed exactly as the toy export does."""
    lines = (repo_root() / "data" / "babel" / "theme.txt").read_text().splitlines()
    return [ln.split("#", 1)[0].strip().lower() for ln in lines if ln.split("#", 1)[0].strip()]


def build_tunables() -> dict:
    t = load_tunables("game")
    return {k: t[k] for k in sorted(t) if k != "$schema"}


def build_content() -> dict:
    acts = load_acts()
    return {
        "acts": {k: {"title": ACT_FILES[k], "words": v} for k, v in acts.items()},
        "lexicon": [[lw.word, lw.pos] for lw in load_lexicon()],
        "theme": load_theme(),
        "templates": [{"id": tp.id, "pattern": tp.pattern} for tp in load_templates()],
        "anagrams": {w: anagrams_of(w) for words in acts.values() for w in words},
    }


def main(out_dir: Path | None = None) -> int:
    out_dir = Path(out_dir) if out_dir is not None else repo_root() / "game" / "data"
    out_dir.mkdir(parents=True, exist_ok=True)

    tunables = {"_generated": GENERATED, **build_tunables()}
    content = {"_generated": GENERATED, **build_content()}

    tun_path = out_dir / "tunables.json"
    con_path = out_dir / "content.json"
    tun_path.write_text(json.dumps(tunables, indent=2) + "\n")
    con_path.write_text(json.dumps(content, separators=(",", ":")) + "\n")

    n_words = sum(len(a["words"]) for a in content["acts"].values())
    n_anag = sum(1 for v in content["anagrams"].values() if v)
    print(
        f"wrote {tun_path} ({len(tunables) - 1} tunables) and {con_path} ({con_path.stat().st_size // 1024} KB): "
        f"{n_words} act words, {len(content['lexicon'])} lexicon words, {len(content['templates'])} templates, "
        f"{n_anag} words with anagrams",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

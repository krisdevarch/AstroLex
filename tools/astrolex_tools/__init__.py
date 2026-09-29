"""AstroLex content tooling.

Everything here is engine-free: plain Python over data files in ``data/``.
Run modules with ``python -m astrolex_tools.<module>`` from anywhere inside the repo.
"""
from __future__ import annotations

import json
from pathlib import Path


def repo_root(start: Path | None = None) -> Path:
    """Walk up from ``start`` (default: this file) until a directory containing ``data/`` and ``docs/`` is found."""
    here = (start or Path(__file__)).resolve()
    for parent in [here, *here.parents]:
        if (parent / "data").is_dir() and (parent / "docs").is_dir():
            return parent
    raise RuntimeError("AstroLex repo root not found (no directory with data/ and docs/)")


def data_dir() -> Path:
    return repo_root() / "data"


def reports_dir() -> Path:
    return repo_root() / "reports"


def load_tunables(name: str) -> dict:
    """Load ``data/tunables/<name>.json``. Every number a player can feel lives there, never in code."""
    path = data_dir() / "tunables" / f"{name}.json"
    with path.open() as f:
        return json.load(f)

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


def report_path(p: str) -> Path:
    """Resolve a CLI --out value. Absolute paths are used as given; a path that already
    starts with reports/ is taken from the repo root; anything else is relative to reports/."""
    path = Path(p)
    if path.is_absolute():
        return path
    if path.parts and path.parts[0] == "reports":
        return repo_root() / path
    return reports_dir() / path


def load_tunables(name: str) -> dict:
    """Load ``data/tunables/<name>.json``. Every number a player can feel lives there, never in code."""
    path = data_dir() / "tunables" / f"{name}.json"
    with path.open() as f:
        return json.load(f)

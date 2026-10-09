"""Validate every ``data/tunables/*.json`` against its sibling ``*.schema.json``.

Usage: ``python -m astrolex_tools.validate_data``
"""
from __future__ import annotations

import json
import sys

from jsonschema import Draft202012Validator

from astrolex_tools import data_dir


def check_mods(doc: dict, game_keys: set[str], name: str) -> list[str]:
    """Every key in every ``mod`` of a characters/difficulty doc must be a game.json key."""
    errors: list[str] = []
    entries = doc.get("characters") or doc.get("levels") or []
    for entry in entries:
        for op, keys in (entry.get("mod") or {}).items():
            for key in keys:
                if key not in game_keys:
                    errors.append(f"{name}: {entry.get('id')}: mod.{op} key '{key}' is not in game.json")
    return errors


def validate_mod_files(root=None) -> list[str]:
    root = root or data_dir()
    game = json.loads((root / "tunables" / "game.json").read_text())
    game_keys = {k for k in game if k != "$schema"}
    errors: list[str] = []
    for rel in ("characters.json", "tunables/difficulty.json"):
        path = root / rel
        schema = json.loads(path.with_name(path.stem + ".schema.json").read_text())
        doc = json.loads(path.read_text())
        errors += [f"{rel}: {e.message}" for e in Draft202012Validator(schema).iter_errors(doc)]
        errors += check_mods(doc, game_keys, rel)
    diff = json.loads((root / "tunables" / "difficulty.json").read_text())
    if diff.get("default") not in [lv.get("id") for lv in diff.get("levels", [])]:
        errors.append("tunables/difficulty.json: default is not a level id")
    return errors


def validate_all() -> list[str]:
    errors: list[str] = []
    tunables = data_dir() / "tunables"
    for path in sorted(tunables.glob("*.json")):
        if path.name.endswith(".schema.json"):
            continue
        schema_path = path.with_name(path.stem + ".schema.json")
        if not schema_path.exists():
            errors.append(f"{path.name}: no schema ({schema_path.name} missing)")
            continue
        schema = json.loads(schema_path.read_text())
        doc = json.loads(path.read_text())
        for err in Draft202012Validator(schema).iter_errors(doc):
            errors.append(f"{path.name}: {err.message}")
    babel = data_dir() / "babel"
    for name in ("templates.json",):
        path, schema_path = babel / name, babel / name.replace(".json", ".schema.json")
        schema = json.loads(schema_path.read_text())
        for err in Draft202012Validator(schema).iter_errors(json.loads(path.read_text())):
            errors.append(f"babel/{name}: {err.message}")
    errors += validate_mod_files()
    from astrolex_tools.levels import check_all

    errors += [f"levels/{e}" for e in check_all()]
    return errors


def main() -> int:
    errors = validate_all()
    for e in errors:
        print("ERROR", e)
    print("data validation:", "ok" if not errors else f"{len(errors)} error(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

"""Validate every ``data/tunables/*.json`` against its sibling ``*.schema.json``.

Usage: ``python -m astrolex_tools.validate_data``
"""
from __future__ import annotations

import json
import sys

from jsonschema import Draft202012Validator

from astrolex_tools import data_dir


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

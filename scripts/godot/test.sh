#!/usr/bin/env bash
# Imports the Godot project and runs every headless test in game/tests/.
# Fails on a failing test, on zero tests, and on any SCRIPT ERROR or parse error in the log
# (GDScript cannot catch runtime errors, so the log is the only place they show).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT="${GODOT:-$("$REPO_ROOT/scripts/godot/install.sh" | tail -n 1)}"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

# First import builds game/.godot (class cache, imported resources). Errors here fail too.
"$GODOT" --headless --path "$REPO_ROOT/game" --import 2>&1 | tee "$LOG"
"$GODOT" --headless --path "$REPO_ROOT/game" -s res://tests/run_tests.gd 2>&1 | tee -a "$LOG"

if grep -E "SCRIPT ERROR|Parse Error|Failed to load script" "$LOG" >/dev/null; then
  echo "Godot reported script errors (see above)." >&2
  exit 1
fi

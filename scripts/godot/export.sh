#!/usr/bin/env bash
# Exports the game with a preset from game/export_presets.cfg into build/<platform>/.
#   scripts/godot/export.sh web             # build/web/index.html (release, single-threaded)
# Web is the only preset for now; other platforms are added when their builds start.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT="${GODOT:-$("$REPO_ROOT/scripts/godot/install.sh" --templates | tail -n 1)}"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

case "${1:-}" in
  web) PRESET="Web"; OUT="$REPO_ROOT/build/web/index.html"; MODE="--export-release" ;;
  *) echo "usage: $0 web" >&2; exit 2 ;;
esac

mkdir -p "$(dirname "$OUT")"
# Build info for playtest telemetry (gitignored; the game reads commit "dev" when it is absent).
VERSION_STR="$(sed -n 's/^config\/version="\(.*\)"/\1/p' "$REPO_ROOT/game/project.godot")"
printf '{"version": "%s", "commit": "%s", "built": "%s"}\n' "$VERSION_STR" \
  "$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo dev)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  > "$REPO_ROOT/game/data/build.json"
"$GODOT" --headless --path "$REPO_ROOT/game" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$REPO_ROOT/game" "$MODE" "$PRESET" "$OUT" 2>&1 | tee "$LOG"

if grep -E "SCRIPT ERROR|Parse Error|ERROR: .*[Ee]xport|Project export for preset .* failed" "$LOG" >/dev/null || [ ! -s "$OUT" ]; then
  echo "Export of $PRESET failed (see above)." >&2
  exit 1
fi
ls -la "$(dirname "$OUT")"

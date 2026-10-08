#!/usr/bin/env bash
# Exports the game with a preset from game/export_presets.cfg into build/<platform>/.
#   scripts/godot/export.sh web             # build/web/index.html (release, single-threaded)
#   scripts/godot/export.sh ios             # build/ios/AstroLex.xcodeproj (Xcode project only, WP-3.0;
#                                           # works on Linux too, xcodebuild on a Mac builds it)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

case "${1:-}" in
  web) PRESET="Web"; OUT="$REPO_ROOT/build/web/index.html"; MODE="--export-release"; CHECK="$OUT" ;;
  ios) PRESET="iOS"; OUT="$REPO_ROOT/build/ios/AstroLex.xcodeproj"; MODE="--export-release"
       CHECK="$OUT/project.pbxproj"
       # A stale project would hide a failed export; Godot rewrites the whole folder anyway.
       rm -rf "$REPO_ROOT/build/ios" ;;
  *) echo "usage: $0 web|ios" >&2; exit 2 ;;
esac
GODOT="${GODOT:-$("$REPO_ROOT/scripts/godot/install.sh" --templates "$1" | tail -n 1)}"

mkdir -p "$(dirname "$OUT")"
# Build info for playtest telemetry (gitignored; the game reads commit "dev" when it is absent).
VERSION_STR="$(sed -n 's/^config\/version="\(.*\)"/\1/p' "$REPO_ROOT/game/project.godot")"
printf '{"version": "%s", "commit": "%s", "built": "%s"}\n' "$VERSION_STR" \
  "$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo dev)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  > "$REPO_ROOT/game/data/build.json"
"$GODOT" --headless --path "$REPO_ROOT/game" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$REPO_ROOT/game" "$MODE" "$PRESET" "$OUT" 2>&1 | tee "$LOG"

if grep -E "SCRIPT ERROR|Parse Error|ERROR: .*[Ee]xport|Project export for preset .* failed" "$LOG" >/dev/null || [ ! -s "$CHECK" ]; then
  echo "Export of $PRESET failed (see above)." >&2
  exit 1
fi
ls -la "$(dirname "$OUT")"

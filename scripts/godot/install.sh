#!/usr/bin/env bash
# Installs the pinned Godot editor (headless-capable) and, with --templates, the export
# templates this project uses (web without threads; iOS on request). Idempotent; used by CI,
# by cloud sessions (Linux) and on the owner's Mac (macOS). Prints the editor path on the last line.
#
#   scripts/godot/install.sh                   # editor only
#   scripts/godot/install.sh --templates       # editor plus the web templates
#   scripts/godot/install.sh --templates ios   # editor plus the iOS templates (WP-3.0)
#
# GODOT_VERSION (default from scripts/godot/VERSION) and GODOT_HOME (default ~/.local/godot)
# can be overridden.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${GODOT_VERSION:-$(tr -d '[:space:]' < "$HERE/VERSION")}"
GODOT_HOME="${GODOT_HOME:-$HOME/.local/godot}"
BASE="https://github.com/godotengine/godot/releases/download/${VERSION}-stable"
if [ "$(uname -s)" = "Darwin" ]; then
  EDITOR_ZIP="Godot_v${VERSION}-stable_macos.universal.zip"
  EDITOR_DIR="$GODOT_HOME/$VERSION"
  BIN="$EDITOR_DIR/Godot.app/Contents/MacOS/Godot"
  TEMPLATE_DIR="$HOME/Library/Application Support/Godot/export_templates/${VERSION}.stable"
else
  EDITOR_ZIP="Godot_v${VERSION}-stable_linux.x86_64.zip"
  EDITOR_DIR="$GODOT_HOME"
  BIN="$EDITOR_DIR/Godot_v${VERSION}-stable_linux.x86_64"
  TEMPLATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${VERSION}.stable"
fi

case "${2:-web}" in
  web) TEMPLATES="templates/web_nothreads_debug.zip templates/web_nothreads_release.zip" ;;
  ios) TEMPLATES="templates/ios.zip" ;;
  *) echo "usage: $0 [--templates [web|ios]]" >&2; exit 2 ;;
esac

mkdir -p "$EDITOR_DIR"
if [ ! -x "$BIN" ]; then
  echo "Downloading Godot $VERSION editor" >&2
  curl -fsSL --retry 3 -o "$GODOT_HOME/editor.zip" "$BASE/$EDITOR_ZIP"
  unzip -q -o "$GODOT_HOME/editor.zip" -d "$EDITOR_DIR"
  rm -f "$GODOT_HOME/editor.zip"
  chmod +x "$BIN"
fi

MISSING=0
for t in templates/version.txt $TEMPLATES; do
  [ -f "$TEMPLATE_DIR/$(basename "$t")" ] || MISSING=1
done
if [ "${1:-}" = "--templates" ] && [ "$MISSING" -eq 1 ]; then
  echo "Downloading Godot $VERSION export templates (${2:-web})" >&2
  mkdir -p "$TEMPLATE_DIR"
  TPZ="$GODOT_HOME/templates-${VERSION}.tpz"
  [ -f "$TPZ" ] || curl -fsSL --retry 3 -o "$TPZ" "$BASE/Godot_v${VERSION}-stable_export_templates.tpz"
  # Keep only what the presets in game/export_presets.cfg need (web about 20 MB, iOS about 200 MB
  # of the 2 GB archive).
  # shellcheck disable=SC2086
  unzip -q -o -j "$TPZ" templates/version.txt $TEMPLATES -d "$TEMPLATE_DIR"
  rm -f "$TPZ"
fi

"$BIN" --headless --version >&2
echo "$BIN"

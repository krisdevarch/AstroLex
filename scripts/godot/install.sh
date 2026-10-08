#!/usr/bin/env bash
# Installs the pinned Godot editor (headless-capable) and, with --templates, the export
# templates this project uses (web without threads). Idempotent; used by CI and
# by cloud sessions. Prints the editor path on the last line.
#
#   scripts/godot/install.sh               # editor only
#   scripts/godot/install.sh --templates   # editor plus the web templates
#
# GODOT_VERSION (default from scripts/godot/VERSION) and GODOT_HOME (default ~/.local/godot)
# can be overridden.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${GODOT_VERSION:-$(tr -d '[:space:]' < "$HERE/VERSION")}"
GODOT_HOME="${GODOT_HOME:-$HOME/.local/godot}"
BASE="https://github.com/godotengine/godot/releases/download/${VERSION}-stable"
BIN="$GODOT_HOME/Godot_v${VERSION}-stable_linux.x86_64"
TEMPLATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${VERSION}.stable"

mkdir -p "$GODOT_HOME"
if [ ! -x "$BIN" ]; then
  echo "Downloading Godot $VERSION editor" >&2
  curl -fsSL --retry 3 -o "$GODOT_HOME/editor.zip" "$BASE/Godot_v${VERSION}-stable_linux.x86_64.zip"
  unzip -q -o "$GODOT_HOME/editor.zip" -d "$GODOT_HOME"
  rm -f "$GODOT_HOME/editor.zip"
  chmod +x "$BIN"
fi

if [ "${1:-}" = "--templates" ] && [ ! -f "$TEMPLATE_DIR/version.txt" ]; then
  echo "Downloading Godot $VERSION export templates (web)" >&2
  mkdir -p "$TEMPLATE_DIR"
  TPZ="$GODOT_HOME/templates-${VERSION}.tpz"
  [ -f "$TPZ" ] || curl -fsSL --retry 3 -o "$TPZ" "$BASE/Godot_v${VERSION}-stable_export_templates.tpz"
  # Keep only what the presets in game/export_presets.cfg need (about 20 MB of the 1.3 GB archive).
  unzip -q -o -j "$TPZ" \
    templates/version.txt \
    templates/web_nothreads_debug.zip templates/web_nothreads_release.zip \
    -d "$TEMPLATE_DIR"
  rm -f "$TPZ"
fi

"$BIN" --headless --version >&2
echo "$BIN"

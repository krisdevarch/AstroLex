#!/usr/bin/env bash
# Renders the HUD art (scripts/art/hud/*.svg) to game/art/hud/*.png at 2x the viewBox size (WP-F.28).
# The game draws these textures at half size (HudArt.ART_SCALE) with mipmaps, so they stay sharp.
# Needs Playwright (scripts/godot/web-smoke/node_modules) and Chromium: CHROMIUM_PATH=/opt/pw-browsers/chromium.
set -euo pipefail
cd "$(dirname "$0")/../.."
export CHROMIUM_PATH="${CHROMIUM_PATH:-/opt/pw-browsers/chromium}"
python3 scripts/art/hud/gen_buttons.py
mkdir -p game/art/hud
for svg in scripts/art/hud/*.svg; do
  name=$(basename "$svg" .svg)
  w=$(grep -o '<svg[^>]*' "$svg" | grep -o ' width="[0-9.]*"' | grep -o '[0-9.]*')
  h=$(grep -o '<svg[^>]*' "$svg" | grep -o ' height="[0-9.]*"' | grep -o '[0-9.]*')
  node scripts/art/render_svg.cjs "$svg" "game/art/hud/$name.png" $((w * 2)) $((h * 2))
done

#!/usr/bin/env bash
# Renders the HUD SVGs (scripts/art/hud/*.svg, drawn in game px) to game/art/hud/*.png at 2x
# (HudArt.ART_SCALE). Needs Playwright: scripts/godot/web-smoke/node_modules (npm install there)
# and CHROMIUM_PATH if Playwright's own Chromium is not installed.
set -euo pipefail
cd "$(dirname "$0")/../.."
export CHROMIUM_PATH="${CHROMIUM_PATH:-/opt/pw-browsers/chromium}"
mkdir -p game/art/hud
r() { node scripts/art/render_svg.cjs "scripts/art/hud/$1.svg" "game/art/hud/$1.png" "$2" "$3"; }
r console 1820 1064
for k in pause sound settings; do r "btn_$k" 300 300; r "btn_${k}_icon" 300 300; done
r bulb 204 344

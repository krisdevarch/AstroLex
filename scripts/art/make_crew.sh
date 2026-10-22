#!/usr/bin/env bash
# Renders the crew bust SVGs (scripts/art/crew/*.svg) to game/art/crew/*.png (512x512, transparent).
# Optional: regenerate the SVGs first with `python3 scripts/art/crew/gen_crew_svgs.py`.
# Needs Playwright: NODE_PATH=$(npm root -g) works, or scripts/godot/web-smoke/node_modules.
set -euo pipefail
cd "$(dirname "$0")/../.."
export NODE_PATH="${NODE_PATH:-$(npm root -g)}"
mkdir -p game/art/crew
for who in rhee ade kit vanta tomas; do
  node scripts/art/render_svg.cjs "scripts/art/crew/$who.svg" "game/art/crew/$who.png" 512 512
done

#!/usr/bin/env bash
# Dev helper: render stills/NAME.svg to a half-size preview in the given dir. usage: preview.sh outdir f1 f2 ...
set -e
cd "$(dirname "$0")/../.."
export NODE_PATH="$(npm root -g)"
out="$1"; shift
for n in "$@"; do
  node scripts/art/render_svg.cjs "scripts/art/stills/$n.svg" "$out/$n.png" 1080 1920
  python3 -c "from PIL import Image;Image.open('$out/$n.png').convert('RGB').resize((540,960)).save('$out/${n}_s.jpg',quality=85)"
done

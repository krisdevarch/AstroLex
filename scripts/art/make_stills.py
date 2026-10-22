"""Renders the 5 stills of the Act III flashback (f1-f5) (WP-F.7, art WP-F.13b) into game/art/stills/.

The art is layered SVG in scripts/art/stills/f1.svg .. f5.svg (1080x1920): Babel's memory of the Loud
Wars, drawn from the captions in data/story/flashback.json. Each SVG is rasterised in headless
Chromium by scripts/art/render_svg.cjs (Playwright; NODE_PATH is set from `npm root -g` when unset)
and saved as JPEG quality 85. Also writes game/data/stills.json (ids and seconds only).

    python3 scripts/art/make_stills.py

Needs node + Playwright with Chromium (see scripts/godot/web-smoke). Deterministic: no random
input, the SVG grain uses a fixed feTurbulence seed.
"""
import json
import os
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

W, H = 1080, 1920
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SRC = HERE / "stills"
OUT = ROOT / "game" / "art" / "stills"
NAMES = ["f1", "f2", "f3", "f4", "f5"]
QUALITY = 85


def render(svg: Path, png: Path) -> None:
    env = dict(os.environ)
    if not env.get("NODE_PATH"):
        env["NODE_PATH"] = subprocess.run(["npm", "root", "-g"], capture_output=True, text=True, check=True).stdout.strip()
    subprocess.run(["node", str(HERE / "render_svg.cjs"), str(svg), str(png), str(W), str(H)], check=True, env=env)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    timing = {}  # game/data/stills.json: ids and seconds only (captions are for the artist)
    for key, src in (("flashback", "flashback.json"),):
        beats = json.loads((ROOT / "data" / "story" / src).read_text())["stills"]
        timing[key] = [{"id": b["id"], "seconds": b["seconds"]} for b in beats]
    (ROOT / "game" / "data" / "stills.json").write_text(json.dumps(timing, indent=1) + "\n")
    with tempfile.TemporaryDirectory() as tmp:
        for name in NAMES:
            png = Path(tmp) / f"{name}.png"
            render(SRC / f"{name}.svg", png)
            img = Image.open(png).convert("RGB")
            assert img.size == (W, H), img.size
            img.save(OUT / f"{name}.jpg", quality=QUALITY, optimize=True)
            print(name, (OUT / f"{name}.jpg").stat().st_size)


if __name__ == "__main__":
    main()

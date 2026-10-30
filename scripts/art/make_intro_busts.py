"""Circle-cropped 640 px busts for the intro screen (WP-F.29). Pillow only.
Reads the four character sheets from the design mount, writes game/art/intro/<id>.png."""
import sys
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw

SRC = Path(sys.argv[1] if len(sys.argv) > 1 else "/mnt/project-files/design/characters")
OUT = Path(__file__).resolve().parents[2] / "game" / "art" / "intro"
SIZE = 640
SS = 4


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for cid in ("wren", "juno", "ash", "pip"):
        im = Image.open(SRC / f"{cid}.png").convert("RGBA")
        x0, y0, x1, y1 = im.getbbox()
        side = 760  # head and shoulders: the top of the head down to the chest
        cx = (x0 + x1) // 2
        left = max(0, min(im.width - side, cx - side // 2))
        crop = im.crop((left, y0, left + side, y0 + side)).resize((SIZE, SIZE), Image.LANCZOS)
        mask = Image.new("L", (SIZE * SS, SIZE * SS), 0)
        ImageDraw.Draw(mask).ellipse((0, 0, SIZE * SS - 1, SIZE * SS - 1), fill=255)
        mask = mask.resize((SIZE, SIZE), Image.LANCZOS)
        crop.putalpha(ImageChops.multiply(crop.getchannel("A"), mask))
        crop.save(OUT / f"{cid}.png", optimize=True)
        print(cid, left, y0, side)


main()

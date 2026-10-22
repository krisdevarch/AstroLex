#!/usr/bin/env python3
"""Contact sheet: the 5 crew + 2 Catchers cropped to discs (~92%), 200 px each -> reports/WP-F.13/crew.jpg."""
import os
from PIL import Image, ImageDraw

root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
items = [("art/crew/rhee.png", "#F8BC04"), ("art/crew/ade.png", "#88FFEE"), ("art/crew/kit.png", "#FF88CC"),
         ("art/crew/vanta.png", "#C9374C"), ("art/crew/tomas.png", "#FF6B35"),
         ("brand/characters/wren.png", "#88FFEE"), ("brand/characters/pip.png", "#FF88CC")]
D = 200
sheet = Image.new("RGB", (D * len(items) + 10 * (len(items) + 1), D + 20), "#0f1426")
for k, (p, col) in enumerate(items):
    im = Image.open(os.path.join(root, "game", p)).convert("RGBA")
    s = min(im.size)
    inner = int(s * 0.92)
    l, t = (im.width - inner) // 2, (im.height - inner) // 2
    im = im.crop((l, t, l + inner, t + inner)).resize((D - 10, D - 10), Image.LANCZOS)
    tile = Image.new("RGBA", (D, D), (0, 0, 0, 0))
    d = ImageDraw.Draw(tile)
    d.ellipse((0, 0, D - 1, D - 1), fill=col)
    d.ellipse((4, 4, D - 5, D - 5), fill="#2a3150")
    mask = Image.new("L", (D, D), 0)
    ImageDraw.Draw(mask).ellipse((5, 5, D - 6, D - 6), fill=255)
    layer = Image.new("RGBA", (D, D), (0, 0, 0, 0))
    layer.paste(im, (5, 5), im)
    tile.paste(layer, (0, 0), Image.composite(layer.split()[3], Image.new("L", (D, D), 0), mask))
    sheet.paste(tile, (10 + k * (D + 10), 10), tile)
out = os.path.join(root, "reports", "WP-F.13", "crew.jpg")
os.makedirs(os.path.dirname(out), exist_ok=True)
sheet.save(out, quality=90)
print(out)

"""Paints the 5 placeholder stills of the Act III flashback (f1-f5) (WP-F.7) into game/art/stills/.
PIL only. Grey-toned silhouettes drawn from the captions in data/story/flashback.json; human art
replaces them.

    python3 scripts/art/make_stills.py

Deterministic.
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

W, H = 1080, 1920
OUT = Path(__file__).resolve().parents[2] / "game" / "art" / "stills"
INK = (18, 20, 26)


def G(v):
    return (v, v, v)


def lift(img):
    """Tone lift so the near-black drawings read on a phone in daylight: a gamma curve that keeps the
    blacks black and brings the mid greys up (the stills are drawn dark, like a storyboard)."""
    lut = [int(255 * (v / 255) ** 0.55) for v in range(256)] * 3
    return img.point(lut)


def canvas(top, bottom):
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        u = y / (H - 1)
        d.line([(0, y), (W, y)], fill=tuple(int(a + (b - a) * u) for a, b in zip(top, bottom)))
    return img


def person(d, x, base, h, col=INK, crouch=False):
    """A simple silhouette: head and body, feet at `base`, height h."""
    if crouch:
        h = int(h * 0.62)
    hr = h * 0.11
    d.ellipse([x - hr, base - h, x + hr, base - h + 2 * hr], fill=col)
    d.polygon([(x - hr * 1.5, base - h + 2.3 * hr), (x + hr * 1.5, base - h + 2.3 * hr), (x + hr * 1.9, base), (x - hr * 1.9, base)], fill=col)


def glow(img, box, col, r, ellipse=True):
    m = Image.new("L", (W, H), 0)
    dm = ImageDraw.Draw(m)
    (dm.ellipse if ellipse else dm.rectangle)(box, fill=255)
    m = m.filter(ImageFilter.GaussianBlur(r))
    img.paste(Image.new("RGB", (W, H), col), (0, 0), m)


def f1():
    img = canvas((24, 24, 30), (40, 40, 52))
    d = ImageDraw.Draw(img)
    for i in range(14):
        y = 80 + i * 130
        d.rounded_rectangle([90, y, 990, y + 100], 18, fill=G(60 + (i * 37) % 70))
        d.rectangle([120, y + 24, 120 + (i * 97) % 500 + 200, y + 40], fill=G(150))
    img = img.filter(ImageFilter.BoxBlur(14))
    glow(img, [0, 600, W, 1300], (70, 70, 120), 200)
    return img


def f2():
    img = canvas(G(10), G(16))
    glow(img, [200, 900, 880, 1500], G(120), 150)
    d = ImageDraw.Draw(img)
    d.rectangle([200, 1000, 880, 1500], fill=G(150))  # glowing screen
    person(d, 540, 1900, 760, G(6))
    d.ellipse([380, 1250, 460, 1330], fill=G(6))  # fists
    d.ellipse([620, 1250, 700, 1330], fill=G(6))
    return img


def f3():
    img = canvas(G(80), G(40))
    d = ImageDraw.Draw(img)
    d.polygon([(0, 900), (200, 600), (300, 1000), (480, 520), (700, 1050), (W, 700), (W, H), (0, H)], fill=G(30))
    person(d, 640, 1650, 900, G(8))
    d.rounded_rectangle([590, 1000, 690, 1130], 12, fill=G(200))  # the phone
    return img


def f4():
    img = canvas(G(40), G(24))
    glow(img, [560, 0, 740, 1500], G(110), 70, ellipse=False)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 1450, W, H], fill=G(16))
    d.rectangle([200, 1000, 260, 1450], fill=G(10))  # empty chair
    d.rectangle([200, 1000, 460, 1040], fill=G(10))
    d.rectangle([430, 1040, 460, 1450], fill=G(10))
    d.rectangle([640, 1330, 740, 1450], fill=G(70))  # cold cup
    return img


def f5():
    img = canvas(G(20), G(14))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 1250, W, H], fill=G(12))
    d.polygon([(140, 1300), (540, 1220), (540, 700), (140, 760)], fill=G(190))
    d.polygon([(540, 1220), (940, 1300), (940, 760), (540, 700)], fill=G(170))
    d.line([(540, 700), (540, 1220)], fill=G(90), width=6)
    d.ellipse([700, 900, 724, 924], fill=(232, 150, 40))  # one amber dot
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    root = OUT.parents[2]
    timing = {}  # game/data/stills.json: ids and seconds only (captions are for the artist)
    for key, src in (("flashback", "flashback.json"),):
        beats = json.loads((root / "data" / "story" / src).read_text())["stills"]
        timing[key] = [{"id": b["id"], "seconds": b["seconds"]} for b in beats]
    (root / "game" / "data" / "stills.json").write_text(json.dumps(timing, indent=1) + "\n")
    for name in ["f1", "f2", "f3", "f4", "f5"]:
        img = lift(globals()[name]()).filter(ImageFilter.GaussianBlur(1.2))
        img.save(OUT / f"{name}.jpg", quality=72, optimize=True)
        print(name, (OUT / f"{name}.jpg").stat().st_size)


if __name__ == "__main__":
    main()

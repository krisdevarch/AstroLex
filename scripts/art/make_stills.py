"""Paints the 12 placeholder stills of the Prologue (p1-p7) and the Act III flashback (f1-f5)
(WP-F.7) into game/art/stills/. PIL only. Grey-toned silhouettes drawn from the captions in
data/story/prologue_beats.json and flashback.json; human art replaces them.

    python3 scripts/art/make_stills.py

p7 carries a faint tint (cold blue, one amber glint) so the saturation shader has something to
bring back when the word water appears. Deterministic.
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


def earth(d, cx, cy, r, col):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)


def p1():
    img = canvas(G(26), G(44))
    d = ImageDraw.Draw(img)
    d.rectangle([140, 380, 940, 1300], fill=G(12))  # open window onto the night
    earth(d, 540, 1100, 420, G(58))
    for i in range(30):
        d.point([(200 + i * 25) % 900 + 150, 420 + (i * 83) % 300], fill=G(170))
    d.rectangle([0, 1300, W, H], fill=G(22))
    person(d, 540, 1500, 700, G(8))
    d.line([(600, 900), (760, 840)], fill=G(70), width=5)  # the thin line of breath
    return img


def p2():
    img = canvas(G(30), G(20))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 1100, W, H], fill=G(14))  # sill
    d.rounded_rectangle([300, 780, 780, 1100], 40, fill=G(52))  # radio
    d.ellipse([360, 840, 560, 1040], fill=G(30))
    d.rectangle([620, 840, 730, 880], fill=G(26))
    d.line([(700, 780), (860, 420)], fill=G(60), width=10)  # antenna
    d.ellipse([520, 1000, 800, 1160], fill=G(10))  # resting hand
    return img


def p3():
    img = canvas(G(70), G(40))
    d = ImageDraw.Draw(img)
    for x in range(0, W, 220):
        d.rectangle([x, 500 + (x % 3) * 60, x + 180, 1400], fill=G(46))
    d.rectangle([0, 1400, W, H], fill=G(28))
    person(d, 360, 1700, 800, G(10), crouch=True)
    person(d, 720, 1700, 520, G(10))
    d.line([(430, 1180), (620, 1150)], fill=G(220), width=14)  # the pointing hand
    return img


def p4():
    img = canvas(G(80), G(44))
    d = ImageDraw.Draw(img)
    d.polygon([(0, 700), (W, 700), (W, H), (0, H)], fill=G(36))
    d.polygon([(380, 700), (700, 700), (1000, H), (80, H)], fill=G(30))
    for i, x in enumerate((140, 250, 380, 480, 620, 720, 840, 940)):
        person(d, x, 1150 + i % 3 * 120, 330 + i % 3 * 90, G(14))
    d.ellipse([480, 1130, 540, 1190], fill=G(245))  # only the pointing hand is white
    return img


def p5():
    img = canvas(G(22), G(30))
    d = ImageDraw.Draw(img)
    d.ellipse([160, 340, 920, 1100], fill=G(60), outline=G(90), width=18)  # round window
    earth(d, 540, 900, 300, G(46))
    person(d, 330, 1500, 820, G(8))
    d.line([(400, 800), (480, 700)], fill=G(8), width=24)  # palm on the glass
    for i in range(7):  # stacked cards
        d.rectangle([620, 1450 - i * 22, 940, 1470 - i * 22], fill=G(100 + i * 6))
    d.ellipse([760, 1080, 840, 1120], fill=G(18))  # lamp, off
    return img


def tile(img, cx, cy, s, rot=0.0):
    t = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    dt = ImageDraw.Draw(t)
    dt.rounded_rectangle([0, 0, s - 1, s - 1], s // 6, fill=G(190))
    dt.rounded_rectangle([s // 12, s // 12, s - s // 12, s - s // 12], s // 8, fill=G(230))
    t = t.rotate(rot, expand=True, resample=Image.BICUBIC)
    glow(img, [cx - s, cy - s, cx + s, cy + s], G(70), s * 0.6)
    img.paste(t, (int(cx - t.width / 2), int(cy - t.height / 2)), t)


def stars(d, col):
    for i in range(60):
        d.point([((i * 197) % W, (i * 331) % H)], fill=col)


def p6():
    img = canvas(G(4), G(10))
    stars(ImageDraw.Draw(img), G(120))
    tile(img, 190, 900, 190, 18)
    return img


def p7():
    img = canvas((8, 12, 22), (18, 22, 34))
    stars(ImageDraw.Draw(img), (150, 160, 200))
    glow(img, [200, 560, 880, 1340], (60, 80, 140), 160)
    glow(img, [500, 140, 580, 200], (230, 160, 60), 30)
    return img


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
    for key, src in (("prologue", "prologue_beats.json"), ("flashback", "flashback.json")):
        beats = json.loads((root / "data" / "story" / src).read_text())["stills"]
        timing[key] = [{"id": b["id"], "seconds": b["seconds"]} for b in beats]
    (root / "game" / "data" / "stills.json").write_text(json.dumps(timing, indent=1) + "\n")
    for name in ["p1", "p2", "p3", "p4", "p5", "p6", "p7", "f1", "f2", "f3", "f4", "f5"]:
        img = lift(globals()[name]()).filter(ImageFilter.GaussianBlur(1.2))
        img.save(OUT / f"{name}.jpg", quality=72, optimize=True)
        print(name, (OUT / f"{name}.jpg").stat().st_size)


if __name__ == "__main__":
    main()

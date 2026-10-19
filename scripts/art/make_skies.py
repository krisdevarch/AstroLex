"""Painted the placeholder Act II-IV backdrops (WP-F.3). PIL only. Retired 19 Oct 2026: all four
acts now use the owner's paintings in game/art/backdrop/, so running this writes nothing.

    python3 scripts/art/make_skies.py

Each is 1080x1920 with a dark curved horizon whose crest sits at y=1540 (HORIZON), so the HUD
curve lines up the way it does on low_orbit.jpg. Seeded: reruns give identical pictures.
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

W, H, HORIZON = 1080, 1920, 1540
OUT = Path(__file__).resolve().parents[2] / "game" / "art" / "backdrop"


def gradient(stops):
    """Vertical gradient from [(y_fraction, (r,g,b)), ...]."""
    img = Image.new("RGB", (W, H))
    px = ImageDraw.Draw(img)
    for y in range(H):
        f = y / (H - 1)
        for (f0, c0), (f1, c1) in zip(stops, stops[1:]):
            if f0 <= f <= f1:
                u = (f - f0) / max(1e-6, f1 - f0)
                px.line([(0, y), (W, y)], fill=tuple(int(a + (b - a) * u) for a, b in zip(c0, c1)))
                break
    return img


def glow(img, colour, shapes, blur, alpha=1.0):
    """Paint blurred shapes (callable taking an ImageDraw) in a colour."""
    mask = Image.new("L", (W, H), 0)
    shapes(ImageDraw.Draw(mask))
    mask = mask.filter(ImageFilter.GaussianBlur(blur)).point(lambda v: int(v * alpha))
    img.paste(Image.new("RGB", (W, H), colour), (0, 0), mask)


def blobs(img, rng, colour, n, box, rmin, rmax, blur, alpha):
    def shapes(d):
        for _ in range(n):
            x, y = rng.randint(box[0], box[2]), rng.randint(box[1], box[3])
            r = rng.randint(rmin, rmax)
            d.ellipse([x - r * 1.6, y - r * 0.7, x + r * 1.6, y + r * 0.7], fill=255)
    glow(img, colour, shapes, blur, alpha)


def stars(img, rng, n, ymax, band=None):
    """Scattered stars; `band` = (x0,y0,x1,y1,width) adds a denser diagonal star band."""
    d = ImageDraw.Draw(img)
    for i in range(n):
        if band and i % 2 == 0:
            t = rng.random()
            x = band[0] + (band[2] - band[0]) * t + rng.gauss(0, band[4])
            y = band[1] + (band[3] - band[1]) * t + rng.gauss(0, band[4])
        else:
            x, y = rng.randint(0, W), rng.randint(0, ymax)
        if not (0 <= x < W and 0 <= y < ymax):
            continue
        v = rng.randint(150, 255)
        r = 1 if rng.random() < 0.85 else 2
        d.ellipse([x - r, y - r, x + r, y + r], fill=(v, v, min(255, v + 15)))


def horizon(img, body, rim, rim_alpha=0.9):
    """A dark curved limb: crest at y=HORIZON mid-screen, falling away to the sides."""
    def shapes(d):
        d.ellipse([-1500, HORIZON - 6, W + 1500, HORIZON + 2600], fill=255)
    glow(img, rim, shapes, 14, rim_alpha)
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).ellipse([-1500, HORIZON + 4, W + 1500, HORIZON + 2610], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(1.5))
    below = gradient([(0, body), (1, tuple(int(c * 0.55) for c in body))])
    img.paste(below, (0, 0), mask)


def nebula():
    rng = random.Random(2)
    img = gradient([(0, (28, 12, 52)), (0.45, (78, 30, 96)), (0.8, (150, 60, 120)), (1, (60, 24, 70))])
    blobs(img, rng, (226, 110, 170), 9, (60, 200, 1020, 1200), 90, 200, 70, 0.55)
    blobs(img, rng, (140, 90, 220), 9, (60, 100, 1020, 1300), 80, 190, 60, 0.5)
    blobs(img, rng, (250, 170, 210), 4, (200, 700, 900, 1250), 50, 110, 50, 0.35)
    stars(img, rng, 700, HORIZON, band=(1100, 60, -60, 760, 150))
    # drifting shapes: pale rock slivers and a ringed moon
    d = ImageDraw.Draw(img)
    for _ in range(9):
        x, y, r = rng.randint(80, 1000), rng.randint(300, 1250), rng.randint(14, 40)
        d.polygon([(x + r * math.cos(a) * rng.uniform(.7, 1.2), y + r * 0.7 * math.sin(a) * rng.uniform(.7, 1.2))
                   for a in [i * math.tau / 7 for i in range(7)]], fill=(70, 38, 80), outline=(190, 120, 170))
    d.ellipse([760, 330, 900, 470], fill=(196, 150, 200), outline=(250, 210, 240))
    d.arc([715, 380, 945, 420], 0, 360, fill=(250, 220, 240), width=5)
    horizon(img, (40, 18, 48), (240, 130, 160))
    return img


def tower():
    rng = random.Random(3)
    img = gradient([(0, (30, 40, 58)), (0.5, (80, 98, 120)), (0.8, (128, 142, 158)), (1, (60, 68, 82))])
    blobs(img, rng, (150, 170, 190), 10, (0, 300, 1080, 1300), 90, 200, 70, 0.4)
    stars(img, rng, 450, 900, band=(-60, 120, 1100, 640, 120))
    d = ImageDraw.Draw(img)
    # the tower: a tall stepped silhouette rising out of the horizon, off-centre
    cx = 600
    seg = [(150, 1400, 0), (112, 1130, 400), (84, 800, 330), (58, 520, 280), (32, 330, 190)]
    for half, top, _ in seg:
        d.rectangle([cx - half, top, cx + half, HORIZON + 60], fill=(18, 22, 34))
    d.rectangle([cx - 4, 140, cx + 4, 340], fill=(18, 22, 34))
    d.ellipse([cx - 9, 126, cx + 9, 144], fill=(255, 170, 70))
    for half, top, _ in seg[:-1]:  # little shoulders
        d.polygon([(cx - half - 22, top + 24), (cx - half, top), (cx + half, top), (cx + half + 22, top + 24)], fill=(18, 22, 34))
    for y in range(360, 1500, 46):  # amber windows, thinner towards the top
        half = next(h for h, t, _ in reversed(seg) if t <= y + 20) if y > 330 else 0
        for x in range(cx - half + 16, cx + half - 14, 30):
            if rng.random() < 0.38:
                d.rectangle([x, y, x + 12, y + 20], fill=(255, rng.randint(160, 200), 80))
    glow(img, (255, 170, 70), lambda dd: [dd.rectangle([cx - 120, 420, cx + 120, 1500], fill=70)], 60, 0.25)
    horizon(img, (22, 26, 38), (150, 175, 205), 0.8)
    return img


def core():
    rng = random.Random(4)
    cx, cy = 540, 1180
    img = gradient([(0, (18, 14, 52)), (0.5, (52, 50, 130)), (0.8, (104, 106, 190)), (1, (30, 26, 80))])
    glow(img, (170, 175, 255), lambda d: d.ellipse([cx - 330, cy - 330, cx + 330, cy + 330], fill=255), 120, 0.9)
    stars(img, rng, 450, 1000, band=(-60, 700, 1100, 100, 130))
    ring = Image.new("L", (W, H), 0)
    rd = ImageDraw.Draw(ring)
    for i, r in enumerate(range(120, 1400, 118)):
        rd.ellipse([cx - r, cy - r, cx + r, cy + r], outline=max(40, 210 - i * 14), width=4 + (i % 3) * 2)
    img.paste(Image.new("RGB", (W, H), (190, 195, 255)), (0, 0), ring.filter(ImageFilter.GaussianBlur(1.2)))
    glow(img, (240, 240, 255), lambda d: d.ellipse([cx - 90, cy - 90, cx + 90, cy + 90], fill=255), 34, 1.0)
    d = ImageDraw.Draw(img)
    d.ellipse([cx - 46, cy - 46, cx + 46, cy + 46], fill=(255, 255, 255))
    # glitch slivers: slices of the sky shifted sideways, with cyan/pink fringes
    for _ in range(14):
        y, h = rng.randint(80, 1400), rng.randint(6, 30)
        dx = rng.choice([-1, 1]) * rng.randint(20, 120)
        strip = img.crop((0, y, W, y + h))
        img.paste(ImageChops.offset(strip, dx, 0), (0, y))
        d.rectangle([0, y, rng.randint(80, 400), y + 2], fill=(120, 240, 255))
        d.rectangle([W - rng.randint(80, 400), y + h - 2, W, y + h], fill=(255, 110, 200))
    horizon(img, (14, 12, 40), (150, 155, 255), 0.7)
    return img


if __name__ == "__main__":
    for name, fn in []:  # was act2_nebula, act3_tower, act4_core
        path = OUT / f"{name}.jpg"
        for q in (88, 80, 72, 64):
            fn().save(path, quality=q, optimize=True)
            if path.stat().st_size < 400_000:
                break
        print(path.name, path.stat().st_size // 1024, "KB q", q)

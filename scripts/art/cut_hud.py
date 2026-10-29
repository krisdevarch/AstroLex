"""SUPERSEDED for the console, buttons and bulb (WP-F.28): they are now vector art, see
scripts/art/hud/gen_hud_svgs.py and scripts/art/make_hud.sh. Kept for reference.

Cuts the play-screen HUD art out of the owner's target mock (19 Oct 2026, 572x1024).

  python3 scripts/art/cut_hud.py <mock.jpeg> [out_dir]   # default out_dir: game/art/hud

The owner asked for the console to be a pixel-perfect copy of the mock, so the console tray (porthole,
slot screen, cables and the clock bar), the three round buttons and the hint bulb are taken from the
mock itself, upscaled to the game's 1080-wide pixels. Everything that changes in play is cleaned out
of the art and drawn by the game: the astronaut in the porthole (the Catcher goes there), the letter
tiles, wires and slots in the screen, the clock liquid, and the button icons (kept in the *_icon
copies). Masks are built from the mock's own shapes, measured in mock pixels (MOCK_* in field.gd).
Needs numpy, Pillow and opencv-python-headless.
"""
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageFilter

K = 1080.0 / 572.0  # mock px -> game px
SS = 4  # mask supersampling

PORT = (83.5, 832.5)  # porthole centre
PORT_R = 80.0
WINDOW_R = 55.0  # the porthole's screen, where the Catcher sits
SCREEN = (174, 777, 459, 904)  # slot screen inner area (x0, y0, x1, y1)
BAR = (59, 955.5, 468.5, 1005.0)  # clock bar outer
CHANNEL = (72, 964, 461, 997)  # clock bar inner channel
BUTTONS = {"pause": (526.3, 793.0), "sound": (526.3, 874.0), "settings": (526.3, 955.0)}
BTN_R = 37.0
FILL_R = 23.0  # the icons end inside this; the neon ring starts at 24
FILL_R = 23.0  # the icons end inside this; the neon ring starts at 24
BULB = (497, 650, 551, 741)
CABLES = [
    [(17, 893), (9, 905), (6, 920), (7, 935), (12, 946), (20, 953), (35, 961), (50, 966), (61, 970)],
    [(17, 893), (14, 910), (14, 930), (17, 946)],
    [(17, 953), (20, 963), (27, 975), (40, 985), (60, 989)],
]


def luma(a):
    return a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114


def body_outline(L):
    """Per column top and bottom ink of the tray body, and per row its right edge (mock px)."""
    tops, bots = {}, {}
    for x in range(140, 466):
        top = next((y for y in range(745, 800) if L[y, x] < 45 and L[y - 2, x] > 60), None)
        # The bottom rim: a lighter row over the outline ink. The lowest such ink above the clock bar
        # is the body's edge (higher hits are the inner lip).
        hits = [y for y in range(915, 941) if L[y, x] < 20 and max(L[y - 1, x], L[y - 2, x]) > 50]
        tops[x] = top
        bots[x] = hits[-1] if hits else np.nan
    xs = sorted(tops)
    t = np.array([tops[x] if tops[x] is not None else np.nan for x in xs], float)
    t = np.where(np.isnan(t), np.nanmedian(t), t)
    b = np.array([bots[x] for x in xs], float)
    b = np.interp(np.arange(len(b)), np.flatnonzero(~np.isnan(b)), b[~np.isnan(b)])
    from_median = lambda v: np.array([np.median(v[max(0, i - 3):i + 4]) for i in range(len(v))])
    t, b = from_median(t), from_median(b)
    rights = {}
    for y in range(int(t[-1]), int(b[-1]) + 1):
        r = next((x for x in range(482, 440, -1) if L[y, x] < 30 and L[y, x + 2] > 55), None)
        if r is not None:
            rights[y] = r
    return xs, t, b, rights


def console_mask(L, w, h):
    m = np.zeros((h * SS, w * SS), np.uint8)
    s = lambda p: (int(round(p[0] * SS)), int(round(p[1] * SS)))
    cv2.circle(m, s(PORT), int(PORT_R * SS), 255, -1, cv2.LINE_AA)
    collar = np.zeros_like(m)
    cv2.circle(collar, s(PORT), int(101 * SS), 255, -1, cv2.LINE_AA)
    collar[: 866 * SS] = 0
    collar[:, : 8 * SS] = 0
    collar[:, 160 * SS:] = 0
    m = np.maximum(m, collar)
    xs, t, b, rights = body_outline(L)
    pts = [(x, t[i] - 0.5) for i, x in enumerate(xs)]
    ys = sorted(rights)
    pts += [(rights[y] + 1.5, y) for y in ys]
    pts += [(x, b[i] + 1.5) for i, x in reversed(list(enumerate(xs)))]
    poly = np.array([s(p) for p in pts], np.int32)
    cv2.fillPoly(m, [poly], 255, cv2.LINE_AA)
    # Close the gap between the porthole and the body's left end.
    cv2.rectangle(m, s((120, t[0] + 2)), s((150, b[0])), 255, -1)
    for line in CABLES:
        cv2.polylines(m, [np.array([s(p) for p in line], np.int32)], False, 255, int(7 * SS), cv2.LINE_AA)
    cv2.rectangle(m, s((58, 963)), s((68, 995)), 255, -1)
    x0, y0, x1, y1 = BAR
    r = (y1 - y0) / 2
    cv2.rectangle(m, s((x0, y0)), s((x1 - r, y1)), 255, -1)
    cv2.circle(m, s((x1 - r, (y0 + y1) / 2)), int(r * SS), 255, -1, cv2.LINE_AA)
    for lx0, lx1 in ((117, 129.5), (421.5, 439)):
        cv2.rectangle(m, s((lx0, y1 - 2)), s((lx1, 1024)), 255, -1)
    return m


def fill_rows(a, x0, y0, x1, y1, left, right, shape=None):
    """Repaints a rectangle row by row, blending from samples at its left and right margins."""
    for y in range(y0, y1):
        lc = np.median(a[y, left[0]:left[1]], axis=0)
        rc = np.median(a[y, right[0]:right[1]], axis=0)
        for x in range(x0, x1):
            if shape is not None and not shape(x, y):
                continue
            u = (x - x0) / max(1, x1 - x0 - 1)
            a[y, x] = lc * (1 - u) + rc * u


def is_teal(px):
    r, g, b = px
    return g > r + 35 and b > r + 35 and 45 < r * 0.3 + g * 0.6 + b * 0.1 < 150


def fill_window(a, mock):
    """The porthole screen without the astronaut: each row takes the median of its clean teal
    pixels, which keeps the screen's scan lines and its top-to-bottom shading."""
    cx, cy = PORT
    r = WINDOW_R - 2.5
    rows = {}
    for y in range(int(cy - r), int(cy + r) + 1):
        half = (r * r - (y - cy) ** 2) ** 0.5
        px = [mock[y, x] for x in range(int(cx - half), int(cx + half) + 1) if is_teal(mock[y, x])]
        if len(px) >= 6:
            rows[y] = np.median(np.array(px), axis=0)
    ys = np.array(sorted(rows))
    for y in range(int(cy - r), int(cy + r) + 1):
        c = np.array([np.interp(y, ys, [rows[v][i] for v in ys]) for i in range(3)])
        for x in range(int(cx - r - 1), int(cx + r) + 2):
            d = ((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2) ** 0.5
            k = np.clip(r + 0.5 - d, 0.0, 1.0)
            if k > 0:
                # Slightly darker toward the rim, as in the mock.
                shade = 1.0 - 0.12 * (d / r) ** 2
                a[y, x] = a[y, x] * (1 - k) + c * shade * k


def up(a, mask_ss, box):
    """Crops box (mock px) from art + mask, upscales to game px, returns RGBA."""
    x0, y0, x1, y1 = box
    rgb = Image.fromarray(a[y0:y1, x0:x1].astype(np.uint8))
    size = (round((x1 - x0) * K), round((y1 - y0) * K))
    rgb = rgb.resize(size, Image.LANCZOS).filter(ImageFilter.UnsharpMask(2, 70, 2))
    m = Image.fromarray(mask_ss[y0 * SS:y1 * SS, x0 * SS:x1 * SS]).resize(size, Image.LANCZOS)
    out = rgb.convert("RGBA")
    out.putalpha(m)
    return out


def main():
    mock = np.asarray(Image.open(sys.argv[1]).convert("RGB")).astype(float)
    out = Path(sys.argv[2] if len(sys.argv) > 2 else "game/art/hud")
    out.mkdir(parents=True, exist_ok=True)
    h, w = mock.shape[:2]
    L = luma(mock)
    art = mock.copy()
    # Porthole screen: the astronaut out, the teal scan lines kept (sampled at the screen's edges).
    cx, cy = PORT
    fill_window(art, mock)
    # Slot screen: tiles, wires and slots out.
    sx0, sy0, sx1, sy1 = SCREEN
    fill_rows(art, sx0 + 8, sy0 + 3, sx1 - 6, sy1 - 3, (sx0 + 3, sx0 + 8), (sx1 - 6, sx1 - 2))
    # Clock bar: the liquid out; the channel takes the colour of its empty right end.
    cx0, cy0, cx1, cy1 = CHANNEL
    ch = art[cy0:cy1, 420:452].copy()
    for y in range(cy0 + 1, cy1 - 1):
        c = np.median(ch[y - cy0], axis=0)
        for x in range(cx0 + 2, 410):
            art[y, x] = c
    mask = console_mask(L, w, h)
    up(art, mask, (0, 742, 482, 1024)).save(out / "console.png")
    # Buttons, with and without their icons.
    for name, (bx, by) in BUTTONS.items():
        bm = np.zeros((h * SS, w * SS), np.uint8)
        cv2.circle(bm, (int(bx * SS), int(by * SS)), int(BTN_R * SS), 255, -1, cv2.LINE_AA)
        box = (int(bx - BTN_R - 2), int(by - BTN_R - 2), int(bx + BTN_R + 3), int(by + BTN_R + 3))
        up(mock, bm, box).save(out / f"btn_{name}_icon.png")
        blank = mock.copy()
        # Each ring glows a little into its disc, so the blank disc follows the ring's own radial
        # profile: per radius, the median of the pixels that are not icon (icons are the bright ones).
        prof = {}
        for yy in range(int(by - FILL_R - 2), int(by + FILL_R + 3)):
            for xx in range(int(bx - FILL_R - 2), int(bx + FILL_R + 3)):
                d = ((xx + 0.5 - bx) ** 2 + (yy + 0.5 - by) ** 2) ** 0.5
                if d <= FILL_R + 1 and luma(mock[yy, xx]) < 75:
                    prof.setdefault(int(d), []).append(mock[yy, xx])
        rs = sorted(r for r in prof if len(prof[r]) >= 5)
        med = np.array([np.median(np.array(prof[r]), axis=0) for r in rs])
        for yy in range(int(by - FILL_R - 1), int(by + FILL_R + 2)):
            for xx in range(int(bx - FILL_R - 1), int(bx + FILL_R + 2)):
                d = ((xx + 0.5 - bx) ** 2 + (yy + 0.5 - by) ** 2) ** 0.5
                k = np.clip(FILL_R + 0.5 - d, 0.0, 1.0)
                if k > 0:
                    c = np.array([np.interp(d, rs, med[:, i]) for i in range(3)])
                    blank[yy, xx] = blank[yy, xx] * (1 - k) + c * k
        up(blank, bm, box).save(out / f"btn_{name}.png")
    # Hint bulb: the glass and the screw base.
    bm = np.zeros((h * SS, w * SS), np.uint8)
    cv2.circle(bm, (int(523.2 * SS), int(678.5 * SS)), int(24.8 * SS), 255, -1, cv2.LINE_AA)
    cv2.ellipse(bm, (int(523.2 * SS), int(700 * SS)), (int(14 * SS), int(10 * SS)), 0, 0, 360, 255, -1, cv2.LINE_AA)
    base = np.array([(509.5, 703), (537, 703), (535.5, 733), (530, 739.5), (516.5, 739.5), (511, 733)]) * SS
    cv2.fillPoly(bm, [base.astype(np.int32)], 255, cv2.LINE_AA)
    up(mock, bm, BULB).save(out / "bulb.png")
    print("wrote", sorted(p.name for p in out.glob("*.png")))


if __name__ == "__main__":
    main()

"""Generates the intro screen art (WP-F.28) into game/art/intro/.

  python3 scripts/art/make_intro.py [out_dir] [--characters DIR]

  sky.jpg    1080x1920  deep-blue starfield with a diagonal nebula band of star dust
  logo.png   1300 px    chrome "AstroLex" wordmark (Fredoka Bold, outline, cyan glow, magenta underside)
  <id>.png   640 px     the four Catchers as busts in glass bubbles (cut from the 1024 px Catcher art)

Reproducible (fixed seed). Uses only game/fonts/Fredoka.ttf and the four Catcher PNGs
(default /mnt/project-files/design/characters). Needs numpy, Pillow and opencv-python-headless.
"""
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
FONT = ROOT / "game/fonts/Fredoka.ttf"
SEED = 2810
W, H = 1080, 1920


def blur(a, s):
    return cv2.GaussianBlur(a, (0, 0), s)


def fbm(rng, shape, base, octaves=5, gain=0.55):
    """Smooth value noise in [0,1]: sum of upsampled random grids."""
    h, w = shape
    out = np.zeros(shape, np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        n = base * (2 ** o)
        g = rng.random((int(n * h / w) + 3, n + 3)).astype(np.float32)
        up = cv2.resize(g, (w, h), interpolation=cv2.INTER_CUBIC)
        out += amp * up
        tot += amp
        amp *= gain
    out /= tot
    return np.clip((out - out.min()) / (out.max() - out.min()), 0, 1)


def screen_blend(base, add):
    return 1 - (1 - base) * (1 - np.clip(add, 0, 1))


def sparkle(img, cx, cy, r, color, rng):
    """Additive 4-point star with a soft core."""
    x0, x1 = int(max(cx - r * 1.2, 0)), int(min(cx + r * 1.2, img.shape[1]))
    y0, y1 = int(max(cy - r * 1.2, 0)), int(min(cy + r * 1.2, img.shape[0]))
    if x1 <= x0 or y1 <= y0:
        return
    yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
    dx, dy = np.abs(xx - cx), np.abs(yy - cy)
    thin = r * 0.045
    arm = np.exp(-(dy / thin) ** 2) * np.clip(1 - dx / r, 0, 1) ** 2 + np.exp(-(dx / thin) ** 2) * np.clip(1 - dy / r, 0, 1) ** 2
    core = np.exp(-((dx ** 2 + dy ** 2) / (r * 0.16) ** 2))
    glow = np.exp(-((dx ** 2 + dy ** 2) / (r * 0.5) ** 2)) * 0.25
    v = np.clip(arm + core + glow, 0, 1.4)[..., None]
    img[y0:y1, x0:x1] = screen_blend(img[y0:y1, x0:x1], v * np.array(color, np.float32))


def make_sky(out):
    rng = np.random.default_rng(SEED)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    # deep navy base, a touch lighter in the middle
    t = yy / H
    img = np.zeros((H, W, 3), np.float32)
    img[..., 0] = 0.020 + 0.03 * np.sin(t * np.pi)
    img[..., 1] = 0.055 + 0.05 * np.sin(t * np.pi)
    img[..., 2] = 0.20 + 0.09 * np.sin(t * np.pi)
    # broad cloudy colour variation
    cl = fbm(rng, (H, W), 3, 5)
    img += (cl[..., None] - 0.5) * np.array([0.05, 0.03, 0.10], np.float32)

    # band: line from top-left to bottom-right, bending slightly
    ang = np.arctan2(1500, 780)
    nx, ny = -np.sin(ang), np.cos(ang)
    cx0, cy0 = W * 0.50, H * 0.50
    wob = (fbm(rng, (H, W), 2, 3) - 0.5) * 220
    d = (xx - cx0) * nx + (yy - cy0) * ny + wob
    along = (xx - cx0) * np.cos(ang) + (yy - cy0) * np.sin(ang)
    taper = np.clip(1.15 - np.abs(along) / 1450, 0.25, 1)
    core = np.exp(-(d / (120 * taper)) ** 2)
    halo = np.exp(-(d / (330 * taper)) ** 2)
    n1 = fbm(rng, (H, W), 5, 6, 0.62)
    n2 = fbm(rng, (H, W), 9, 5, 0.6)
    filament = np.clip((n1 - 0.30) * 2.8, 0, 1)
    dust = halo * (0.45 + 0.95 * n2) + core * (0.5 + filament) * 0.9
    mixc = fbm(rng, (H, W), 3, 3)[..., None]
    purple = np.array([0.42, 0.22, 0.85], np.float32)
    cyan = np.array([0.18, 0.62, 1.00], np.float32)
    magenta = np.array([0.80, 0.30, 0.85], np.float32)
    tint = purple * (1 - mixc) + cyan * mixc
    tint = tint * 0.82 + magenta * 0.18 * (1 - mixc)
    img = screen_blend(img, tint * (dust * 1.0)[..., None])
    # luminous cool core
    img = screen_blend(img, (np.array([0.35, 0.65, 1.0], np.float32) * (core * (0.4 + filament) * 0.5)[..., None]))
    # blue-white heart of the river
    heart = np.exp(-(d / (45 * taper)) ** 2) * (0.35 + 0.65 * n2)
    img = screen_blend(img, np.array([0.65, 0.88, 1.0], np.float32) * (heart * 0.28)[..., None])

    # stars: sparse background + dense dust in the band
    star = np.zeros((H, W), np.float32)
    n_bg = 1100
    px = rng.integers(0, W, n_bg)
    py = rng.integers(0, H, n_bg)
    star[py, px] = rng.random(n_bg) ** 3 * 0.9 + 0.1
    prob = np.clip(halo * 1.0 + core * 1.4, 0, 1) ** 1.1
    r = rng.random((H, W))
    dense = (r < prob * 0.075).astype(np.float32) * (rng.random((H, W)) ** 2.2)
    star = np.maximum(star, dense * 1.3)
    tiny = star.copy()
    soft = blur(star, 0.7) * 2.6
    soft = np.clip(soft, 0, 1)
    sc = rng.random((H, W, 3)).astype(np.float32)
    starcol = np.array([0.80, 0.90, 1.0], np.float32) * (0.75 + 0.25 * sc)
    # bluer inside the band
    starcol = starcol * (1 - 0.5 * halo[..., None]) + np.array([0.55, 0.85, 1.0], np.float32) * 0.5 * halo[..., None]
    img = screen_blend(img, soft[..., None] * starcol * 1.15)
    img = screen_blend(img, blur(tiny, 2.2)[..., None] * 2.5 * starcol * 0.5)

    # brighter mid stars with halos
    for _ in range(70):
        x, y = rng.random() * W, rng.random() * H
        s = rng.random() ** 2 * 3.2 + 1.2
        yy0, xx0 = int(y), int(x)
        pt = np.zeros((H, W), np.float32)
        pt[yy0 % H, xx0 % W] = 1
        img = screen_blend(img, (blur(pt, s) * s * s * 3.0)[..., None] * np.array([0.7, 0.85, 1.0], np.float32) * 0.35)

    # 4-point sparkles, more of them near the band
    cols = [(0.75, 0.95, 1.0), (0.9, 0.85, 1.0), (1.0, 1.0, 1.0)]
    placed = 0
    while placed < 26:
        x, y = rng.random() * W, rng.random() * H
        dd = abs((x - cx0) * nx + (y - cy0) * ny)
        if dd > 420 and rng.random() < 0.7:
            continue
        sparkle(img, x, y, 12 + rng.random() ** 2 * 34, cols[rng.integers(0, 3)], rng)
        placed += 1

    # vignette
    vx = (xx - W / 2) / (W * 0.75)
    vy = (yy - H / 2) / (H * 0.7)
    img *= (1 - 0.38 * np.clip(vx ** 2 + vy ** 2, 0, 1.4))[..., None]
    # film grain to avoid banding
    img += (rng.random((H, W, 1)).astype(np.float32) - 0.5) * 0.012
    Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8)).save(out / "sky.jpg", quality=88, subsampling=0, optimize=True)


# ---------------------------------------------------------------------------------------------
def dilate(mask, r):
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1, 2 * r + 1))
    return cv2.dilate(mask, k)


def make_logo(out):
    text = "AstroLex"
    size = 560
    f = ImageFont.truetype(str(FONT), size)
    f.set_variation_by_axes([700, 100])
    pad = 150
    tw = f.getbbox(text)
    w, h = tw[2] - tw[0] + 2 * pad, tw[3] - tw[1] + 2 * pad
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).text((pad - tw[0], pad - tw[1]), text, font=f, fill=255)
    # slight italic skew
    sk = 0.16
    m = m.transform((w + int(h * sk), h), Image.AFFINE, (1, sk, -h * sk, 0, 1, 0), Image.BICUBIC)
    w = m.size[0]
    a = np.asarray(m, np.float32) / 255
    u8 = (a * 255).astype(np.uint8)

    ys, xs = np.nonzero(a > 0.5)
    y0, y1 = ys.min(), ys.max()
    v = np.clip((np.arange(h, dtype=np.float32) - y0) / (y1 - y0), 0, 1)[:, None]
    # chrome: bright sky on top, dark horizon line, pale underside
    stops = [
        (0.00, (0.97, 0.99, 1.00)),
        (0.30, (0.78, 0.84, 0.92)),
        (0.47, (0.38, 0.45, 0.58)),
        (0.52, (0.20, 0.26, 0.40)),
        (0.58, (0.60, 0.74, 0.88)),
        (0.80, (0.84, 0.90, 0.96)),
        (1.00, (0.60, 0.70, 0.84)),
    ]
    px = np.array([s[0] for s in stops])
    col = np.stack([np.interp(v[:, 0], px, [s[1][c] for s in stops]) for c in range(3)], 1).astype(np.float32)
    fill = np.repeat(col[:, None, :], w, 1)
    # bevel: light from top-left via a blurred height map
    hm = blur(a, 7)
    gy, gx = np.gradient(hm)
    shade = np.clip(-(gx * 0.7 + gy * 0.9) * 7.5, -0.5, 0.6)[..., None]
    fill = np.clip(fill + shade * (a[..., None] > 0.5) * 0.9, 0, 1)
    # inner dark-blue edge line
    inner = blur(a, 3)
    edge = np.clip((0.75 - inner) * 3.2, 0, 1) * (a > 0.01)
    fill = fill * (1 - 0.55 * edge[..., None]) + np.array([0.2, 0.3, 0.5], np.float32) * 0.55 * edge[..., None]

    # outline (dark navy), then neon cyan ring, then glow
    o1 = dilate(u8, 24)
    o1a = blur(o1.astype(np.float32) / 255, 1.6)
    ring_o = dilate(u8, 36)
    ring_a = blur(ring_o.astype(np.float32) / 255, 1.6)
    glow = blur(dilate(u8, 30).astype(np.float32) / 255, 30)


    canvas = np.zeros((h, w, 4), np.float32)

    def over(rgb, alpha):
        al = alpha[..., None]
        oa = canvas[..., 3:4]
        na = al + oa * (1 - al)
        rgb = np.asarray(rgb, np.float32)
        canvas[..., :3] = (rgb * al + canvas[..., :3] * oa * (1 - al)) / np.maximum(na, 1e-6)
        canvas[..., 3:4] = na

    over((0.15, 0.80, 1.0), np.clip(glow * 1.5, 0, 1))
    over((0.12, 0.70, 1.0), np.clip(ring_a - o1a, 0, 1) * 0.9)  # cyan neon ring
    over((0.05, 0.08, 0.24), o1a)  # dark navy outline
    # magenta rim at the lower edge of the outline
    low = np.clip(o1a - np.roll(o1a, -16, 0), 0, 1)
    over((1.0, 0.30, 0.88), np.clip(low * 3.0, 0, 1))
    over(fill, a)
    # top gleam on the letters
    top = np.clip(a - np.roll(a, 7, 0), 0, 1)
    over((1, 1, 1), np.clip(top * 1.2, 0, 1) * 0.5)

    img = Image.fromarray((np.clip(canvas, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA")
    img = img.crop(img.getbbox())
    k = LOGO_PX / img.size[0]
    img = img.resize((LOGO_PX, round(img.size[1] * k)), Image.LANCZOS)
    img.save(out / "logo.png", optimize=True)
    print("logo", img.size)


# ---------------------------------------------------------------------------------------------
BUBBLE = 640
LOGO_PX = 1300  # drawn 1130 game px wide; the 2x pixel-ratio cap never needs more
CROPS = {  # x, y, size in the 1024 px art: head and shoulders
    "wren": (130, 30, 760),
    "juno": (130, 40, 760),
    "ash": (120, 30, 790),
    "pip": (160, 30, 720),
}


def make_bubble(cid, src_dir, out):
    S = BUBBLE
    ss = 2
    N = S * ss
    art = Image.open(src_dir / f"{cid}.png").convert("RGBA")
    x, y, sz = CROPS[cid]
    bust = art.crop((x, y, x + sz, y + sz)).resize((int(N * 0.90), int(N * 0.90)), Image.LANCZOS)
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    c = (N - 1) / 2
    R = N * 0.465
    rr = np.hypot(xx - c, yy - c) / R
    inside = np.clip((1 - rr) * R / 1.5 + 0.5, 0, 1)

    # tinted interior: purple at edges, lighter middle
    interior = np.zeros((N, N, 4), np.float32)
    k = np.clip(rr, 0, 1)
    interior[..., 0] = 0.30 + 0.20 * k
    interior[..., 1] = 0.22 + 0.10 * k
    interior[..., 2] = 0.58 + 0.15 * (1 - k)
    interior[..., 3] = (0.30 + 0.30 * k ** 2) * inside
    layer = Image.fromarray((np.clip(interior, 0, 1) * 255).astype(np.uint8), "RGBA")
    # character: bottom of the bust sits on the bubble floor; clip to circle
    chars = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    chars.alpha_composite(bust, ((N - bust.size[0]) // 2, N - bust.size[1] - int(N * 0.012)))
    ca = np.asarray(chars, np.float32) / 255
    ca[..., 3] *= inside
    chars = Image.fromarray((ca * 255).astype(np.uint8), "RGBA")
    layer.alpha_composite(chars)
    base = np.asarray(layer, np.float32) / 255
    # bluish-purple bounce light low in the bubble over the art
    bounce = np.clip(1 - np.hypot(xx - c, yy - (c + R * 0.95)) / (R * 0.8), 0, 1) ** 2 * 0.25 * inside
    base[..., :3] = base[..., :3] * (1 - bounce[..., None]) + np.array([0.55, 0.45, 1.0], np.float32) * bounce[..., None]

    # glass overlays (premultiplied-free additive/over mix)
    glass = np.zeros((N, N, 4), np.float32)

    def add(rgb, alpha):
        al = np.clip(alpha, 0, 1)[..., None]
        oa = glass[..., 3:4]
        na = al + oa * (1 - al)
        glass[..., :3] = (np.array(rgb, np.float32) * al + glass[..., :3] * oa * (1 - al)) / np.maximum(na, 1e-6)
        glass[..., 3:4] = na

    th = np.arctan2(yy - c, xx - c)
    # iridescent rim: hue wheel around the edge
    hue = (th / (2 * np.pi) * 2 + 0.15) % 1.0
    pal = np.array([[1.0, 0.55, 0.85], [0.55, 0.85, 1.0], [0.7, 0.6, 1.0], [0.6, 1.0, 0.9], [1.0, 0.7, 0.9]], np.float32)
    idx = hue * (len(pal) - 1)
    i0 = np.floor(idx).astype(int)
    fr = (idx - i0)[..., None]
    rim_rgb = pal[i0] * (1 - fr) + pal[np.minimum(i0 + 1, len(pal) - 1)] * fr
    band = np.exp(-(((rr - 0.965) * R) / (N * 0.014)) ** 2)
    wide = np.clip((rr - 0.80) / 0.2, 0, 1) ** 2.2 * inside
    # rim body
    al = np.clip(wide * 0.38 + band * 0.80, 0, 1) * inside
    al2 = al[..., None]
    glass[..., :3] = rim_rgb
    glass[..., 3] = al
    # crisp bright outer line
    add((0.92, 0.95, 1.0), np.exp(-(((rr - 0.992) * R) / (N * 0.004)) ** 2) * 0.9 * inside)
    # soft inner shadow-ish tint on lower right
    lr = np.clip((xx - c + yy - c) / (2 * R), 0, 1) ** 1.5
    add((0.62, 0.5, 1.0), wide * lr * 0.35)

    # specular: curved highlight arc along upper-left inside rim
    arc_r = 0.80
    arc = np.exp(-(((rr - arc_r) * R) / (N * 0.022)) ** 2)
    ang = np.degrees(th)
    mask = np.clip(1 - np.abs(((ang + 135 + 180) % 360) - 180) / 48, 0, 1) ** 0.8  # centred at -135 deg (upper-left)
    add((1, 1, 1), arc * mask * 0.85)
    # smaller arc, lower right
    mask2 = np.clip(1 - np.abs(((ang - 40 + 180) % 360) - 180) / 34, 0, 1)
    arc2 = np.exp(-(((rr - 0.86) * R) / (N * 0.014)) ** 2)
    add((0.9, 1.0, 1.0), arc2 * mask2 * 0.7)
    # blob highlights
    for (hx, hy, rx, ry, a_) in [(-0.50, -0.50, 0.10, 0.05, 0.9), (0.50, 0.46, 0.05, 0.03, 0.6)]:
        e = ((xx - (c + hx * R)) / (rx * R)) ** 2 + ((yy - (c + hy * R)) / (ry * R)) ** 2
        add((1, 1, 1), np.exp(-e * 1.4) * a_ * inside)

    gl = Image.fromarray((np.clip(glass, 0, 1) * 255).astype(np.uint8), "RGBA")
    res = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8), "RGBA")
    res.alpha_composite(gl)
    # soft outer halo so the bubble sits in the sky
    res = res.resize((S, S), Image.LANCZOS)
    res.save(out / f"{cid}.png", optimize=True)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    chars = Path("/mnt/project-files/design/characters")
    if "--characters" in sys.argv:
        chars = Path(sys.argv[sys.argv.index("--characters") + 1])
        args = [a for a in args if a != str(chars)]
    out = Path(args[0]) if args else ROOT / "game/art/intro"
    out.mkdir(parents=True, exist_ok=True)
    make_sky(out)
    make_logo(out)
    for cid in CROPS:
        make_bubble(cid, chars, out)


if __name__ == "__main__":
    main()

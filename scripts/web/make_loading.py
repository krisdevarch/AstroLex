"""Builds the web loading screen (WP-F.13c, reworked in WP-F.29 AC 5: the loader is the intro). Deterministic;
run from anywhere:
    python3 scripts/web/make_loading.py
Reads game/brand/intro_still.jpg and game/fonts/Fredoka.ttf, writes
  game/brand/splash.png   Godot boot splash (the still + a full load bar + the disabled button)
  game/web/shell.html     custom HTML shell (from scripts/web/shell.template.html), one file

The player sees one screen from page open to tap: the intro. The shell overlay is the intro's art (the
still) with the play screen's clock-bar liquid as the load bar and a disabled "Tap to start" under it; the
Godot intro then appears in the same place with the button enabled. Everything is laid out in design units
u = width / 1080, like game/scenes/intro_screen.gd, and the still is cover-fitted like the Godot design box.

The still is a capture of the real intro (art only: sky, wordmark, tagline, four bubbles at rest, no
button), 1080x1920. Regenerate it whenever the intro's art or layout changes:
    scripts/godot/export.sh web
    cd scripts/godot/web-smoke && node intro-still.cjs ../../../build/web ../../../game/brand/intro_still.jpg
    python3 scripts/web/make_loading.py
Needs Pillow; fontTools + brotli subset the font to woff2 (else a system rounded font is used).
"""
import base64
import io
import pathlib

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
STILL = ROOT / "game/brand/intro_still.jpg"
FONT = ROOT / "game/fonts/Fredoka.ttf"
TEMPLATE = ROOT / "scripts/web/shell.template.html"
SHELL = ROOT / "game/web/shell.html"
SPLASH = ROOT / "game/brand/splash.png"
GLYPHS = "Tap to start0123456789%"
# Layout in 1080x1920 design units, as game/scenes/intro_screen.gd and the shell template.
BTN_W, BTN_H, BTN_FROM_BOTTOM = 600, 150, 330  # intro_screen.gd TAP_FROM_BOTTOM; button top edge
BAR_W, BAR_BOTTOM = 560, 370  # the bar's bottom edge, from the bottom of the view
FRAME_W, FRAME_H = 773, 94  # the clock bar's frame in scripts/art/hud/console.svg
CH_X, CH_Y, CH_W, CH_H = 25, 16, 734, 62  # its channel, relative to the frame
PAD = 4.5  # HudArt.Liquid pad
C1, C2 = (255, 100, 104), (254, 171, 123)  # HudArt.Liquid coral to peach
BTN_FILL, BTN_RIM, BTN_INK = (115, 107, 97), (156, 84, 12), (51, 51, 64)  # ui.gd primary, disabled


def font_b64():
    try:
        from fontTools import subset
        from fontTools.ttLib import TTFont
        from fontTools.varLib import instancer
    except ImportError:
        return ""
    f = TTFont(str(FONT))
    if "fvar" in f:
        f = instancer.instantiateVariableFont(f, {"wght": 600, "wdth": 100})
    opts = subset.Options()
    opts.flavor = "woff2"
    opts.layout_features = []
    opts.name_IDs = []
    opts.notdef_outline = True
    sub = subset.Subsetter(opts)
    sub.populate(text=GLYPHS)
    sub.subset(f)
    f.flavor = "woff2"
    buf = io.BytesIO()
    f.save(buf)
    return base64.b64encode(buf.getvalue()).decode()


def bar_svg():
    """The clock bar's frame and channel (console.svg) as inline SVG; the shell's script draws the liquid
    into the nested #liquid svg."""
    return f"""<svg viewBox="0 0 {FRAME_W} {FRAME_H}" aria-hidden="true">
						<defs>
							<linearGradient id="barframe" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#92c0e5"/><stop offset="0.2" stop-color="#5b8fbe"/><stop offset="0.55" stop-color="#43689f"/><stop offset="1" stop-color="#395585"/></linearGradient>
							<linearGradient id="chan" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#132253"/><stop offset="0.3" stop-color="#14224d"/><stop offset="0.7" stop-color="#1f4570"/><stop offset="1" stop-color="#244a78"/></linearGradient>
							<linearGradient id="liq" gradientUnits="userSpaceOnUse" x1="{PAD}" y1="0" x2="{PAD + (CH_W - 2 * PAD) * 0.8}" y2="0"><stop offset="0" stop-color="rgb{C1}"/><stop offset="1" stop-color="rgb{C2}"/></linearGradient>
						</defs>
						<rect x="2.5" y="2.5" width="{FRAME_W - 5}" height="{FRAME_H - 5}" rx="44.5" fill="url(#barframe)" stroke="#04071a" stroke-width="5"/>
						<rect x="8" y="8" width="{FRAME_W - 16}" height="{FRAME_H - 16}" rx="39" fill="none" stroke="#a9d3f0" stroke-width="2" opacity="0.55"/>
						<rect x="{CH_X}" y="{CH_Y}" width="{CH_W}" height="{CH_H}" rx="31" fill="url(#chan)" stroke="#04071a" stroke-width="4"/>
						<path d="M57,20 H727" stroke="#4d79a9" stroke-width="2" opacity="0.5"/>
						<rect x="2" y="22" width="15" height="52" rx="5" fill="#34507e" stroke="#04071a" stroke-width="3"/>
						<circle cx="9" cy="36" r="3" fill="#9fc0e0"/><circle cx="9" cy="60" r="3" fill="#9fc0e0"/>
						<svg id="liquid" x="{CH_X}" y="{CH_Y}" width="{CH_W}" height="{CH_H}" viewBox="0 0 {CH_W} {CH_H}"></svg>
					</svg>"""


def liquid_polygon(share=1.0):
    """HudArt.Liquid's outline at rest (phase 0) in channel pixels, same maths as the shell script."""
    import math
    h, full = CH_H - 2 * PAD, CH_W - 2 * PAD
    r = h / 2
    front = PAD + max(r * 1.2, full * share)
    corner = 7.0

    def surf(x):
        return PAD + 0.34 * h + 0.24 * h * math.sin(x / 48)

    def cap(x):
        dx = PAD + r - x
        return math.sqrt(max(0.0, r * r - dx * dx)) if x < PAD + r else r

    steps = max(2, int((front - corner - PAD) / 6))
    top = []
    for i in range(steps + 1):
        x = PAD + (front - corner - PAD) * i / steps
        c = cap(x)
        top.append((x, min(max(surf(x), PAD + r - c), PAD + r + c * 0.6)))
    pts = list(top) + [(front, top[-1][1] + corner), (front, PAD + h)]
    for i in range(steps):
        x = front - corner + (PAD - front + corner) * i / steps
        pts.append((x, PAD + r + cap(x)))
    return top, pts, front, surf


def draw_bar(img):
    """The full bar on the 1080x1920 canvas, supersampled 3x."""
    ss = 3
    u = BAR_W / FRAME_W  # frame units to design px
    fw, fh = round(FRAME_W * u * ss), round(FRAME_H * u * ss)
    bar = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    d = ImageDraw.Draw(bar)
    k = u * ss

    def vgrad(w, h, stops):
        g = Image.new("RGBA", (1, h))
        for y in range(h):
            f = y / max(1, h - 1)
            for (a, ca), (b, cb) in zip(stops, stops[1:]):
                if a <= f <= b:
                    t = (f - a) / (b - a)
                    g.putpixel((0, y), tuple(round(ca[i] + (cb[i] - ca[i]) * t) for i in range(3)) + (255,))
                    break
        return g.resize((w, h))

    def rr(box, rad, fill_img, stroke, sw):
        x0, y0, x1, y1 = [v * k for v in box]
        m = Image.new("L", (fw, fh), 0)
        ImageDraw.Draw(m).rounded_rectangle((x0, y0, x1, y1), rad * k, fill=255)
        bar.paste(fill_img.resize((fw, fh)) if fill_img.size != (fw, fh) else fill_img, (0, 0), m)
        d.rounded_rectangle((x0, y0, x1, y1), rad * k, outline=stroke, width=round(sw * k))

    ink = (4, 7, 26, 255)
    frame_g = vgrad(fw, fh, [(0, (146, 192, 229)), (0.2, (91, 143, 190)), (0.55, (67, 104, 159)), (1, (57, 85, 133))])
    rr((2.5, 2.5, FRAME_W - 2.5, FRAME_H - 2.5), 44.5, frame_g, ink, 5)
    d.rounded_rectangle((8 * k, 8 * k, (FRAME_W - 8) * k, (FRAME_H - 8) * k), 39 * k, outline=(169, 211, 240, 140), width=round(2 * k))
    chan_g = vgrad(fw, fh, [(0, (19, 34, 83)), (0.3, (20, 34, 77)), (0.7, (31, 69, 112)), (1, (36, 74, 120))])
    chan_m = Image.new("L", (fw, fh), 0)
    ImageDraw.Draw(chan_m).rounded_rectangle((CH_X * k, CH_Y * k, (CH_X + CH_W) * k, (CH_Y + CH_H) * k), 31 * k, fill=255)
    chan = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    cg = vgrad(fw, fh, [(0, (19, 34, 83)), (0.3, (20, 34, 77)), (0.7, (31, 69, 112)), (1, (36, 74, 120))])
    chan.paste(cg, (0, 0), chan_m)
    bar = Image.alpha_composite(bar, chan)
    d = ImageDraw.Draw(bar)
    d.rounded_rectangle((CH_X * k, CH_Y * k, (CH_X + CH_W) * k, (CH_Y + CH_H) * k), 31 * k, outline=ink, width=round(4 * k))
    d.rounded_rectangle((2 * k, 22 * k, 17 * k, 74 * k), 5 * k, fill=(52, 80, 126, 255), outline=ink, width=round(3 * k))
    for cy in (36, 60):
        d.ellipse((6 * k, (cy - 3) * k, 12 * k, (cy + 3) * k), fill=(159, 192, 224, 255))
    # Liquid, clipped to the channel.
    top, pts, front, surf = liquid_polygon(1.0)
    liq = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    full = CH_W - 2 * PAD
    grad = Image.new("RGBA", (fw, 1))
    for x in range(fw):
        cx = x / k - CH_X
        t = min(1.0, max(0.0, (cx - PAD) / (full * 0.8)))
        grad.putpixel((x, 0), tuple(round(C1[i] + (C2[i] - C1[i]) * t) for i in range(3)) + (255,))
    grad = grad.resize((fw, fh))
    pm = Image.new("L", (fw, fh), 0)
    ImageDraw.Draw(pm).polygon([((CH_X + x) * k, (CH_Y + y) * k) for x, y in pts], fill=255)
    cm = Image.new("L", (fw, fh), 0)
    ImageDraw.Draw(cm).rounded_rectangle((CH_X * k, CH_Y * k, (CH_X + CH_W) * k, (CH_Y + CH_H) * k), 31 * k, fill=255)
    from PIL import ImageChops
    liq.paste(grad, (0, 0), ImageChops.multiply(pm, cm))
    ld = ImageDraw.Draw(liq)
    ld.line([((CH_X + x) * k, (CH_Y + y + 3) * k) for x, y in top], fill=(255, 230, 209, 190), width=round(4 * k), joint="curve")
    for i in range(7):
        bx = PAD + 13.25 * 0.6 + (i * 113) % max(1, front - PAD - 26.5)
        by = (PAD + 53 - 6) + (surf(bx) + 6 - (PAD + 53 - 6)) * 0.5
        rad = 2.5 + (i % 3) * 1.5
        ld.ellipse(((CH_X + bx - rad) * k, (CH_Y + by - rad) * k, (CH_X + bx + rad) * k, (CH_Y + by + rad) * k), fill=(255, 219, 214, 178))
    bar = Image.alpha_composite(bar, liq)
    bar = bar.resize((round(FRAME_W * u), round(FRAME_H * u)), Image.LANCZOS)
    x = (1080 - bar.width) // 2
    y = 1920 - BAR_BOTTOM - bar.height
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow.paste((0, 3, 14, 110), (x, y + 6), bar.getchannel("A"))
    img.alpha_composite(shadow)
    img.alpha_composite(bar, (x, y))


def draw_button(img):
    """ui.gd primary() in its disabled state: fill, rounded bottom rim, ink text, at the intro's place."""
    ss = 3
    w, h = BTN_W * ss, BTN_H * ss
    lip = 10 * ss
    b = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(b)
    d.rounded_rectangle((0, 0, w - 1, h - 1), h // 2, fill=BTN_RIM + (255,))
    d.rounded_rectangle((0, 0, w - 1, h - 1 - lip), (h - lip) // 2, fill=BTN_FILL + (255,))
    font = ImageFont.truetype(str(FONT), 62 * ss)
    try:
        font.set_variation_by_axes([600, 100])
    except Exception:
        pass
    d.text((w / 2, (h - 2 * lip) / 2 + 2 * ss), "Tap to start", font=font, fill=BTN_INK + (255,), anchor="mm")
    b = b.resize((BTN_W, BTN_H), Image.LANCZOS)
    img.alpha_composite(b, ((1080 - BTN_W) // 2, 1920 - BTN_FROM_BOTTOM))


def make_splash(still):
    img = still.convert("RGBA").resize((1080, 1920), Image.LANCZOS)
    draw_bar(img)
    draw_button(img)
    # Godot's web export only takes PNG: 720x1280, 256-colour dithered keeps it small.
    img.convert("RGB").resize((720, 1280), Image.LANCZOS).quantize(256, dither=Image.FLOYDSTEINBERG).save(SPLASH, optimize=True)


def main():
    raw = STILL.read_bytes()
    still_b64 = base64.b64encode(raw).decode()
    make_splash(Image.open(STILL))
    fb = font_b64()
    html = (TEMPLATE.read_text().replace("{{STILL_B64}}", still_b64).replace("{{FONT_B64}}", fb)
            .replace("{{BAR_SVG}}", bar_svg()))
    SHELL.parent.mkdir(parents=True, exist_ok=True)
    SHELL.write_text("<!-- Generated by scripts/web/make_loading.py from scripts/web/shell.template.html; do not edit. -->\n" + html)
    print(f"still {len(raw)/1024:.0f} KB, font {len(fb)*3//4/1024:.1f} KB, "
          f"shell {SHELL.stat().st_size/1024:.0f} KB, splash {SPLASH.stat().st_size/1024:.0f} KB")


if __name__ == "__main__":
    main()

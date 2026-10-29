"""Writes the play-screen HUD art as SVG (console, round buttons, hint bulb) next to this file.

  python3 scripts/art/hud/gen_hud_svgs.py && scripts/art/make_hud.sh

Every SVG is drawn in game px (the 1080-wide layout) so that features sit where field.gd's MOCK_*
constants expect them; make_hud.sh renders them at 2x (HudArt.ART_SCALE). The shapes follow the
owner's mock (the old cut_hud.py crops): navy ink outline, steel-blue bevelled body, cyan neon
rims, orange accents, glossy clean glass (the game animates the scan lines on top).
"""
import math
from pathlib import Path

OUT = Path(__file__).parent
K = 1080.0 / 572.0
INK = "#0a1228"
CYAN = "#46e6f6"
ORANGE = "#ff9a4a"

DEFS = """<defs>
<linearGradient id="steel" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5d86b6"/><stop offset=".45" stop-color="#3e6192"/><stop offset="1" stop-color="#2a4474"/></linearGradient>
<linearGradient id="steelD" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#33507f"/><stop offset="1" stop-color="#1f3562"/></linearGradient>
<linearGradient id="glass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1e6a8c"/><stop offset=".5" stop-color="#14527a"/><stop offset="1" stop-color="#1b6f93"/></linearGradient>
<radialGradient id="pglass" cx=".42" cy=".3" r=".85"><stop offset="0" stop-color="#1f7a98"/><stop offset=".6" stop-color="#124c72"/><stop offset="1" stop-color="#0b2d52"/></radialGradient>
<linearGradient id="chan" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0d1c3a"/><stop offset=".5" stop-color="#18305a"/><stop offset="1" stop-color="#22406c"/></linearGradient>
<linearGradient id="cable" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9fb4d2"/><stop offset="1" stop-color="#5d7298"/></linearGradient>
<filter id="glow" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="4"/></filter>
<filter id="glowS" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="2"/></filter>
</defs>"""


def svg(w, h, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f"{DEFS}{body}</svg>\n")


def pill(x, y, w, h, c):
    return (f'<rect x="{x-1}" y="{y-1}" width="{w+2}" height="{h+2}" rx="{h/2+1}" fill="{c}" opacity=".55" filter="url(#glowS)"/>'
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h/2}" fill="{c}" stroke="{INK}" stroke-width="2"/>'
            f'<rect x="{x+2}" y="{y+1}" width="{w-4}" height="{h/3:.1f}" rx="{h/6:.1f}" fill="#fff" opacity=".35"/>')


def arc(cx, cy, r, a0, a1):
    p = lambda a: (cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)))
    x0, y0 = p(a0)
    x1, y1 = p(a1)
    large = 1 if (a1 - a0) % 360 > 180 else 0
    return f"M{x0:.2f},{y0:.2f} A{r},{r} 0 {large} 1 {x1:.2f},{y1:.2f}"


def poly(pts):
    return "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts)


def smooth(pts):
    d = f"M{pts[0][0]},{pts[0][1]}"
    for i in range(1, len(pts)):
        x0, y0 = pts[i - 1]
        x1, y1 = pts[i]
        d += f" Q{x0},{y0} {(x0 + x1) / 2:.1f},{(y0 + y1) / 2:.1f}"
    return d + f" L{pts[-1][0]},{pts[-1][1]}"


def console():
    m = lambda x, y: (x * K, (y - 742) * K)
    pcx, pcy = 158.0, 171.0
    parts = []
    # cables, behind everything
    cables = [
        [m(17, 893), m(9, 905), m(6, 920), m(7, 935), m(12, 946), m(20, 953), m(35, 961), m(50, 966), m(61, 970)],
        [m(17, 893), m(14, 910), m(14, 930), m(17, 946)],
        [m(17, 953), m(20, 963), m(27, 975), m(40, 985), m(60, 989)],
    ]
    for c in cables:
        d = smooth([(round(x, 1), round(y, 1)) for x, y in c])
        parts.append(f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="13" stroke-linecap="round" stroke-linejoin="round"/>')
        parts.append(f'<path d="{d}" fill="none" stroke="url(#cable)" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>')
        parts.append(f'<path d="{d}" fill="none" stroke="#fff" stroke-opacity=".35" stroke-width="2" stroke-linecap="round" transform="translate(-1.5,-1.5)"/>')
    # body
    body = ("M240,70 C380,44 700,40 826,46 Q884,50 890,104 L894,246 Q892,296 862,318 "
            "C790,336 640,352 470,354 C380,355 300,346 236,318 Z")
    parts.append(f'<path d="{body}" fill="url(#steel)" stroke="{INK}" stroke-width="9" stroke-linejoin="round"/>')
    # lower lip with trapezoid notches
    parts.append(f'<path d="M268,322 C380,346 700,350 850,326 L846,338 C700,356 380,356 276,334 Z" fill="url(#steelD)" stroke="{INK}" stroke-width="3"/>')
    parts.append(f'<path d="{poly([(420,318),(440,336),(745,336),(768,318)])} Z" fill="#2a4272" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>')
    parts.append('<path d="M452,326 H735" stroke="#6f9bd0" stroke-opacity=".6" stroke-width="2.5" stroke-linecap="round"/>')
    # top cyan tab
    parts.append(f'<path d="{poly([(452,42),(470,54),(722,54),(742,42)])} Z" fill="#17496e" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>')
    parts.append(f'<path d="M470,50 H722" stroke="{CYAN}" stroke-width="3" stroke-linecap="round"/><path d="M460,44 H736" stroke="#8fe9f5" stroke-opacity=".7" stroke-width="2"/>')
    # slot screen
    scr = ("M338,66 H852 Q870,66 870,84 V150 L864,160 V230 L870,242 V300 Q870,312 858,312 H340 "
           "Q326,312 326,298 V244 L332,234 V150 L326,140 V82 Q326,66 338,66 Z")
    parts.append(f'<path d="{scr}" fill="{INK}" stroke="{INK}" stroke-width="16" stroke-linejoin="round"/>')
    parts.append(f'<path d="{scr}" fill="url(#glass)" stroke="{CYAN}" stroke-width="7" stroke-linejoin="round" filter="url(#glowS)" opacity=".7"/>')
    parts.append(f'<path d="{scr}" fill="url(#glass)" stroke="{CYAN}" stroke-width="4" stroke-linejoin="round"/>')
    parts.append('<path d="M344,76 H850 Q860,76 860,86 V132 Q600,150 340,132 V86 Q340,76 344,76 Z" fill="#fff" opacity=".07"/>')
    parts.append('<path d="M345,300 H852" stroke="#7fe9f5" stroke-opacity=".28" stroke-width="3" stroke-linecap="round"/>')
    # lights
    parts.append(pill(290, 62, 32, 9, ORANGE))
    parts.append(f'<path d="M846,70 Q872,72 880,106 L880,118" fill="none" stroke="{INK}" stroke-width="12" stroke-linecap="round"/>'
                 f'<path d="M846,70 Q872,72 880,106 L880,118" fill="none" stroke="{ORANGE}" stroke-width="6" stroke-linecap="round"/>')
    parts.append(pill(140, 309, 38, 11, CYAN))
    parts.append(pill(333, 335, 30, 8, CYAN))
    parts.append(pill(813, 334, 32, 8, CYAN))
    for x in (354, 775, 788):
        parts.append(f'<circle cx="{x}" cy="340" r="4.2" fill="#ff7a5a" stroke="{INK}" stroke-width="2"/>')
    for i in range(3):
        parts.append(f'<rect x="{288+i*9}" y="290" width="5" height="17" rx="2" fill="{ORANGE}" stroke="{INK}" stroke-width="2"/>')
    # porthole
    parts.append(f'<circle cx="{pcx}" cy="{pcy}" r="152" fill="{INK}"/>')
    parts.append(f'<circle cx="{pcx}" cy="{pcy}" r="147" fill="url(#steel)"/>')
    parts.append(f'<circle cx="{pcx}" cy="{pcy}" r="141" fill="none" stroke="#a9cbef" stroke-opacity=".55" stroke-width="2.5"/>')
    parts.append(f'<circle cx="{pcx}" cy="{pcy}" r="132" fill="#16264a" stroke="{INK}" stroke-width="4"/>')
    for a in (-135, -45, 45, 135):
        bx, by = pcx + 139 * math.cos(math.radians(a)), pcy + 139 * math.sin(math.radians(a))
        parts.append(f'<circle cx="{bx:.1f}" cy="{by:.1f}" r="7.5" fill="#22385f" stroke="{INK}" stroke-width="3"/>'
                     f'<circle cx="{bx-1.5:.1f}" cy="{by-1.5:.1f}" r="2.4" fill="#8fb3dd"/>')
    for a0, a1 in ((200, 292), (334, 40), (110, 165)):
        d = arc(pcx, pcy, 119, a0, a1)
        parts.append(f'<path d="{d}" fill="none" stroke="{ORANGE}" stroke-width="16" stroke-linecap="round" opacity=".5" filter="url(#glowS)"/>')
        parts.append(f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="15" stroke-linecap="round"/>')
        parts.append(f'<path d="{d}" fill="none" stroke="#ffb066" stroke-width="10" stroke-linecap="round"/>')
        parts.append(f'<path d="{d}" fill="none" stroke="{ORANGE}" stroke-width="5" stroke-linecap="round"/>')
    parts.append(f'<circle cx="{pcx}" cy="{pcy}" r="106" fill="none" stroke="{CYAN}" stroke-width="12" opacity=".5" filter="url(#glow)"/>')
    parts.append(f'<circle cx="{pcx}" cy="{pcy}" r="106" fill="{INK}"/>')
    parts.append(f'<circle cx="{pcx}" cy="{pcy}" r="104" fill="none" stroke="{CYAN}" stroke-width="7"/>')
    parts.append(f'<circle cx="{pcx}" cy="{pcy}" r="100" fill="url(#pglass)" stroke="{INK}" stroke-width="2"/>')
    parts.append(f'<path d="{arc(pcx, pcy, 88, 200, 255)}" fill="none" stroke="#fff" stroke-opacity=".22" stroke-width="7" stroke-linecap="round"/>')
    # clock bar frame, channel and legs
    for x0, x1 in ((221, 244), (796, 829)):
        parts.append(f'<path d="M{x0},488 H{x1} L{x1+4},532 H{x0-4} Z" fill="url(#steelD)" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>'
                     f'<path d="M{x0+4},492 V528" stroke="#8fb3dd" stroke-opacity=".5" stroke-width="2.5"/>')
    bar = "M135,402 H838 Q885,402 885,449.5 Q885,497 838,497 H135 Q111,497 111,473 V426 Q111,402 135,402 Z"
    parts.append(f'<path d="{bar}" fill="url(#steel)" stroke="{INK}" stroke-width="8" stroke-linejoin="round"/>')
    parts.append('<path d="M140,408 H836" stroke="#bcd8f6" stroke-opacity=".6" stroke-width="2.5" stroke-linecap="round"/>')
    parts.append(f'<path d="M730,411 H786" stroke="{CYAN}" stroke-width="3" stroke-linecap="round"/>')
    ch = "M152,419 H838 Q870,419 870,450 Q870,481 838,481 H152 Q136,481 136,465 V435 Q136,419 152,419 Z"
    parts.append(f'<path d="{ch}" fill="url(#chan)" stroke="{INK}" stroke-width="6" stroke-linejoin="round"/>')
    parts.append('<path d="M156,424 H836" stroke="#fff" stroke-opacity=".12" stroke-width="2.5" stroke-linecap="round"/>')
    return svg(910, 532, "".join(parts))


# --- buttons -------------------------------------------------------------------------------------
BS = 150  # canvas, game px; the button centre is the canvas centre
BC = BS / 2
R_RING = 48.1  # == MOCK_RING_R * K


def ring_svg(kind):
    if kind == "pause":
        out = []
        for a0, a1 in ((200, 262), (278, 340), (20, 82), (98, 160)):
            d = arc(BC, BC, R_RING, a0, a1)
            out.append(f'<path d="{d}" fill="none" stroke="{ORANGE}" stroke-width="14" stroke-linecap="round" opacity=".45" filter="url(#glowS)"/>'
                       f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="12" stroke-linecap="round"/>'
                       f'<path d="{d}" fill="none" stroke="#ffb878" stroke-width="9" stroke-linecap="round"/>'
                       f'<path d="{d}" fill="none" stroke="{ORANGE}" stroke-width="5" stroke-linecap="round"/>')
        return "".join(out)
    d = f'<circle cx="{BC}" cy="{BC}" r="{R_RING}" fill="none"'
    return (d + f' stroke="{CYAN}" stroke-width="15" opacity=".45" filter="url(#glowS)"/>' + d +
            f' stroke="{INK}" stroke-width="12"/>' + d + ' stroke="#8ff3fb" stroke-width="9"/>' + d + f' stroke="{CYAN}" stroke-width="5"/>')


def gear(cx, cy, ro, ri, hole, teeth=8):
    pts = []
    for i in range(teeth):
        a = 2 * math.pi * i / teeth
        w = math.pi / teeth
        for da, r in ((-0.62 * w, ri), (-0.38 * w, ro), (0.38 * w, ro), (0.62 * w, ri)):
            pts.append((cx + r * math.cos(a + da), cy + r * math.sin(a + da)))
    return (f'<path d="{poly(pts)} Z M{cx+hole},{cy} a{hole},{hole} 0 1 0 {-2*hole},0 a{hole},{hole} 0 1 0 {2*hole},0 Z" fill-rule="evenodd"')


ICON = "#6fe6f2"
ICON_LIGHT = "#b9f6fb"


def icon_svg(kind):
    c = BC
    if kind == "pause":
        out = []
        for x in (-19, 5):
            out.append(f'<rect x="{c+x}" y="{c-27}" width="14" height="54" rx="6" fill="{ICON}" stroke="{INK}" stroke-width="3"/>'
                       f'<rect x="{c+x+3}" y="{c-23}" width="4" height="46" rx="2" fill="{ICON_LIGHT}" opacity=".7"/>')
        return "".join(out)
    if kind == "sound":
        sp = [(c - 33, c - 9), (c - 21, c - 9), (c - 4, c - 26), (c - 4, c + 26), (c - 21, c + 9), (c - 33, c + 9)]
        out = [f'<path d="{poly(sp)} Z" fill="{ICON}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>',
               f'<path d="M{c-30},{c-6} H{c-19} L{c-8},{c-17}" fill="none" stroke="{ICON_LIGHT}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" opacity=".8"/>']
        for r, w in ((13, 3.6), (22, 3.6)):
            d = arc(c + 1, c, r, -42, 42)
            out.append(f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="{w+4}" stroke-linecap="round"/>'
                       f'<path d="{d}" fill="none" stroke="{ICON}" stroke-width="{w}" stroke-linecap="round"/>')
        return "".join(out)
    g = gear(c, c, 27, 20, 8.5)
    return (g + f' fill="{ICON}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>' +
            f'<circle cx="{c}" cy="{c}" r="8.5" fill="none" stroke="{ICON_LIGHT}" stroke-width="1.5" opacity=".6"/>')


def button(kind, with_icon):
    ringcol = ORANGE if kind == "pause" else CYAN
    disc = (f'<defs><radialGradient id="disc" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="{ringcol}" stop-opacity=".05"/>'
            f'<stop offset=".7" stop-color="{ringcol}" stop-opacity=".1"/><stop offset="1" stop-color="{ringcol}" stop-opacity=".3"/></radialGradient></defs>')
    p = [disc,
         f'<circle cx="{BC}" cy="{BC}" r="70" fill="{INK}"/>',
         f'<circle cx="{BC}" cy="{BC}" r="67" fill="url(#steel)"/>',
         f'<circle cx="{BC}" cy="{BC}" r="62" fill="none" stroke="#a9cbef" stroke-opacity=".5" stroke-width="2"/>']
    for a in (-135, -45, 45, 135):
        bx, by = BC + 64 * math.cos(math.radians(a)), BC + 64 * math.sin(math.radians(a))
        p.append(f'<circle cx="{bx:.1f}" cy="{by:.1f}" r="3.6" fill="#1d3358" stroke="{INK}" stroke-width="1.6"/>')
    p.append(f'<circle cx="{BC}" cy="{BC}" r="58" fill="#15264a" stroke="{INK}" stroke-width="3"/>')
    p.append(ring_svg(kind))
    p.append(f'<circle cx="{BC}" cy="{BC}" r="43.6" fill="#0d1a38"/>')
    p.append(f'<circle cx="{BC}" cy="{BC}" r="43.6" fill="url(#disc)"/>')
    if with_icon:
        if kind == "settings":
            p.append(f'<circle cx="{BC}" cy="{BC}" r="38" fill="none" stroke="#9fe9f3" stroke-opacity=".8" stroke-width="2" stroke-dasharray="0.1 4.6" stroke-linecap="round"/>')
        elif kind == "sound":
            p.append(f'<path d="{arc(BC, BC, 38, 100, 360)}" fill="none" stroke="#e8c8c0" stroke-opacity=".7" stroke-width="1.8" stroke-linecap="round"/>')
        p.append(icon_svg(kind))
    return svg(BS, BS, "".join(p))


# --- bulb ----------------------------------------------------------------------------------------
def bulb():
    cx, cy, r = 51.0, 53.8, 46.8
    glass = (f"M{cx-r:.1f},{cy} A{r},{r} 0 0 1 {cx+r:.1f},{cy} C{cx+r:.1f},{cy+22} {cx+22},{cy+30} {cx+19},{cy+43} "
             f"L{cx+18},{cy+47} H{cx-18} L{cx-19},{cy+43} C{cx-22},{cy+30} {cx-r:.1f},{cy+22} {cx-r:.1f},{cy} Z")
    defs = ('<defs><radialGradient id="bg" cx=".4" cy=".3" r=".8"><stop offset="0" stop-color="#ffe08a"/><stop offset=".5" stop-color="#ffb938"/>'
            '<stop offset="1" stop-color="#f08a14"/></radialGradient>'
            '<linearGradient id="scr" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8d99ad"/><stop offset=".35" stop-color="#dfe6f1"/><stop offset="1" stop-color="#6a768c"/></linearGradient></defs>')
    p = [defs]
    base = poly([(25.6, 100), (77.5, 100), (76, 160), (70, 169), (33, 169), (28, 160)]) + " Z"
    p.append(f'<path d="{base}" fill="url(#scr)" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>')
    for y in (111, 124, 137, 150):
        p.append(f'<path d="M27,{y} H77" stroke="{INK}" stroke-width="3.2" stroke-linecap="round"/><path d="M29,{y-2.6} H74" stroke="#fff" stroke-opacity=".5" stroke-width="1.6" stroke-linecap="round"/>')
    p.append('<path d="M35,165 H69" stroke="#5a4a7e" stroke-width="5" stroke-linecap="round"/>')
    p.append(f'<path d="{glass}" fill="url(#bg)" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>')
    p.append(f'<path d="M{cx-19},{cy+44} H{cx+19} L{cx+19},{cy+50} H{cx-19} Z" fill="#a8b2c4" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>')
    for dx in (-15, 0, 15):
        p.append(f'<path d="M{cx+dx*0.5},{cy+44} V{cy+22} Q{cx+dx},{cy+10} {cx+dx*1.2},{cy-2} Q{cx+dx*1.1},{cy-12} {cx+dx*0.5},{cy-8}" fill="none" stroke="#7a3b0a" stroke-width="2.8" stroke-linecap="round"/>')
    p.append(f'<ellipse cx="{cx-20}" cy="{cy-22}" rx="14" ry="8" transform="rotate(-35 {cx-20} {cy-22})" fill="#fff" opacity=".75"/>')
    p.append(f'<circle cx="{cx-34}" cy="{cy-3}" r="3.4" fill="#fff" opacity=".7"/>')
    p.append(f'<path d="M{cx+r-9:.1f},{cy-8} Q{cx+r-9:.1f},{cy+14} {cx+24},{cy+26}" fill="none" stroke="#fff" stroke-opacity=".28" stroke-width="3.5" stroke-linecap="round"/>')
    return svg(102, 172, "".join(p))


def main():
    (OUT / "console.svg").write_text(console())
    for kind in ("pause", "sound", "settings"):
        (OUT / f"btn_{kind}.svg").write_text(button(kind, False))
        (OUT / f"btn_{kind}_icon.svg").write_text(button(kind, True))
    (OUT / "bulb.svg").write_text(bulb())
    print("wrote", sorted(p.name for p in OUT.glob("*.svg")))


if __name__ == "__main__":
    main()

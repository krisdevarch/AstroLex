#!/usr/bin/env python3
"""Writes the three round console buttons as SVG, each in two variants: btn_<k>.svg (face with the icon
disc left plain) and btn_<k>_icon.svg (with the icon). 149x149 game px, centre (73.5,73.5), neon ring r 48,
icon disc r 43.4, as the WP-F.12 cut. Run by make_hud.sh."""
import math
from pathlib import Path

C = 73.5
ORANGE = ("#ffb070", "#ff8a4a")
CYAN = ("#5ff2ff", "#22c8e0")
KINDS = {
    "pause": dict(ring=ORANGE, disc=("#0f5a78", "#162f55")),
    "sound": dict(ring=CYAN, disc=("#123c66", "#10294d")),
    "settings": dict(ring=CYAN, disc=("#132a54", "#0e1e44")),
}


def arc(r, a0, a1):
    p = lambda a: (C + r * math.cos(math.radians(a)), C + r * math.sin(math.radians(a)))
    (x0, y0), (x1, y1) = p(a0), p(a1)
    large = 1 if (a1 - a0) % 360 > 180 else 0
    return f"M{x0:.2f},{y0:.2f} A{r},{r} 0 {large} 1 {x1:.2f},{y1:.2f}"


def icon(kind, col):
    hi, lo = ("#55ecf6", "#22c8e0") if kind == "pause" else col
    if kind == "pause":
        return (f'<g fill="{hi}" stroke="#04202e" stroke-width="2.5">'
                '<rect x="55" y="50" width="12" height="47" rx="5"/><rect x="80" y="50" width="12" height="47" rx="5"/></g>'
                '<g fill="#d8ffff" opacity="0.7"><rect x="58" y="55" width="3.5" height="33" rx="1.7"/><rect x="83" y="55" width="3.5" height="33" rx="1.7"/></g>')
    if kind == "sound":
        waves = "".join(f'<path d="M{C + 4 + 0:.1f},0" fill="none"/>' for _ in range(0))
        def wv(r):
            a = math.radians(48)
            x, y = 73 + r * math.cos(a), 73.5 - r * math.sin(a)
            return f'<path d="M{x:.1f},{73.5 - r * math.sin(a):.1f} A{r},{r} 0 0 1 {x:.1f},{73.5 + r * math.sin(a):.1f}" fill="none" stroke="{hi}" stroke-width="4" stroke-linecap="round"/>'
        return (f'<path d="M48,61 H60 L77,48 V99 L60,86 H48 Z" fill="{hi}" stroke="#04202e" stroke-width="2.5" stroke-linejoin="round"/>'
                '<path d="M52,64 H60" stroke="#d8ffff" stroke-width="2.5" opacity="0.7"/>' + wv(15) + wv(25))
    # settings gear
    teeth = []
    for i in range(8):
        a = i * 45
        teeth.append(f'<rect x="{C - 6.5}" y="{C - 26}" width="13" height="14" rx="2.5" transform="rotate({a} {C} {C})"/>')
    return (f'<g fill="{hi}" stroke="#04202e" stroke-width="2.5" stroke-linejoin="round">' + "".join(teeth) +
            f'<circle cx="{C}" cy="{C}" r="18"/></g><circle cx="{C}" cy="{C}" r="18" fill="{hi}"/>'
            f'<circle cx="{C}" cy="{C}" r="8" fill="#10305a" stroke="#04202e" stroke-width="2.5"/>')


def svg(kind, with_icon):
    k = KINDS[kind]
    hi, lo = k["ring"]
    d0, d1 = k["disc"]
    if kind == "pause":
        arcs = [(188, 265), (275, 352), (8, 85), (95, 172)]
    elif kind == "settings":
        arcs = [(186, 354), (6, 174)]
    else:
        arcs = [(190, 350), (10, 170)]
    ring = "".join(f'<path d="{arc(48, a, b)}" fill="none" stroke="{hi}" stroke-width="7" stroke-linecap="butt"/>' for a, b in arcs)
    halo = "".join(f'<path d="{arc(48, a, b)}" fill="none" stroke="{lo}" stroke-width="13" opacity="0.28" filter="url(#bl)"/>' for a, b in arcs)
    ticks = "".join(
        f'<path d="M{C + 59 * math.cos(math.radians(a)):.1f},{C + 59 * math.sin(math.radians(a)):.1f} L{C + 69 * math.cos(math.radians(a)):.1f},{C + 69 * math.sin(math.radians(a)):.1f}" stroke="#04071a" stroke-width="3"/>'
        for a in (45, 135, 225, 315))
    dots = (f'<circle cx="{C}" cy="{C}" r="37" fill="none" stroke="#8fe9f0" stroke-width="1.4" stroke-dasharray="1.2 3.6" opacity="0.8"/>' if kind == "settings" else "")
    body = icon(kind, k["ring"]) if with_icon else ""
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="149" height="149" viewBox="0 0 149 149">
  <defs>
    <linearGradient id="rim" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8fb3d9"/><stop offset="0.5" stop-color="#55789f"/><stop offset="1" stop-color="#34507c"/></linearGradient>
    <radialGradient id="disc" cx="0.5" cy="0.5" r="0.55"><stop offset="0" stop-color="{d0}"/><stop offset="1" stop-color="{d1}"/></radialGradient>
    <filter id="bl" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="2"/></filter>
  </defs>
  <circle cx="{C}" cy="{C}" r="70" fill="#04071a"/>
  <circle cx="{C}" cy="{C}" r="67.5" fill="url(#rim)"/>
  <circle cx="{C}" cy="{C}" r="58" fill="#04071a"/>
  <circle cx="{C}" cy="{C}" r="56" fill="#2c3454"/>
  <circle cx="{C}" cy="{C}" r="53" fill="#232b4a"/>
  {ticks}
  {halo}
  {ring}
  {dots}
  <circle cx="{C}" cy="{C}" r="44.5" fill="#04071a"/>
  <circle cx="{C}" cy="{C}" r="43.4" fill="url(#disc)"/>
  {body}
</svg>
'''


out = Path(__file__).parent
for kind in KINDS:
    (out / f"btn_{kind}.svg").write_text(svg(kind, False))
    (out / f"btn_{kind}_icon.svg").write_text(svg(kind, True))

"""HUD text contrast report (WP-F.9): WCAG contrast ratios of the HUD text colours against the navy panel and
each act sky's average colour (game/art/backdrop/*.jpg). Fails (exit 1) under 4.5:1 for body text.

Usage: ``python -m astrolex_tools.contrast --out reports/ci/contrast.md``  (needs Pillow)

Menu text sits on the sky under a dark veil (ui.gd `add_sky(veil)` draws NAVY_DEEP over it at SKY_VEIL alpha), so
the sky rows are measured through that veil too; the bare average is listed for information.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from astrolex_tools import repo_root

CREAM = "#efe8d6"
MUTED = "#aab3cc"
ORANGE = "#f7a21d"
INK = "#1c2740"
NAVY = (0.09 * 255, 0.12 * 255, 0.2 * 255)  # ui.gd NAVY (cards and panels)
NAVY_DEEP = (0x0B, 0x12, 0x26)
SKY_VEIL = 0.66  # settings and credits screens; the menus use 0.45-0.66
BODY_MIN = 4.5
SKIES = ["low_orbit", "act2_nebula", "act3_tower", "act4_core"]


def rgb(h: str) -> tuple[float, float, float]:
    h = h.lstrip("#")
    return tuple(float(int(h[i:i + 2], 16)) for i in (0, 2, 4))  # type: ignore[return-value]


def luminance(c) -> float:
    def lin(v: float) -> float:
        v /= 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(v) for v in c)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ratio(a, b) -> float:
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def veiled(c, veil: float = SKY_VEIL):
    return tuple(v * (1 - veil) + d * veil for v, d in zip(c, NAVY_DEEP))


def sky_average(name: str):
    from PIL import Image
    path = repo_root() / "game" / "art" / "backdrop" / f"{name}.jpg"
    px = Image.open(path).convert("RGB").resize((1, 1), Image.BOX).getpixel((0, 0))
    return tuple(float(v) for v in px)


def rows() -> list[tuple[str, str, float, bool]]:
    """(text, background, ratio, is_body) for every checked pair."""
    out = [
        ("cream", "navy panel", ratio(rgb(CREAM), NAVY), True),
        ("muted", "navy panel", ratio(rgb(MUTED), NAVY), True),
        ("orange", "navy panel", ratio(rgb(ORANGE), NAVY), True),
        ("ink", "orange button", ratio(rgb(INK), rgb(ORANGE)), True),
    ]
    for s in SKIES:
        avg = sky_average(s)
        for name, col in (("cream", CREAM), ("muted", MUTED)):
            out.append((name, f"{s} sky average (bare, info)", ratio(rgb(col), avg), False))
            out.append((name, f"{s} sky under veil", ratio(rgb(col), veiled(avg)), True))
    return out


def render(rs) -> str:
    lines = ["# HUD text contrast (WP-F.9)", "", f"WCAG ratio; body text must reach {BODY_MIN}:1.", "",
             "| text | background | ratio | body | result |", "|---|---|---|---|---|"]
    for t, bg, r, body in rs:
        res = "pass" if r >= BODY_MIN else ("FAIL" if body else "info")
        lines.append(f"| {t} | {bg} | {r:.2f} | {'yes' if body else 'no'} | {res} |")
    return "\n".join(lines) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="WP-F.9/contrast.md")
    a = ap.parse_args()
    rs = rows()
    p = Path(a.out)
    if not p.is_absolute():
        p = repo_root() / (p if p.parts[0] == "reports" else Path("reports") / p)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(render(rs))
    bad = [r for r in rs if r[3] and r[2] < BODY_MIN]
    for t, bg, r, _ in bad:
        print(f"FAIL {t} on {bg}: {r:.2f}")
    print(f"contrast: {len(rs)} pairs, {len(bad)} below {BODY_MIN}:1")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())

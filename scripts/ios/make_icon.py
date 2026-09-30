"""Placeholder app icon (1024x1024 RGB PNG, no alpha) drawn with the stdlib only.

Human-made art replaces it in Phase 4 (O-14). Run: python3 scripts/ios/make_icon.py
"""
import math
import pathlib
import struct
import zlib

SIZE = 1024
OUT = pathlib.Path(__file__).resolve().parents[2] / "ios/AstroLex/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

BG_TOP = (5, 8, 20)
BG_BOTTOM = (18, 24, 52)
TILE = (245, 244, 238)
INK = (13, 18, 41)
GOLD = (250, 199, 77)


def seg_dist(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - ax - t * dx, py - ay - t * dy)


def rounded_box_dist(px, py, cx, cy, half, radius):
    qx = abs(px - cx) - (half - radius)
    qy = abs(py - cy) - (half - radius)
    return math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - radius


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def pixel(x, y):
    px, py = x + 0.5, y + 0.5
    colour = mix(BG_TOP, BG_BOTTOM, py / SIZE)
    # Faint stars.
    h = (x * 73856093 ^ y * 19349663) & 0xFFFF
    if h < 6:
        colour = mix(colour, (200, 210, 255), 0.6)
    # Gold tether arc behind the tile.
    ring = abs(math.hypot(px - 512, py - 560) - 400) - 7
    if ring < 1:
        colour = mix(colour, GOLD, min(1, 1 - ring) if ring > 0 else 1)
    # Tile.
    d = rounded_box_dist(px, py, 512, 500, 300, 70)
    if d < 1:
        colour = mix(colour, TILE, min(1, 1 - d) if d > 0 else 1)
        # Letter A: two legs and a crossbar.
        s = min(
            seg_dist(px, py, 512, 300, 372, 700),
            seg_dist(px, py, 512, 300, 652, 700),
            seg_dist(px, py, 425, 560, 599, 560),
        ) - 38
        if s < 1:
            colour = mix(colour, INK, min(1, 1 - s) if s > 0 else 1)
    return colour


def main():
    rows = bytearray()
    for y in range(SIZE):
        rows.append(0)
        for x in range(SIZE):
            rows.extend(pixel(x, y))

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(rows), 9))
    png += chunk(b"IEND", b"")
    OUT.write_bytes(png)
    print(f"wrote {OUT} ({len(png)} bytes)")


if __name__ == "__main__":
    main()

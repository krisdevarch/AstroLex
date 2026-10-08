"""Placeholder AstroLex icon (dark sky, gold tether ring, letter tile 'A') for the Godot project:
app icon, web favicon and home-screen icon, and the loading-screen image. Stdlib only.
Human-made art replaces it in Phase 4 (O-14). Run: python3 scripts/godot/make_brand.py
"""
import math
import pathlib
import struct
import zlib

SIZE = 512
OUT = pathlib.Path(__file__).resolve().parents[2] / "game" / "brand" / "icon.png"
BG_TOP, BG_BOTTOM = (5, 8, 20), (18, 24, 52)
TILE, INK, GOLD = (245, 244, 238), (13, 18, 41), (250, 199, 77)


def seg(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - ax - t * dx, py - ay - t * dy)


def box(px, py, cx, cy, half, r):
    qx, qy = abs(px - cx) - (half - r), abs(py - cy) - (half - r)
    return math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - r


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def cover(d):
    return 1.0 if d <= 0 else max(0.0, 1.0 - d)


def pixel(x, y):
    s = SIZE / 1024
    px, py = (x + 0.5) / s, (y + 0.5) / s
    c = mix(BG_TOP, BG_BOTTOM, py / 1024)
    c = mix(c, GOLD, cover((abs(math.hypot(px - 512, py - 560) - 400) - 7) * s))
    c = mix(c, TILE, cover(box(px, py, 512, 500, 300, 70) * s))
    letter = min(seg(px, py, 512, 300, 372, 700), seg(px, py, 512, 300, 652, 700), seg(px, py, 425, 560, 599, 560)) - 38
    if box(px, py, 512, 500, 300, 70) < 0:
        c = mix(c, INK, cover(letter * s))
    return c


def main():
    rows = bytearray()
    for y in range(SIZE):
        rows.append(0)
        for x in range(SIZE):
            rows.extend(pixel(x, y))

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(rows), 9)) + chunk(b"IEND", b"")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(png)
    print(f"wrote {OUT} ({len(png)} bytes)")


if __name__ == "__main__":
    main()

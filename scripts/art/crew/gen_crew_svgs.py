#!/usr/bin/env python3
"""Generates the five crew bust SVGs (rhee, ade, kit, vanta, tomas) next to this file.
Style rules: docs/design/characters.md. Bold dark outline on every shape, flat fill + one cel-shade
+ one glossy highlight, big glossy eyes, ~15 degree turn to the right (features shifted right).
Run: python3 scripts/art/crew/gen_crew_svgs.py  (then scripts/art/make_crew.sh renders the PNGs)."""
import os

OUT = "#1b2333"
SW = 8
_n = [0]
defs = []


def uid():
    _n[0] += 1
    return f"c{_n[0]}"


def E(cx, cy, rx, ry):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" %s/>'


def C(cx, cy, r):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" %s/>'


def P(d):
    return f'<path d="{d}" %s/>'


def shape(el, fill, shade=None, gloss=None, sw=SW, dx=-14, dy=-12):
    """Outlined shape: shade colour underneath, lit fill offset up-left on top (cel band), gloss ellipse."""
    stroke = f'stroke="{OUT}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round"'
    if not shade:
        s = el % f'fill="{fill}" {stroke}'
    else:
        i = uid()
        defs.append(f'<clipPath id="{i}">{el % ""}</clipPath>')
        s = el % f'fill="{shade}"'
        lit = el % ('fill="%s"' % fill)
        s += f'<g clip-path="url(#{i})"><g transform="translate({dx},{dy})">{lit}</g></g>'
        s += el % f'fill="none" {stroke}'
    if gloss:
        x, y, rx, ry, r = gloss
        s += f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" transform="rotate({r} {x} {y})" fill="#fff" opacity=".85"/>'
    return s


def eye(cx, cy, rx, ry, iris, look=(3, 2)):
    ix, iy = cx + look[0], cy + look[1]
    irx, iry = rx * 0.76, ry * 0.82
    s = f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#fff" stroke="{OUT}" stroke-width="7"/>'
    s += f'<ellipse cx="{ix}" cy="{iy}" rx="{irx}" ry="{iry}" fill="{iris}" stroke="{OUT}" stroke-width="4"/>'
    s += f'<ellipse cx="{ix}" cy="{iy + iry * .1}" rx="{irx * .55}" ry="{iry * .58}" fill="{OUT}"/>'
    s += f'<ellipse cx="{ix - irx * .35}" cy="{iy - iry * .38}" rx="{irx * .34}" ry="{iry * .3}" fill="#fff"/>'
    s += f'<circle cx="{ix + irx * .38}" cy="{iy + iry * .42}" r="{irx * .14}" fill="#fff"/>'
    return s


def cheek(x, y, c, rx=22, ry=14):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{c}" opacity=".85"/>'


def smile(x, y, w, h, sw=7):
    return f'<path d="M{x - w} {y} Q{x} {y + h} {x + w} {y}" fill="none" stroke="{OUT}" stroke-width="{sw}" stroke-linecap="round"/>'


def brow(x1, y1, x2, y2, c=OUT, w=9):
    return f'<path d="M{x1} {y1} Q{(x1 + x2) / 2} {min(y1, y2) - 10} {x2} {y2}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round"/>'


def stalk(pts, tip, tip_r, col, glow=None):
    """Wobbly stalk through pts (smooth quad chain) with a round tip."""
    d = f"M{pts[0][0]} {pts[0][1]}"
    for (cx, cy), (x, y) in zip(pts[1::2], pts[2::2]):
        d += f" Q{cx} {cy} {x} {y}"
    s = f'<path d="{d}" fill="none" stroke="{OUT}" stroke-width="22" stroke-linecap="round"/>'
    s += f'<path d="{d}" fill="none" stroke="{col}" stroke-width="10" stroke-linecap="round"/>'
    tc = glow or col
    s += shape(C(tip[0], tip[1], tip_r), tc, None)
    s += f'<circle cx="{tip[0] - tip_r * .3}" cy="{tip[1] - tip_r * .3}" r="{tip_r * .32}" fill="#fff" opacity=".9"/>'
    return s


def svg(body):
    d = "".join(defs)
    defs.clear()
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">'
            f'<defs>{d}</defs><g transform="translate(262 266) scale(1.1) translate(-262 -262)">{body}</g></svg>')


SHOULDERS = "M30 512 L30 478 Q44 404 150 380 Q262 408 376 380 Q480 404 494 478 L494 512 Z"


def rhee():
    SK, SKS = "#CFC8EA", "#A9A0D2"
    HAIR, HAIRS = "#DADFE8", "#AEB6C8"
    AM, AMS = "#F8BC04", "#D08E00"
    b = ""
    # bun + stylus
    b += shape(C(262, 84, 52), HAIR, HAIRS, (240, 66, 16, 8, -30))
    b += f'<path d="M205 118 L335 36" stroke="{OUT}" stroke-width="20" stroke-linecap="round"/>'
    b += f'<path d="M205 118 L335 36" stroke="{AM}" stroke-width="9" stroke-linecap="round"/>'
    b += shape(C(336, 36, 11), "#fff", None, None, 6)
    # coat
    b += shape(P(SHOULDERS), AM, AMS, (110, 440, 24, 8, -20))
    # high collar flaps
    b += shape(P("M170 372 L196 330 L262 372 L240 440 L190 424 Z"), AM, AMS, None)
    b += shape(P("M354 372 L330 330 L262 372 L284 440 L334 424 Z"), AM, AMS, None)
    b += f'<path d="M262 400 L262 512" stroke="{OUT}" stroke-width="7"/>'
    b += f'<circle cx="262" cy="452" r="9" fill="#fff" stroke="{OUT}" stroke-width="5"/>'
    b += f'<circle cx="262" cy="490" r="9" fill="#fff" stroke="{OUT}" stroke-width="5"/>'
    # head
    b += shape(E(264, 244, 146, 134), SK, SKS, (160, 160, 30, 11, -35))
    # ear (far side hint) handled by hair; fringe/hair cap
    b += shape(P("M116 246 Q104 118 264 108 Q420 114 412 246 Q372 190 318 178 Q250 206 190 186 Q132 196 116 246 Z"),
               HAIR, HAIRS, (180, 138, 34, 9, -25))
    # cheeks
    b += cheek(190, 306, "#F59ABA", 20, 12) + cheek(340, 304, "#F59ABA", 20, 12)
    # glasses (round amber rims)
    for cx, cy, r in ((206, 252, 48), (328, 248, 44)):
        b += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#fff" fill-opacity=".35"/>'
    b += eye(208, 254, 32, 36, "#B7791F") + eye(330, 250, 29, 34, "#B7791F")
    for cx, cy, r in ((206, 252, 48), (328, 248, 44)):
        b += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{OUT}" stroke-width="16"/>'
        b += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{AM}" stroke-width="7"/>'
    b += f'<path d="M253 246 Q267 236 283 244" fill="none" stroke="{OUT}" stroke-width="14" stroke-linecap="round"/>'
    b += f'<path d="M253 246 Q267 236 283 244" fill="none" stroke="{AM}" stroke-width="6" stroke-linecap="round"/>'
    b += '<path d="M172 226 Q190 212 208 214" fill="none" stroke="#fff" stroke-width="6" stroke-linecap="round" opacity=".8"/>'
    # guilty brows: inner ends raised
    b += brow(176, 190, 234, 176, "#8A92A8", 10) + brow(296, 174, 348, 188, "#8A92A8", 10)
    # nose + small kind smile
    b += f'<path d="M270 288 Q280 296 270 302" fill="none" stroke="{OUT}" stroke-width="5" stroke-linecap="round"/>'
    b += smile(276, 330, 28, 14)
    return svg(b)


def ade():
    SK, SKS = "#FF9A3C", "#F2A878"
    SF, SFS = "#88FFEE", "#4DD2C0"
    b = ""
    # ear stalks (wobbly)
    b += stalk([(210, 130), (180, 112), (214, 96), (188, 80), (196, 64)], (196, 64), 19, "#FF9A3C", "#FFB866")
    b += stalk([(322, 130), (352, 112), (318, 96), (344, 80), (336, 64)], (336, 64), 19, "#FF9A3C", "#FFB866")
    # jacket
    b += shape(P(SHOULDERS), SF, SFS, (110, 440, 24, 8, -20))
    b += f'<path d="M262 410 L262 512" stroke="{OUT}" stroke-width="7"/>'
    b += shape(P("M170 384 L214 410 L250 400 L262 440 L226 454 Z"), SF, SFS, None)
    b += shape(P("M358 384 L318 410 L284 400 L262 440 L298 454 Z"), SF, SFS, None)
    # head
    b += shape(E(264, 238, 152, 142), SK, SKS, (170, 150, 32, 11, -35))
    b += cheek(180, 298, "#FF8A6A", 24, 15) + cheek(352, 296, "#FF8A6A", 24, 15)
    # headset band over crown
    b += f'<path d="M122 236 Q130 90 270 88 Q404 92 412 236" fill="none" stroke="{OUT}" stroke-width="28" stroke-linecap="round"/>'
    b += f'<path d="M122 236 Q130 90 270 88 Q404 92 412 236" fill="none" stroke="{SF}" stroke-width="14" stroke-linecap="round"/>'
    b += '<path d="M170 140 Q200 104 250 98" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round" opacity=".85"/>'
    # ear cups
    b += shape(E(120, 262, 28, 42), "#2A3550", "#1b2333", (112, 244, 6, 14, 0))
    b += shape(E(120, 262, 16, 28), SF, None)
    b += shape(E(410, 262, 26, 40), "#2A3550", "#1b2333", None)
    b += shape(E(410, 262, 14, 26), SF, None)
    # eyes
    b += eye(214, 236, 34, 40, "#7A3E1D") + eye(334, 232, 31, 37, "#7A3E1D")
    b += brow(176, 186, 240, 182, "#5A2D12", 9) + brow(308, 180, 366, 182, "#5A2D12", 9)
    # huge grin
    b += shape(P("M196 292 Q276 288 354 290 Q344 372 276 376 Q206 372 196 292 Z"), "#7A1F2B", None, None, 8)
    b += f'<path d="M204 296 Q276 292 346 294 Q342 318 276 320 Q212 318 204 296 Z" fill="#fff" stroke="{OUT}" stroke-width="4"/>'
    b += f'<path d="M232 350 Q276 330 322 350 Q308 372 276 372 Q244 372 232 350 Z" fill="#FF7A92"/>'
    b += f'<path d="M196 292 Q276 288 354 290 Q344 372 276 376 Q206 372 196 292 Z" fill="none" stroke="{OUT}" stroke-width="8" stroke-linejoin="round"/>'
    # mic boom from left cup
    b += f'<path d="M112 296 Q124 384 196 372" fill="none" stroke="{OUT}" stroke-width="16" stroke-linecap="round"/>'
    b += f'<path d="M112 296 Q124 384 196 372" fill="none" stroke="{SF}" stroke-width="7" stroke-linecap="round"/>'
    b += shape(E(204, 372, 20, 16), "#2A3550", "#1b2333", (198, 366, 6, 4, 0))
    return svg(b)


def kit():
    SK, SKS = "#C2EBDA", "#A3A2DE"
    PK, PKS = "#FF88CC", "#D4559F"
    VI, VIS = "#8450E0", "#5A2FB0"
    b = ""
    # antennae
    b += stalk([(200, 108), (182, 80), (176, 66), (160, 50), (140, 48)], (136, 48), 22, "#FFB3DD", "#FF88CC")
    b += stalk([(326, 104), (348, 78), (356, 66), (376, 50), (396, 48)], (400, 48), 22, "#FFB3DD", "#FF88CC")
    # shirt + overalls
    b += shape(P(SHOULDERS), "#38C5C9", "#1F94A0", None)
    b += shape(P("M110 512 L126 430 Q190 400 262 420 Q340 400 392 430 L410 512 Z"), PK, PKS, (160, 470, 24, 8, -15))
    b += shape(P("M150 384 L194 396 L186 512 L128 512 Z"), PK, PKS, None)
    b += shape(P("M376 384 L330 396 L338 512 L396 512 Z"), PK, PKS, None)
    b += shape(C(178, 446, 12), "#FFD84A", "#E0A800", None, 6)
    b += shape(C(346, 446, 12), "#FFD84A", "#E0A800", None, 6)
    # collar of shirt
    b += shape(P("M206 392 L262 438 L318 392 L300 372 L262 396 L224 372 Z"), "#fff", "#C6D4E4", None)
    # head
    b += shape(E(264, 244, 146, 136), SK, SKS, (166, 166, 30, 11, -35))
    # spiky violet hair (behind fringe)
    b += shape(P("M120 236 Q100 160 130 130 L140 78 L184 118 L210 52 L244 112 L282 46 L304 112 L350 64 L358 126 L402 112 L398 170 Q420 200 410 238 Q372 180 320 170 Q262 196 206 176 Q148 190 120 236 Z"),
               VI, VIS, (176, 112, 22, 8, -40))
    b += cheek(184, 308, "#FF7FA8", 22, 13) + cheek(346, 304, "#FF7FA8", 22, 13)
    # freckles
    for x, y in ((170, 290), (190, 298), (204, 286), (322, 286), (338, 296), (356, 284), (310, 300)):
        b += f'<circle cx="{x}" cy="{y}" r="3.6" fill="#5F8FA8"/>'
    # eyes
    b += eye(212, 250, 32, 36, "#FF4FA8", (2, 2)) + eye(334, 246, 29, 34, "#FF4FA8", (2, 2))
    b += brow(176, 202, 238, 198, "#5A2FB0", 9)
    # loupe on viewer-right eye
    b += f'<circle cx="334" cy="246" r="46" fill="#bfefff" fill-opacity=".35"/>'
    b += f'<circle cx="334" cy="246" r="46" fill="none" stroke="{OUT}" stroke-width="18"/>'
    b += f'<circle cx="334" cy="246" r="46" fill="none" stroke="#FFD24A" stroke-width="8"/>'
    b += '<path d="M306 226 Q316 210 336 208" fill="none" stroke="#fff" stroke-width="6" stroke-linecap="round"/>'
    b += f'<path d="M380 236 Q404 200 396 150" fill="none" stroke="{OUT}" stroke-width="10" stroke-linecap="round"/>'
    # blunt mouth
    b += f'<path d="M232 328 Q268 336 300 324" fill="none" stroke="{OUT}" stroke-width="7" stroke-linecap="round"/>'
    b += f'<path d="M300 324 Q308 322 312 314" fill="none" stroke="{OUT}" stroke-width="6" stroke-linecap="round"/>'
    return svg(b)


def vanta():
    SK, SKS = "#E7B4C2", "#BE8398"
    CR, CRS = "#C9374C", "#8E1F34"
    RO = "#FF8AA0"
    b = ""
    # crest (swept back, sharp)
    b += shape(P("M300 100 Q250 40 130 36 Q122 34 112 28 Q196 60 190 112 Z"), RO, "#E0566E", (150, 62, 22, 6, -25))
    # suit + white stripe
    b += shape(P(SHOULDERS), CR, CRS, (110, 440, 24, 8, -20))
    b += f'<path d="M60 470 Q150 410 262 430" fill="none" stroke="{OUT}" stroke-width="40" stroke-linecap="round"/>'
    b += f'<path d="M60 470 Q150 410 262 430" fill="none" stroke="#fff" stroke-width="24" stroke-linecap="round"/>'
    b += shape(P("M186 388 L236 410 L262 512 L170 512 Z"), CR, CRS, None)
    b += shape(P("M338 388 L288 410 L262 512 L354 512 Z"), CR, CRS, None)
    b += f'<path d="M186 388 Q262 436 338 388" fill="none" stroke="{OUT}" stroke-width="8"/>'
    # head
    b += shape(P("M120 228 Q112 118 266 112 Q416 118 410 228 Q410 310 340 350 Q266 392 190 350 Q122 312 120 228 Z"),
               SK, SKS, (160, 170, 28, 10, -35))
    # helmet dome with open face
    b += shape(P("M104 252 Q92 90 262 84 Q438 90 424 252 L400 262 Q396 198 340 190 Q262 168 190 190 Q132 198 130 262 Z"),
               CR, CRS, (170, 120, 36, 9, -30))
    # visor pushed up on dome
    b += shape(P("M144 186 Q150 120 262 112 Q384 120 388 186 Q262 150 144 186 Z"), "#2B3560", "#161C38", None)
    b += '<path d="M176 156 Q214 128 262 126" fill="none" stroke="#9FB8FF" stroke-width="7" stroke-linecap="round" opacity=".9"/>'
    b += f'<path d="M150 192 Q262 160 384 192" fill="none" stroke="{RO}" stroke-width="7" stroke-linecap="round"/>'
    # ear pieces
    b += shape(E(112, 270, 24, 40), "#2A3550", "#1b2333", None)
    b += shape(E(418, 270, 22, 38), "#2A3550", "#1b2333", None)
    # cheeks guard rose trim
    b += cheek(176, 312, "#F08098", 18, 11) + cheek(350, 306, "#F08098", 18, 11)
    # eyes: confident, half-lidded top
    b += eye(214, 256, 31, 34, "#C9374C") + eye(332, 252, 28, 32, "#C9374C")
    b += brow(172, 222, 244, 218, OUT, 10) + brow(304, 214, 366, 204, OUT, 10)
    # smirk
    b += f'<path d="M244 330 Q290 342 332 316" fill="none" stroke="{OUT}" stroke-width="8" stroke-linecap="round"/>'
    b += f'<path d="M332 316 L342 306" stroke="{OUT}" stroke-width="7" stroke-linecap="round"/>'
    b += f'<path d="M280 292 Q290 300 280 306" fill="none" stroke="{OUT}" stroke-width="5" stroke-linecap="round"/>'
    return svg(b)


def tomas():
    SK, SKS = "#BDBAF4", "#938FD2"
    CO, COS = "#FF6B35", "#CC4412"
    HR, HRS = "#5A3C2E", "#3A2418"
    TL = "#2DD4BF"
    b = ""
    # hood ring behind head
    b += shape(E(264, 408, 168, 74), CO, COS, (150, 392, 26, 8, -10))
    # hoodie body (oversized)
    b += shape(P("M12 512 L12 480 Q20 408 130 392 Q264 440 396 392 Q504 408 512 480 L512 512 Z"), CO, COS, (100, 448, 24, 8, -20))
    # hood opening rim + strings
    b += shape(P("M150 392 Q264 452 380 392 Q370 428 264 450 Q160 430 150 392 Z"), "#FF9A6A", COS, None, 7)
    b += f'<path d="M232 440 L224 500" stroke="{OUT}" stroke-width="12" stroke-linecap="round"/>'
    b += f'<path d="M232 440 L224 500" stroke="#fff" stroke-width="5" stroke-linecap="round"/>'
    b += f'<path d="M300 442 L308 498" stroke="{OUT}" stroke-width="12" stroke-linecap="round"/>'
    b += f'<path d="M300 442 L308 498" stroke="#fff" stroke-width="5" stroke-linecap="round"/>'
    b += shape(C(224, 502, 8), "#fff", None, None, 5) + shape(C(308, 500, 8), "#fff", None, None, 5)
    # rounded ear-fins
    b += shape(P("M146 268 Q96 226 84 270 Q92 316 148 306 Z"), "#8F8CE8", "#6A67C2", (110, 266, 6, 14, 0))
    b += shape(P("M392 262 Q440 222 452 264 Q444 308 394 300 Z"), "#8F8CE8", "#6A67C2", None)
    # small round head
    b += shape(E(268, 256, 128, 122), SK, SKS, (190, 190, 26, 10, -35))
    # hair: messy fringe
    b += shape(P("M140 250 Q128 128 262 124 Q396 126 394 250 Q372 196 338 178 Q326 214 292 176 Q262 212 236 176 Q206 214 190 184 Q154 202 140 250 Z"),
               HR, HRS, (200, 150, 28, 8, -25))
    b += cheek(186, 330, "#FF8FB0", 26, 17) + cheek(350, 326, "#FF8FB0", 24, 16)
    # very big eyes
    b += eye(214, 262, 42, 48, "#2E7DD6", (3, 3)) + eye(328, 258, 38, 45, "#2E7DD6", (3, 3))
    b += brow(176, 202, 244, 196, HRS, 8) + brow(298, 194, 360, 200, HRS, 8)
    # tiny nose and small brave smile
    b += f'<path d="M272 308 Q280 314 272 318" fill="none" stroke="{OUT}" stroke-width="5" stroke-linecap="round"/>'
    b += smile(276, 340, 20, 12, 6)
    return svg(b)


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    for name, fn in (("rhee", rhee), ("ade", ade), ("kit", kit), ("vanta", vanta), ("tomas", tomas)):
        with open(os.path.join(here, name + ".svg"), "w") as f:
            f.write(fn())
        print("wrote", name)

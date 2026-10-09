# WP-3.G evidence: glass-tile spike and frame-rate bench (O-22)

Branch `claude/glass-tiles-tny1fk`. Glass is a fourth tile treatment (default stays `tilt`) so the owner can measure the frame rate in a phone browser before glass becomes the look (O-22 gate: 20 glass tiles at 60 fps).

| # | Acceptance criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | Glass treatment: refraction (mip-blurred screen texture warped by the bevel), frost core, white glyph with ink halo, specular that slides with tilt, accent edge tint; back-plane shards are frosted with no glyph | pass | `scripts/godot/test.sh` (`test_glass.gd`), screenshot read by eye | `glass-bench.png`, `glass-bench-mid.png` |
| 2 | Glass look numbers are tunables (`glass.blur`, `glass.refractPx`, `glass.frost`, `glass.specular`, `glass.edgeTint`) | pass | `python -m astrolex_tools.validate_data` | `data/tunables/game.json` |
| 3 | Settings: four tile looks, "Show frame rate", "Frame-rate test" button | pass | `test_glass.gd`, `test_settings.gd` | – |
| 4 | Frame-rate readout (fps, p95 frame time, tiles) in rounds when enabled or with `?fps=1` | pass | `test_glass.gd` | `game/scenes/fps_meter.gd` |
| 5 | Bench: 20/30/40 drifting tiles, glass/tilt/flat toggle, 10 s test with avg fps, p50/p95 and PASS (avg ≥ 58, p95 ≤ 20 ms); `?bench=1`, `?bench=1&auto=1` | pass | `test_glass.gd`; `node smoke.cjs ../../../build/web --bench` | console `AstroLex bench: treatment=glass tiles=20 avg=29.5 fps p50=33.3 ms p95=38.3 ms BELOW 60` (software GL in headless Chromium, not a phone figure) |
| 6 | Godot tests and web export still pass | pass | `scripts/godot/test.sh`: 72 passed, 0 failed, no SCRIPT ERROR; `scripts/godot/export.sh web` + `smoke.cjs` ok | CI `godot.yml` |
| 7 | Phone frame-rate test (the O-22 gate) | owner | open `https://krisdevarch.github.io/AstroLex/?bench=1` on the phone after merge, Run 10 s test on glass and on tilt | to be pasted into the PR / `wps/_index.md` |

Notes: the painted placeholder sky (one baked texture) now sits behind the stars for every treatment so the comparison is fair. Local `pytest tools` shows 3 failures that also occur on a clean `main` in this container (the local word DB was built without ENABLE); CI builds its own DB.

## Round 2 (9 Oct 2026): owner phone test

Owner's iPhone (Safari), bench at 20 glass tiles: the tiles drew **black** and the meter read 26 fps with p95 124 ms. Cause: the live screen-texture copy and its mipmaps do not work on WebKit's WebGL (black) and cost a full-screen copy every frame. Fix: the glass now samples the baked sky texture (the backdrop's own, with mipmaps) at `SCREEN_UV`, so there is no screen copy at all. Added from the CC0 Fluid Glass UI shader (Binbun): a colour fringe at the bevel (`glass.chroma`) and fine grain (`glass.grain`); frost lowered to 0.18 so the glass reads as clear.

| Check | Result | Artefact |
|---|---|---|
| `scripts/godot/test.sh` | 72 passed, 0 failed | – |
| `smoke.cjs --bench` (software GL) | `avg=35.6 fps p50=27.2 ms p95=36.2 ms` (was 29.5 fps on the same machine) | `glass-bench-sky.png` |
| Owner phone re-test | pending | – |

## Round 3 (9 Oct 2026): clear glass from the owner's reference

The owner sent an Apple Liquid Glass reference (a clear sphere over a grid) and asked for the letters to match it. Changes: no frost (`glass.frost` 0), almost no blur (`glass.blur` 0.05), a lens zone at the rim that samples from further in so the sky and stars bend (`glass.refractPx` 24), a thin bright rim (cool on the left, warm on the right), a faint milky lift (`glass.milk` 0.08), a soft glow inside the top edge, accent edge cut to 0.15 and a lighter shadow. Stars are now baked into a texture (`tile_textures.stars()`) that both the backdrop and the glass sample, so stars bend at a tile's rim. The glyph stays white with a softer halo: a black glyph, as in the reference, would vanish on the dark sky.

| Check | Result | Artefact |
|---|---|---|
| `scripts/godot/test.sh` | 72 passed, 0 failed | – |
| `smoke.cjs --bench` (software GL) | `avg=36.0 fps p50=27.3 ms p95=31.3 ms` | `glass-clear.png` |
| Rounder corners (owner, 9 Oct): glass corner radius 24 → 38 of 61 px half-width | 72 passed; bench `avg=35.7 fps` | `glass-round.png` |

## Round 4 (9 Oct 2026): bubble look

The owner asked whether bubbles would look cooler. Added `bubble` as a fifth look (Settings and bench): the same glass shader with a circular shape (`corner` = half width), a lens across most of the ball, a thin-film rainbow rim that drifts slowly, a bright highlight spot up and to the left, and a gentle wobble instead of tilt (a sphere looks the same from any angle). The bench takes `?look=bubble` (and `smoke.cjs --look=bubble`).

| Check | Result | Artefact |
|---|---|---|
| `scripts/godot/test.sh` | 73 passed, 0 failed (new `test_tile_view_bubble_is_round_and_untilted`) | – |
| `smoke.cjs --bench --look=bubble` (software GL) | `avg=33.1 fps p50=29.3 ms p95=33.3 ms` | `bubbles.png` |
| Bigger bubbles, same letters (owner, 9 Oct): `glass.bubbleScale` 1.25; visual only, the catch radius is unchanged | 73 passed; bench `avg=30.9 fps p95=40.0 ms` (software GL) | `bubbles-big.png` |

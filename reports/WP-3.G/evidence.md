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

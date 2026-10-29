# WP-F.28 evidence: a sharp HUD

Branch `claude/project-thread-dh7ho0`. Frames: 390x844 phone at device pixel ratio 3 (the shell caps the game's ratio at 2, as on a real phone), `scripts/godot/web-smoke/hud-shot.cjs`, query `?autoplay=1&level=1-06&tap=3`.

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | Vector HUD art | pass | `scripts/art/make_hud.sh` renders `scripts/art/hud/console.svg`, `bulb.svg` and the six button SVGs (written by `gen_buttons.py`) at 2x into `game/art/hud/*.png` (console 1820x1064, buttons 298x298, bulb 204x344). Same viewBox as the old PNGs, so every `MOCK_*` position is unchanged. | `scripts/art/hud/`, `scripts/art/make_hud.sh` |
| 2 | Shown sharp | pass | All eight imports lossless (`compress/mode=0`) with mipmaps; `HudArt.ART_SCALE` 0.5 in `Console`, `RingArt`, `Icon._disc`; those controls use `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`. Slots sit in the screen, liquid in the channel, icons centred in their rings. | `reports/WP-F.28/hud-before-after.jpg`, `before-hud.png`, `after-hud.png` |
| 3 | Tidy layout | pass | In-round messages ("Drone down", "Letter stolen −2 s", wrong catch) were bare coloured text over the letters; they now sit on a dark glass pill like the top chips, sized to the text and centred. The redraw also drops two dark rectangles the old JPEG cut left at the clock bar's left end. | `reports/WP-F.28/toast-pill.png` |
| 4 | Checks | pass | `scripts/godot/test.sh`: 371 passed, 0 failed. `scripts/godot/export.sh web` ok (pack 3.8 MB); boots and plays on autoplay in Chromium. | this file |

## What changed in the look
- The art is a clean vector redraw of the old console, not a pixel copy: the JPEG noise and the painted scan-line texture in the porthole window are gone, the screen's edge notches are simpler, cables, gear and bulb filament are redrawn in the same style.
- The top chips, wrong-catch pill and all text were already drawn by Godot and were already sharp; they are unchanged.
- `scripts/art/cut_hud.py` stays for the record; the game no longer uses its output.

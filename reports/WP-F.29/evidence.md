# WP-F.29 evidence: intro screen in the game's own look (rebuild)

Frames: 390x844 phone at device pixel ratio 3, `node shot.cjs build/web <dir> '' 5000,3000` (intro) and `'?intro=0' 4000` (title).

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | Built from the game's kit | pass | `Ui.add_sky` (the title's painted Low Orbit sky and stars), "AstroLex" in Fredoka via `Ui.text` (cream, navy outline, soft cyan 4fe3ff glow copies), four `TileView` bubbles (the title logo row's glass shader, no glyph) over the Catcher busts with a thin suit-colour rim, standard `Ui.primary("Tap to start")` 600x156. Layout as the owner's reference: Wren top left small, Juno top right large, Ash bottom left large, Pip bottom right small. Bubbles pop in one by one and bob out of step; reduced motion holds still. Tap anywhere, the button or `intro.holdSec` finishes; skips unchanged. | `reports/WP-F.29/intro.jpg`, `intro-title.jpg`; `game/tests/scenes/test_intro.gd` |
| 2 | No generated key art | pass | `game/art/intro/` and `scripts/art/make_intro.py` deleted; only `res://brand/characters/*.png` is used. Busts sit on a layer behind all glass (the glass refracts one screen copy per frame) and the intro lowers `glass.dark` locally so they show through. | `grep -r art/intro` finds nothing |
| 3 | Checks | pass | `scripts/godot/test.sh`: 376 passed, 0 failed, no SCRIPT ERROR. `validate_data` ok. `scripts/godot/export.sh web` ok and boots in Chromium. | this file |

Left: the busts are the 320 px character PNGs cropped to the circle; at 540 px they are slightly soft.

# WP-F.29 evidence: intro screen in the game's own look (rebuild)

Frames: 390x844 phone at device pixel ratio 3, `node shot.cjs build/web <dir> '' 5000,3000` (intro) and `'?intro=0' 4000` (title).

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | Built from the game's kit | pass | `Ui.add_sky` (the title's painted Low Orbit sky and stars), "AstroLex" in Fredoka via `Ui.text` (cream, navy outline, soft cyan 4fe3ff glow copies), four `TileView` bubbles (the title logo row's glass shader, no glyph) over the Catcher busts with a thin suit-colour rim, standard `Ui.primary("Tap to start")` 600x156. Layout as the owner's reference: Wren top left small, Juno top right large, Ash bottom left large, Pip bottom right small. Bubbles pop in one by one and bob out of step; reduced motion holds still. Tap anywhere, the button or `intro.holdSec` finishes; skips unchanged. | `reports/WP-F.29/intro.jpg`, `intro-title.jpg`; `game/tests/scenes/test_intro.gd` |
| 2 | No generated key art | pass | No baked sky, logo or bubble. The only art added is four plain circle-cropped 640 px busts (head and shoulders, no bubble) in `game/art/intro/`, made by `scripts/art/make_intro_busts.py` (Pillow, reads only the four sheets in /mnt/project-files/design/characters), imported lossless with mipmaps. Busts sit on a layer behind all glass. The glass is tamed locally: dark, refract_px, blur, magnify, frost 0, rim_bend 0.12, chroma 0.25, milk 0.03, film 0.45; specular and rim kept. | `game/art/intro/*.png`, `intro.jpg` |
| 3 | Checks | pass | `scripts/godot/test.sh`: 376 passed, 0 failed, no SCRIPT ERROR. `validate_data` ok. `scripts/godot/export.sh web` ok and boots in Chromium. | this file |

Left: nothing.

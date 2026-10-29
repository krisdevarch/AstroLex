# WP-F.28 evidence: intro screen with the crew, and a crisp HUD

Branch `claude/project-thread-ub88bv`. Frames are from the web export in headless Chromium at 390x844 CSS px, device pixel ratio 3 (the game caps it at 2, WP-F.16), as on the owner's iPhone.

| AC | Result | Test or command | Artefact |
|---|---|---|---|
| 1 Intro screen | pass | `game/tests/scenes/test_intro.gd` (5 tests: off in headless, logo + four bubbles + Tap to start, tap goes to the title and Back from the map shows no second intro, double tap ends it once, timer under reduced motion); `scripts/godot/test.sh` | `intro.jpg`, `title.jpg`, `intro-title-play.jpg` |
| 2 Intro art | pass | `python3 scripts/art/make_intro.py` (fixed seed; rerun reproduces the committed files) | `game/art/intro/` |
| 3 Crisp HUD | pass | `scripts/art/hud/gen_hud_svgs.py` + `scripts/art/make_hud.sh` (SVG rendered at 2x); `HudArt.ART_SCALE` 2; mipmapped linear filtering; `test_hud.gd` layout tests unchanged and green | `hud-before.jpg`, `hud-after.jpg`, `play-after.jpg` |
| 4 Layout | pass, partly | bulb and the three buttons share one centre x (`test_hud.gd`, 0.5 px tolerance); right button rim 11 px and porthole 7 px from the screen edges. Not moved to `SIDE_PAD` (44 px): the console is edge-to-edge art and that would shrink the whole HUD | `hud-after.jpg` |
| 5 Checks | pass | `validate_data` ok; `scripts/godot/test.sh` 376 passed, 0 failed, no SCRIPT ERROR; `scripts/godot/export.sh web` boots to the intro and to play | this folder |

## Notes
- Cause of the blur: the console, buttons and bulb were crops of the 572x1024 JPEG mock upscaled 1.89x, with no mipmaps. They are now vector art in the same shapes and places.
- Game pack: 3.2 MB to 5.0 MB (intro sky 0.6 MB, four bubbles 0.75 MB, logo 0.35 MB, HUD at 2x). The intro, the logo and the console are lossy WebP at 0.92 with mipmaps; the logo is 1300 px, enough for the 2x cap.
- New tunable `intro.holdSec` (6 s). `?intro=0` skips the intro; the web smoke scripts use it.
- Placeholder art (O-14): the bubble busts are cut from the 1024 px Catcher art; the sky and logo are generated.

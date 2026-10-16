# WP-3.P evidence: Babel flies in, speaks and shoots the letters

Branch `claude/babel-entrance-muhodi`, 16 Oct 2026. Brief: `wps/WP-3.P.md`.

| AC | Result | Test or command | Artefact |
|---|---|---|---|
| AC1 | pass | `test_babel_flies_in_from_the_left_at_mid_screen_and_leaves` | `babel-entrance.mp4` |
| AC2 | pass | `test_babel_says_the_level_quote` (also checks the line stays inside the bubble and the bubble sits below the chips) | `babel-quote.jpg` |
| AC3 | pass | `test_letters_leave_from_the_muzzle`, `test_tiles_land_within_a_pixel_after_the_intro` | `babel-shoots.jpg` |
| AC4 | pass | `test_tap_skips_the_intro`, `test_reduced_motion_has_no_travel` | — |
| AC5 | pass | `test_new_letters_grow_in`, `test_a_long_first_frame_does_not_skip_the_throw`, `test_letters_ease_into_their_drift_after_the_throw` | `babel-entrance.mp4` |
| AC6 | pass | `python -m astrolex_tools.levels` (ok), `validate_data` (ok), `pytest tools` (all pass), `scripts/godot/test.sh` (184 passed, 0 failed, after round 2), `scripts/godot/export.sh web`, `smoke.cjs --autoplay` (ready in 1.9 s, round won) | — |
| AC7 | pass | `?autoplay=1` in headless Chromium, 393×852 | `babel-entrance.mp4` |

## The letter glitch
Found by logging every tile view frame by frame through level 1-01 (headless) and by frame-stepping a web recording:
1. Letters made during play (the refill after a catch and the next word's letters, five at once after the first word) appeared at full size and full opacity in a single frame. They now grow in from 0.35 scale and fade in over `tile.spawnInSec` (0.25 s; fade only under reduced motion).
2. The first frame of the throw can carry a load hitch (the field clamps a step to 0.25 s), which skipped the first launches, so a few letters were already sitting in place when the screen appeared. The intro and chatter now step at most 1/30 s per frame.
No existing letter jumped more than 10 px in a frame during play, so the separation pass is not a cause.

## Notes
- `babel-entrance.mp4`: 12 s, `?demo=1` (Wren picked, crew chatter on) in headless Chromium, software rendering at about real speed: the end of the chatter, Babel flies in from the left at mid-screen, types "Breakfast? Adorable. Show me how you chew." above his head, shoots 1-01's letters from his gun with a flash and recoil per shot, turns and flies back out left, the letters ease into their drift and the bot plays.
- Round 2 (owner, 16 Oct 2026, 14:07): entrance moved from the top right to the left at mid-screen, sprite smaller (`babel.heightShare` 0.36 → 0.26), bubble above him. The throw's remaining glitch was the landing: a 40 Hz scale wobble (it flickers at phone frame rates) and a large overshoot (`babel.throwOvershoot` 1.3 → 0.6); the wobble is gone. All letters also stood still through the throw and then started moving on one frame; they now ease into their drift over `babel.settleSec` (0.6 s) through a presentation-only `drift_scale` on the round (default 1.0, so the rules match the Python reference; the clock is unaffected).
- Babel's sprite: the owner's image cut out (`game/art/babel/README.md`). Idle: hover bob, breathing, slight tilt, cape sway shader; jet puffs in flight.
- Tunables added: `babel.settleSec`, `babel.enterSec`, `babel.quoteSec`, `babel.exitSec`, `babel.perchX`, `babel.perchY`, `babel.heightShare`, `babel.bobPx`, `babel.swayAmp`, `babel.recoilPx`, `tile.spawnInSec`. Removed (unused now the rift is gone): `babel.throwOriginX`, `babel.throwOriginY`, `babel.riftRadius`.
- Quotes: 48 `babelIntro` lines, `status: draft` (level files). Owner chose free quotes over letters-only (16 Oct 2026); the story bible's Rule 4 notes the exception.
- With a quote the entrance takes about 5 s; a tap skips it.
- Review (reviewer agent, 10 findings, none blocking): fixed the intro step clamp (0.1 s, so phones under 30 fps still run the entrance at speed), a grow-in cut short by a catch (the fly now starts at full size and alpha), Babel's recoil state after a skip, the quote hold time, and the sway shader keeping modulate. Look constants in `babel_view.gd` and the reduced-motion refresh went to the backlog.

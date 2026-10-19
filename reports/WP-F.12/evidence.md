# WP-F.12 evidence: play screen to the target mock, cute HUD animations, quiet stars

Brief: `wps/WP-F.12.md`. Decision: O-31 in `wps/_index.md`.

`before-after-mock.jpg`: the same moment of 1-01 in the exported web build (headless Chromium, `?demo=1`) before and after, next to the owner's target mock. `screens.jpg`: title, Catcher pick, Babel's bubble with the level card, pause. The animation recording (18 s of 1-01) is in the project files: `design/play-screen-mock-match/animations.mp4`.

| AC | Result | Check | Artefact |
|---|---|---|---|
| 1. Layout follows the target mock | pass | `test_hud.gd::test_hud_follows_the_target_mock` (1080x1920 and 1179x2556), `test_babel_bubble_fits_his_line`, `test_hud_nodes_exist_and_portrait_only_with_a_character` (no name pill), `test_bottom_hud_anchors_to_the_real_bottom_on_a_taller_screen` | `before-after-mock.jpg` |
| 2. Idle animations, all resting under reduced motion | pass | `test_hud.gd::test_hud_idles_with_life_and_rests_under_reduced_motion`; reduced motion is read every frame, so switching it in Settings mid-level stops them | `animations.mp4` |
| 3. Floating objects gone, quiet stars instead | pass | `test_hud.gd::test_back_plane_is_quiet_twinkling_stars`, `test_backdrop_has_quiet_stars_and_shooting_stars`, `test_glass.gd::test_back_plane_is_a_twinkling_star`; chair painted out of `game/art/backdrop/low_orbit.jpg` (OpenCV inpaint); `game/art/space/` removed | `before-after-mock.jpg` |
| 4. Whole-game look pass | pass | web tour of title, Catcher pick, difficulty, map, comms, play, level card, pause; title logo wave, Catcher bob, readable footer, Earth veil drawn as one polygon (no strip seams) | `screens.jpg` |
| 6. Console is the mock's own art (owner, 19 Oct: "make it pixel perfect") | pass | `scripts/art/cut_hud.py` cuts the console tray, clock-bar frame, three buttons and the bulb from the mock into `game/art/hud/` (astronaut, tiles, wires and liquid painted out); `field.gd` places everything in mock pixels (`_m()`); tiles, wires, slots, liquid and the play/muted icons are drawn in the mock's colours; `test_hud.gd` (all layout tests) | `console-vs-mock.jpg` (mock left, game right) |
| 5. Suite, data and web | pass | `scripts/godot/test.sh`: 262 passed, 0 failed, no SCRIPT ERROR; `python -m astrolex_tools.validate_data`: ok; `scripts/godot/export.sh web` exit 0; `smoke.cjs`: main scene ran in 2.1 s | |

New tunables (`data/tunables/game.json`, schema entries added): `glass.filmSat` 0.85 (rainbow saturation of the bubble rim), `glass.filmWidth` 17 (rim width in tile texture px). `glass.film` raised from 0.85 to 1.0.

Reviewer pass: no blocking findings. Fixed: a quick tap could leave a button shrunk (squish tween now replaces the last one); the clock liquid's front could cross its own cap at low time or poke past the frame when full; reduced motion switched mid-level now stops and resets every HUD animation; Babel's bubble measures with its own font; the console reuses its styleboxes instead of making new ones each frame.

Not changed, on purpose: the act paintings' planets, moon, galaxies and the heart nebula stay. They are each act's sky, not floating objects; the owner can ask for them to go too.

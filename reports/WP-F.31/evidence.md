# WP-F.31 evidence

Branch `claude/project-thread-7nbi9y`, 6 Nov 2026. Spec: `wps/WP-F.31.md`.

Frames: `node scripts/godot/web-smoke/boot-film.cjs build/web <out> 12 150 2 2` (390x844, wasm held 2 s, tap 2 s after the hand-off), stock web template, swiftshader.

- Before (main 81d6db3): `before.jpg`. Loader, overlay fading over the intro, intro, intro at 6 s, dip to black, title rebuilt.
- After: `after.jpg`. Loader, loader at 100 %, hand-off to the enabled "Tap to start", tap, menu fading in, title. The art never changes.

## Acceptance criteria

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | Intro is the title; tap or timer cross-fades the button to the menu; no rebuild, no black | pass | `test_intro.gd`: `test_intro_is_the_title_with_only_tap_to_start`, `test_tap_reveals_the_menu_on_the_same_screen_once_per_launch` (same node after the tap), `test_reveal_cross_fades_without_a_black_dip`, `test_timer_reveals_the_menu_even_with_reduced_motion`, `test_touch_and_double_tap_reveal_once` | `game/scenes/start_screen.gd`, `after.jpg` |
| 2 | Loader waits for the game's first drawn screen (10 s fallback), bar at 100 % | pass | boot-film: game ready at 3.75 s, overlay gone at 5.89 s (two frames + 0.5 s fade); `after.jpg` frame 2 | `scripts/web/shell.template.html`, `game/scenes/main.gd` `_tell_page_when_drawn` |
| 3 | Boot splash image off | pass | `game/project.godot` `boot_splash/show_image=false` | — |
| 4 | `?intro=still` capture still works | pass | `test_intro.gd::test_still_capture_is_still_available` | `game/scenes/intro_screen.gd` |
| 5 | Tests, smoke, recovery | pass | `scripts/godot/test.sh`: 384 passed, 0 failed; `smoke.cjs`: ok, main scene ran in 1.8 s; `recover.cjs`: cases A–D ok | `before.jpg`, `after.jpg` |

`game/web/shell.html` regenerated with `python3 scripts/web/make_loading.py` (splash.png unchanged byte for byte).

## Review (reviewer agent, 6 Nov 2026)
No blocking findings. Fixed: menu buttons ignore clicks while they fade in (a quick double tap could start the game unseen; asserted in `test_reveal_cross_fades_without_a_black_dip`); the screen keeps its default mouse filter after the reveal; `_tell_page_when_drawn` returns if main left the tree during the await. Re-run: 384 passed, 0 failed.

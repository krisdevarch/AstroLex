# WP-3.I evidence

Branch `claude/project-thread-4bg9x3`, 12 Oct 2026.

| AC | Result | Check | Artefact |
|---|---|---|---|
| AC1 | pass | `scripts/godot/test.sh`: `test_spawn_never_overlaps_catchable_tiles`, `test_catchable_tiles_keep_their_gap_while_drifting`, `test_head_on_pair_bounces` (test_round.gd) | log: 157 passed, 0 failed |
| AC2 | pass | `python -m astrolex_tools.validate_data` → ok; `python -m astrolex_tools.export_game_data` leaves no diff | `data/tunables/game.json` `tile.minGap: 0.04` |
| AC3 | pass | `test_hud_sits_on_one_grid` (test_hud.gd) | `phone-393x852-ash.jpg`, `phone-405x720-juno.jpg` |
| AC4 | pass | `test_backdrop_regains_colour_as_words_are_restored` (test_hud.gd) | screenshots |
| AC4b | pass | `test_sky_drifters_move_behind_the_letters`, `test_sky_drifters_hold_still_under_reduced_motion` (test_hud.gd) | `motion-393x852-wren.gif` |
| AC5 | pass | `scripts/godot/test.sh` 157/0, no SCRIPT ERROR; `scripts/godot/export.sh web` exit 0; `node smoke.cjs ../../../build/web` → "ok: main scene ran" | — |

Notes
- Spawn uses up to 64 tries per tile (act 1 round 1 packs about 22 catchable tiles); if none fits, the last try is kept and the per-tick separation pushes the pair apart within a few frames. Denser acts rely on that.
- The shot target is not frozen by separation: the shot locks its aim at fire time and the hit test is distance-based.
- Screenshots: local web export in headless Chromium (SwiftShader) at `?autoplay=1` with a temporary character override that is not committed. The sky, planets and craft are placeholder art (O-14) drawn from gradients, shapes and one planet shader (`game/scenes/planet.gdshader`).
- 13 Oct: sky restyled after two owner references (cartoon planets on a starry blue night) and the card choice "Just behind letters".

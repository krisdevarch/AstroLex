# WP-3.L evidence

Branch `claude/project-thread-4bg9x3`, 13 Oct 2026.

| AC | Result | Check | Artefact |
|---|---|---|---|
| AC1 | pass | `test_letter_layers_may_overlap_but_not_within_a_layer`; `test_spawn_never_overlaps_catchable_tiles` (200 seeds, same-layer pairs); `test_catchable_tiles_keep_their_gap_while_drifting` (30 seeds × 20 s) | `layers-phone-and-9x16.jpg` |
| AC2 | pass | `test_a_tap_on_overlapping_letters_picks_the_front_one` | — |
| AC3 | pass | `test_drift_speed_is_within_the_variation_band_and_ramps` (mid layer checked against `plane.midSpeedMul`) | — |
| AC4 | pass | `python -m astrolex_tools.validate_data` ok; `scripts/godot/test.sh` 162 passed, 0 failed, no SCRIPT ERROR; `scripts/godot/export.sh web` exit 0 | — |

Notes
- `layers-phone-and-9x16.jpg`: act 1 round 1 on a phone (393×852) and at 9:16 (405×720), headless Chromium, `?autoplay=1` with a temporary character override that is not committed. Mid letters (smaller and darker) pass behind front letters, for example A behind B.
- A mid letter can be fully hidden behind a front letter for a moment; it drifts out, since the layers move at different speeds.
- The no-overlap rule now holds per layer. With one decoy per needed letter at `tile.size` 0.19, every one of the 200 spawn seeds keeps the gap within each layer.

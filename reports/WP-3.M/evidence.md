# WP-3.M evidence

Branch `claude/project-thread-4bg9x3`, 13 Oct 2026.

| AC | Result | Check | Artefact |
|---|---|---|---|
| AC1 | pass | `test_letters_swoop_on_curved_paths_and_surge` (heading turns over 0.2 rad in 4 s; max speed above 1.2× min) | `letters-motion.mp4` |
| AC2 | pass | `test_a_stopped_letter_stays_stopped` | — |
| AC3 | pass | `test_drift_speed_is_within_the_variation_band_and_ramps` (band read from tunables); `test_tuning_overrides` | — |
| AC4 | pass | `test_bubble_squashes_on_a_bounce_and_leans_into_its_motion` | `letters-motion.mp4` |
| AC5 | pass | `test_catchable_tiles_keep_their_gap_while_drifting` (30 seeds × 20 s); `test_spawn_never_overlaps_catchable_tiles` (200 seeds) | — |
| AC6 | pass | `python -m astrolex_tools.validate_data` ok; `scripts/godot/test.sh` 165 passed, 0 failed, no SCRIPT ERROR; `scripts/godot/export.sh web` exit 0 | — |

Notes
- `letters-motion.mp4`: act 1 round 1 on a phone (393×852), headless Chromium with `?autoplay=1` (the bot catches letters). Software rendering ran the game at about 0.43× real time, so the clip is sped up 2.3× to show real speed.
- Catching stays fair: the fastest letter (0.17 × 1.45 × 1.35 ≈ 0.33 field units/s) moves about 0.07 during the longest tether flight (0.2 s), inside the 0.096 hit tolerance.

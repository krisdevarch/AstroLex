# WP-3.M: Livelier letter movement

Owner (13 Oct 2026, 19:01): "can letter movement be more dynamic and interesting what are your thoughts? like this very slow like making old people play". Before this WP, letters slid in straight lines at 0.1 field widths a second and only changed course at a wall.

## Scope
- **Faster:** `drift.speed` 0.1 → 0.17, `drift.speedVariation` 0.35 → 0.45, so some letters dart and some float.
- **Curved paths:** each letter's heading swings one way and then the other (`drift.curve` 0.7 rad/s at `drift.curveHz` 0.09), so letters swoop in S-curves.
- **Surges:** each letter's speed rises and eases by `drift.surge` 0.35 at `drift.surgeHz` 0.3.
- Both waves take their phase from the tile id, so neighbours move out of step and a seed still replays exactly. A stopped letter stays stopped.
- **Feel (view only):** a bubble squashes for a moment when it bounces (`tile.bounceSquash` 0.16), and its letter leans into sideways motion (`tile.leanDeg` 9). Both are off under reduced motion.

## Acceptance criteria
| AC | Check |
|---|---|
| AC1 | Letters turn without a wall and surge, within bounds | `test_letters_swoop_on_curved_paths_and_surge` (test_round.gd) |
| AC2 | A stopped letter stays stopped | `test_a_stopped_letter_stays_stopped` (test_round.gd) |
| AC3 | Spawn speeds sit in the new band and ramp; tuning still overrides | `test_drift_speed_is_within_the_variation_band_and_ramps` (test_round.gd), `test_tuning_overrides` (test_level.gd) |
| AC4 | Bubbles squash on a bounce, spring back, and lean into motion | `test_bubble_squashes_on_a_bounce_and_leans_into_its_motion` (test_glass.gd) |
| AC5 | Same-layer letters still keep their gap at the new speeds | `test_catchable_tiles_keep_their_gap_while_drifting`, `test_spawn_never_overlaps_catchable_tiles` (test_round.gd) |
| AC6 | New tunables have schema entries; all tests pass; the web export builds | `validate_data`, `scripts/godot/test.sh`, `scripts/godot/export.sh web` |

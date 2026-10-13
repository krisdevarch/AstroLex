# WP-3.L: Letters in 2.5D layers, more letters, a touch smaller

Owner (13 Oct 2026, 18:38): "okay now lock the design since it's good. next suggestion would be to make the letters go in 2.5d one behind another to make the experience more playful. in that case there is also chance to put more letters. also circles with letters both can be smaller 3-5px." The look from WP-3.J and WP-3.K is locked; this WP changes only depth, count and size.

## Scope
- **Two letter layers:** front (plane 0) and mid (plane 1). Letters on the same layer still never touch. Letters on different layers may overlap, so a mid letter can drift behind a front one.
- **Depth cues:** the mid layer is smaller (`plane.midScale` 0.92 → 0.74), a little darker and bluer (`plane.midDim` 0.18, new), and drifts slower (`plane.midSpeedMul` 0.8, new). It is drawn behind the front layer.
- **Taps:** where letters overlap, a tap takes the front letter.
- **More letters:** `spawner.decoyRatio` 0.75 → 1.0, so act 1 round 1 shows about 16 letters (was about 14). `spawner.frontShare` 0.62 → 0.55 balances the layers.
- **Smaller:** `tile.size` 0.2 → 0.19, which makes the bubble and its letter about 4 CSS px smaller on a 393-px-wide phone.

## Acceptance criteria
| AC | Check |
|---|---|
| AC1 | Letters on one layer keep their gap; letters on different layers may overlap | `test_letter_layers_may_overlap_but_not_within_a_layer`, `test_spawn_never_overlaps_catchable_tiles`, `test_catchable_tiles_keep_their_gap_while_drifting` (test_round.gd) |
| AC2 | A tap on overlapping letters takes the front one | `test_a_tap_on_overlapping_letters_picks_the_front_one` (test_field.gd) |
| AC3 | Mid letters drift slower (parallax) | `test_drift_speed_is_within_the_variation_band_and_ramps` (test_round.gd) |
| AC4 | New tunables have schema entries; all tests pass; the web export builds | `validate_data`, `scripts/godot/test.sh`, `scripts/godot/export.sh web` |

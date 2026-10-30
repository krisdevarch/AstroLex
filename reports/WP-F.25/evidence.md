# WP-F.25 evidence

Branch `claude/project-thread-8q83z2`, 28 Oct 2026. Spec: `wps/WP-F.25.md`. Follows WP-F.24 (#73).

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | A caught letter is replaced on its own spot; the field keeps its starting count all round | pass | `game/tests/rules/test_refill.gd::test_a_right_catch_is_replaced_on_its_own_spot` (6 seeds), `::test_the_field_stays_full_over_several_catches`, `::test_without_refill_the_field_thins_out`; `test_round.gd` surplus tests step past `spawner.refillDelay` | `reports/WP-F.25/refill.jpg`: 1-10 at 8, 16, 24 and 30 s (20 letters at the start, 18 on the last word "apple") |
| 2 | More letters | pass | `test_refill.gd::test_more_letters_than_before` (moon + star: ≥ 16 letters); `test_mistakes.gd` tap-everything bot still loses every Act I level, careful bot still wins | 1-06: 12 letters on 15 anchors (was 10); 1-10: 20 on 24 (was 15 on 19) |
| 3 | Checks | pass | `scripts/godot/test.sh` 363 passed / 0 failed; `validate_data` ok; `levels` ok; `pytest tools` ok; `scripts/godot/export.sh web` ok; Chromium autoplay wins 1-06 (`AstroLex round won`) and plays 1-10 | CI `godot.yml`, `pr.yml` |

Headless probe (bot plays the whole level, counts catchable letters every second): 1-06 starts with 12 letters, fewest seen 11, won; 1-10 starts with 20, fewest seen 14 (the bot catches several letters per second, faster than the 0.4 s refill, and `ramp.decoyMax` 14 caps the decoys on the last word), won.

Tunables: `spawner.decoyRatio` 0.6 → 1.0; new `spawner.refill` 1, `spawner.refillDelay` 0.4 (schema entries added). Difficulty presets unchanged (Easy ×0.6, Hard ×1.4 on the ratio).

Rules change: `_ensure_decoys` targets `_letters_target − real alive` (set in `_anchor_demand`: the first two words' letters plus their decoys) when `spawner.refill` is on; `_refill_anchor` makes the next spawn take the caught letter's anchor; a right catch schedules the refill through `_pending_respawn` after `spawner.refillDelay`.

Not covered: a visual for the replacement beyond the existing grow-in; whether 1.0 decoys per letter is the right density is the owner's playtest call.

# WP-F.23 evidence

Branch `claude/project-thread-8q83z2`, 27 Oct 2026. Spec: `wps/WP-F.23.md`. Follows WP-F.21 (#70) and WP-F.22 (#71).

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | `burst.maxWrong` 3 wrong catches lose the round, reason `mistakes`; the clock gives `time` | pass | `game/tests/rules/test_mistakes.gd::test_mistakes_left_counts_down_and_the_last_one_ends_the_round`, `::test_zero_max_wrong_means_no_limit`, `::test_time_out_reason_is_time` | `scripts/godot/test.sh` 356 passed, 0 failed |
| 2 | Pips, toast and end-card title | pass | `test_field_feedback.gd` (toast starts with the cost), `MistakePips` in `field.gd` synced on `wrong`, `counterfeit` and level start; `level_card.gd` reads `summary.reason` | `reports/WP-F.23/short-words.jpg` (pips under the clock) |
| 3 | Lattice sized to the round and spread evenly | pass | `test_motion.gd::test_anchor_layout_is_a_honeycomb_inside_the_field` (count within the demand, columns span the width, rows span the height, neighbours ≥ spacing, none under the porthole); frames of 1-04 (book/shelf) and 1-06 (bed/cat) | `reports/WP-F.23/short-words.jpg` |
| 4 | Tap-everything cannot win | pass | `test_mistakes.gd::test_tapping_every_letter_loses_every_act1_level` (12 levels, all lost on mistakes), `::test_tapping_every_letter_loses_on_every_difficulty`, `::test_careful_bot_still_wins` | same |
| 5 | Checks | pass | `validate_data` ok, `levels` ok, `pytest tools` ok, Godot 356/0, `scripts/godot/export.sh web` ok, Chromium autoplay boots 1-04 and 1-06 (`?autoplay=1&level=1-06&tap=1.6`) | — |

Tunables: `burst.maxWrong` 3 (new; difficulty Easy 5, Hard 2), `anchors.spare` 2 (new).

Strings added in code (HUD, not story text): "one more loses the sector", "N more allowed", "Too many wrong catches".

Not covered: whether 3 is the right number is the owner's playtest call; the Daily Signal uses the same cap.

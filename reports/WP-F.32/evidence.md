# WP-F.32 evidence

Branch `claude/project-thread-xw5yt6`, 6 Nov 2026.

| AC | Result | Test or command | Artefact |
|---|---|---|---|
| 1 | pass | `grep -o '"hazard.counterfeitRatio": [0-9.]*' data/levels/*.json` gives 48 × `0`; `game/tests/rules/test_daily.gd` asserts 0 | `data/levels/*.json`, `game/rules/daily.gd` |
| 2 | pass | 24 × `"hazard.stroop": 0` in Acts III–IV; `test_any_copy.gd` asserts the jam never comes on in any level | `data/levels/act3_tower.json`, `act4_core.json` |
| 3 | pass | `test_hazard_view.gd::test_counterfeit_and_trap_tiles_get_their_marks` now asserts a trap letter has no ring and a white letter | `game/scenes/tile_view.gd` |
| 4 | pass | `test_any_copy.gd::test_every_copy_of_a_needed_letter_is_accepted_in_every_level`, `::test_two_copies_of_a_letter_both_fill_its_two_slots` | `game/tests/rules/test_any_copy.gd` |
| 5 | pass | `scripts/godot/test.sh` 384 passed, 0 failed; `pytest tools` passed; `levels: ok`; `data validation: ok`; `curve: 48 levels, 0 flag(s)` | CI `evidence` artifact |

Levels get a little easier from 1-10 on (no forgery costs). The curve report flags none.

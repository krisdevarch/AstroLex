# WP-F.27 evidence

Branch `claude/project-thread-rto5j6`, 29 Oct 2026. Spec: `wps/WP-F.27.md`. Follows WP-F.26 (#75).

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | Pip has one fewer decoy | pass | `game/tests/rules/test_perks.gd::test_pip_wants_one_fewer_decoy_everywhere` (all 48 levels, Normal and Easy: target one lower; all 12 Act I levels start with exactly one fewer), `::test_decoy_bonus_never_goes_below_zero` | `round.gd _decoy_target`, `data/tunables/game.json` `spawner.decoyBonus` 0, `data/characters.json` |
| 2 | The Catcher speaks in the suit's voice | pass | `game/tests/scenes/test_story_voices.gd::test_the_catcher_speaks_four_times_with_a_line_per_suit`, `::test_catcher_comms_use_the_suit_line_colour_and_name`, `::test_story_strip_shows_the_catcher_bubble_in_suit_colour`; `tools/tests/test_levels.py::test_catcher_lines_are_checked_for_spoilers`, `::test_catcher_reply_counts_once_at_its_longest_line` | `main.gd catcher_comms`, `story_strip.gd`, `crew_art.gd` |
| 3 | New Rhee and Babel lines | pass | `test_story_voices.gd::test_babel_has_comms_lines_in_act_one_and_act_four`; `python -m astrolex_tools.levels` (Babel lines use only board letters) | `data/levels/act1_low_orbit.json`, `act4_core.json` |
| 4 | Fixes | pass | `game/tests/scenes/test_name.gd::test_ending_names_the_catcher_in_tomas_text` (4 cards: Rhee amber with the 4-12 definition, Babel's line, Tomas, closing) | `ending.gd`, `data/characters.json`, `docs/story-bible.md` |
| 5 | VANTA's time on the end card | pass | `test_story_voices.gd::test_vanta_time_shows_after_a_win_only`, `::test_vanta_posts_times_in_act_two` | `level_card.gd vanta_text`, `data/levels/act2_nebula.json` |
| 6 | Act files approved | pass | `validate_data` ok | four `data/levels/*.json` |
| 7 | Checks | pass | `scripts/godot/test.sh` 371 passed / 0 failed; `pytest tools` 65 passed; `validate_data` ok; `levels` ok | CI `godot.yml`, `pr.yml` |

Note: Pip's lower target always applies, but in a few dense levels (Act II-IV, Easy) the field already starts short of its target (anchors and `spawner.maxCopies` bind first), so the first spawn can show the same count; the refill then keeps one fewer.

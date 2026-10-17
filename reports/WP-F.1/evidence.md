# WP-F.1 evidence: Babel's hazards

| AC | Result | Test / command | Artefact |
|---|---|---|---|
| Counterfeits only with ratio > 0, only on needed letters, decoy kind | pass | `test_hazards.gd::test_counterfeits_only_with_ratio_and_only_on_needed_letters` (200 seeds), `test_no_hazards_by_default`, `test_ratio_zero_changes_nothing_in_the_spawn_stream` | game/rules/round.gd |
| Catching one costs `burst.wrongCost`, emits "counterfeit", real letter stays | pass | `test_catching_a_counterfeit_costs_time_and_emits_the_event`, `test_counterfeits_do_not_fill_hints_or_survive_their_letter` | |
| Trap word from lexicon, unneeded letters; pair in window fires once, Babel says the word, clock -3 s | pass | `test_trap_word_uses_only_unneeded_letters_and_is_in_the_lexicon`, `test_two_trap_letters_in_the_window_set_it_off_once`, `test_trap_letters_outside_the_window_do_not_count` | |
| Jam on schedule, `jammed`, jam_on/jam_off | pass | `test_jam_toggles_on_schedule`, `test_jam_off_when_disabled` | |
| Deterministic per seed; hazard boards stay solvable | pass | `test_deterministic_for_a_seed`, `test_all_hazards_stay_winnable_for_the_bot` (60 seeds, all hazards on) | |
| View: shimmer (2 s), trap ring, jam colours, slot hints dark, first-bite toasts, summary counters | pass | `game/tests/scenes/test_hazard_view.gd` (4 tests) | game/scenes/tile_view.gd, field.gd |
| Tunables, level tuning, export | pass | `validate_data`, `levels`, `export_game_data`; `pytest tools` pass | data/tunables/game*.json, data/levels/* |
| Full suite, no SCRIPT ERROR | pass | `scripts/godot/test.sh`: 206 passed, 0 failed | |
| Web export boots and autoplay wins | pass | `export.sh web`; `node smoke.cjs ../../../build/web /tmp/f1.png --autoplay`: won, score 501 | /tmp/f1.png |

Design choices
- `Tile.kind` is "" (plain), "counterfeit" or "trap"; both hazards are decoys. They use their own seeded RNG (`seed ^ 0x4A2A2D`); with all hazard tunables at 0 the spawn stream is unchanged.
- Counterfeits number `max(1, round(decoys x ratio))`; the decoy total grows if needed. A forgery whose letter is no longer needed dissolves and is remade. Hints and the bot ignore them. Time-cost reasons: "counterfeit", "trap".
- Trap word: 3-4 letter lexicon word with no letter in any word of the level. It fires once per round (two different trap tiles within `hazard.trapWindowSec`); trap letters are not remade afterwards. Babel's line is the word capitalised plus ".". Some levels have no fitting word and so no trap: 11/12 (Act II), 8/12 (Act III), 9/12 (Act IV) have one.
- Jam: first at `stroopEverySec`, repeats every `stroopEverySec`, lasts `stroopSec`; it blanks the ghost letters in the slots. The hint button still works.
- Level tuning: Act I 0 before 1-10, 0.25 from 1-10; Act II ratio 0.3-0.4 plus trap; Act III 0.35-0.45, trap, jam (14 s / 2.5 s, then 12 s / 3 s); Act IV 0.4-0.5, trap, jam (12/3 down to 8/4).
- Telemetry round result gains `counterfeits`, `traps`, `jams` (docs/playtest-telemetry.md updated).
- Python reference: this repo has no Python round implementation or conformance vectors (`data/conformance/` does not exist), and the toy v1.3 has no hazards, so nothing needed keeping in step.
- `wps/MILESTONE-finish.md` is not in the tree; the brief was used as the spec.

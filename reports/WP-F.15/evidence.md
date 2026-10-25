# WP-F.15 evidence: Ease time pressure at later levels

Brief: `wps/WP-F.15.md`. Owner playtest note (25 Oct 2026): from about level 14 there is not enough time to collect the letters for a player with intermediate English.

## What changed
- A round's clock is now `burst.seconds + burst.perLetterSec × letters` (letters = sum of the level's word lengths), in `game/rules/round.gd` `_setup()`. New tunable `burst.perLetterSec` (game.json default 0: random rounds and the Daily Signal keep a flat clock).
- Act tunings (only `tuning` keys changed in the level files; no words or text touched):

| Act | Before | After | Clock range now |
|---|---|---|---|
| I Low Orbit | 60 s flat | 50 s + 1.0 s/letter | 60–70 s |
| II Nebula | 50 s flat | 25 s + 2.75 s/letter | 53–99 s |
| III Tower | 45 s (3-10 55, 3-11 60) | 15 s + 4.0 s/letter | 55–127 s |
| IV Core | 40 s (4-09 55, 4-10 60, 4-11 70, 4-12 30) | 10 s + 4.75 s/letter | 58–148 s |

Level 14 (2-02, fear / rage / envy): 50 s → 58 s. The levels that change most are the long ones late in each act, for example 2-11 50 → 99 s, 3-08 45 → 111 s, 4-08 40 → 105 s.

- Curve report (`tools/astrolex_tools/curve.py`) gains an "intermediate" player profile: 0.9 s base per letter instead of 0.45, slower search and chase, hit by counterfeits, traps, drones and jams about twice as often. These constants are modelling guesses chosen so that Act I (which the owner found fine) comes out playable and the old Act II–IV clocks come out too short, as reported. They should be checked against playtest telemetry. Under the old clocks this profile had negative slack (could not finish) from 2-07 on and in most of Acts III and IV; now every level leaves it at least 20%.

Full table: `reports/WP-F.15/curve.md` (same as the regenerated `reports/WP-F.9/curve.md`).

## Acceptance criteria

| AC | Result | Check | Artefact |
|---|---|---|---|
| 1. Clock = burst.seconds + perLetterSec × letters | pass | `test_round.gd::test_clock_adds_per_letter_seconds`, `test_clock_is_flat_without_per_letter_seconds`; `test_levels_flow.gd::test_act_one_burst_is_at_least_sixty_seconds_and_the_bar_fits_it` (time bar spans the new clock) | |
| 2. Tunable in game.json, game.schema.json, level schema | pass | `python -m astrolex_tools.validate_data`: ok; `python -m astrolex_tools.levels`: ok | |
| 3. No level gets less time | pass | `tools/tests/test_levels.py::test_no_level_gets_less_time_than_before` | |
| 4. Intermediate slack ≥ 20%, skilled ≤ 85%, trend down per act | pass | `python -m astrolex_tools.curve`: 48 levels, 0 flags; minimum intermediate slack I 22% (1-12), II 22% (2-11), III 22% (3-11), IV 20% (4-11); `test_curve.py::test_an_intermediate_player_keeps_slack_on_every_shipped_level` | `reports/WP-F.15/curve.md` |
| 5. All tests pass, data re-exported | pass | `pytest tools`: all pass; `scripts/godot/test.sh`: 266 passed, 0 failed; `python -m astrolex_tools.export_game_data` | `game/data/*.json` |

## Notes
- Stars are a share of the clock, so with longer clocks three stars still means finishing with a third of the clock left.
- Longest round is now 4-11 at about 2.5 minutes. Drones keep coming every 5 s in Acts III–IV, so a longer clock also means more steals; if late levels still feel tight, the next lever is a longer `thief.interval` there, not more clock.
- Easy difficulty does not change the clock. A `mul` on `burst.perLetterSec` in `data/tunables/difficulty.json` would give Easy players more time per letter if wanted.

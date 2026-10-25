# WP-F.15: Ease time pressure at later levels

Owner playtest (25 Oct 2026): from about level 14 a player with intermediate English runs out of time collecting the letters; the words themselves are fine.

Cause: after Act I the clock shrinks (60, 50, 45, 40 s) while the letters per level grow (10 to 29) and the hazards (counterfeits, traps, drones, jams) eat more of it. Act I gives about 3 s per letter; late Act II about 1.9, late Act IV about 2.

Fix: the clock scales with the level's letters. A round starts with `burst.seconds + burst.perLetterSec × letters` (sum of the level's word lengths). New tunable `burst.perLetterSec` (game.json default 0, so random rounds and the Daily Signal keep their flat clock). Act tunings: I 50 + 1.0/letter, II 25 + 2.75, III 15 + 4.0, IV 10 + 4.75; the per-level `burst.seconds` overrides in Acts III and IV go. No level gets less time than before.

The curve report gains an "intermediate player" profile (slower per letter, hit by hazards more often). Its constants are modelling guesses, to be checked against playtest telemetry.

## Acceptance criteria
1. `Round` starts every round with `burst.seconds + burst.perLetterSec × letters`; `burst_seconds` reports that clock; stars, hints and the HUD use it. Headless test.
2. `burst.perLetterSec` is in `game.json`, `game.schema.json` and the level tuning schema.
3. Every level's new clock is at least its old clock (test).
4. Curve report: every level keeps at least 20 % intermediate slack and at most 85 % skilled slack; slack still trends down within each act.
5. All Python and Godot tests pass; game data re-exported.

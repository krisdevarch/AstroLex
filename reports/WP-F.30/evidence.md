# WP-F.30 evidence

Branch `claude/project-thread-gr6fdh`, 26 Oct 2026; brought up to date with main on 30 Oct 2026. Spec: `wps/WP-F.30.md`.

## Diagnosis (from the owner's playtest log, build 2e33ec4)
- 1-10's words are garden, tree, apple; the round summaries show `counterfeits` 4 and 6 for the two attempts.
- Every real R was accepted (`catch` events with `ch: r` at t=382.0, 421.6 and 462.2). The second attempt has 9 `fire` events with no result; forgery catches (6) and drone hits (3) are the two outcomes the log did not record, and they add up to 9.
- No `wrong` event in either 1-10 attempt is for a letter of garden, tree or apple still needed, so no needed letter was judged against the wrong word.

## Second report (30 Oct 2026): "two A's, one used, the other says wrong"
- Probe on main ff22a9d (a throwaway script, not committed): 4 seeds of each of the 48 levels, the test bot plus random taps on any letter 30 % of the time, up to 120 s each. 545 wrong catches, 0 of kind `surplus` (a letter of the words with no open slot), and no plain (not forged) copy of a word letter stayed on the field more than 1 s after its last slot filled.
- So when a word still needs A and an A is refused, that A is a forgery. Main still shows the "Forged letter" toast only for the first one, which is why the earlier fix is needed.

## Acceptance criteria

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | Toast for every forgery, naming the letter | pass | `test_hazard_view.gd::test_forged_letter_toast_and_summary_counter` (catches two forgeries) | `scripts/godot/test.sh` |
| 2 | Forgery rim alpha 0.5, width 0.9; forged letter periwinkle, real letter white | pass | `test_hazard_view.gd::test_counterfeit_and_trap_tiles_get_their_marks` (tint asserts) | `game/scenes/tile_view.gd` |
| 3 | `counterfeit` and `trap` events in playtest results; contract doc updated | pass | `test_telemetry.gd::test_forged_letter_catch_is_an_event` | `docs/playtest-telemetry.md` |
| 4 | No `squish` meta error on first button press | pass | `test_hazard_view.gd::test_first_button_press_squishes_without_meta`; `has_meta` guard before `get_meta` | `game/scenes/field.gd` |
| 5 | Godot tests pass | pass | `scripts/godot/test.sh`: 382 passed, 0 failed (after the merge of main) | — |

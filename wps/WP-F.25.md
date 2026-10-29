# WP-F.25: Caught letters are replaced; more letters on the field

Owner feedback (28 Oct 2026, project thread) on the WP-F.24 build: "now it's better, only one small change, always replace the letters when guessed and add more letters so it make the game a bit more difficult."

## What we found
After a right catch `_refill()` topped the decoys up to `max(spawner.decoys, decoyRatio × real letters left)`. As the real letters were caught that target fell with them, so the spot stayed empty and the field thinned out towards the end of every word pair. `spawner.decoyRatio` was 0.6.

## Acceptance criteria
1. **Refill.** With `spawner.refill` 1 the catchable letters on the field stay as many as the two current words' letters plus their decoys: the decoy target is `pair + max(spawner.decoys, ceil(decoyRatio × pair)) − real letters alive`, capped by `ramp.decoyMax`. A caught letter's anchor is remembered and the next spawn takes it, `spawner.refillDelay` (0.4 s) after the catch. `spawner.refill` 0 keeps the old behaviour. Tests: a right catch is replaced on its own spot after the delay (6 seeds); the field stays full over several catches; refill 0 thins the field.
2. **More letters.** `spawner.decoyRatio` 1.0 (a decoy per real letter; Easy ×0.6, Hard ×1.4 as before), so moon + star shows 16 letters instead of 13; the grid grows with the demand (WP-F.24). The tap-everything bot still loses every level and the careful bot still wins (WP-F.23 tests).
3. **Checks.** Schema entries for the two tunables; `validate_data`, `levels`, `pytest tools`, `scripts/godot/test.sh` pass; the web export plays 1-06 on autoplay with the frames showing a replaced letter; `wps/_index.md` and `docs/PROJECT-BRIEF.md` updated.

Out of scope: colour rings for needed letters, the replacement letter's own animation beyond the existing grow-in.

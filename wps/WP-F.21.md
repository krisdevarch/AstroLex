# WP-F.21: Forged letters read as a refused needed letter

Owner report (26 Oct 2026, project thread, iPhone Chrome, build 2e33ec4): "i clicked so many times on r button and it says it's invalid but actually it was part of the tree word." The attached playtest log also has an engine error at t=239.8: `The object does not have any 'meta' values with the key 'squish'`.

What we found:
- Level 1-10 (garden, tree, apple) is the first level with counterfeits (`hazard.counterfeitRatio` 0.25; the story bible puts them in Act I's closing). Each forgery is a copy of a needed letter, here R. The log shows `counterfeits` 4 and 6 for the two 1-10 attempts, and every real R caught was accepted (`catch` events at 382.0, 421.6, 462.2). The rules are right: the R taps that were refused hit forgeries.
- Three things made that look like a bug: the "Forged letter" toast shows only for the first forgery of a screen, so later ones were refused with only a red flash; the forgery's rim (alpha 0.16) is hard to see on a phone; and forgery catches were not written to the playtest log, so the log shows a `fire` with no result.
- The `squish` error is real: Godot 4's `get_meta(key, null)` prints an error when the key is missing, which happens on the first press of every HUD button. Harmless to play.

## Acceptance criteria
1. Every forgery caught shows a toast naming the letter ("Forged R, find the real one −N s"), not only the first.
2. A forgery's rim is plain to see (alpha 0.5, width 0.9 of the ring; it was 0.16 and 0.6).
3. Playtest results log `counterfeit` events with the letter, and `trap` events with the word; `docs/playtest-telemetry.md` lists them.
4. The first press of a HUD button no longer logs the `squish` meta error.
5. `scripts/godot/test.sh` passes with tests for 1, 3 and 4.

Out of scope: level tuning and comms (1-10 keeps its counterfeits; a warning line for 1-10 would be story text for the owner to write or approve).

# WP-F.23: Tapping everything must not win; the lattice sized to the round

Owner feedback (27 Oct 2026, project thread) on the anchored drift build: "you can tap all letters all the time and finish the game", and "letters look very strange when words are small... we should fill equally the space".

## Why tapping everything won
A wrong catch cost `burst.wrongCost` (1 s) and the letter stayed on the field. With letters that no longer dodge, a player who taps every bubble loses about 8 s on an Act I clock of 60 s and fills every slot. Before the layout change the same strategy existed but motion and overlap made most taps miss.

## Acceptance criteria
1. **Mistakes lose the round.** `burst.maxWrong` (3; Easy 5, Hard 2; 0 = no limit) wrong catches, plain or forged, end the round as lost with `round_end{won:false, reason:"mistakes"}`; the clock still ends it with `reason:"time"`. `Round.mistakes_left()` and `Round.end_reason` expose the state; the `wrong` and `counterfeit` events carry `left`.
2. **The player can see it.** Mistake pips over the clock channel (one ring per allowed wrong catch, filled coral with a cross when used), the wrong-catch toast says how many are left ("one more loses the sector"), and the end card titles the loss "Too many wrong catches".
3. **Lattice sized to the round.** `_build_anchors` picks the fewest rows and columns that hold the first two words' letters, their decoys, `anchors.spare` (2) free spots and the porthole's spot, choosing the most honeycomb-like pitch, and spreads them evenly over the whole field, so a short-word level fills the space with its few letters instead of leaving gaps.
4. **Tests.** A tap-everything bot (nearest catchable tile, whatever it is) loses every Act I level and on every difficulty preset, always on mistakes; the careful bot still wins; the pips and reasons are unit-tested. `validate_data`, `levels`, `pytest tools`, `scripts/godot/test.sh` pass; the web export boots on autoplay; frames of 1-04 and 1-06 in the evidence.

# WP-F.22: Letters across the whole screen, fewer repeats

Owner feedback on the anchored drift build (27 Oct 2026, project thread, screenshot of 1-05): the honeycomb hugged the middle of the screen with empty margins left, right and above the tray ("like this it looks okayish"), and the field carried four T's and three P's ("there shouldn't be so many same letters at the same time").

## Acceptance criteria
1. **Full width.** The rules field has a width (`field.width`, 1.33 at the 1080×1920 reference, so one uniform scale spans the screen edge to edge); every x bound in `round.gd` (back shards, clamps, drone edges and flee, dropped letters, the gun origin) uses it; `field.gd` fits `width × (height − topMargin)` to the screen with one scale and centres it.
2. **Even spread.** The anchor lattice spreads its columns and rows evenly over the whole field (pitch at least `anchors.spacing`, rows offset by half a pitch), so the first and last columns sit at the side walls and the first and last rows at the top and bottom of the field; 22 anchors at the defaults (5/4/5/4/5 less the one under Babel's porthole, `anchors.clearX` re-mapped to the new scale).
3. **Fewer repeats.** A plain decoy never brings a letter to more than `spawner.maxCopies` (2) copies on the field; needed letters, counterfeits and trap letters are not capped. `spawner.decoyRatio` 0.6 (the design page's "about half"), so the field has air for hops.
4. **Checks.** Tests for the spread, the width bounds and the copy cap; `validate_data`, `levels`, `pytest tools`, `scripts/godot/test.sh` pass; the web export wins a round on autoplay; frames of 1-05 in the evidence.

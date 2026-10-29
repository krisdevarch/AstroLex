# WP-F.27: Finish the story's cast and voices

Owner request (29 Oct 2026, project thread): "consolidate and finish the story with characters and gameplay and words and everything". The consolidated story doc ("AstroLex: the complete story", Claude Doc in the project) listed 23 new lines and six build items; the owner picked "Approve and build" on the decision card the same day.

## Acceptance criteria
1. **Pip's perk works.** New tunable `spawner.decoyBonus` (default 0) is added after `spawner.decoyRatio` and the `ramp.decoyMax` cap, never below 0 decoys; Pip's Sharp eye sets it to -1 instead of `spawner.decoys` (which the ratio overrode in all 48 levels). `curve.py` mirrors it.
2. **The Catcher speaks.** Comms take `"who": "catcher"` with a `lines` reply per suit (schema, levels checker: spoilers and word count cover every suit line). The game shows the picked suit's line in its colour, with its portrait and the player's name. Four moments: after 1-01, 2-12 (after Rhee's grief), 3-08 (after "Go on or stop"), 4-12 (before the last words).
3. **New lines.** Rhee's "You don't remember your name..." in 1-01; Babel comms BRAVE TRICK. (1-12), SPEAK. I REPLY. (4-07), ONE QUESTION. (4-11), each from the level's letters; Babel's ending card "I was wrong about words. Thank you, <name>."
4. **Fixes.** Tomas 4-09 "she sings for me"; Rhee's ending definition matches 4-12 ("let them change you") and her card is amber; Juno "The pirate", Ash "The ninja"; story bible uses "it" for Babel in rule 4 and records the Catcher's replies.
5. **VANTA's time.** Levels take an optional `vanta` time (2-02: 38 s, 2-08: 36 s, 2-12: 30 s, as VANTA says them); after a win the end card shows "VANTA n s · You n s · Beaten!" or "Keep up.".
6. **Approved.** The four act files are `status: approved` (O-29 approved the drafted text; the new lines were approved on 29 Oct 2026).
7. **Checks.** `validate_data`, `levels`, `pytest tools`, `scripts/godot/test.sh` pass; CI web export and smoke pass.

Out of scope: a real VANTA ghost race, the Prologue (dropped, O-30), Act V, counterfeits, anagram traps, Stroop.

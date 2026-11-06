# WP-F.31: Any copy of a needed letter counts, no colour coding

Owner report (6 Nov 2026, project thread): "why multiple letters are different colors, it should accept the letters that are in the word. if there are two A for example, it should accept every A that i can tap on. we should not make them different color."

Third report of the same feel (26 Oct, 30 Oct, 6 Nov). WP-F.30 showed the rules already accept every plain copy of a needed letter; the only refused copies were Babel's forgeries (`hazard.counterfeitRatio`, from level 1-10 on), which WP-F.30 then tinted periwinkle. The tint is the "different colour" and the refusal is the "it doesn't accept my A". The owner's call: drop both.

## Acceptance criteria
1. No shipped level and not the Daily Signal spawns forged letters: `hazard.counterfeitRatio` is 0 in every level of `data/levels/*.json` and in `game/rules/daily.gd`.
2. No shipped level turns on the colour jam (`hazard.stroop` 0), so letters never pulse cyan or periwinkle by role.
3. Babel's trap letters look like every other letter (no ring); the trap itself still goes off on two wrong catches.
4. In every one of the 48 levels, a bot that taps a random copy of any letter the words still need is never refused (no `wrong`, no `counterfeit`), and two A's both fill BANANA's A slots: `game/tests/rules/test_any_copy.gd`.
5. `scripts/godot/test.sh`, `pytest tools`, `python -m astrolex_tools.levels`, `validate_data` and the level curve pass.

Out of scope: the forgery and jam code stays (dormant, still tested) in case the owner wants them back as a later, clearly taught hazard. The overlapping intro/loading/title screens from the same message are separate work.

# WP-F.26: Remove the pronoun pick

Owner request (29 Oct 2026, project thread): "remove the pronuns". A character check that day found the pronoun choice was saved but no line in the game used it: every line about the Catcher is written without a gendered word.

## Acceptance criteria
1. **Picker gone.** The Catcher screen shows the four suits, the name field and Suit up / Back, with no Pronouns row. `confirmed` carries the suit and the name only.
2. **Save.** `profile` is `{character, difficulty, name}`; `Save.set_profile(character, difficulty, name)`. An older save's `"pronouns"` is dropped on load, everything else is kept (save version unchanged, 3).
3. **Text.** The story bible no longer says the player picks pronouns; the lines still never assume a gender.
4. **Checks.** `scripts/godot/test.sh` passes; CI web export and Chromium smoke pass.

Out of scope: any other finding from the character check (Pip's perk, role labels, Catcher lines, Prologue, VANTA ghost race, Babel comms).

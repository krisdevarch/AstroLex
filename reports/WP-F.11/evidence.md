# WP-F.11 evidence: Remove the Prologue

Brief: `wps/WP-F.11.md`. Decision: O-30 in `wps/_index.md`.

`web-flow.jpg`: the exported web build in headless Chromium. Left: a new player right after Launch on the difficulty screen lands on the level map, with no Prologue. Right: a page reload shows Continue. Steps: `scripts/godot/web-smoke/tour.cjs`.

| AC | Result | Check | Artefact |
|---|---|---|---|
| 1. New game goes straight to the map | pass | `test_flashback.gd::test_new_player_goes_straight_to_the_map`; `test_flow.gd` | `web-flow.jpg` |
| 2. No Prologue replay in Settings | pass | `test_settings_has_no_prologue_replay` | |
| 3. Flashback before 3-06 unchanged | pass | `test_flashback_plays_before_3_06_once_and_skips`, `test_flashback_ends_on_its_own`, `test_reduced_motion_has_no_drift` | |
| 4. Prologue art and data removed; make_stills paints only f1-f5 with identical output | pass | `python3 scripts/art/make_stills.py` leaves `game/art/stills/f*.jpg` unchanged (git status clean) | |
| 5. Suite and web | pass | `scripts/godot/test.sh`: 260 passed, 0 failed, no SCRIPT ERROR; `scripts/godot/export.sh web` exit 0; tour with no page errors | `web-flow.jpg` |

Not changed: Tomas's first inbox message (the `prologue` entry in `data/story/tomas.json`, shown in the inbox) is story text, not the Prologue scene, so it stays.

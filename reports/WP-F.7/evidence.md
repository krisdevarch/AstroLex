# WP-F.7 evidence: wordless Prologue and Act III flashback

Contact sheet of the 12 placeholder stills (row 1: p1-p6, row 2: p7, f1-f5): `contact-sheet.jpg`.
Stills are 1080x1920 JPEGs under 40 KB each (`game/art/stills/`), painted by `scripts/art/make_stills.py`,
which also writes `game/data/stills.json` (ids and seconds only) from `data/story/*`.

| AC | Result | Check |
|---|---|---|
| 12 placeholder stills, each under 120 KB | pass | `python3 scripts/art/make_stills.py` prints sizes (max 38.9 KB) |
| Wordless animatic: fade, hold with Ken Burns, fade; no text | pass | `game/scenes/prologue.gd`; test_reduced_motion_has_no_drift |
| Last still: tile "w" drifts in, tap anywhere plays tether sound, WATER letter by letter, colour returns, ends | pass | test_tapping_the_water_tile_ends_the_prologue |
| Skip chip from the second still | pass | test_skip_ends_the_prologue_and_saves_the_flag |
| New player sees it once, after difficulty, before the map; flag saved; Settings replay | pass | test_new_player_sees_the_prologue_once_then_the_map, test_flag_persists_in_the_save_file; `PrologueButton` in settings |
| Flashback before 3-06 once, skippable, no water, under 30 s | pass | test_flashback_plays_before_3_06_once_and_skips (29 s) |
| Music duck hook guarded with has_method | pass | `main.gd` `_play_animatic` (no music node in this tree) |
| Whole suite | pass | `scripts/godot/test.sh`: 216 passed, 0 failed, no SCRIPT ERROR |
| Web export and smoke | pass | `export.sh web`; `node smoke.cjs ../../../build/web /tmp/f7.png --autoplay`: round won, score 502, no Prologue in autoplay |

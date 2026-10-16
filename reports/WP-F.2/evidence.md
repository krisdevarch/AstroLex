# WP-F.2 evidence: the Catcher's name and the ending

| AC | Result | Check / artefact |
|---|---|---|
| Name entry (3-8 letters A-Z, upper-case, Suit up disabled until 3, "Pick another name" for blocklisted) | pass | test_name.gd::test_character_screen_gates_suit_up_on_the_name, test_clean_..., test_validation_... |
| Saved in profile; v3 save migrates old saves (name ""), asked on the map's first visit | pass | test_name.gd::test_save_stores_and_migrates_the_name, test_old_save_without_a_name_is_asked_on_the_map |
| Blocklist exported to content.json ("blocklist") | pass | `python -m astrolex_tools.export_game_data` |
| 4-12 words are LISTEN then the name (file keeps listen + placeholder "name"; level checker ok) | pass | test_name.gd::test_4_12_words_are_listen_then_the_name; `python -m astrolex_tools.levels` |
| Name row ghosts shown in full; LISTEN snaps colour; Babel lines | pass | test_name.gd (_name_row, test_finale_babel_lines); round.gd `_finale_line` |
| Ending screen replaces BetaComplete for the final level; name in Tomas's text; reduced motion no sweep; Back to map | pass | test_flow.gd::test_winning_4_12_shows_the_ending, test_name.gd ending tests |
| Full suite | pass | `scripts/godot/test.sh`: 199 passed, 0 failed, no SCRIPT ERROR |
| Web export and smoke | pass | `export.sh web`; `node smoke.cjs ../../../build/web /tmp/f2.png --autoplay`: round won, score 501 |

Defaults chosen: no `babelFinal` or `tomas.json` exists, so Babel's line after the name is "I hear you." (shown as the bible's one allowed exception to letters-only); Tomas: "I can say all of it now. I love you, Gran. Thank you, <Name>. Come and see the water with us." (his 4-12 line with the name added); Rhee's card is her 4-12 line plus the bible's definition of listen. The 4-12 closing chatter is skipped because the ending carries it. Not visually checked: the character screen layout (separation tightened to fit the name field) and the ending art; the smoke only plays 1-01.

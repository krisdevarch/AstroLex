# WP-F.6 Daily Signal: evidence

| AC | Result | Test / command | Artefact |
|---|---|---|---|
| Same UTC date gives the same level, different dates differ; seed = FNV-1a of the date | pass | `game/tests/rules/test_daily.gd` (same_date, seed_is_fnv1a) | `game/rules/daily.gd` |
| 4 words, one per act, 3-6 letters, no repeats; title gives nothing away | pass | `test_four_words_one_per_act_from_the_acts`, `test_level_shape_and_no_spoilers` | |
| 45 s burst, counterfeit 0.3, 1 trap, no comms | pass | `test_level_shape_and_no_spoilers` | |
| Copy matches approved story data | pass | `test_copy_matches_the_approved_story_data` | `data/story/daily.json`, `babel_final.json` |
| Title button and map signal button route to the daily; new player picks a Catcher first | pass | `game/tests/scenes/test_daily_flow.gd` | title screenshot (scratch) |
| Result card has Share and Back, Babel line, stars | pass | `test_result_card_save_streak_and_replay` | `game/scenes/level_card.gd` |
| Save records stars, time, streak; replay same day leaves streak alone; next day extends | pass | `test_result_card_save_streak_and_replay`, `test_streak_counts_consecutive_days_and_replays_do_not_count` | `game/services/daily_record.gd` |
| Share text = template + squares + URL; navigator.share, else clipboard + "Copied" | pass (text and clipboard path in tests; the share sheet is browser-only, not tested here) | `test_share_text`, `on_share` in the flow test | `game/services/share.gd` |
| 1080x1080 PNG card offered via navigator.share files | built; rendered on the web only, skipped quietly if no image | not exercised headless | `game/scenes/daily_image.gd` |
| Telemetry level `daily-<date>`, act `daily` | pass | `test_title_button_plays_the_days_level` | |
| Suite and web build | pass: 239 passed, 0 failed, no SCRIPT ERROR; `export.sh web` ok | `scripts/godot/test.sh` | |
| Web smoke | pass: autoplay round won, score 501 | `node smoke.cjs ../../../build/web /tmp/f6.png --autoplay` | |

Choices: `babelIntro` is the approved `intro` line (daily_lines holds only win and lose lines); the result card picks its win or lose line from the date. The daily round uses Act II's sky and the player's difficulty and Catcher mods. Daily stars do not count towards map stars.

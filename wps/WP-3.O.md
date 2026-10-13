# WP-3.O: One game screen from level to level

Owner (13 Oct 2026, 21:29): "now let's work on transition from one to another level design. try to design it to look very smooth when going from one to another level, show how many stars reached in a same design level. also make the story from the characters to be on the same screen where the game is. The point is for players to have very smooth transition between levels."

Before this WP, a level ended by cutting to a separate end screen (text stars `**-`), then to a separate comms screen with the crew's lines, then back to a freshly built field. Three hard cuts per level.

## Scope
The game screen (the locked mock-v3 look of WP-3.J to 3.N) now stays up for the whole act. Nothing on it is restyled.
- **Clear:** when a level ends, every letter and item still drifting lets go and floats out of the field (`flow.clearSec`); drones fade. The filled slots stay, so the restored word is still on screen.
- **Level card** (`game/scenes/level_card.gd`): rises in the play field, drawn in the HUD's own look (the slot tray's navy and slate rim, teal-outlined star sockets like the slots, the Hint button's orange for the main button). Each earned star flies out of the clock bar, where the time left ends (stars come from time left), arcs into its socket, pops with a burst and rings a rising note (`flow.starSec`, `flow.starGapSec`). Won: Next and Retry, with a quiet Map link. Lost: "Out of time", empty sockets, Retry and Map. Send and Copy results stay on the card for playtests.
- **Story on the game screen** (`game/scenes/story_strip.gd`): on Next, the card folds away and the crew's chatter (this level's `commsAfter`, then the next level's `commsBefore`) rises line by line above Earth's rim, in bubbles drawn like Babel's (navy, a pill outline in the speaker's colour, a small avatar disc until the crew have portraits). Lines type in and move on at reading pace (`flow.storyReadSec` + length / `flow.storyCps`); a tap finishes the line or moves on; Skip ends it. Babel's own lines go to his bubble at the top. The first level from the map plays its `commsBefore` the same way.
- **Change-over in place:** while the crew talk, the level name and counter chips cross-fade to the next level, the new empty slots pop in one by one, the clock bar refills (`flow.refillSec`) and the sky and city lights drain back to grey. When the chatter ends, Babel's rift throws the new letters (WP-3.T) and play starts.
- **Retry** and the pause menu's **Restart** replay on the same screen with no chatter. The act-complete and beta-complete screens stay separate screens (the act changes); the act's last `commsAfter` plays on the game screen first.
- `?demo=1` (web) / `--demo`: the autoplay bot with a Catcher, the chatter, and Next pressed a few seconds after each win, for clips. Autoplay (CI smoke) is unchanged: no chatter.
- Removed: `end_screen.gd`, `comms_screen.gd`.

## Acceptance criteria
| AC | Check |
|---|---|
| AC1 | A win shows the level card on the same field (no end screen); the stars fly from the clock bar and every earned star lands | `test_a_win_shows_the_level_card_on_the_game_screen`, `test_level_card_shows_the_stars_and_the_numbers` |
| AC2 | Leftover letters drift off when a level ends; a loss shows "Out of time", no Next, no stars | `test_leftover_letters_drift_away_when_the_level_ends` |
| AC3 | Next keeps the same field: chatter (after + before) on the field, Babel's lines in his bubble, chips and counter change, clock refills, letters wait, then Babel throws | `test_next_plays_the_chatter_and_the_next_level_on_the_same_screen`, `test_story_strip_taps_skip_and_colours`, `test_story_strip_reads_on_by_itself_and_reduced_motion_shows_all` |
| AC4 | Retry replays in place without chatter; only the first card choice counts | `test_retry_replays_in_place_without_chatter`, `test_the_card_takes_only_the_first_choice` |
| AC5 | Two levels on one screen record two telemetry rounds, events not doubled; saves kept | `test_two_levels_on_one_screen_record_two_rounds_once_each` |
| AC6 | Act and beta complete still reached; all tests pass; data valid; web export builds; autoplay smoke wins | `test_flow.gd`, `validate_data`, `pytest tools`, `scripts/godot/test.sh`, `scripts/godot/export.sh web`, `smoke.cjs --autoplay` |
| AC7 | A phone-size clip of win, stars, story and the next throw | `reports/WP-3.O/level-transition.mp4` |

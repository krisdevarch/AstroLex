# WP-3.O evidence

Branch `claude/project-thread-ud6443`, 13 Oct 2026.

| AC | Result | Check | Artefact |
|---|---|---|---|
| AC1 | pass | `test_a_win_shows_the_level_card_on_the_game_screen`, `test_level_card_shows_the_stars_and_the_numbers` | `card-story-throw.jpg` (left) |
| AC2 | pass | `test_leftover_letters_drift_away_when_the_level_ends` | `level-transition.mp4` |
| AC3 | pass | `test_next_plays_the_chatter_and_the_next_level_on_the_same_screen`, `test_story_strip_taps_skip_and_colours`, `test_story_strip_reads_on_by_itself_and_reduced_motion_shows_all` | `card-story-throw.jpg` (middle, right) |
| AC4 | pass | `test_retry_replays_in_place_without_chatter`, `test_the_card_takes_only_the_first_choice`, `test_restart_during_the_chatter_drops_it_and_its_follow_up` | — |
| AC5 | pass | `test_two_levels_on_one_screen_record_two_rounds_once_each` | — |
| AC6 | pass | `validate_data` ok; `levels: ok`; `pytest tools` exit 0; `scripts/godot/test.sh` 178 passed, 0 failed, no SCRIPT ERROR; `scripts/godot/export.sh web` exit 0; `smoke.cjs --autoplay` round won (score 503) | — |
| AC7 | pass | `?demo=1` in headless Chromium, 393×852 | `level-transition.mp4` |

Notes
- `level-transition.mp4`: 24 s at real speed (software rendering keeps the transition at about 1×): 1-01's last word, the leftover letters drifting off, the card with three stars flying out of the clock bar, Next, Rhee's lines on the game screen while the chips, slots and clock change over, then Babel throwing 1-02's letters and the bot playing.
- Reviewer (static read): one blocking finding fixed (a pause-menu Restart during the chatter left the old strip running, which could re-run the throw or jump to act complete; now dropped, with a test), Babel's last line is now cleared between levels (it leaked into the next level's card and telemetry), the act's closing chatter keeps the field empty, and a second strip replaces the first.
- Not changed: the small animation constants inside the new views (card rise 0.35 s, chip cross-fade 0.5 s, slot pop 0.28 s) follow the existing view constants such as `PULSE_SEC`; the timings a player waits on are tunables (`flow.*`).

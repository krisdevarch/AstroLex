# WP-3.N evidence

Branch `claude/project-thread-4bg9x3`, 13 Oct 2026.

| AC | Result | Check | Artefact |
|---|---|---|---|
| AC1 | pass | `test_sounds_are_synthesised_and_catch_notes_climb_the_scale` | `sounds-demo.m4a` |
| AC2 | pass | `test_a_round_plays_a_note_per_catch_and_a_chord_per_word` (autoplay round) | `sounds-demo.m4a` |
| AC3 | pass | `test_a_restored_word_shows_its_banner_and_shakes_the_field` | `game-feel.mp4` |
| AC4 | pass | `test_reduced_motion_keeps_the_field_still` | — |
| AC5 | pass | `test_a_combo_pops_up_where_the_letter_was_caught` | `game-feel.mp4` |
| AC6 | pass | `test_the_heartbeat_sounds_in_the_last_seconds` | `sounds-demo.m4a` |
| AC7 | pass | `validate_data` ok; `levels: ok`; `pytest tools` passed; `scripts/godot/test.sh` 171 passed, 0 failed, no SCRIPT ERROR; `scripts/godot/export.sh web` exit 0 | — |

Notes
- `game-feel.mp4`: level 1-01 on a phone (393×852), headless Chromium, `?autoplay=1` (the bot plays) with a temporary character override that is not committed. Sped up 1.9× to real speed, since software rendering runs slow. Video only: the recorder captures no audio.
- `sounds-demo.m4a`: the sounds exported from `sfx.gd` by a headless Godot script, in the order a player hears them: five catches with their tether zips (a five-letter word), the restore chord, a wrong-letter buzz, then three heartbeats.
- Fastest catchable letter after the speed change: 0.22 × 1.45 × 1.35 ≈ 0.43 field units/s, so about 0.086 of drift during the longest tether flight (0.2 s), inside the 0.096 hit tolerance.

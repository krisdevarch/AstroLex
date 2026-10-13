# WP-3.N: Game feel pack 1 (real speed, sound, reward moments)

Owner (13 Oct 2026, 20:10): "it's fine, but still it's kinda boring, investigate what we can do to improve the gamers experience". The review found three gaps: each level sets its own `drift.speed` (0.06–0.14), which overrode the WP-3.M speed-up; the game had no sound, haptics or shake at all; and the combo was invisible.

## Scope
- **Real speed:** every level's `drift.speed` × 1.6 (act 1 now 0.10–0.22). Level data is `status: draft`; only tuning numbers change, no text.
- **Placeholder sounds** (`game/scenes/sfx.gd`, synthesised in code, no files; O-14: the audio designer replaces them in WP-4.8): a tether zip, a catch note that climbs a pentatonic scale with the letter's slot (spelling a word plays a tune), a wrong-letter buzz, a restore chord, drone sounds, and a heartbeat once a second under `fx.heartbeatSec` (8). Volume `sfx.volumeDb`; the sound button mutes them.
- **Reward moments:** a "×1.3" combo pop where a letter is caught (bigger and warmer as it climbs, "MAX" at the top); the restored word bursts across the field ("BREAD!", `fx.bannerSec`) with a gold burst; the field shakes (`fx.shakePx`, `fx.shakeSec`) on a restore and half as much on a wrong catch or a drone shot down; a short vibration where the browser supports it. Shake and vibration are off under reduced motion.

## Acceptance criteria
| AC | Check |
|---|---|
| AC1 | Sounds are synthesised; catch notes rise with the slot | `test_sounds_are_synthesised_and_catch_notes_climb_the_scale` (test_feel.gd) |
| AC2 | A real round plays a note per catch, the zip and the restore chord | `test_a_round_plays_a_note_per_catch_and_a_chord_per_word` |
| AC3 | A restored word shows its banner, shakes the field, then settles | `test_a_restored_word_shows_its_banner_and_shakes_the_field` |
| AC4 | Reduced motion keeps the field still | `test_reduced_motion_keeps_the_field_still` |
| AC5 | The combo pops where the letter was caught and says MAX at the top | `test_a_combo_pops_up_where_the_letter_was_caught` |
| AC6 | The heartbeat sounds in the last seconds | `test_the_heartbeat_sounds_in_the_last_seconds` |
| AC7 | Level speeds raised; data and levels valid; all tests pass; web export builds | `validate_data`, `python -m astrolex_tools.levels`, `pytest tools`, `scripts/godot/test.sh`, `scripts/godot/export.sh web` |

# WP-F.8 evidence: music and audio settings

Placeholder audio synthesised in code (owner pre-approved; O-14 human audio replaces it).

| AC | Result | Test / command | Artefact |
|---|---|---|---|
| Beds for 4 acts + menu, 8-12 s loops, 22050 Hz, cached | pass | `test_music.gd::test_a_bed_exists_for_every_act_and_the_menu` (5 beds in ~1.3 s native; only the menu bed renders at start, acts render one per frame afterwards) | game/scenes/music.gd |
| play(act) crossfade 1.5 s, stop() | pass | `test_play_sets_the_stream_and_crossfades` | |
| duck(true/false) | pass | `test_duck_lowers_the_music_and_restores_it` | |
| Leitmotifs (rhee, babel = rhee reversed, ade, kit, vanta, tomas, catcher) 4-6 notes; sting(who) from story_strip | pass | `test_motifs_and_stings` | story_strip.gd hook |
| Music and Sfx buses; sfx on Sfx; sliders 70/100 persist and apply | pass | `test_sliders_persist_and_drive_the_buses`, `test_settings_screen_sliders_save`, `test_sfx_players_use_the_sfx_bus` | ui.gd `slider`, settings_screen.gd |
| Hooks: menu bed in `_swap`, `play(act)` in `_start_level`, field ducks in play_story / set_paused | pass | web smoke below | |
| Headless without audio device | pass | `scripts/godot/test.sh`: 197 passed, 0 failed, no SCRIPT ERROR | |
| Web export boots and autoplay wins | pass | `node smoke.cjs ../../../build/web /tmp/f8.png --autoplay`: round won, score 502 | |

New tunables (data/tunables/game.json, schema, regenerated game/data/tunables.json): music.crossfadeSec, music.duckDb, music.bedDb, music.stingDb, music.defaultVolume, sound.defaultVolume. `validate_data`: ok. Slider defaults 70/100 are also constants in app_settings.gd (DEFAULT_MUSIC, DEFAULT_SOUND).

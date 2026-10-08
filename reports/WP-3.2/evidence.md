# Evidence: milestone first draft (WP-3.2)

Commit: 0375592 (branch claude/first-draft, uncommitted evidence) · Date: 2026-10-08 · Godot 4.7.2 stable

## AC table

| AC | Check | Result | Artefact |
|---|---|---|---|
| D1 | `python3 -m pytest tools -q`; `python3 -m astrolex_tools.validate_data` | pass (all tests green, "data validation: ok") | terminal |
| D2 | `scripts/godot/test.sh`: 42 passed, 0 failed. test_round.gd: test_spawns_exactly_the_needed_letters_plus_decoys_and_back_tiles, test_decoys_never_use_a_letter_of_the_active_or_preview_word, test_back_tiles_are_decorative_and_not_catchable, test_tiles_stay_inside_the_bounds_while_drifting, test_catch_active_slot, test_catch_preview_slot_then_carry_over, test_wrong_catch_unneeded_resets_combo_and_flips_velocity, test_wrong_catch_surplus_when_letter_is_in_word_but_no_open_slot, test_surplus_real_copy_and_word_letter_decoy_dissolve_after_next_catch, test_escape_when_the_tile_moves_more_than_tolerance, test_one_shot_in_flight_and_one_queued, test_pressure_drains_and_loses, test_restore_score_and_events, test_thousand_seeded_rounds_are_solvable_in_drift, test_same_seed_same_event_stream, test_ramp_numbers | pass | test.sh output |
| D3 | test_babel.gd: test_lines_use_only_pool_letters_with_multiplicity, test_min_letters_filters_short_lines, test_pick_never_repeats_a_shown_line, test_compose_without_rng_is_deterministic, test_empty_pool_composes_nothing; test_round.gd::test_babel_lines_follow_restore_and_never_repeat; test_letter_pool.gd (4 tests). Pool-constraint property test: the multiplicity test above | pass | test.sh output |
| D4 | test_field.gd: test_tap_on_a_tile_fires_and_a_far_tap_does_not, test_back_plane_tiles_cannot_be_tapped, test_autoplay_wins_a_drift_round_and_the_hud_score_matches; screenshots from the web smoke. Treatment switch (O-22) covered by test_settings.gd only as a stored setting; visual check of all three is owner-side | pass (tests); visuals pending owner | reports/WP-3.2/draft.png, draft-mid.png |
| D5 | test_main_scene.gd: test_start_screen_shows_title_and_both_modes, test_start_leads_to_the_field_and_pressure_shows_the_oxygen_bar, test_end_screen_lists_the_numbers; test_settings.gd: test_settings_round_trip, test_settings_ignore_an_unknown_treatment | pass | test.sh output |
| D6 | test_field.gd::test_autoplay_wins_a_drift_round_and_the_hud_score_matches (headless); web smoke `--autoplay` waits for the won line | pass | smoke output below |
| D7 test.sh green | 42 passed, 0 failed | pass | |
| D7 web export + Chromium smoke | `scripts/godot/export.sh web` ok; smoke ok (below) | pass | build/web |
| D7 CI green on the PR | | pending | |
| D7 reviewer verdict | | pending | |

## Web export sizes (build/web)

| File | Raw bytes | gzip -9 bytes |
|---|---|---|
| index.wasm | 39,514,754 | 10,084,297 |
| index.pck | 76,076 | 62,385 |

## Web smoke (autoplay)

Command: `cd scripts/godot/web-smoke && NODE_PATH=/opt/node22/lib/node_modules CHROMIUM_PATH=/opt/pw-browsers/chromium-1194/chrome-linux/chrome node smoke.cjs ../../../build/web ../../../reports/WP-3.2/draft.png --autoplay`
- Ready line: `AstroLex ready: 20 tiles`
- Won line: `AstroLex round won: score=358`
- Time: main scene ran in 1.8 s; whole smoke run 13.7 s wall clock
- Renderer: WebGL 2.0 (Compatibility), Emscripten 4.0.20 single-threaded

## Tunables introduced

None in this evidence run (game.json was covered by D1 in earlier WPs).

## Owner check pending

- Does a catch feel snappy?
- Are the tiles readable and big enough on the phone?
- Which tile treatment do you prefer: flat, tilt or bevel (O-22)?

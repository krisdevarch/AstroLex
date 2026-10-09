# WP-B evidence (beta milestone)
Commit e0e1a9a, 2026-10-09. Screenshots: /mnt/project-files/beta-shots/

| AC (Definition of Done) | Check | Result | Artefact |
|---|---|---|---|
| Godot rules and flow pass | `scripts/godot/test.sh` (run by orchestrator) | pass, 130 passed (after review fixes) | game/tests: test_round, test_level, test_thief_view, test_flow, test_dictionary, test_save |
| Python tools | `. .venv/bin/activate; pytest tools -q` | pass (all dots, 100%) | |
| Data valid | `python -m astrolex_tools.validate_data` | pass, "data validation: ok" | |
| Web export | `scripts/godot/export.sh web` | pass | build/web/index.wasm, index.pck |
| Boots in Chromium and autoplay wins 1-01 | `node smoke.cjs --autoplay ../../../build/web` | pass, ready in 1.8 s; "autoplay round won, score 353" | |
| Pick character and difficulty | Playwright clicks | pass (screens render, Confirm advances) | 02-char.png, 03-difficulty.png |
| Level map with stars | Playwright | pass, 4 acts shown, only 1-01 unlocked | 04-map.png |
| Comms then 30 s burst with clock | Playwright, 8 s in play | pass, clock bar and 20 s counter visible | 05-comms.png, 06-play.png |
| Thief drones | covered by test_thief_view, test_round; no drone in 1-01 | not checked in browser | |
| Stars on results | covered by test_round, test_flow | not checked in browser | |
| Quit and continue later | covered by test_save, test_flow | not checked in browser (save-reload.cjs not run) | |
| Act I-01 to Act IV last level, beta-complete screen | covered by test_level, test_flow | not checked by hand | |
| Dictionary loader | test_dictionary | pass | |

Tunables introduced: none by this evidence run.
Owner check pending: feel of the 30 s burst, clock bar, thief difficulty, comms text (draft), character perks.

## Review
Reviewer pass on the full diff: 1 blocking and 5 should-fix findings, all fixed (dictionary shape check, stricter validation, `?dict` debug-only and no cache without REMOTE_URL, remote content applied from the next start, end screen before beta complete, thieves never grab a tile under an in-flight shot, spawn schedule advances at max). Two nits fixed (idle speed after a chase).

## WP-B.9: longer bursts per act, one-letter hint (owner playtest, 9 Oct 2026)
Owner ask: "a hint of one letter per word, and more than 30 s; 30 s is too little to solve three words; maybe in the latest levels."

| AC | Check | Result | Artefact |
|---|---|---|---|
| Burst length is per-act data, longest in Act I, 30 s only late in Act IV | `pytest tools/tests/test_levels.py::test_act_tuning_merges_under_level_tuning` | pass | act `tuning` block in `data/levels/act*.json`, merged under level tuning by `load_levels` |
| Stars scale with the clock | `test_round.gd::test_stars_thresholds`, `test_stars_scale_with_a_longer_burst` | pass | `stars.threeShare`, `stars.twoShare` in `data/tunables/game.json` |
| Time bar spans the whole burst | `test_levels_flow.gd::test_act_one_burst_is_sixty_seconds_and_the_bar_fits_it` | pass | `field.gd` `_update_hud` |
| First letter of each word shown by default, Settings keeps all four choices | `test_hint.gd::test_one_shows_first_letter_only`, `test_default_hint_is_one_letter`; `test_settings.gd` | pass | `app_settings.gd` (key `hint_v3`) |
| All checks | `validate_data`, `levels`, `pytest tools`, `scripts/godot/test.sh` | pass, Godot 135 passed | |

Numbers chosen (owner tunes): Act I 60 s, Act II 50 s, Act III 45 s, Act IV 40 s for 4-01 to 4-06, 35 s for 4-07 to 4-09, 30 s for 4-10 to 4-12. Three stars at a third of the clock left, two at a sixth (60 s: 20 s / 10 s; 30 s: 10 s / 5 s, as before). Base `burst.seconds` stays 30 for unauthored rounds.
Tunables introduced: `stars.threeShare` 0.3333 and `stars.twoShare` 0.1667 (replace `stars.three` and `stars.two`).

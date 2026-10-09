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

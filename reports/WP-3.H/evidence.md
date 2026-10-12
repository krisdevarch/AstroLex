# WP-3.H evidence: Game screen v2

Commit a2a7c8d (uncommitted working tree), 2026-10-12.

| AC | Check | Result | Artefact |
|---|---|---|---|
| AC1 | `scripts/godot/test.sh` (rules tests for `use_hint`) | PASS: 150 passed, 0 failed, no SCRIPT ERROR | test log |
| AC2 | `python -m astrolex_tools.validate_data` -> ok; `export_game_data` then `git status --short game/data` shows only ` M game/data/tunables.json` (the intended change) | PASS | `game/data/tunables.json` |
| AC3 | Scene tests (in the 150) + screenshots | PASS for 393x852 and 405x720 phone shots; 1080x1920 and 1179x2556 covered by scene tests only. Shots came from a local build with a temporary character hook, since reverted. | `reports/WP-3.H/phone-393x852-ash.jpg`, `phone-405x720-juno.jpg` |
| AC4 | Scene tests (Hint, Pause, Sound persistence, Settings) | PASS (in the 150) | test log |
| AC5 | Scene test: no catchable tile under bottom HUD | PASS (in the 150) | test log |
| AC6 | `test.sh` 150/0; `pytest tools -q` all passed; `export.sh web` built build/web; `node smoke.cjs ../../../build/web` -> "ok: main scene ran in 1.8 s (8 tiles)" | PASS. Note: the smoke output reports boot and 8 tiles; it did not print an explicit round win. | build/web |

## Tunables introduced
- `burst.hintCost` = 3 (seconds), in `data/tunables/game.json` with schema entry, exported to `game/data/tunables.json`.

## Notes
- Portraits in `game/brand/characters/` are cropped from `docs/design/characters/` (owner-generated images). They are placeholder art under O-14.

## Owner check pending
- Feel and look of the HUD, portrait, amber hint glow (about 1.5 s), clock bar colours, hint cost of 3 s.

## Review fixes (after the reviewer pass, 12 Oct 2026)
- The field uses one scale for x and y and is centred, so on 16:9 screens (1080x1920) the letters are smaller (about 0.71x) with side margins; on taller phones (19.5:9, e.g. 1179x2556) it is close to full size. Layout maths clamp the view height to at least 1600.
- The next-word preview boxes shrink to fit the tray (11-letter word tested).
- The hint glow clears when the tile is caught; a repeat hint on the same tile is free and re-glows it; a hint is refused when it would end the round (`time_left <= burst.hintCost`).
- Re-run: `scripts/godot/test.sh` 150 passed, 0 failed, no SCRIPT ERROR (the "Parse JSON failed" line is an existing negative test); `validate_data` ok; `export_game_data` changes only `game/data/tunables.json`. Screenshots above re-taken from the fixed build.

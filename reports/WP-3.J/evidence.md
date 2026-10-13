# WP-3.J evidence

Branch `claude/project-thread-4bg9x3`, 13 Oct 2026.

| AC | Result | Check | Artefact |
|---|---|---|---|
| AC1 | pass | `python -m astrolex_tools.validate_data` → ok; `python -m astrolex_tools.export_game_data` leaves no diff | `tile.glyphScale: 0.8`, `glass.bubbleTint: 0.35` |
| AC2 | pass | `test_tile_view_bubble_is_round_and_untilted`, `test_bubbles_are_softly_coloured_and_letters_stay_white` (test_glass.gd) | `bubble-colour-compare.jpg` |
| AC3 | pass | `scripts/godot/test.sh` 160 passed, 0 failed, no SCRIPT ERROR; `scripts/godot/export.sh web` exit 0; `node smoke.cjs ../../../build/web` → "ok: main scene ran"; `pytest tools` passes | — |

Notes
- `bubble-colour-compare.jpg` shows clear, soft colour (0.35, the default here) and full colour (a temporary 0.5 wash with a strong rim, not committed). Screenshots: local web export in headless Chromium at `?autoplay=1` with a temporary character override that is not committed.
- Full colour gave the same letter the same colour, which reads as a clue, and its light cyan and yellow bubbles cut the white letter's contrast. Soft colour avoids both.

# WP-3.J: Bigger letters and softly coloured bubbles

Owner feedback (13 Oct 2026, after WP-3.I merged): "can you make a letters a little bit more bigger and i need you to think does it make sence to make the letter bubbles colorfull, or it will be too much". Web only.

## Scope
- **Bigger letters:** the glyph grows from 0.68 to 0.80 of the tile (new tunable `tile.glyphScale`). The bubble and tile spacing are unchanged, so the no-overlap guarantees from WP-3.I still hold.
- **Soft colour (proposed default, owner to confirm):** each bubble gets a light wash of one of six deep colours (`glass.bubbleTint` 0.35; 0 puts the clear glass back). Colours are picked per bubble, not per letter, so colour is never a clue. No amber or yellow, which belong to the hint glow. Letters stay white. The glass look stays clear.

## Acceptance criteria
| AC | Check |
|---|---|
| AC1 | `tile.glyphScale` and `glass.bubbleTint` are in `data/tunables/game.json` with schema entries, exported to `game/data/tunables.json` | `validate_data`, `export_game_data` leaves no diff |
| AC2 | The glyph uses `tile.glyphScale`; bubbles carry a tint from the palette, several colours for one letter, white letters; the glass look stays clear | `test_tile_view_bubble_is_round_and_untilted`, `test_bubbles_are_softly_coloured_and_letters_stay_white` (test_glass.gd) |
| AC3 | All existing tests pass, the web export builds and the Chromium smoke test runs | `scripts/godot/test.sh`, `scripts/godot/export.sh web`, `node smoke.cjs` |

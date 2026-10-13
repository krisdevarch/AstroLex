# WP-3.J: Bigger letter bubbles in liquid glass

Owner feedback (13 Oct 2026, after WP-3.I merged): "can you make a letters a little bit more bigger", then, on colourful bubbles: "no just make the bubbles bigger, also i've noticed that the glass layout does not magnify the object behind. and it should look exactly like this" with a reference image of Apple-style liquid-glass controls (not committed: third-party art), "take the icon with the plus sign". Web only. Bubbles stay clear (no colour).

## Scope
- **Bigger bubbles and letters:** `tile.size` 0.13 → 0.15 and `glass.bubbleScale` 1.25 → 1.2, so a front bubble is 0.18 of the field width (was 0.1625, +11 %). The glyph is `tile.glyphScale` 0.75 of the tile (was 0.68 of 0.13). `tile.minGap` stays 0.03, so bubbles still never touch.
- **Room for them:** the spawner tries up to 256 spots and keeps the roomiest; after each refill and each tick, the separation runs a few passes so a crowded cluster settles.
- **Liquid glass like the reference "+" disc:** the bubble reads the live screen and acts as a convex lens: what is behind (planets, rockets, stars) shows magnified, `glass.magnify` 0.12 at the centre and more toward the rim (`glass.rimBend` 0.9), with a slight colour split at the edge. A thin bright rim, brightest top-left and bottom-right, a faint iridescent edge and the soft drop shadow; no highlight spot. `glass.live` 0 falls back to the baked sky. The square glass look is unchanged.

## Acceptance criteria
| AC | Check |
|---|---|
| AC1 | New tunables (`tile.glyphScale`, `glass.live`, `glass.magnify`, `glass.rimBend`) have schema entries and are exported | `validate_data`, `export_game_data` leaves no diff |
| AC2 | At the larger size no two catchable tiles spawn or drift closer than r1 + r2 + `tile.minGap` | `test_spawn_never_overlaps_catchable_tiles`, `test_catchable_tiles_keep_their_gap_while_drifting` (test_round.gd) |
| AC3 | Bubbles read the live screen and magnify it; the glyph follows `tile.glyphScale` | `test_bubble_glass_magnifies_the_live_screen`, `test_tile_view_bubble_is_round_and_untilted` (test_glass.gd) + screenshot |
| AC4 | All existing tests pass, the web export builds and the Chromium smoke test runs | `scripts/godot/test.sh`, `scripts/godot/export.sh web`, `node smoke.cjs` |

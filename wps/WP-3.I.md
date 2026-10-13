# WP-3.I: Game screen polish from owner feedback

Owner feedback (12 Oct 2026, thread "design") on the merged WP-3.H screen: "the letters are overlapping with the background and the alignment of the elements are fully random. also the background looks boring and does not catch player attention". Web only. Bubble and glass looks unchanged.

## Scope
- **Letters never overlap:** catchable tiles (planes 0 and 1) keep a gap of `tile.minGap` (field units, default 0.03, a tunable); letters are larger (`tile.size` 0.13, glyph 0.68 of the tile). Spawns are rejection-sampled; drifting tiles that come too close bounce apart.
- **Readable letters:** the backdrop behind the play field is calm and dark (no bright nebula blobs behind the glass).
- **One grid:** 48 px margins on both sides. Left column: portrait. Right column: info row (NEXT boxes at left, points and combo at right), slot tray, four buttons, all sharing the column's edges. Full-width clock bar at the bottom. Top chips and Babel's band on the same margins. The night panel's curve is symmetric.
- **Sky (owner references and card choice, 13 Oct 2026):** the backdrop is just stars: a deep blue night with white dots and twinkling four-point sparkles. Cartoon planets with ink outlines (Earth with clouds, a ringed planet, a sun with rays, an orange, a blue, a red and a grey one), asteroids, a rocket, a satellite and fiery meteors move through the play field **just behind the letters** (owner pick "Just behind letters"): slower than the letters, never on top of them, and taps pass through. Planets turn and bob; under reduced motion nothing drifts. This replaces the first pass on this branch (galaxy band, Moon, sunrise).
- **Colour story (§9):** the scene starts drained and regains its colour, and Earth's city lights come on, as the level's words are restored.

## Acceptance criteria
| AC | Check |
|---|---|
| AC1 | No two catchable tiles spawn or drift closer than r1 + r2 + `tile.minGap` (act 1 round 1, 200 seeds; 30 seeds × 20 s); a head-on pair bounces | `scripts/godot/test.sh` (rules tests) |
| AC2 | `tile.minGap` is in `data/tunables/game.json` with a schema entry, exported to `game/data/tunables.json` | `validate_data`, `export_game_data` leaves no diff |
| AC3 | HUD controls start and end on the grid margins and column edges at 1080×1920 and 1179×2556; slots centred in the tray | scene test `test_hud_sits_on_one_grid` |
| AC4 | The backdrop starts desaturated and regains colour; city lights come on as words are restored | scene test `test_backdrop_regains_colour_as_words_are_restored` + screenshots |
| AC4b | Planets and craft sit in the letters' layer, drawn behind the tiles; they drift and stay around the field; they hold still under reduced motion | scene tests `test_sky_drifters_move_behind_the_letters`, `test_sky_drifters_hold_still_under_reduced_motion` + recording |
| AC5 | All existing tests pass, the web export builds and the Chromium smoke test runs | `scripts/godot/test.sh`, `scripts/godot/export.sh web`, `node smoke.cjs` |

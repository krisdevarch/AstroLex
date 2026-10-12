# WP-3.H: Game screen v2 from the owner's mock

Owner ask (12 Oct 2026, thread "design"): build the game screen agreed on the "AstroLex Game Screen" page (owner mock `docs/design/mock.gif`, reworked in the approved look of `docs/design/AstroLex-Design-Direction.md`). Web only. Keep the bubble and glass tile looks unchanged.

## Scope
- **Bottom HUD on Earth's night side:** a curved dark panel across the bottom of the screen with a thin cyan atmosphere line and a few coral city lights. Everything the thumb uses sits on it.
- **Porthole portrait:** the player's chosen Catcher (save profile `character`) as a head-and-shoulders bust in a circle at bottom left: metal rim, a ring and glow in the suit colour (`characters[].colour`), a small starry sky and Earth's curve inside, the name in a suit-colour pill under it. Images: `game/brand/characters/<id>.png`, cropped from `docs/design/characters/`. No portrait when no character is set (autoplay).
- **Clear word slots:** on a dark tray to the right of the portrait. Empty slot: dark fill, bright cyan outline. Restored letter: solid cream tile, dark letter. Ghost hint letters dimmed. The next word is a row of small boxes above the tray.
- **Bottom row:** points and combo at left; four square icon buttons at right: Hint (amber), Pause, Sound, Settings. Under them, the burst clock as a coral bar with a seconds label; the bar turns crimson for the last 5 s.
- **Top:** a level chip at left ("1-01 · First Breakfast"), "Level n / N" within the act at right, and Babel's line as a periwinkle band under them.
- **Field:** the letters' area sits between the top band and the bottom HUD; nothing in the HUD covers a catchable tile.
- **Hint (new rule):** `Round.use_hint()` picks a catchable tile that a slot of the active word still needs, costs `burst.hintCost` seconds (default 3, a tunable), emits `hint{tile_id}` and `time_cost{amount, reason: "hint"}`, and counts `stats.hints`. The view makes that tile glow amber for about 1.5 s.
- **Sound:** a mute switch saved in settings (`sound_on`); it mutes the master bus. The game has no audio yet.
- **Settings button:** pauses the round and opens the settings screen; closing it returns to the pause menu.

## Out of scope
The Act I background art (far debris), a live animated portrait, the tether starting from the portrait, new audio.

## Acceptance criteria
| AC | Check |
|---|---|
| AC1 | `Round.use_hint()` returns a needed catchable tile id, deducts `burst.hintCost`, emits `hint` and `time_cost`, counts `stats.hints`; returns -1 and costs nothing when no needed tile is catchable or the round is not in play | `scripts/godot/test.sh` (rules tests) |
| AC2 | `burst.hintCost` is in `data/tunables/game.json` with a schema entry, exported to `game/data/tunables.json` | `python -m astrolex_tools.validate_data`, `python -m astrolex_tools.export_game_data` leaves no diff |
| AC3 | The HUD shows the portrait of the chosen character, slots, preview, points, combo, four buttons, clock bar, level chip and counter, Babel band, laid out as in Scope at 1080×1920 and on a taller 1179×2556 phone screen | scene tests + screenshots in `reports/WP-3.H/` |
| AC4 | Hint, Pause, Sound and Settings buttons work; Sound persists across reloads | scene tests |
| AC5 | No catchable tile spawns or drifts under the bottom HUD | scene test |
| AC6 | All existing tests pass, the web export builds and the Chromium smoke test wins a round | `scripts/godot/test.sh`, `scripts/godot/export.sh web`, `node smoke.cjs` |

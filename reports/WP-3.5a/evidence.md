# WP-3.5a evidence: browser save (local-first, sync-ready)

Date: 9 October 2026. Branch `claude/project-thread-kdyzz8`. Owner decision: save in the browser now, sync to a server later (O-6 unchanged).

| AC | Result | Check | Artefact |
|---|---|---|---|
| AC1 one-file save service with a fake | pass | `game/tests/services/test_save.gd` runs the API on the fake and on a real `user://` file | `game/services/save.gd` |
| AC2 resume at next unbeaten level; wins move on, losses count a play; Act I complete offers "Play Act I again" keeping best scores | pass | save tests + scene tests ("Continue  1-05" starts 1-05) | `game/scenes/main.gd`, `start_screen.gd` |
| AC3 corrupt, partly corrupt, missing or unknown-version save starts fresh or is repaired, no script error | pass | tests: garbage act, level missing `won`, unknown version, unparsable file falls back to `.tmp` | – |
| AC4 Reset progress with confirm | pass | scene test: reset at index 4, back to Start, starts 1-01 | `settings_screen.gd` |
| AC5 tests, smoke, reload | pass | `scripts/godot/test.sh`: 101 passed, 0 failed; web smoke with autoplay wins (score 232); `save-reload.cjs`: win 1-01, reload, game resumes at 1-02 | `scripts/godot/web-smoke/save-reload.cjs` |

Notes:
- Writes go to a temp file and are renamed, so a failed write never truncates the live save.
- On the web Godot copies `user://` to IndexedDB on its own shortly after a write. Measured: a reload 0 to 500 ms after the write lost it, 750 ms and 1 s kept it. A player who closes the tab within about 0.75 s of a level ending could lose that one level; the end screen alone takes 1 s to appear.
- Stored: a random anonymous id, level ids, best scores, wins per mode and play counts. Nothing personal.
- The `?savetest=1` reload hook writes to a separate `user://save_test.json`, never the real save. The reload check is not in CI yet.

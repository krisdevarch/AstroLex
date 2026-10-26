# WP-F.20: Survive app switching, resume the level, report a problem

Owner report (26 Oct 2026, project thread): "when you switch from chrome to other app multiple times, the game froze and then I need to run it from scratch. Does not even remember the current state when I force close the tab. Usually happens on level 4. Also what can we do to report such issues and know what to do with them."

What we found before the change:
- Switching away and back (page hidden, frozen, resumed; 6 cycles on 1-04 in headless Chromium) does not stop the game loop: frames keep coming, no errors. Delta is clamped (0.25 s), and the round pauses on focus loss (WP-F.16).
- What does stop it is the browser dropping the game's graphics or memory while the app is in the background, which Chrome on Android does under memory pressure. Godot cannot rebuild a lost WebGL context, and a wasm abort (out of memory) leaves a frozen picture with no notice at all: the WP-F.16 notice covers only the context-lost alert.
- Progress is written only when a level ends, so a reload lands on the start screen and Continue opens the map; the level being played is not remembered.
- Playtest results can already be sent as a prefilled GitHub issue (`game/services/telemetry.gd`), but there is no way to report a problem, and the page keeps no record of what happened before a freeze.

## Acceptance criteria
1. The save remembers the story level being played (`resume`: act, index, level id) from the moment it starts, and forgets it when the level ends or the player quits to the map. Daily and autoplay never set it.
2. Continue on the start screen drops straight into the remembered level (from its start; time and caught letters are not kept). With nothing remembered, Continue opens the map as before.
3. After an automatic recovery reload the game skips the start screen and opens the remembered level.
4. When the browser drops WebGL, the page reloads itself (at once if visible, else as soon as the player comes back) and lands back in the level. A wasm abort or a game loop that stops for 5 s while the page is visible shows the notice with Reload and Report a problem.
5. The page keeps a short lifecycle log (visibility, freeze and resume, page hide, context lost, aborts, stalls) and the previous session's log survives a reload or force close.
6. Settings has "Report a problem": opens a prefilled `[bug]` GitHub issue (level, act, device, build, WebGL renderer and context state, recent errors, lifecycle logs, frame rate) or copies the same report. The notice page has the same button.
7. `docs/bug-triage.md` says what to do with a report; `.github/ISSUE_TEMPLATE/bug.md` for reports written by hand.
8. `scripts/godot/test.sh` passes with tests for 1, 2, 3 and 6; a Chromium check proves 3 and 4 (context lost, page reloads, level resumes).

Out of scope: restoring the clock and caught letters mid-round; a server for reports.

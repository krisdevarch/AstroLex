# WP-F.15: Web stability and phone heat

Owner report (25 Oct 2026, project thread): "few times the game has crashed in chrome, after retrying to solve the letters" and "on my iphone 17 pro max it gets very hot so it should not happen."

What we found before the change:
- Retry does not leak. 40 retries each on 1-01, 1-08 and 2-02 (headless Godot, a lost round, then Retry) left node, object and resource counts flat, no orphan nodes and no script errors.
- The game draws every frame the browser offers, with no frame cap: 120 frames a second on a 120 Hz screen.
- It renders at the full device pixel ratio: on a 3x phone the canvas is 1290 × 2796 (3.6 M pixels) and every pixel is redrawn every frame, with a full-screen copy for the bubble glass. In headless Chromium (software GL) the frame rate scales with pixel count: 3.1 fps at 3x, 7.3 fps at 2x.
- Menus, the pause menu and the level card run at the same rate as play.
- The telemetry frame-time list (`frames_ms`) grows without limit for the whole session.

## Acceptance criteria
1. Render resolution is capped at 2 device pixels per CSS pixel (`?dpr=` overrides it for testing). A 3x phone draws 44 % fewer pixels; 1x and 2x screens are unchanged.
2. Frame cap from tunables: `perf.playFps` (60) during play, `perf.menuFps` (30) on menus, the pause menu and other screens. A 120 Hz screen draws at most 60 frames a second in play.
3. Leaving the tab or app during a level opens the pause menu, so the clock and music stop until the player comes back.
4. If the browser drops the game's graphics (WebGL context lost, the usual cause of a frozen or crashed tab), the page shows a short notice with a Reload button instead of a frozen picture. Progress is kept because the save is written after every level.
5. Telemetry keeps the last 3,600 frame times only.
6. `scripts/godot/test.sh` passes, with tests for 2, 3 and 5; the web export boots and wins a round on autoplay in Chromium.

Out of scope: the glass look itself (the bubble's live refraction stays as the owner approved it), the level 14 timer and story words (separate threads).

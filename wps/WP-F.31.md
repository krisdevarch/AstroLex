# WP-F.31: One boot screen, no overlap

Owner report (6 Nov 2026, project thread): "the initial screen and the loading screen and the start screen are overlapping and there is like strange transition."

What we found (filmed at 390x844 in Chromium with the wasm held back 2 s, `scripts/godot/web-smoke/boot-film.cjs`):
- Three screens draw the same art in turn: the HTML loader (still + load bar + disabled "Tap to start"), the Godot intro (same art, button enabled) and the title (same art again, with the menu).
- The intro ends by fading to black and the title is then built from scratch, so the player sees the picture dim out and snap back with a different set of buttons.
- The loader fades as soon as the engine's start promise resolves, before Godot has drawn its first frame. On a phone the first frame can take seconds (shader compiles), and Godot's boot splash (a 720x1280 image stretched to the full window) shows through the fading loader as a third, distorted copy.

## Acceptance criteria
1. The intro is the title screen itself: it opens with only "Tap to start"; a tap or `intro.holdSec` cross-fades that button out and the menu in on the same screen. No rebuild, no fade to black.
2. The web loader stays up until the game has drawn its first screen (`window.__alxDrawn`, called by main.gd after two drawn frames), with a 10 s fallback; the bar shows 100 % at the hand-off.
3. Godot's boot splash image is off (`boot_splash/show_image=false`), so nothing stretched can show between the loader and the game.
4. `?intro=still` still captures the loader's picture (`intro_screen.gd` kept for that only).
5. `scripts/godot/test.sh` passes with the intro tests rewritten for one screen; the web smoke and recovery checks pass; before and after frames in `reports/WP-F.31/`.

Out of scope: changing the loader's art or the title's layout.

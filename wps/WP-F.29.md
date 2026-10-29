# WP-F.29: Intro screen with the crew

Owner request (29 Oct 2026, project thread): "can you create a intro screen that will look similar to this one but with our characters?" The reference image is key art: a deep-blue starfield with a diagonal purple nebula band, a chrome "AstroLex" logo in the middle and four characters in glossy glass bubbles around it. (The same message's HUD request is WP-F.28.)

Owner feedback on the first build (29 Oct 2026): "tap to start and the whole intro screen looks like some 10 years old did. also does not follow the overall game design ... it's like you play two different games." So the screen is rebuilt from the game's own kit, not from generated key art.

## Acceptance criteria
1. **Intro screen in the game's look.** On launch the game opens on an intro screen before the title, built only from what the game already uses: the painted Low Orbit sky and twinkling stars (`Ui.add_sky`), the game font (`Ui.text`, Fredoka) for the AstroLex wordmark, the glass bubble shader for the four Catchers' bubbles, the HUD's cyan and orange, and the standard orange `Ui.primary` button. The four Catchers are placed as in the reference: Wren top left, Juno large top right, Ash bottom left, Pip bottom right. The bubbles float in and bob out of step. A tap on the button or anywhere, or `intro.holdSec` seconds, goes to the title screen. Reduced motion holds everything still. It is skipped on autoplay, after a graphics-loss reload and with `?intro=0`, and shows once per launch (Back from the map goes to the title). Tests cover show, tap, timeout, the skips and the four Catchers.
2. **No generated key art.** No baked sky, logo or bubble images: the only art the intro adds is the four Catcher busts, and only if the existing `res://brand/characters/*.png` are not enough.
3. **Checks.** Schema entry for the new tunable; `validate_data`, `pytest tools` and `scripts/godot/test.sh` pass; the web export boots, and frames of the intro next to the title and play screens are in `reports/WP-F.29/`.

Out of scope: the start screen's own design, the HUD (WP-F.28), final human-made art.

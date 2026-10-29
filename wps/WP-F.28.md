# WP-F.28: A sharp HUD

Owner feedback (29 Oct 2026, project thread): "polish and improve the resolution and layout of the game HUD elements. they are good but they look like they are in very bad resolution".

## What we found
- The top chips, the wrong-catch pill and all text are drawn by Godot (StyleBox and fonts) and are already sharp on a 2x/3x phone.
- The bottom console (porthole frame, slot screen, cables, clock-bar frame), the three round buttons and the hint bulb are raster art cut from the owner's 572 px wide JPEG mock (`scripts/art/cut_hud.py`, WP-F.12) and upscaled 1.89x to the game's 1080 px. On a 390 pt phone at the capped pixel ratio of 2 they are shown at 1.37x the mock's own pixels, so every edge is soft and carries the JPEG's blocks. WP-F.14 then imported them lossy (WebP 0.9), which adds more blur.

## Acceptance criteria
1. **Vector HUD art.** The console, the three button faces (`btn_*.png`), their icons (`btn_*_icon.png`) and the hint bulb are redrawn as SVG (`scripts/art/hud/*.svg`) that keep the current art's shapes, colours and every geometry the game places things by (`MOCK_*` in `field.gd`), and are rendered by one script (`scripts/art/make_hud.sh`, via `render_svg.cjs`) at 2x the current pixel size. The JPEG cut script stays for the record but no longer feeds the game.
2. **Shown sharp.** The textures are imported lossless with mipmaps and drawn at half their pixel size with mipmap filtering, so they stay crisp from a 2x phone up to a large desktop window. No `MOCK_*` position changes; slots, wires, liquid, portrait and buttons still sit where they did.
3. **Tidy layout.** Small, measured fixes found while comparing before and after frames, listed in the evidence (nothing that moves the slots or buttons off the console).
4. **Checks.** `scripts/godot/test.sh` passes; web export boots in Chromium; before/after frames of the HUD at 390x844 @3x in `reports/WP-F.28/`. `wps/_index.md` updated.

Out of scope: a new HUD design, the intro screen (its own thread), the letters' glass.

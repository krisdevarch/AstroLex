# WP-F.13 evidence: placeholder art and the web loading screen

Owner ask (Kris, 22 Oct 2026, project thread): "work on the placeholder art and the loading screen. the music we will add later."

| AC | Result | Check | Artefact |
|---|---|---|---|
| a. Crew portraits (Rhee, Ade, Kit, VANTA, Tomas) are illustrated busts in the Catcher sticker style, clipped in the comms, Codex and inbox discs | pass | `scripts/art/make_crew.sh`; `test_codex_inbox.gd::test_every_crew_portrait_texture_loads` | `crew.jpg` (5 crew, then Wren and Pip for comparison) |
| b. Act III flashback stills f1–f5 are layered illustrations from the approved captions, no legible text, each under 300 KB | pass | `python3 scripts/art/make_stills.py` (99–120 KB each); flashback tests | `stills.jpg` |
| c. Branded loading screen: Low Orbit painting, AstroLex logo, coral progress bar with percent, drifting letter bubbles (still under reduced motion), fades out when the engine starts | pass | `node scripts/godot/web-smoke/loading.cjs ../../../build/web`: 40% mid-load, overlay removed after start | `loading.jpg` |
| d. Godot boot splash matches the loading screen, so the hand-off doesn't flash | pass | `game/project.godot` boot_splash = `res://brand/splash.png` (720x1280, 254 KB; Godot accepts only PNG here) | `splash.jpg` |
| e. Suite and web | pass | `scripts/godot/test.sh`: 264 passed, 0 failed, no SCRIPT ERROR; `export.sh web` exit 0; `smoke.cjs --autoplay`: round won, score 502 | |

Download sizes after this change (raw / gzip -9): wasm 39.5 MB / 10.1 MB, pck 12.4 MB (was 11.3 MB; images do not compress), js 280 KB / 68 KB, html 104 KB (the shell embeds the background and a 2.7 KB font subset). GitHub Pages compression could not be checked from the sandbox.

Still placeholder: the art is agent-drawn vector art (O-14: shipped art is human-made). Music and sound effects are unchanged, per the owner.

Rebuild: `scripts/art/make_crew.sh` (SVGs from `scripts/art/crew/gen_crew_svgs.py`), `python3 scripts/art/make_stills.py`, `python3 scripts/web/make_loading.py`. All three render SVG through `scripts/art/render_svg.cjs` (headless Chromium).

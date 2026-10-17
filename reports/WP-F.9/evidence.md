# WP-F.9 evidence: ship quality

| AC | Result | Test / command | Artefact |
|---|---|---|---|
| Curve report, 48 rows, flags (slack <15% or >70%, act trend) | pass | `python -m astrolex_tools.curve --out reports/ci/curve.md`; `tools/tests/test_curve.py` | reports/WP-F.9/curve.md, tools/astrolex_tools/curve.py (model in one function, `estimate`) |
| CI step for curve and contrast | pass | .github/workflows/pr.yml | |
| Tuning: before 30 flagged levels (slack down to -343%), after 0 | pass | burst.seconds set per level so slack runs ~58% to 25% (Act I), 55 to 22, 52 to 20, 50 to 18; thief.interval 4 to 5 on 4-10..4-12 | data/levels/*.json |
| Text size Normal / Large (x1.2), High contrast letters (tile.glyphOutline) | pass | `game/tests/scenes/test_polish_f9.gd` | app_settings.gd, settings_screen.gd (Comfort), game_font.gd `scaled`, tile_view.gd |
| Contrast script, fails under 4.5:1 | pass (20 pairs, lowest body pair 7.08) | `python -m astrolex_tools.contrast`; `tools/tests/test_contrast.py` | reports/WP-F.9/contrast.md |
| Credits and privacy screen, linked from Settings and the ending | pass | `test_credits_screen_shows_the_text_and_privacy` | game/scenes/credits.gd; content.json "credits" built from docs/story/credits.md + LICENCES.md |
| Download size | no change possible | see below | |
| Suites | pass | pytest tools; validate_data; levels; scripts/godot/test.sh 229 passed, no SCRIPT ERROR; web export; `smoke.cjs --autoplay` won (score 476) | |

## Curve summary
Act I 12 levels slack 58% to 25%, Act II 55 to 22, Act III 52 to 20, Act IV 50 to 18; bursts run 55 s to 160 s (the old 60 to 30 s clock could not fit the words: the model said 2.4x over budget in Act IV). The old test that asserted a falling clock (owner note, 9 Oct) was replaced: the clock now follows the words. Owner to playtest the longest rounds (4-11 at 160 s).

## Download size (build/web)
Before and after identical: wasm 39,514,754 B (gzip -9: 10,084,297 B), pck 2,917,740 B to 2,922,824 B (credits text, +5 KB). Tried vram_texture_compression off for desktop and mobile: no pck change (2D textures are lossless), reverted. Backdrops are already 69-137 KB JPEGs (make_skies.py stops under 400 KB), so a lower quality gains under 100 KB. The wasm is the stock Godot template; shrinking it needs a custom template build (disable 3D, physics, modules), added as a backlog idea. The host's gzip gives the 10 MB first-load figure.

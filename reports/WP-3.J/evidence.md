# WP-3.J evidence

Branch `claude/project-thread-4bg9x3`, 13 Oct 2026.

| AC | Result | Check | Artefact |
|---|---|---|---|
| AC1 | pass | `python -m astrolex_tools.validate_data` → ok; `python -m astrolex_tools.export_game_data` leaves no diff | `data/tunables/game.json` |
| AC2 | pass | `test_spawn_never_overlaps_catchable_tiles` (200 seeds), `test_catchable_tiles_keep_their_gap_while_drifting` (30 seeds × 20 s) | log |
| AC3 | pass | `test_bubble_glass_magnifies_the_live_screen`, `test_tile_view_bubble_is_round_and_untilted` | `phone-393x852-liquid-glass.jpg` |
| AC3b | pass | `test_sky_drifters_move_behind_the_letters`, `test_hud_follows_the_owner_mock`, `test_the_game_font_is_libre_caslon_condensed` | `phone-393x852-mock-v3.jpg` |
| AC4 | pass | `scripts/godot/test.sh` 161 passed, 0 failed, no SCRIPT ERROR; `scripts/godot/export.sh web` exit 0; `node smoke.cjs ../../../build/web` → "ok: main scene ran"; `pytest tools` passes | — |

Notes
- At `tile.size` 0.15 the old spawner (64 tries, keep the last) overlapped on 2 of 200 seeds and drifting clusters stayed squeezed (slack −0.03). Keeping the roomiest try, 256 tries and a few separation passes fixed both. 0.16 still failed 2 spawn seeds, so 0.15 is the largest size that keeps the guarantee for act 1 round 1.
- The live screen read is new for the web build. The earlier attempt (screen copy plus mipmaps) came out black and slow on iPhone Safari; this one has no mipmaps. It renders correctly in headless Chromium (SwiftShader); iPhone Safari is untested here. If it misbehaves there, `glass.live` 0 restores the baked-sky glass.
- Screenshots: local web export in headless Chromium at `?autoplay=1` with a temporary character override that is not committed.
- An earlier version of this branch tinted the bubbles in soft colours; the owner chose clear bubbles, so that was removed.
- Owner, 14:22: "reduce the circles for like 4-5 px": `glass.bubbleScale` 1.2 → 1.12 (about 5 CSS px less on a 393-px-wide phone). Letters and spacing are unchanged.
- Owner, 14:34 to 14:42: new item sheet, no planets, mock v3, painted backdrop and the Libre Caslon Condensed font. The backdrop image is 572×1024, so it is upscaled about 1.9× on a 1080-wide screen and looks a little soft; a larger export would sharpen it. The item stickers are 60 to 150 px, shown at 70 to 124 px.
- Owner, 14:54 and 15:00: matched mock v3 by side-by-side screenshots (`mock-v3-side-by-side.jpg`, five rounds). Remaining differences: the mock's letters are a bold sans while the owner asked for Libre Caslon Condensed everywhere; the mock shows 8 larger bubbles, while act 1 round 1 has about 14 catchable letters, so bubbles stay at the size that keeps them apart.
- CI failure on 61c12f6 ("Godot import and headless tests"): `Parse Error: [ext_resource] referenced non-existent resource at: res://fonts/LibreCaslonCondensed.ttf` during the first import. Reproduced the cause, moved the font to a runtime setting, and re-ran `scripts/godot/test.sh` from a deleted `game/.godot`: 161 passed, 0 failed, no parse error.

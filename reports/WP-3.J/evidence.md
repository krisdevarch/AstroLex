# WP-3.J evidence

Branch `claude/project-thread-4bg9x3`, 13 Oct 2026.

| AC | Result | Check | Artefact |
|---|---|---|---|
| AC1 | pass | `python -m astrolex_tools.validate_data` → ok; `python -m astrolex_tools.export_game_data` leaves no diff | `data/tunables/game.json` |
| AC2 | pass | `test_spawn_never_overlaps_catchable_tiles` (200 seeds), `test_catchable_tiles_keep_their_gap_while_drifting` (30 seeds × 20 s) | log |
| AC3 | pass | `test_bubble_glass_magnifies_the_live_screen`, `test_tile_view_bubble_is_round_and_untilted` | `phone-393x852-liquid-glass.jpg` |
| AC4 | pass | `scripts/godot/test.sh` 160 passed, 0 failed, no SCRIPT ERROR; `scripts/godot/export.sh web` exit 0; `node smoke.cjs ../../../build/web` → "ok: main scene ran"; `pytest tools` passes | — |

Notes
- At `tile.size` 0.15 the old spawner (64 tries, keep the last) overlapped on 2 of 200 seeds and drifting clusters stayed squeezed (slack −0.03). Keeping the roomiest try, 256 tries and a few separation passes fixed both. 0.16 still failed 2 spawn seeds, so 0.15 is the largest size that keeps the guarantee for act 1 round 1.
- The live screen read is new for the web build. The earlier attempt (screen copy plus mipmaps) came out black and slow on iPhone Safari; this one has no mipmaps. It renders correctly in headless Chromium (SwiftShader); iPhone Safari is untested here. If it misbehaves there, `glass.live` 0 restores the baked-sky glass.
- Screenshots: local web export in headless Chromium at `?autoplay=1` with a temporary character override that is not committed.
- An earlier version of this branch tinted the bubbles in soft colours; the owner chose clear bubbles, so that was removed.
- Owner, 14:22: "reduce the circles for like 4-5 px": `glass.bubbleScale` 1.2 → 1.12 (about 5 CSS px less on a 393-px-wide phone). Letters and spacing are unchanged.

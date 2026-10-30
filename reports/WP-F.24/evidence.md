# WP-F.24 evidence

Branch `claude/project-thread-8q83z2`, 28 Oct 2026. Spec: `wps/WP-F.24.md`. Follows WP-F.23 (#72).

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | Aligned grid sized to the round | pass | `test_motion.gd::test_anchor_layout_is_an_aligned_grid_inside_the_field` (≤ 5 × 5, evenly pitched columns and rows, every anchor on both, neighbours ≥ `anchors.spacing`, none under the porthole, spread to the walls); 1-06 (bed/cat) gets 4 × 4 = 15 anchors, 1-10 gets 5 × 4 = 19 | `reports/WP-F.24/grid.jpg` (1-06 at 6 s and 10 s, 1-10 at 6 s and 10 s) |
| 2 | Letters gather in the middle, hops fill the innermost hole | pass | `::test_letters_fill_the_grid_from_the_middle` (8 seeds), `::test_hop_fills_the_innermost_hole_from_outside`; existing hop and Babel-move tests unchanged | same |
| 3 | Wrong-catch counter pill | pass | `test_hud.gd` (node `MistakeChip`, right margin, under the level counter, "0 / 3"), `test_field_feedback.gd::test_wrong_catch_flashes_the_tile_and_shows_the_toast` (counts, pops, settles) | `reports/WP-F.24/wrong-counter.jpg` (autoplay with `?wrong=2`: 0 → 2 / 3, coral pips) |
| 4 | Even motion between fixed steps | pass | `test_motion.gd::test_view_position_is_even_between_fixed_steps` (120 Hz frames: the step holds still on ~half, the view moves on every frame and stays on the segment between the two steps); `test_throw_in.gd` lands views on `view_pos` | — |
| 5 | No per-frame uniform writes for bubbles | pass | `tile_view.gd::place` bubble branch writes no shader parameter; `glass.gdshader` drifts on `TIME + bubble_phase` × `bubble_drift` (0 under reduced motion) | — |
| 6 | Checks | pass | `scripts/godot/test.sh` 359 passed / 0 failed; `validate_data` ok; `levels` ok; `pytest tools` ok; `scripts/godot/export.sh web` ok; Chromium autoplay boots 1-06 (15 tiles) and 1-10 (22 tiles) | CI `godot.yml`, `pr.yml` |

## Measurements (Linux test machine, headless Godot, not a phone)
| Level | Catchable tiles | Anchors | Field `advance()` per frame before | after |
|---|---|---|---|---|
| 1-06 | 13 | 13 → 15 | 0.72 ms | 0.68 ms |
| 1-10 | 19 | 22 → 19 | 1.08 ms | 1.12 ms |

Rules `step()` alone is 0.3–0.6 ms per tick. The GDScript side is not the frame budget; the phone's frame rate is what the owner's "Show frame rate" switch (Settings) reports and could not be measured here.

Engine facts checked in the Godot 4.7.2 source: the GL canvas renderer copies the screen for `hint_screen_texture` once per frame per layer (`material_screen_texture_cached`, `rasterizer_canvas_gles3.cpp`), not once per bubble; the web main loop paces frames by a running target of 1/`max_fps` (`web_main.cpp`), so on a 120 Hz screen the 64 fps cap draws an extra frame about every eighth, which the interpolation now smooths.

Tunables: none added. Evidence hook: the web query `?wrong=<n>` makes the autoplay bot's first n taps catch unneeded letters (like `?tap=`).

Strings added in code (HUD): "n / N", "n wrong".

Not covered: whether the letters should also be colour-coded (owner's earlier "otherwise we would need to work with colors") stays a separate WP; the owner's phone frame rate.

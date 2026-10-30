# WP-F.22 evidence

Branch `claude/project-thread-8q83z2`, 27 Oct 2026. Spec: `wps/WP-F.22.md`. Follows WP-F.21 (PR #70).

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | `field.width` 1.33 drives every x bound in the rules and the view's fit | pass | `test_motion.gd` side-spawn tests (edges at `field.width`), `test_round.gd::test_travel_time_scales_with_distance` (origin at width/2), `test_babel_moves.gd` gust/scramble "x in field" | `scripts/godot/test.sh` 350 passed, 0 failed |
| 2 | Lattice spread evenly edge to edge, 22 anchors, none under the porthole | pass | `test_motion.gd::test_anchor_layout_is_a_honeycomb_inside_the_field` (count, porthole clearance, columns span the width, rows span the height, neighbours ≥ spacing) | `reports/WP-F.22/spread.jpg` (1-05 at 1.2 s, 3 s, 6 s on a 430×932 viewport) |
| 3 | At most `spawner.maxCopies` = 2 copies from plain decoys; `spawner.decoyRatio` 0.6 | pass | `test_motion.gd::test_plain_decoys_never_make_a_third_copy` (30 seeds); headless check of 1-05 at 1.2 s: every decoy letter ≤ 2 copies | same |
| 4 | Checks | pass | `validate_data` ok, `levels` ok, `pytest tools` ok, Godot 350/0, web export + Chromium autoplay on 1-05 won (score 581) | `scripts/godot/web-smoke/frames.cjs ../../../build/web <out> '?autoplay=1&level=1-05&tap=1.6' 14 100` |

Tunables: `field.width` 1.33 (new), `spawner.maxCopies` 2 (new), `spawner.decoyRatio` 1.0 → 0.6, `anchors.clearX` 0.01 → 0.172 (the field now starts at the screen's left edge), `drift.rippleRadius` 0.3 → 0.4 and `drift.ripplePush` 1.0 → 1.4 (neighbours sit farther apart on the wider pitch).

Not covered: the web toy (still 1.0 wide, backlog). On screens taller than 1080×1920 the field keeps its width and gains nothing sideways; on wider screens it is centred with margins, as before.

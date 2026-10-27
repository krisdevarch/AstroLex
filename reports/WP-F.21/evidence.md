# WP-F.21 evidence

Branch `claude/project-thread-8q83z2`, 26 Oct 2026. Spec: `wps/WP-F.21.md`. Design page: project files `design/letter-layout/letter-layout-options.html` (option 1, the playful cut).

## Acceptance criteria

| # | Criterion | Result | Check | Artefact |
|---|---|---|---|---|
| 1 | Anchors: honeycomb from `anchors.spacing`, spacing bound, one anchor per catchable tile, one catchable plane, needed letters spawn by dissolving a plain decoy when full, decoys capped by free anchors | pass | `game/tests/rules/test_motion.gd::test_anchor_layout_is_a_honeycomb_inside_the_field`, `::test_spacing_keeps_offset_letters_apart`, `::test_every_tile_has_its_own_anchor`, `::test_needed_letter_spawns_when_anchors_are_full`; 17 anchors at the defaults (5 rows of 4/3/4/3/4 less the one under Babel's porthole, `anchors.clear*`) | `scripts/godot/test.sh` |
| 2 | Motion: anchor + body sway + wave + bob + spring offset, deterministic, no overlap ever, `_separate_tiles` never acts, `drift.speed` keeps its meaning as the pace | pass | `::test_no_overlap_with_everything_on` (2,000 steps × 20 seeds with sway, wave, bob, hops, gust and scramble on; separation returns false every step), `::test_motion_is_deterministic_per_seed`, `::test_pace_follows_drift_speed` | same |
| 3 | Hops: `hop_tell` → `hop` → `hop_land`, seeded, skips the shot target, queued, hinted, shielded, landing and drone-targeted tiles, firing on a hopper catches it, difficulty scales `hop.every`, Act I before `hop.fromLevel` has none | pass | `::test_hops_happen_and_are_deterministic`, `::test_hop_skips_protected_tiles`, `::test_firing_on_a_hopping_tile_catches_it`, `::test_no_hops_before_hop_from_level`; frames of a tell and a hop in flight | `reports/WP-F.21/hop.jpg` |
| 4 | Babel and drones on anchors: volley fills free anchors, gust springs back, scramble lands every letter on its own anchor, dropped letters take the nearest free anchor, bot still wins | pass | `test_babel_moves.gd` (volley cap, gust push and return, scramble distinct anchors), `test_motion.gd::test_bot_still_wins_with_everything_on`, Act II–IV move tests | `scripts/godot/test.sh` |
| 5 | View: gold tell ring and wind-up squash, arc flight above the others with stretch, landing squash and ring, miss flinch, combo-warm tether, reduced motion fades | pass | `game/tests/scenes/test_hop_view.gd` (tell, lift, land, flinch, reduced motion); web frames | `reports/WP-F.21/hop.jpg`, `reports/WP-F.21/field.jpg` |
| 6 | Checks | pass | `scripts/godot/test.sh` 349 passed, 0 failed; `validate_data` ok; `astrolex_tools.levels` ok; `pytest tools -q` ok; `scripts/godot/export.sh web` ok; Chromium autoplay smoke won (score 476 on 2-03 with `?tap=1.6`, 585 at full speed) | `scripts/godot/web-smoke/frames.cjs ../../../build/web <out> '?autoplay=1&level=2-03&tap=1.6' 16 100` |

## Tunables added

| Key | Default |
|---|---|
| `anchors.spacing` | 0.246 |
| `anchors.maxOffset` | 0.012 |
| `anchors.bodyRoom` | 0.02 |
| `anchors.clearX` | 0.01 |
| `anchors.clearY` | 0.234 |
| `anchors.clearRadius` | 0.17 |
| `anchors.swayX` | 0.02 |
| `anchors.swayY` | 0.012 |
| `anchors.swayHz` | 0.06 |
| `anchors.waveAmp` | 0.01 |
| `anchors.waveHz` | 0.18 |
| `anchors.waveLen` | 0.9 |
| `anchors.spring` | 40 |
| `anchors.damping` | 7 |
| `anchors.speedRef` | 0.17 |
| `drift.bob` | 0.006 |
| `drift.bobHz` | 0.35 |
| `hop.every` | 2.8 |
| `hop.jitter` | 0.6 |
| `hop.firstAt` | 3 |
| `hop.windSec` | 0.35 |
| `hop.flySec` | 0.45 |
| `hop.fromLevel` | 3 |
| `hop.arcPx` | 70 |
| `hop.ringPx` | 90 |
| `hop.ringSec` | 0.35 |
| `tile.flinchSquash` | 0.1 |
| `tether.comboWarm` | 0.6 |

Removed: `drift.orbit*`, `drift.dart*`, `drift.curve`, `drift.curveHz`, `drift.surge`, `drift.surgeHz`, `drift.speedVariation`, `plane.midSpeedMul`. `spawner.frontShare` is 1.0 (one catchable plane). `drift.rippleRadius` 0.3 and `drift.ripplePush` 1.0 (the old radius was below the anchor spacing, so no neighbour was ever in range). Difficulty: Easy `hop.every` ×1.5, Hard ×0.7. `anchors.clearX/Y/Radius` mirror `babel.corner*` and the field layout in `field.gd` (FIELD_TOP 320, scale 812.5 at 1080×1920); change them together.

## Review
Reviewer: no blocking findings, 6 minor. Fixed: a letter that found no anchor when it arrived (or was dropped by a drone with the field full) now takes the first anchor that frees up each tick; a hopper caught or dissolved mid-flight keeps its catch or dissolve z-order; a dead `hop_lift()` term in the landing ripple; the `?tap=` query now parses only a positive number in a `tap=` part and otherwise keeps `autoplay.tapInterval`.

## Deviations from the brief (worker choices, kept)
- The wave, bob and spring offset together are clamped to `anchors.maxOffset` (not only bob and spring), so the spacing bound is exact.
- A hopper flies above the others and is exempt from separation and the overlap test while in the air (its landing anchor is reserved from the tell).
- Scramble snaps the rule positions to the new anchors at once and the view animates them over `babel.scrambleSec`, as before; a hop under way is finished first.
- The lattice stops `anchors.bodyRoom` short of the walls, so the body sway and the gust can move it without any tile leaving the field.

## Not covered
Colour rings for needed letters (next WP). Per-act anchor shapes. The web toy still runs the old free drift (backlog). Density: with 17 anchors and `spawner.decoyRatio` 1.0 the field is usually full; the owner's playtest decides whether to lower the ratio.

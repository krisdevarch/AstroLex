# WP-F.18 evidence: Babel in the corner, drones from three sides, livelier letters

Branch `claude/project-thread-hfcl28`, 25 Oct 2026. Work package: `wps/WP-F.18.md`. Mock the owner approved: project files `design/babel-corner/`.

| AC | Result | Check | Artefact |
| --- | --- | --- | --- |
| 1. Babel's corner porthole, bubble replaces the top band, no overlap with the top pills | pass | `game/tests/scenes/test_corner_life.gd`, `test_hud.gd` (porthole and bubble clear the title and level pills) | `corner.png`, `smoke-mid.png` |
| 2. Opening throw and every mid-round spawn fly from the muzzle; reduced motion fades in | pass | `test_throw_in.gd`, `test_corner_life.gd` (spawn starts at the muzzle, ends at the tile); `test_motion.gd::test_letter_fired_mid_round_cannot_be_caught_until_it_lands` | `mid.png` |
| 3. Drones from top, left, right, never the bottom; escape to the nearest of those edges; Act I top-only; view enters from its side | pass | `test_motion.gd`: side share and positions, no bottom spawn or escape, flee to nearest edge, Act I `sideShare` 0, spawn event names the entry side; `test_thief_view` slide-in | — |
| 4. Orbit, dart, shy and ripple motion; breathing and stretch; deterministic; reduced motion off | pass | `test_motion.gd`: styles deterministic per seed, orbit starts on its circle, slow letters wander, ripple, shy; `test_corner_life.gd` breathing off under reduced motion | — |
| 5. Mean speed within 10 %, darting letters catchable, bot still wins | pass | `test_motion.gd`: mean speed at default and 0.4/0.4 shares, dart catchable mid-burst, bot wins 6 Act I and 4 Act II seeds | — |
| 6. Checks | pass | `scripts/godot/test.sh` 295 passed, 0 failed; `validate_data` ok; `astrolex_tools.levels` ok; `pytest tools` ok; web export + Chromium autoplay smoke: round won, score 517 | `smoke-mid.png` |

## New tunables (`data/tunables/game.json`, schema entries added)
`drift.orbitShare` 0.25, `drift.orbitRadius` 0.06, `drift.orbitHz` 0.22, `drift.dartShare` 0.25, `drift.dartEvery` 2.6, `drift.dartBoost` 1.8, `drift.dartSec` 0.4, `drift.shyRadius` 0.16, `drift.shyPush` 0.22, `drift.rippleRadius` 0.22, `drift.ripplePush` 0.35, `drift.rippleSec` 0.45, `thief.sideShare` 0.6 (Act I levels 0), `thief.sideMaxY` 0.6, `babel.cornerX` 0.13, `babel.cornerY` 0.13, `babel.cornerSize` 0.2, `tile.breathe` 0.03, `tile.breatheHz` 0.35, `tile.stretch` 0.12.

## Review
Reviewer pass on the merged diff found one blocking and five smaller issues, all fixed: side drones read their entry from the rules (they dropped from the top before), orbiting letters start on their circle (no first-frame jump), slow letters do not orbit (keeps mean speed), a letter Babel fires mid-round cannot be caught or grabbed until it lands (`babel.throwSec`), a repeated taunt pops the bubble again, and no bubble opens while Babel is leaving.

## For the owner's playtest
Dart bursts peak near 2.9x a letter's base speed for 0.4 s (the cycle is normalised so the average holds). If darting feels too quick, lower `drift.dartBoost`.

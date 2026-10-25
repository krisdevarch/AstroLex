# WP-F.19 evidence: Babel's moves

Branch `wp-f19-babel-moves` (stacked on WP-F.18, PR #66), 25 Oct 2026. Work package: `wps/WP-F.19.md`.

| AC | Result | Check | Artefact |
| --- | --- | --- | --- |
| 1. Move timer, tell then move, events, gating by act and `babel.movesFromLevel`, off with `moveEvery` 0, Daily uses its act | pass | `game/tests/rules/test_babel_moves.gd` (gating per act, early Act I none, tell precedes move by `tellSec`, deterministic per seed, no repeat when alternatives exist, off switch) | — |
| 2. Fair: bounce costs nothing, drones and hints skip shields, gust stays in the field and never blows down, scramble keeps clearance and letters are uncatchable while they fly, volley decoys respect the cap and dissolve after `babel.volleyLifeSec`, bot wins Act I–IV samples with moves on | pass | `test_babel_moves.gd` (each rule above, plus scramble leaves the letter under fire in place) | — |
| 3. View: tell glow and pictogram, volley from the muzzle, gust streaks, shield ring and bounce flash, scramble flight, reduced motion | pass | `game/tests/scenes/test_babel_moves_view.gd` (9 tests, including no node leak over 16 moves) | `tell-volley.jpg`, `tell-gust.jpg`, `gust.jpg`, `tell-scramble.jpg`, `moves-sheet.jpg` (Act IV level 4-05, untouched round, rendered by Godot under Xvfb) |
| 4. Sounds: tell and one per move, plus bounce | pass | `test_babel_moves_view.gd` drives every sound path without errors | — |
| 5. Checks | pass | `scripts/godot/test.sh` 322 passed, 0 failed; `validate_data` ok; `astrolex_tools.levels` ok; `pytest tools` ok; web export + Chromium autoplay smoke won (score 517); autoplay of 4-05 via the new `?autoplay=1&level=4-05` hook won (score 694) | — |

## Tunables (`data/tunables/game.json`, schema entries added)
`babel.moveEvery` 11, `babel.moveFirstAt` 7, `babel.tellSec` 1.2, `babel.movesFromLevel` 5, `babel.volleyDecoys` 3, `babel.volleyLifeSec` 8, `babel.gustFromAct` 2, `babel.gustSec` 1.2, `babel.gustPush` 0.3, `babel.shieldFromAct` 3, `babel.shieldSec` 4, `babel.scrambleFromAct` 4, `babel.scrambleSec` 0.6.

## Review
Reviewer pass found no blocking issues. Fixed: a scramble no longer moves the letter a shot is flying at or queued for; a queued shot never starts at a letter still flying in; hints and the autoplay targeter skip letters still flying in; Babel never shields the letter the player paid a hint for. Added in review: volley decoys dissolve after `babel.volleyLifeSec` so repeated volleys do not fill the field. Left as is (cosmetic): a tell whose move became impossible shows with no effect; the tell glow can outlast the move by a frame after a hitch.

## Tooling
`scripts/godot/web-smoke/frames.cjs` saves a frame every N ms from a web build with any query, and `main.gd` accepts `?autoplay=1&level=<id>` on the web, so later-act levels can be filmed and smoke-tested.

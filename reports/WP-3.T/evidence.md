# WP-3.T evidence: Babel throws the letters at round start

Owner ask (9 Oct 2026): "it would be nice if the villain can throw the letters when round is starting to be more fun". Story: `docs/story-bible.md` §2 rule 4.

| AC | Result | Check | Artefact |
|---|---|---|---|
| Each round opens with Babel's periwinkle rift throwing the round's letters (staggered, back-eased, scale-up, no glyph rotation) | pass | screenshots from the web build in headless Chromium | `throw-mid.png`, `throw-late.png` |
| Rules untouched; no sim time, drift or air drain during the throw; a tap skips it | pass | `game/tests/scenes/test_throw_in.gd` (4 tests); `git diff --stat main -- game/rules` empty | `scripts/godot/test.sh`: 78 passed, 0 failed, no SCRIPT ERROR |
| Reduced motion: tiles fade in place, no flight | pass | `test_throw_in.gd` | same |
| Every number is a tunable | pass | `babel.throwOriginX/Y`, `throwSec`, `throwStagger`, `throwOvershoot`, `riftRadius` in `data/tunables/game.json` and schema; `validate_data` ok, `pytest tools -q` ok | `game/data/tunables.json` regenerated |
| Self-play still wins after the intro | pass | `node smoke.cjs ../../../build/web --autoplay`: "autoplay round won, score 358" | – |

Notes: back-plane shards are thrown too, at their lower alpha. The throw lasts `throwSec + throwStagger × (tiles − 1)`, about 1.7 s with 20 tiles. Babel says nothing during the throw (no letters are restored yet). No sound yet.

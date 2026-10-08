# Milestone: first playable draft (Godot, web)

Owner request (8 Oct 2026): agents loop until the first draft of the game is ready. The orchestrator works this file; workers get briefs cut from it.

**First draft** means the toy v1.3 game loop rebuilt in the Godot client, with the plan Part 8 look (2D world, 2.5D tiles), playable in the browser from the CI artifact. It does not include real art, audio polish, the Daily Signal date seed, telemetry, platform services, iOS or Android.

## Definition of done (all must hold)

| # | Item | Check |
|---|---|---|
| D1 | `data/tunables/game.json` (+ schema) is the only source of gameplay and look numbers; `python -m astrolex_tools.export_game_data` writes `game/data/tunables.json` and `game/data/content.json` | `pytest tools -q`; `validate_data`; exporter test |
| D2 | Rules core in `game/rules/` (pure GDScript) per the interface below: seeded spawner (needed letters plus decoys that never use a letter of the active or preview word), fixed-step drift with bounds bounce on 2 reachable planes plus decorative back tiles, tether travel and escape, catch taxonomy (active, preview, surplus, unneeded), preview carry-over, surplus dissolve, oxygen per mode, score and combo, per-round ramp, round end | `scripts/godot/test.sh`: unit tests per rule; 1,000 seeded rounds solvable; same seed gives the same event stream |
| D3 | Babel composer in GDScript: lines only from restored letters (with multiplicity), templates and anagrams from `content.json`, no repeat within a round, `babel.minLineLetters` respected | tests, including a pool-constraint property test |
| D4 | Field scene: 2.5D tiles (§8.2) with the three treatments switchable (O-22), depth planes as scale, `Line2D` tether with travel, screen-space circle hit test, caught tile flies to its slot, surplus dissolves, wrong catch bounces and flashes, HUD (active and preview slots, oxygen bar in Pressure, combo, score), Babel band | scene tests; screenshot from the web smoke |
| D5 | App flow: start screen (title, Drift or Pressure), play, end screen (won or out of air, score, words, time, catches, wrong, Babel line, play again, mode switch), settings (tile treatment, reduced motion) | scene tests |
| D6 | Autoplay for tests: `?autoplay=1` on the web (via `JavaScriptBridge`) or `--autoplay` on the command line plays a Drift round by tapping needed tiles; prints `AstroLex round won: score=<n>` | headless scene test; the web smoke waits for that line |
| D7 | Quality: `scripts/godot/test.sh` green; web export plus Chromium smoke green; CI green on the PR; `reviewer` verdict "ship"; evidence in `reports/WP-3.2/evidence.md` with a screenshot | CI and evidence |

## Data contract (`game/data/`, generated, never edited by hand)

- `tunables.json`: the keys of `data/tunables/game.json` without `$schema`.
- `content.json`: `{"acts": {key: {"title", "words": [...]}}, "lexicon": [[word, pos], ...], "theme": [...], "templates": [{"id", "pattern"}], "anagrams": {word: [...]}}`. This is the same shape as the toy's `window.ASTROLEX_DATA` minus its tunables (see `tools/astrolex_tools/export_toy_data.py`).

## Rules interface (`game/rules/`)

Field coordinates: x from 0 to 1, y from 0 to `field.height`. The tether starts at bottom centre, `(0.5, field.height)`. Tiles keep out of the top `field.topMargin` band (the HUD).

```gdscript
# round.gd  (class_name not required; preload it)
static func create(tunables: Dictionary, content: Dictionary, act: String, mode: String, seed: int, round_no: int = 1) -> Round
var words: PackedStringArray        # this round's words, picked with the seeded RNG
var word_index: int
var active: Array[Dictionary]       # [{ch, filled}] slots of the active word
var preview: Array[Dictionary]      # slots of the next word ([] on the last word)
var tiles: Array                    # Tile objects: id:int, ch:String, decoy:bool, plane:int (0 front, 1 mid, 2 back-decorative), pos:Vector2, vel:Vector2, alive:bool
var oxygen: float                   # Pressure only; Drift keeps oxygen.max
var score: float
var combo: float
var state: String                   # "play" | "won" | "lost"
var stats: Dictionary               # {catches, wrong, escapes, secs, min_oxygen}
func step(dt: float) -> void        # accumulates dt and advances in sim.stepSec steps: drift, bounce, shot travel, oxygen drain
func fire(tile_id: int) -> bool     # starts a shot, or queues one shot while another is in flight; false if the tile is not catchable
func drain_events() -> Array[Dictionary]
```

Events, in order of occurrence (the view animates from these, it never re-derives rules):

`{type:"spawn", tile_id}` · `{type:"fire", tile_id}` · `{type:"queue", tile_id}` · `{type:"catch", tile_id, where:"active"|"preview", slot}` · `{type:"wrong", tile_id, kind:"surplus"|"unneeded"}` · `{type:"escape", tile_id}` · `{type:"dissolve", tile_id}` · `{type:"restore", word, score}` · `{type:"babel", text}` · `{type:"round_end", won}`

`babel.gd`: `static func compose(pool: Dictionary, targets: PackedStringArray, content: Dictionary, min_letters: int) -> Array` (lines as `{text, id}`), and `static func pick(lines: Array, shown: Dictionary, rng: RandomNumberGenerator) -> String`. The behaviour mirrors `tools/astrolex_tools/babel/compose.py` and the toy's preference order.

Reference behaviour: toy v1.3 (`web/toy/index.html`: `spawnForWords`, `trimSurplus`, `ensureDecoys`, `resolveHit`, `wordRestored`, `ramp`) with the run-4 fixes.

## Loop plan

1. `builder`: D1 (exporter and test).
2. `rules-engineer`: D2 and D3.
3. `godot-dev`: D4, D5 and D6, plus extending `scripts/godot/web-smoke/smoke.cjs` to `?autoplay=1`.
4. `verify-runner` and `reviewer` in parallel: D7. Blocking findings go back to the author, at most 3 rounds.

## Out of scope

Real art and fonts, music, Core Haptics, telemetry endpoint, Daily Signal seed and share card, Codex, hazards, hints, visors, iOS and Android exports.

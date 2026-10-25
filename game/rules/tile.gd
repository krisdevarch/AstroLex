extends RefCounted
## One drifting letter tile. Plain data, mutated only by round.gd.
## plane: 0 front, 1 mid (both catchable), 2 back (decorative, never catchable).

var id: int = 0
var ch: String = ""
var decoy: bool = false
var plane: int = 0
var pos: Vector2 = Vector2.ZERO
var vel: Vector2 = Vector2.ZERO
var alive: bool = true
## Draw radius in field units (tile.size * plane scale / 2); also the bounce inset.
var radius: float = 0.0
var carried_by: int = -1
## Spawn speed (field units per second); drift steers and surges around it. 0: plain straight drift.
var base_speed: float = 0.0

## Hazard kind (WP-F.1): "" for a plain tile, "counterfeit" (a forged copy of a needed letter, a decoy)
## or "trap" (one letter of Babel's counter-word, a decoy).
var kind: String = ""

## Motion style (WP-F.18), set at spawn for real letters only: "wander" (default), "orbit" or "dart".
var style: String = "wander"
## Orbit: current angle (radians) and the offset from the wandering centre.
var orbit_angle: float = 0.0
var orbit_off: Vector2 = Vector2.ZERO
## Orbit: wander speed scale that keeps the mean speed at the base speed despite the circling.
var orbit_k: float = 1.0
## Dart: cycle length, per-tile phase offset (seconds), cycle index last seen, speed norm and burst flag.
var dart_len: float = 0.0
var dart_phase: float = 0.0
var dart_idx: int = -1
var dart_norm: float = 1.0
var dart_burst: bool = false
## Ripple impulse: outward velocity at full strength and the seconds of it left.
var kick: Vector2 = Vector2.ZERO
var kick_t: float = 0.0
## Seconds until a letter Babel fired mid-round lands (babel.throwSec); until then it cannot be caught or grabbed.
var landing: float = 0.0

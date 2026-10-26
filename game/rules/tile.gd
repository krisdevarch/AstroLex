extends RefCounted
## One drifting letter tile. Plain data, mutated only by round.gd.
## plane: 0 front, 1 mid (both catchable), 2 back (decorative, never catchable).

var id: int = 0
var ch: String = ""
var decoy: bool = false
var plane: int = 0
var pos: Vector2 = Vector2.ZERO
var alive: bool = true
## Draw radius in field units (tile.size * plane scale / 2); also the bounce inset.
var radius: float = 0.0
var carried_by: int = -1
## Back-plane shards only: straight drift (field units per second). Catchable tiles have no velocity; they hold an anchor.
var vel: Vector2 = Vector2.ZERO

## Hazard kind (WP-F.1): "" for a plain tile, "counterfeit" (a forged copy of a needed letter, a decoy)
## or "trap" (one letter of Babel's counter-word, a decoy).
var kind: String = ""

## Anchored drift (WP-F.21): index of the anchor this tile holds (-1: none, e.g. while a drone carries it).
var anchor: int = -1
## Spring offset from the anchor (ripples, shyness) and its velocity; round.gd clamps the total deviation.
var off: Vector2 = Vector2.ZERO
var off_vel: Vector2 = Vector2.ZERO
## Hop state: destination anchor (-1: not hopping), seconds of wind-up left, seconds flown, flight length,
## whether it has taken off, and where it took off from (relative to the field's body offset).
var hop_to: int = -1
var hop_wind: float = 0.0
var hop_t: float = 0.0
var hop_sec: float = 0.0
var hop_air: bool = false
var hop_from: Vector2 = Vector2.ZERO
## Ripple impulse: outward velocity it adds to the spring in total, and the seconds of it left.
var kick: Vector2 = Vector2.ZERO
var kick_t: float = 0.0
## Seconds until a letter Babel fired mid-round lands (babel.throwSec); until then it cannot be caught or grabbed.
var landing: float = 0.0
## Seconds until a volley decoy dissolves (0 = stays).
var expire_t: float = 0.0
## Babel's shield (WP-F.19): seconds left. While above 0 a shot that reaches the letter bounces off, and drones leave it alone.
var shield_t: float = 0.0

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

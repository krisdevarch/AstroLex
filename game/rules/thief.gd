extends RefCounted
## One Babel-army thief drone. Plain data, mutated only by round.gd. Shares the tile id space.

var id: int = -1
var pos: Vector2 = Vector2.ZERO
var vel: Vector2 = Vector2.ZERO
var target_id: int = -1
var carrying_id: int = -1
var state: String = "seek"

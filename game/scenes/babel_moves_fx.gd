extends Node2D
## WP-F.19: wind streaks for Babel's gust. A few light lines drift across the field in the gust's
## direction for its duration, then the node is done (the field frees it). Capped count, one draw
## call per streak, no textures. Reduced motion: the field never builds this node.

const MAX_STREAKS := 12
const STREAK_LEN := 180.0
const COLOUR := Color(0.78, 0.8, 1.0)

var _dir := Vector2.RIGHT
var _sec := 1.0
var _t := 0.0
var _area := Rect2()
var _streaks: Array = []  # each [start_offset_perpendicular(px), along_start(0..1), speed_mul, length_mul]


## `dir` is a unit vector in screen space; `area` is the field rectangle the streaks cross.
func start(dir: Vector2, sec: float, area: Rect2, count: int = MAX_STREAKS) -> void:
	_dir = dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT
	_sec = maxf(0.05, sec)
	_area = area
	_t = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 19
	_streaks.clear()
	for i in mini(count, MAX_STREAKS):
		_streaks.append([rng.randf(), rng.randf() * 0.35, 0.8 + rng.randf() * 0.5, 0.6 + rng.randf() * 0.8])
	queue_redraw()


func streak_count() -> int:
	return _streaks.size()


## Advances the streaks; true once the gust is over.
func tick(delta: float) -> bool:
	_t += delta
	queue_redraw()
	return _t >= _sec


func _draw() -> void:
	var perp := Vector2(-_dir.y, _dir.x)
	var centre := _area.get_center()
	var reach := _area.size.length() * 0.5
	var u := clampf(_t / _sec, 0.0, 1.0)
	for s in _streaks:
		var p: float = clampf((u - float(s[1])) / (1.0 - float(s[1])) * float(s[2]), 0.0, 1.0)
		if p <= 0.0 or p >= 1.0:
			continue
		var along := lerpf(-reach, reach, p)
		var across := lerpf(-reach, reach, float(s[0])) * 0.6
		var head := centre + _dir * along + perp * across
		var a := sin(p * PI) * 0.55
		draw_line(head - _dir * STREAK_LEN * float(s[3]), head, Color(COLOUR.r, COLOUR.g, COLOUR.b, a), 4.0, true)

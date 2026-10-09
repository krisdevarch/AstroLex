extends Node2D
## One Babel thief drone, drawn procedurally: a dark periwinkle hull with a glowing eye.
## Hovers with a slow bob, brighter and pulsing while it carries a letter, drops in from the top.

const PERIWINKLE := Color(0.561, 0.612, 0.949)  # #8f9cf2
const HULL := Color(0.09, 0.1, 0.2)
const DROP_SEC := 0.45
const DROP_PX := 160.0
const BOB_PX := 6.0
const BOB_HZ := 0.9
const FLASH_SEC := 0.3

var radius_px: float = 50.0
var reduced_motion: bool = false
var carrying: bool = false
var age: float = 0.0
var flash_left: float = 0.0
var base_pos: Vector2 = Vector2.ZERO
var _phase: float = 0.0


func setup(radius: float, reduced: bool, phase: float) -> void:
	radius_px = radius
	reduced_motion = reduced
	_phase = phase
	z_index = 5


func place(p: Vector2) -> void:
	base_pos = p
	_apply()


func set_carrying(on: bool) -> void:
	carrying = on


func flash() -> void:
	flash_left = FLASH_SEC


func tick(delta: float) -> void:
	age += delta
	flash_left = maxf(0.0, flash_left - delta)
	_apply()
	queue_redraw()


func _apply() -> void:
	var u := clampf(age / DROP_SEC, 0.0, 1.0)
	var off := Vector2.ZERO
	if reduced_motion:
		modulate.a = u
	else:
		var e := 1.0 - (1.0 - u) * (1.0 - u)
		off.y = -DROP_PX * (1.0 - e) + sin((age + _phase) * TAU * BOB_HZ) * BOB_PX
		modulate.a = clampf(u * 2.0, 0.0, 1.0)
	position = base_pos + off


func _draw() -> void:
	var r := radius_px
	var glow := 0.35
	if carrying:
		glow = 0.8 + (0.0 if reduced_motion else 0.2 * sin(age * 10.0))
	glow = minf(1.0, glow + flash_left / FLASH_SEC)
	for i in 3:
		draw_circle(Vector2.ZERO, r * (1.9 - 0.3 * i), Color(PERIWINKLE, 0.05 * glow * (i + 1)))
	# Side pods and body.
	draw_circle(Vector2(-r * 0.95, 0), r * 0.32, HULL)
	draw_circle(Vector2(r * 0.95, 0), r * 0.32, HULL)
	draw_arc(Vector2(-r * 0.95, 0), r * 0.32, 0.0, TAU, 20, PERIWINKLE, 3.0)
	draw_arc(Vector2(r * 0.95, 0), r * 0.32, 0.0, TAU, 20, PERIWINKLE, 3.0)
	draw_circle(Vector2.ZERO, r * 0.8, HULL)
	draw_arc(Vector2.ZERO, r * 0.8, 0.0, TAU, 40, Color(PERIWINKLE, 0.6 + 0.4 * glow), 4.0)
	# Eye.
	var eye := Color(1.0, 0.95, 1.0) if carrying or flash_left > 0.0 else PERIWINKLE.lightened(0.3)
	draw_circle(Vector2.ZERO, r * 0.38, Color(PERIWINKLE, 0.35 + 0.4 * glow))
	draw_circle(Vector2.ZERO, r * 0.22, eye)

extends Node2D
## Planets, a sun, asteroids, rockets, a satellite and fiery meteors that drift through the play
## field just behind the letters (owner references and choice, 13 Oct 2026): cartoon style with ink
## outlines, always moving, but slower than the letters so they read as further away. Visual only:
## taps pass through and nothing here touches the rules. Placeholder art (O-14).

const PLANET_SHADER := preload("res://scenes/planet.gdshader")

const SPEED_PX := 26.0  # planet drift, pixels per second at 1080 wide
const SPIN := 0.015
const BOB_PX := 6.0
const ROCKET_EVERY := 8.0  # a rocket or the satellite sets off this often
const ROCKET_SPEED := 210.0
const SATELLITE_SPEED := 70.0
const METEOR_EVERY := 6.5
const METEOR_SEC := 1.4
const ASTEROIDS := 6
const INK := Color(0.06, 0.08, 0.22)
## [kind, radius px, base, detail, shade, ring, start spot as a share of the area]
const PLANETS := [
	[4, 120.0, "ff7a1f", "ffd23a", "e04a12", false, Vector2(0.93, 0.02)],  # sun, top right
	[1, 140.0, "e3a24a", "b86a26", "a85b1c", false, Vector2(0.9, 0.62)],  # orange, Venus-like
	[2, 118.0, "2f8fe0", "4cc24a", "1f5fae", false, Vector2(0.1, 0.36)],  # Earth with clouds
	[0, 92.0, "8a52c6", "e48fd8", "5a2d8e", true, Vector2(0.55, 0.06)],  # ringed purple
	[3, 74.0, "2a7fe0", "86d4ff", "1a56a8", false, Vector2(0.1, 0.9)],  # blue water planet
	[0, 46.0, "e2492e", "f58a4a", "a8281a", false, Vector2(0.58, 0.88)],  # small red
	[1, 58.0, "8f909c", "6b6c78", "54556a", false, Vector2(0.38, 0.5)],  # grey moon
]

var view_size: Vector2 = Vector2(1080, 1920)
## The box the bodies drift in (they may go a little past it, so they peek in from the edges).
var area: Rect2 = Rect2(0, 280, 1080, 1100)
var reduced_motion: bool = false
var sat: float = 1.0:
	set(v):
		sat = v
		for p in _planets:
			(p["node"].material as ShaderMaterial).set_shader_parameter("sat", v)

var _t: float = 0.0
var _planets: Array = []  # {node, pos, vel, r, ring, sun, phase}
var _rocks: Array = []  # {pos, vel, r, rot, spin, shape}
var _rng := RandomNumberGenerator.new()
var _craft: Dictionary = {}  # the rocket or satellite now crossing: {kind, pos, vel}
var _craft_wait: float = 2.0
var _craft_n: int = 0


func _ready() -> void:
	light_mask = 0
	_rng.seed = 2026
	var k := view_size.x / 1080.0
	for i in PLANETS.size():
		var d: Array = PLANETS[i]
		var r: float = float(d[1]) * k
		var q := ColorRect.new()
		q.name = "Planet%d" % i
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
		q.size = Vector2(r, r) * 2.0
		q.light_mask = 0
		var m := ShaderMaterial.new()
		m.shader = PLANET_SHADER
		m.set_shader_parameter("kind", int(d[0]))
		m.set_shader_parameter("base", Color(str(d[2])))
		m.set_shader_parameter("detail", Color(str(d[3])))
		m.set_shader_parameter("shade", Color(str(d[4])))
		m.set_shader_parameter("ink", INK)
		m.set_shader_parameter("seed", float(i) * 0.37)
		m.set_shader_parameter("spin", 0.0 if reduced_motion else SPIN * (1.0 if i % 2 == 0 else -1.0))
		q.material = m
		add_child(q)
		var sun := int(d[0]) == 4
		var speed := SPEED_PX * k * _rng.randf_range(0.7, 1.2) * (0.3 if sun else 1.0)
		_planets.append({"node": q, "pos": area.position + area.size * (d[6] as Vector2), "vel": Vector2.from_angle(_rng.randf() * TAU) * speed, "r": r, "ring": bool(d[5]), "sun": sun, "phase": _rng.randf() * TAU})
	for i in ASTEROIDS:
		var shape := PackedVector2Array()
		var n := 9
		for j in n:
			shape.append(Vector2.from_angle(TAU * float(j) / float(n)) * _rng.randf_range(0.72, 1.0))
		_rocks.append({"pos": area.position + area.size * Vector2(_rng.randf(), _rng.randf()), "vel": Vector2.from_angle(_rng.randf() * TAU) * SPEED_PX * k * _rng.randf_range(0.8, 1.6), "r": _rng.randf_range(14.0, 30.0) * k, "rot": _rng.randf() * TAU, "spin": _rng.randf_range(-0.6, 0.6), "shape": shape})
	var front := Front.new()
	front.name = "Front"
	front.sky = self
	add_child(front)
	_place()


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	_t += delta
	if not reduced_motion:
		for p in _planets:
			_bounce(p, delta, p["r"])
		for a in _rocks:
			_bounce(a, delta, a["r"])
			a["rot"] += a["spin"] * delta
		_tick_craft(delta)
	_place()
	queue_redraw()


func planet_count() -> int:
	return _planets.size()


func craft_flying() -> bool:
	return not _craft.is_empty()


## Moves a body and turns it back at the area's edge; it may slide about half out sideways first.
func _bounce(b: Dictionary, delta: float, r: float) -> void:
	b["pos"] += b["vel"] * delta
	var lo := area.position + Vector2(-r * 0.1, r * 0.45)
	var hi := area.end + Vector2(r * 0.1, -r * 0.45)
	for ax in 2:
		if b["pos"][ax] < lo[ax]:
			b["pos"][ax] = lo[ax]
			b["vel"][ax] = absf(b["vel"][ax])
		elif b["pos"][ax] > hi[ax]:
			b["pos"][ax] = hi[ax]
			b["vel"][ax] = -absf(b["vel"][ax])


func _bob(p: Dictionary) -> Vector2:
	return Vector2(0.0, 0.0 if reduced_motion else sin(_t * 0.8 + float(p["phase"])) * BOB_PX)


func _place() -> void:
	for p in _planets:
		var q: ColorRect = p["node"]
		q.position = p["pos"] + _bob(p) - q.size * 0.5


func _tick_craft(delta: float) -> void:
	if _craft.is_empty():
		_craft_wait -= delta
		if _craft_wait <= 0.0:
			# Alternate a rocket (fast, up and across) and the satellite (slow, level).
			var kind := "rocket" if _craft_n % 2 == 0 else "satellite"
			_craft_n += 1
			var from_left := _rng.randf() < 0.5
			var y := area.position.y + area.size.y * (_rng.randf_range(0.55, 0.95) if kind == "rocket" else _rng.randf_range(0.15, 0.6))
			var x := area.position.x - 100.0 if from_left else area.end.x + 100.0
			var dir := Vector2(1.0 if from_left else -1.0, -_rng.randf_range(0.35, 0.7) if kind == "rocket" else _rng.randf_range(-0.1, 0.1)).normalized()
			var speed := ROCKET_SPEED if kind == "rocket" else SATELLITE_SPEED
			_craft = {"kind": kind, "pos": Vector2(x, y), "vel": dir * speed * (view_size.x / 1080.0)}
		return
	_craft["pos"] += _craft["vel"] * delta
	var pos: Vector2 = _craft["pos"]
	if pos.x < area.position.x - 200.0 or pos.x > area.end.x + 200.0 or pos.y < area.position.y - 200.0:
		_craft = {}
		_craft_wait = ROCKET_EVERY * _rng.randf_range(0.6, 1.2)


func _grey(c: Color) -> Color:
	var g := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	return Color(lerpf(g, c.r, sat), lerpf(g, c.g, sat), lerpf(g, c.b, sat), c.a)


## Back pass (under the planet discs): sun rays, the back halves of rings, asteroids, meteors.
func _draw() -> void:
	for p in _planets:
		var c: Vector2 = p["pos"] + _bob(p)
		if p["sun"]:
			_sun_rays(c, p["r"])
		if p["ring"]:
			_ring_on(self, c, p["r"], PI, TAU)
	for a in _rocks:
		_rock(a)
	_draw_meteor()


func _sun_rays(c: Vector2, r: float) -> void:
	var n := 18
	var turn := 0.0 if reduced_motion else _t * 0.1
	for glow in 4:
		draw_circle(c, r * (1.55 - 0.1 * float(glow)), _grey(Color(1.0, 0.6, 0.15, 0.06)))
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := turn + TAU * float(i) / float(n * 2)
		var len := r * (1.32 if i % 2 == 0 else 0.98)
		pts.append(c + Vector2.from_angle(a) * len)
	draw_colored_polygon(pts, _grey(Color("ff5a14")))
	pts.append(pts[0])
	draw_polyline(pts, _grey(Color("b8320a")), 3.0, true)


func _ring_on(ci: CanvasItem, c: Vector2, r: float, a0: float, a1: float) -> void:
	ci.draw_set_transform(c, -0.28, Vector2(1.0, 0.3))
	ci.draw_arc(Vector2.ZERO, r * 1.75, a0, a1, 48, _grey(INK), r * 0.2, true)
	ci.draw_arc(Vector2.ZERO, r * 1.75, a0, a1, 48, _grey(Color("8fc4ff")), r * 0.14, true)
	ci.draw_arc(Vector2.ZERO, r * 1.72, a0, a1, 48, _grey(Color("d8ecff")), r * 0.04, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _rock(a: Dictionary) -> void:
	var r: float = a["r"]
	draw_set_transform(a["pos"], a["rot"], Vector2(r, r))
	var shape: PackedVector2Array = a["shape"]
	draw_colored_polygon(shape, _grey(Color("8a8790")))
	var outline := shape.duplicate()
	outline.append(shape[0])
	draw_polyline(outline, _grey(INK), 2.5 / r, true)
	draw_circle(Vector2(-0.3, -0.2), 0.22, _grey(Color("6a6770")))
	draw_circle(Vector2(0.35, 0.25), 0.15, _grey(Color("6a6770")))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Every METEOR_EVERY seconds a burning rock streaks down across the field with a fiery tail.
func _draw_meteor() -> void:
	if reduced_motion:
		return
	var n := floorf(_t / METEOR_EVERY)
	var age := _t - n * METEOR_EVERY
	if age > METEOR_SEC:
		return
	var k := age / METEOR_SEC
	var sx := fposmod(sin(n * 12.9898) * 43758.5453, 1.0)
	var start := Vector2(area.position.x + area.size.x * (0.45 + 0.55 * sx), area.position.y - 40.0)
	var dir := Vector2(-0.75, 0.66)
	var head := start + dir * area.size.y * 0.9 * k
	var side := Vector2(-dir.y, dir.x)
	for i in 3:
		var w := 22.0 - float(i) * 6.0
		var len := 210.0 - float(i) * 50.0
		var col: Color = [Color("ff5a14"), Color("ff9a2a"), Color("ffe066")][i]
		draw_colored_polygon(PackedVector2Array([head + side * w, head - side * w, head - dir * len]), _grey(col))
	draw_circle(head, 20.0, _grey(INK))
	draw_circle(head, 17.0, _grey(Color("8a5a3c")))
	draw_circle(head + Vector2(-5, -4), 5.0, _grey(Color("6a4430")))


## Front pass (over the planet discs): the front halves of rings, and the rocket or satellite.
class Front extends Node2D:
	var sky: Node2D

	func _ready() -> void:
		light_mask = 0

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		for p in sky._planets:
			if p["ring"]:
				sky._ring_on(self, p["pos"] + sky._bob(p), p["r"], 0.0, PI)
		if not sky._craft.is_empty():
			var c: Dictionary = sky._craft
			if c["kind"] == "rocket":
				sky._rocket_on(self, c["pos"], (c["vel"] as Vector2).angle(), sky._t)
			else:
				sky._satellite_on(self, c["pos"], sky._t)


## A cartoon rocket with an ink outline, red nose and fins, a window and a flickering flame.
func _rocket_on(ci: CanvasItem, pos: Vector2, ang: float, t: float) -> void:
	var s := 1.15 * view_size.x / 1080.0
	ci.draw_set_transform(pos, ang + PI * 0.5, Vector2(s, s))
	var flick := 1.0 + 0.25 * sin(t * 40.0) + 0.1 * sin(t * 67.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-15, 38), Vector2(15, 38), Vector2(0, 38 + 56.0 * flick)]), _grey(Color("ff5a14")))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-9, 38), Vector2(9, 38), Vector2(0, 38 + 32.0 * flick)]), _grey(Color("ffe066")))
	for sx in [-1.0, 1.0]:
		var fin := PackedVector2Array([Vector2(22 * sx, 6), Vector2(42 * sx, 42), Vector2(20 * sx, 34)])
		ci.draw_colored_polygon(fin, _grey(Color("e8433a")))
		fin.append(fin[0])
		ci.draw_polyline(fin, _grey(INK), 2.5, true)
	var body := PackedVector2Array()
	for i in 21:
		var a := PI * float(i) / 20.0
		body.append(Vector2(-cos(a) * 22.0, -sin(a) * 54.0 + 4.0))
	body.append(Vector2(20, 38))
	body.append(Vector2(-20, 38))
	ci.draw_colored_polygon(body, _grey(Color("f4f4fa")))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-14, -34), Vector2(-7, -44), Vector2(0, -50), Vector2(7, -44), Vector2(14, -34)]), _grey(Color("e8433a")))
	body.append(body[0])
	ci.draw_polyline(body, _grey(INK), 3.0, true)
	ci.draw_circle(Vector2(0, -8), 12.0, _grey(INK))
	ci.draw_circle(Vector2(0, -8), 9.5, _grey(Color("e8433a")))
	ci.draw_circle(Vector2(0, -8), 6.5, _grey(Color("5cc6f0")))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A small satellite with a dish and two blue solar panels, slowly tumbling.
func _satellite_on(ci: CanvasItem, pos: Vector2, t: float) -> void:
	var s := view_size.x / 1080.0
	ci.draw_set_transform(pos, 0.0 if reduced_motion else sin(t * 0.5) * 0.3 - 0.4, Vector2(s, s))
	for sx in [-1.0, 1.0]:
		var r := Rect2(Vector2(46.0 if sx > 0 else -116.0, -20), Vector2(70, 40))
		ci.draw_rect(r, _grey(Color("2f6fd0")))
		for gx in 4:
			ci.draw_line(Vector2(r.position.x + 17.5 * float(gx + 1) - 17.5, r.position.y), Vector2(r.position.x + 17.5 * float(gx + 1) - 17.5, r.end.y), _grey(Color("8fc4ff")), 1.5)
		ci.draw_line(Vector2(r.position.x, 0), Vector2(r.end.x, 0), _grey(Color("8fc4ff")), 1.5)
		ci.draw_rect(r, _grey(INK), false, 2.5)
		ci.draw_line(Vector2(26.0 * sx, 0), Vector2((46.0 if sx > 0 else -46.0), 0), _grey(INK), 3.0)
	var box := Rect2(-26, -22, 52, 44)
	ci.draw_rect(box, _grey(Color("d8d8e2")))
	ci.draw_rect(Rect2(-26, -6, 52, 12), _grey(Color("e8433a")))
	ci.draw_rect(box, _grey(INK), false, 3.0)
	ci.draw_arc(Vector2(0, -34), 18.0, 0.2, PI - 0.2, 16, _grey(INK), 3.0, true)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-17, -30), Vector2(17, -30), Vector2(0, -22)]), _grey(Color("c9cbe0")))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

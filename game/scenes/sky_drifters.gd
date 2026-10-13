extends Node2D
## Planets, a sun, asteroids, a rocket, a satellite, a meteor and passing UFOs that float in the
## play field just behind the letters (owner references, layout mock and choice, 13 Oct 2026). The
## art is the owner's sticker sheet, cut out into game/art/space/ (see its README). Each body loops
## slowly around its home spot from the mock, so the planets frame the field and its middle stays
## calm for the letters. Visual only: taps pass through and nothing here touches the rules.

const ART := "res://art/space/%s.png"
## Planets one level can show; each level deals some of them into PLANET_SPOTS from its seed.
const PLANET_ART := ["earth", "ringed_purple", "orange_spotted", "red_banded", "blue_rocky", "teal_moon", "ringed_green", "pink_swirl", "ice_planet", "yellow_cratered", "pastel_cloudy", "lilac_cloudy", "green_swirl"]
## Craft that cross the field now and then: [art, speed px/s, heading of the art's nose in radians
## (NAN: the art has no nose to point)].
const CRAFT := [["ufo", 110.0, NAN], ["spaceship", 170.0, PI], ["ufo_antenna", 120.0, NAN]]
## Home spots from the owner's layout mock (13 Oct 2026), as shares of the drift area, with display
## diameters in px at 1080 wide. Planets frame the field and leave its middle calm for the letters;
## each level deals its planets into the planet spots from its seed.
const PLANET_SPOTS := [[Vector2(0.22, 0.155), 190.0], [Vector2(0.47, 0.07), 150.0], [Vector2(0.78, 0.15), 240.0], [Vector2(0.11, 0.38), 170.0], [Vector2(0.88, 0.33), 150.0], [Vector2(0.89, 0.51), 142.0], [Vector2(0.11, 0.61), 110.0]]
## [art, spot, diameter, turn rad/s]
const FIXED := [["sun", Vector2(0.83, 0.85), 226.0, 0.08], ["rocket", Vector2(0.17, 0.81), 180.0, 0.0], ["satellite", Vector2(0.36, 0.845), 170.0, 0.05], ["meteor", Vector2(0.57, 0.88), 170.0, 0.0], ["asteroid", Vector2(0.59, 0.17), 70.0, 0.4], ["asteroid", Vector2(0.23, 0.31), 42.0, -0.5], ["asteroid", Vector2(0.86, 0.66), 80.0, 0.3]]
const WANDER_PX := 34.0  # how far a body strays from its home spot
const TURN := 0.04  # planet rotation, radians per second
const BOB_PX := 6.0
const CRAFT_EVERY := 7.0
const CRAFT_D := 150.0

var view_size: Vector2 = Vector2(1080, 1920)
## The box the home spots are laid out in (the play field between the top band and the HUD).
var area: Rect2 = Rect2(0, 280, 1080, 1100)
var reduced_motion: bool = false
## Picks which planets this level shows, and where.
var seed_value: int = 2026

var _t: float = 0.0
var _bodies: Array = []  # {node, art, home, pos, r, turn, phase, w}
var _rng := RandomNumberGenerator.new()
var _craft: Dictionary = {}  # the craft now crossing: {node, vel}
var _craft_wait: float = 2.0
var _craft_n: int = 0


func _ready() -> void:
	light_mask = 0
	_rng.seed = seed_value
	var k := view_size.x / 1080.0
	var pool: Array = PLANET_ART.duplicate()
	for i in pool.size():  # seeded shuffle
		var j := _rng.randi_range(i, pool.size() - 1)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	for i in PLANET_SPOTS.size():
		_add_body(pool[i], float(PLANET_SPOTS[i][1]) * k, PLANET_SPOTS[i][0], TURN * (1.0 if i % 2 == 0 else -1.0))
	for f in FIXED:
		_add_body(f[0], float(f[2]) * k, f[1], float(f[3]))
	_place()


func _sprite(art: String, d: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = art.capitalize().replace(" ", "")
	s.texture = load(ART % art)
	s.light_mask = 0
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var size := s.texture.get_size()
	s.scale = Vector2.ONE * d / maxf(size.x, size.y)
	add_child(s)
	return s


func _add_body(art: String, d: float, spot: Vector2, turn: float) -> void:
	var s := _sprite(art, d)
	var home := area.position + area.size * spot
	_bodies.append({"node": s, "art": art, "home": home, "pos": home, "r": d * 0.5, "turn": turn, "phase": _rng.randf() * TAU, "w": _rng.randf_range(0.12, 0.22)})


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	_t += delta
	if not reduced_motion:
		for b in _bodies:
			# A slow loop around the home spot (two sines at different rates), plus a gentle turn.
			var ph: float = b["phase"]
			var w: float = b["w"]
			b["pos"] = b["home"] + Vector2(sin(_t * w + ph), cos(_t * w * 1.37 + ph * 1.7)) * WANDER_PX * (view_size.x / 1080.0)
			(b["node"] as Sprite2D).rotation += float(b["turn"]) * delta
		_tick_craft(delta)
	_place()


func planet_count() -> int:
	var n := 0
	for b in _bodies:
		if PLANET_ART.has(b["art"]):
			n += 1
	return n


func craft_flying() -> bool:
	return not _craft.is_empty()


func _place() -> void:
	for b in _bodies:
		var bob := 0.0 if reduced_motion else sin(_t * 0.8 + float(b["phase"])) * BOB_PX
		(b["node"] as Sprite2D).position = b["pos"] + Vector2(0.0, bob)


func _tick_craft(delta: float) -> void:
	if _craft.is_empty():
		_craft_wait -= delta
		if _craft_wait <= 0.0:
			var c: Array = CRAFT[_craft_n % CRAFT.size()]
			_craft_n += 1
			var from_left := _rng.randf() < 0.5
			var y := area.position.y + area.size.y * _rng.randf_range(0.2, 0.9)
			var x := area.position.x - 120.0 if from_left else area.end.x + 120.0
			var rise := -_rng.randf_range(0.2, 0.6) if c[0] == "rocket" else _rng.randf_range(-0.15, 0.15)
			var dir := Vector2(1.0 if from_left else -1.0, rise).normalized()
			var s := _sprite(c[0], CRAFT_D * (view_size.x / 1080.0))
			s.position = Vector2(x, y)
			if c[0] == "rocket":
				s.rotation = dir.angle() - float(c[2])  # point the nose along the flight
			elif c[0] == "spaceship":
				s.flip_h = from_left  # the art faces left
			_craft = {"node": s, "vel": dir * float(c[1]) * (view_size.x / 1080.0)}
		return
	var node: Sprite2D = _craft["node"]
	node.position += _craft["vel"] * delta
	if node.position.x < area.position.x - 220.0 or node.position.x > area.end.x + 220.0 or node.position.y < area.position.y - 220.0:
		node.queue_free()
		_craft = {}
		_craft_wait = CRAFT_EVERY * _rng.randf_range(0.6, 1.2)

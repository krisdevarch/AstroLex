extends Node2D
## Lost things floating in the play field just behind the letters (owner sticker sheet and mock v3,
## 13 Oct 2026): Act 1's everyday items (a teacup, bread, a spoon, a key, a lamp, a door, a letter,
## a chair, a TV) plus a comet, a rocket or a sputnik crossing now and then. The
## art is the owner's sheet, cut out into game/art/space/ (see its README). Items keep most of their colour
## under a light blue-grey night tint, as in the mock, and stay a step behind the letters. Each item loops
## slowly around its home spot and tumbles. Visual only: taps pass through and nothing here touches
## the rules.

const ART := "res://art/space/%s.png"
## Act 1 "Lost Everyday Items" (owner sheet). No orbit junk: the painted backdrop already has a
## satellite and a few rocks, and the mock shows only household items in front of them.
const EVERYDAY := ["teacup", "bread", "spoon", "key", "desk_lamp", "door", "envelope", "chair", "tv"]
## Home spots from the owner's mock v3, as shares of the drift area, with display sizes in px at 1080
## wide.
const SPOTS := [[Vector2(0.11, 0.38), 142.6], [Vector2(0.91, 0.47), 133.4], [Vector2(0.09, 0.60), 142.6], [Vector2(0.89, 0.64), 110.4], [Vector2(0.12, 0.84), 128.8], [Vector2(0.36, 0.85), 142.6], [Vector2(0.58, 0.89), 128.8], [Vector2(0.86, 0.88), 147.2]]
## Craft that cross the field now and then: [art, speed px/s, heading of the art's nose in radians
## (NAN: no nose to point)]. The comets' heads point down-left in the art.
const CRAFT := [["comet_big", 260.0, PI * 0.82], ["rocket", 170.0, -PI * 0.35], ["sputnik", 110.0, NAN], ["comet_mid", 220.0, PI * 0.75]]
## The mock's look: items keep most of their colour under a light blue-grey night tint.
const MUTE_SHADER := "shader_type canvas_item;\nuniform float keep = 0.3;\nuniform vec3 night = vec3(0.86, 0.9, 0.98);\nvoid fragment() {\n\tvec4 c = COLOR;\n\tfloat g = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(mix(vec3(g), c.rgb, keep) * night, c.a);\n}\n"
const ITEM_TINT := Color(1, 1, 1, 1)
const CRAFT_TINT := Color(1, 1, 1, 0.95)
const ITEM_KEEP := 0.5  # share of an item's own colour that stays
const CRAFT_KEEP := 0.8
const WANDER_PX := 30.0  # how far an item strays from its home spot
const TUMBLE := 0.12  # item rotation, radians per second (alternating direction)
const BOB_PX := 6.0
const CRAFT_EVERY := 8.0
const CRAFT_D := 120.0

var view_size: Vector2 = Vector2(1080, 1920)
## The box the home spots are laid out in (the play field between the top band and the HUD).
var area: Rect2 = Rect2(0, 280, 1080, 1100)
var reduced_motion: bool = false
## Picks which items this level shows, and where.
var seed_value: int = 2026

var _t: float = 0.0
var _bodies: Array = []  # {node, art, home, pos, r, turn, phase, w}
var _rng := RandomNumberGenerator.new()
var _craft: Dictionary = {}  # the craft now crossing: {node, vel}
var _craft_wait: float = 3.0
var _craft_n: int = 0
var _mute: Shader


func _ready() -> void:
	light_mask = 0
	_rng.seed = seed_value
	var k := view_size.x / 1080.0
	var everyday := _shuffled(EVERYDAY)
	for i in SPOTS.size():
		var art: String = everyday[i % everyday.size()]
		var start := _rng.randf() * TAU
		_add_body(art, float(SPOTS[i][1]) * k, SPOTS[i][0], TUMBLE * (1.0 if i % 2 == 0 else -1.0), start)
	_craft_n = _rng.randi() % CRAFT.size()
	_place()


func _shuffled(list: Array) -> Array:
	var pool: Array = list.duplicate()
	for i in pool.size():
		var j := _rng.randi_range(i, pool.size() - 1)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	return pool


func _sprite(art: String, d: float, tint: Color, keep: float = ITEM_KEEP) -> Sprite2D:
	var s := Sprite2D.new()
	if _mute == null:
		_mute = Shader.new()
		_mute.code = MUTE_SHADER
	var m := ShaderMaterial.new()
	m.shader = _mute
	m.set_shader_parameter("keep", keep)
	s.material = m
	s.name = art.capitalize().replace(" ", "")
	s.texture = load(ART % art)
	s.light_mask = 0
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.modulate = tint
	var size := s.texture.get_size()
	s.scale = Vector2.ONE * d / maxf(size.x, size.y)
	add_child(s)
	return s


func _add_body(art: String, d: float, spot: Vector2, turn: float, start_rot: float) -> void:
	var s := _sprite(art, d, ITEM_TINT)
	s.rotation = (start_rot - PI) * 0.25  # a little askew, as if adrift
	var home := area.position + area.size * spot
	_bodies.append({"node": s, "art": art, "home": home, "pos": home, "r": d * 0.5, "turn": turn, "phase": _rng.randf() * TAU, "w": _rng.randf_range(0.12, 0.22)})


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	_t += delta
	if not reduced_motion:
		for b in _bodies:
			# A slow loop around the home spot (two sines at different rates), plus a gentle tumble.
			var ph: float = b["phase"]
			var w: float = b["w"]
			b["pos"] = b["home"] + Vector2(sin(_t * w + ph), cos(_t * w * 1.37 + ph * 1.7)) * WANDER_PX * (view_size.x / 1080.0)
			(b["node"] as Sprite2D).rotation += float(b["turn"]) * delta
		_tick_craft(delta)
	_place()


## How many floating items this level shows.
func item_count() -> int:
	return _bodies.size()


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
			var art: String = c[0]
			var from_left := _rng.randf() < 0.5
			var dir: Vector2
			var start: Vector2
			if art.begins_with("comet"):
				# Comets fall from the top corner toward the far bottom, head first.
				dir = Vector2(1.0 if from_left else -1.0, _rng.randf_range(0.45, 0.7)).normalized()
				start = Vector2(area.position.x - 120.0 if from_left else area.end.x + 120.0, area.position.y + area.size.y * _rng.randf_range(0.0, 0.3))
			else:
				var rise := -_rng.randf_range(0.2, 0.6) if art == "rocket" else _rng.randf_range(-0.15, 0.15)
				dir = Vector2(1.0 if from_left else -1.0, rise).normalized()
				start = Vector2(area.position.x - 120.0 if from_left else area.end.x + 120.0, area.position.y + area.size.y * _rng.randf_range(0.2, 0.9))
			var s := _sprite(art, CRAFT_D * (view_size.x / 1080.0), CRAFT_TINT, CRAFT_KEEP)
			s.position = start
			if not is_nan(float(c[2])):
				s.rotation = dir.angle() - float(c[2])  # point the head along the flight
			_craft = {"node": s, "vel": dir * float(c[1]) * (view_size.x / 1080.0)}
		return
	var node: Sprite2D = _craft["node"]
	node.position += _craft["vel"] * delta
	if node.position.x < area.position.x - 240.0 or node.position.x > area.end.x + 240.0 or node.position.y < area.position.y - 240.0 or node.position.y > area.end.y + 240.0:
		node.queue_free()
		_craft = {}
		_craft_wait = CRAFT_EVERY * _rng.randf_range(0.6, 1.2)

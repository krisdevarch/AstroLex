extends Node2D
## The sky behind the play field (owner references, 13 Oct 2026): just stars, a deep blue night
## with small white dots, twinkling sticker sparkles in the sheet's colours (ink outline, white
## glint) and now and then a shooting star (owner: "make the stars a bit more interesting"). Planets, the sun, asteroids, rockets, a
## satellite and meteors move through the field in sky_drifters.gd. Colour story: the scene starts drained and its
## colour comes back as words are restored (`restore` 0..1). Placeholder art (O-14).

const TileTextures := preload("res://scenes/tile_textures.gd")

const GREY_SAT := 0.8  # saturation before any word is restored
const RESTORE_RATE := 0.8  # per second, how fast colour eases back
const SPARKLES := 22
const SPARKLE_TINTS := [Color("ffd84a"), Color("fff6d8"), Color("7fe8ff"), Color("ff9bd2"), Color("ffd84a"), Color("fff6d8")]
const INK := Color(0.04, 0.06, 0.18)
const SHOOT_EVERY := 5.0  # seconds between shooting stars, give or take
const SHOOT_SPEED := 1500.0  # px/s at 1080 wide
const SHOOT_TAIL := 260.0
const SAT_SHADER := "shader_type canvas_item;\nuniform float sat = 1.0;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV) * COLOR;\n\tfloat g = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(mix(vec3(g), c.rgb, sat), c.a);\n}\n"

var view_size: Vector2 = Vector2(1080, 1920)
## Share of the level's words restored; the flow sets it, the scene eases toward it.
var restore: float = 0.0
## Reduced motion: steady sparkles.
var reduced_motion: bool = false

var _shown: float = 0.0
var _t: float = 0.0
var _mat: ShaderMaterial
var _live: Node2D
var _sparkles: Array = []  # [pos, size, phase, tint, spin]
var _rng := RandomNumberGenerator.new()
## The shooting star now crossing ({pos, vel}), or empty.
var _shoot: Dictionary = {}
var _shoot_wait: float = 2.5


func _ready() -> void:
	var sh := Shader.new()
	sh.code = SAT_SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	for pair in [["Sky", TileTextures.sky()], ["Stars", TileTextures.stars()]]:
		var s := Sprite2D.new()
		s.name = pair[0]
		s.texture = pair[1]
		s.centered = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		s.scale = view_size / Vector2((pair[1] as Texture2D).get_size())
		s.material = _mat
		add_child(s)
	_live = Live.new()
	_live.name = "Live"
	_live.set("owner_bg", self)
	_live.material = _mat
	add_child(_live)
	_rng.seed = 7
	var k := view_size.x / 1080.0
	for i in SPARKLES:
		var p := Vector2(_rng.randf_range(0.03, 0.97) * view_size.x, _rng.randf_range(0.02, 0.8) * view_size.y)
		var big := i % 4 == 0
		var sz := (_rng.randf_range(28.0, 40.0) if big else _rng.randf_range(14.0, 22.0)) * k
		_sparkles.append([p, sz, _rng.randf() * TAU, SPARKLE_TINTS[i % SPARKLE_TINTS.size()], _rng.randf_range(-0.4, 0.4)])
	_apply_sat()


func _process(delta: float) -> void:
	_t += delta
	_shown = move_toward(_shown, clampf(restore, 0.0, 1.0), RESTORE_RATE * delta)
	_apply_sat()
	if not reduced_motion:
		_tick_shoot(delta)
	_live.queue_redraw()


func shooting() -> bool:
	return not _shoot.is_empty()


func _tick_shoot(delta: float) -> void:
	if _shoot.is_empty():
		_shoot_wait -= delta
		if _shoot_wait <= 0.0:
			var from_left := _rng.randf() < 0.5
			var start := Vector2(_rng.randf_range(0.1, 0.6) * view_size.x, _rng.randf_range(0.05, 0.35) * view_size.y)
			if not from_left:
				start.x = view_size.x - start.x
			var dir := Vector2(1.0 if from_left else -1.0, _rng.randf_range(0.35, 0.6)).normalized()
			_shoot = {"pos": start, "vel": dir * SHOOT_SPEED * (view_size.x / 1080.0), "life": 0.0}
		return
	_shoot["pos"] += _shoot["vel"] * delta
	_shoot["life"] += delta
	var p: Vector2 = _shoot["pos"]
	if p.x < -SHOOT_TAIL or p.x > view_size.x + SHOOT_TAIL or p.y > view_size.y * 0.8:
		_shoot = {}
		_shoot_wait = SHOOT_EVERY * _rng.randf_range(0.7, 1.4)


func saturation() -> float:
	return lerpf(GREY_SAT, 1.0, _shown)


func _apply_sat() -> void:
	_mat.set_shader_parameter("sat", saturation())


class Live extends Node2D:
	var owner_bg: Node2D

	func _draw() -> void:
		var bg := owner_bg
		var calm: bool = bg.reduced_motion
		var t: float = bg._t
		for sp in bg._sparkles:
			var ph := float(sp[2])
			var k := 1.0 if calm else 0.7 + 0.3 * sin(t * 1.7 + ph)
			var turn := 0.0 if calm else t * float(sp[4])
			_sparkle(sp[0], float(sp[1]) * k, ph * 0.2 + turn, sp[3])
		if not bg._shoot.is_empty():
			_shooting_star(bg._shoot["pos"], (bg._shoot["vel"] as Vector2).normalized(), float(bg._shoot["life"]))

	## A sticker sparkle as on the owner's sheet: a four-point star with concave sides, a dark ink
	## outline and a white glint.
	func _sparkle(p: Vector2, s: float, rot: float, c: Color) -> void:
		draw_colored_polygon(_star(p, s + 4.0, rot), INK)
		draw_colored_polygon(_star(p, s, rot), c)
		draw_circle(p + Vector2(-s * 0.12, -s * 0.16), maxf(1.2, s * 0.1), Color(1, 1, 1, 0.9))

	func _star(p: Vector2, s: float, rot: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var n := 32
		for i in n:
			var a := TAU * float(i) / float(n)
			var r := s * (0.38 + 0.62 * pow(absf(cos(2.0 * a)), 2.2))
			pts.append(p + Vector2.from_angle(a + rot) * r)
		return pts

	## A shooting star: a fading gold-to-clear tail behind a small bright sparkle.
	func _shooting_star(head: Vector2, dir: Vector2, life: float) -> void:
		var fade := clampf(life * 4.0, 0.0, 1.0)
		var segs := 12
		for i in segs:
			var u0 := float(i) / float(segs)
			var u1 := float(i + 1) / float(segs)
			var a := Color(1.0, 0.92, 0.6, (1.0 - u0) * 0.8 * fade)
			draw_line(head - dir * SHOOT_TAIL * u0, head - dir * SHOOT_TAIL * u1, a, lerpf(7.0, 1.5, u0), true)
		_sparkle(head, 14.0, life * 3.0, Color("fff6d8"))

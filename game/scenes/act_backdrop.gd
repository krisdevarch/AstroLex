extends Node2D
## The sky behind the play field: the owner's painted Low Orbit backdrop (19 Oct 2026): a purple
## night with the Milky Way, a crescent moon, layered clouds, a tiny floating chair and Earth's tilted
## night side with its city lights and an orange dawn glow at the bottom, lined up so the sky fills the
## screen and Earth's rim runs just above the HUD's curve on the left (`horizon_y`). Over it, a few twinkling
## sticker sparkles and now and then a shooting star (owner: "make the stars a bit more interesting"). The owner's sticker
## items are the decoys, drawn by tile_view.gd. Colour story: the scene starts drained and its
## colour comes back as words are restored (`restore` 0..1).


const GREY_SAT := 0.8  # saturation before any word is restored
const RESTORE_RATE := 0.8  # per second, how fast colour eases back
const DEFAULT_ACT := "act1_low_orbit"
## Per act: the painted sky, where its horizon crests (image px from the top) and the sparkle tints.
## Act I's "horizon" is the row pinned to the HUD crest: its tilted rim crests 1351 px on the left and
## 1455 px mid-image (of 1935), and 1330 keeps the whole sky, moon included, on a 1080x1920 screen.
## Act II is the owner's moon painting (19 Oct 2026: Earth small in the sky, purple and peach clouds,
## the Moon's cratered rim rising from the bottom left), framed the same way as Act I. Act IV is the
## owner's heart nebula under a spiral galaxy, and Act III their ringed purple planet under a spiral
## galaxy (both 19 Oct 2026), framed the same way too.
const SKIES := {
	"act1_low_orbit": {"tex": "res://art/backdrop/low_orbit.jpg", "horizon": 1330.0},
	"act2_nebula": {"tex": "res://art/backdrop/act2_nebula.jpg", "horizon": 1330.0,
		"tints": [Color("ffd0ec"), Color("ffffff"), Color("e6c8ff"), Color("ffb8dc")]},
	"act3_tower": {"tex": "res://art/backdrop/act3_tower.jpg", "horizon": 1330.0,
		"tints": [Color("ffd9a0"), Color("ffffff"), Color("d8e8f4"), Color("ffc070")]},
	"act4_core": {"tex": "res://art/backdrop/act4_core.jpg", "horizon": 1330.0,
		"tints": [Color("b8f4ff"), Color("ffffff"), Color("ffb0e0"), Color("d0d4ff")]},
}
const SPARKLES := 12
const SPARKLE_TINTS := [Color("ffffff"), Color("fff6d8"), Color("dceeff"), Color("ffffff"), Color("cfe6ff"), Color("fff6d8")]
const INK := Color(0.04, 0.06, 0.18)
const SHOOT_EVERY := 5.0  # seconds between shooting stars, give or take
const SHOOT_SPEED := 1500.0  # px/s at 1080 wide
const SHOOT_TAIL := 260.0
const SAT_SHADER := "shader_type canvas_item;\nuniform float sat = 1.0;\nvoid fragment() {\n\tvec4 c = COLOR;  // already the texture times the modulate\n\tfloat g = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(mix(vec3(g), c.rgb, sat), c.a);\n}\n"

## The act whose sky to show (set before _ready, or call set_act); unknown acts show Low Orbit.
var act: String = DEFAULT_ACT
var view_size: Vector2 = Vector2(1080, 1920)
## Share of the level's words restored; the flow sets it, the scene eases toward it.
var restore: float = 0.0
## Reduced motion: steady sparkles.
var reduced_motion: bool = false
## Screen y where Earth's rim crests (the field sets it to the HUD panel's curve).
var horizon_y: float = 1920.0 - 560.0

var _shown: float = 0.0
var _t: float = 0.0
var _mat: ShaderMaterial
var _live: Node2D
var _sky: Sprite2D
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
	_sky = Sprite2D.new()
	_sky.name = "Sky"
	_sky.centered = false
	_sky.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sky.material = _mat
	add_child(_sky)
	_live = Live.new()
	_live.name = "Live"
	_live.set("owner_bg", self)
	_live.material = _mat
	add_child(_live)
	_rng.seed = 7
	var k := view_size.x / 1080.0
	for i in SPARKLES:
		var p := Vector2(_rng.randf_range(0.03, 0.97) * view_size.x, _rng.randf_range(0.02, 0.62) * view_size.y)
		var big := i % 4 == 0
		var sz := (_rng.randf_range(12.0, 16.0) if big else _rng.randf_range(6.0, 9.0)) * k
		_sparkles.append([p, sz, _rng.randf() * TAU, Color.WHITE, _rng.randf_range(-0.4, 0.4)])
	set_act(act)
	_apply_sat()


## The sky entry for an act, falling back to Low Orbit.
static func sky_for(a: String) -> Dictionary:
	return SKIES.get(a, SKIES[DEFAULT_ACT])


## Shows an act's sky and sparkle tints. The colour story (`_shown`) is left alone.
func set_act(a: String) -> void:
	act = a if SKIES.has(a) else DEFAULT_ACT
	if _sky == null:
		return
	_sky.texture = load(str(sky_for(act)["tex"]))
	fit_sky(_sky)
	var tints: Array = sky_for(act).get("tints", SPARKLE_TINTS)
	for i in _sparkles.size():
		_sparkles[i][3] = tints[i % tints.size()]


## Covers the screen with the backdrop, scaled so its Earth crest lands on horizon_y and centred.
func fit_sky(sky: Sprite2D) -> void:
	var size := sky.texture.get_size()
	var hz := float(sky_for(act)["horizon"])
	var k := maxf(view_size.x / size.x * 1.03, horizon_y / hz)
	k = maxf(k, (view_size.y - horizon_y) / (size.y - hz))
	sky.scale = Vector2(k, k)
	sky.position = Vector2((view_size.x - size.x * k) * 0.5, horizon_y - hz * k)


func _process(delta: float) -> void:
	_t += delta
	_shown = move_toward(_shown, clampf(restore, 0.0, 1.0), RESTORE_RATE * delta)
	_apply_sat()
	if not reduced_motion:
		_tick_shoot(delta)
	_live.queue_redraw()


## Jumps to the target colour at once (the finale's LISTEN).
func snap() -> void:
	_shown = clampf(restore, 0.0, 1.0)
	if _mat != null:
		_apply_sat()


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
		draw_colored_polygon(_star(p, s + 2.0, rot), INK)
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

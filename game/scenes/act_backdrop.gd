extends Node2D
## The sky behind the play field (owner references, 13 Oct 2026): just stars, a deep blue night
## with small white dots and twinkling four-point sparkles. Planets, the sun, asteroids, rockets, a
## satellite and meteors move through the field in sky_drifters.gd. Colour story: the scene starts drained and its
## colour comes back as words are restored (`restore` 0..1). Placeholder art (O-14).

const TileTextures := preload("res://scenes/tile_textures.gd")

const GREY_SAT := 0.8  # saturation before any word is restored
const RESTORE_RATE := 0.8  # per second, how fast colour eases back
const SPARKLES := 16
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
var _sparkles: Array = []  # [pos, size, phase]


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
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in SPARKLES:
		var p := Vector2(rng.randf_range(0.03, 0.97) * view_size.x, rng.randf_range(0.02, 0.8) * view_size.y)
		_sparkles.append([p, rng.randf_range(9.0, 22.0), rng.randf() * TAU])
	_apply_sat()


func _process(delta: float) -> void:
	_t += delta
	_shown = move_toward(_shown, clampf(restore, 0.0, 1.0), RESTORE_RATE * delta)
	_apply_sat()
	_live.queue_redraw()


func saturation() -> float:
	return lerpf(GREY_SAT, 1.0, _shown)


func _apply_sat() -> void:
	_mat.set_shader_parameter("sat", saturation())


class Live extends Node2D:
	var owner_bg: Node2D

	func _draw() -> void:
		var bg := owner_bg
		var calm: bool = bg.reduced_motion
		for sp in bg._sparkles:
			var k := 1.0 if calm else 0.55 + 0.45 * (0.5 + 0.5 * sin(float(bg._t) * 1.6 + float(sp[2])))
			_sparkle(sp[0], float(sp[1]) * k, Color(0.8, 0.93, 1.0, 0.5 + 0.5 * k))

	## A flat four-point star: two thin diamonds crossed.
	func _sparkle(p: Vector2, s: float, c: Color) -> void:
		var w := s * 0.28
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(w, 0), p + Vector2(0, s), p + Vector2(-w, 0)]), c)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-s, 0), p + Vector2(0, -w), p + Vector2(s, 0), p + Vector2(0, w)]), c)

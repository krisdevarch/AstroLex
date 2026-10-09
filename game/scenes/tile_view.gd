extends Node2D
## One 2.5D letter tile (plan 8.2): bevelled body (lit, tilted by the tile shader), a glyph that
## always faces the player, and a drop shadow. Plane depth is scale only.

const TileTextures := preload("res://scenes/tile_textures.gd")
const TILE_SHADER: Shader = preload("res://shaders/tile.gdshader")
## The flat treatment skips the lamp, so it needs the ambient dimming undone.
const FLAT_GAIN := Vector3(1.6, 1.6, 1.4)
const GLASS_SHADER: Shader = preload("res://shaders/glass.gdshader")
## The ambient CanvasModulate dims anything it tints; glass is off the lamp, so undo it.
const GLASS_GAIN := Vector3(1.55, 1.52, 1.28)
const GLASS_ACCENT := Color(0.35, 0.85, 1.0)
const GLYPH_COLOR := Color(0.06, 0.08, 0.18)

@onready var shadow: Sprite2D = $Shadow
@onready var body: Sprite2D = $Body
@onready var glyph: Label = $Glyph

var ch: String = ""
var plane: int = 0
var is_back: bool = false
var treatment: String = "tilt"
var reduced_motion: bool = false
var size_px: float = 100.0
var anim: String = ""  # "", "fly" or "dissolve"
var current_tilt: Vector2 = Vector2.ZERO

var _tun: Dictionary = {}
var _phase: float = 0.0
var _mat: ShaderMaterial
var _flash_t: float = 0.0
var _flash_dur: float = 0.4
var _anim_t: float = 0.0
var _anim_dur: float = 1.0
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _to_scale: float = 1.0


func setup(p_ch: String, p_size_px: float, plane_scale: float, p_plane: int, p_treatment: String, p_reduced: bool, tun: Dictionary, p_phase: float) -> void:
	ch = p_ch
	size_px = p_size_px
	plane = p_plane
	treatment = p_treatment
	reduced_motion = p_reduced
	_tun = tun
	_phase = p_phase
	var k := size_px / float(TileTextures.SIZE)
	body.scale = Vector2(k, k)
	_mat = ShaderMaterial.new()
	if treatment == "glass":
		body.texture = TileTextures.glass_mask()
		_mat.shader = GLASS_SHADER
		_mat.set_shader_parameter("unlit_gain", GLASS_GAIN)
		_mat.set_shader_parameter("accent", GLASS_ACCENT)
		_mat.set_shader_parameter("blur", float(_tun["glass.blur"]))
		_mat.set_shader_parameter("refract_px", float(_tun["glass.refractPx"]))
		_mat.set_shader_parameter("frost", float(_tun["glass.frost"]))
		_mat.set_shader_parameter("specular", float(_tun["glass.specular"]))
		_mat.set_shader_parameter("edge_tint", float(_tun["glass.edgeTint"]))
		_mat.set_shader_parameter("chroma", float(_tun["glass.chroma"]))
		_mat.set_shader_parameter("grain", float(_tun["glass.grain"]))
		_mat.set_shader_parameter("sky_tex", TileTextures.sky())
		_mat.set_shader_parameter("stars_tex", TileTextures.stars())
		_mat.set_shader_parameter("milk", float(_tun["glass.milk"]))
		shadow.modulate.a = 0.45  # clear glass casts a faint shadow
		_mat.set_shader_parameter("max_tilt_deg", maxf(1.0, float(_tun["tile.maxTiltDeg"])))
		body.light_mask = 2
	else:
		body.texture = TileTextures.body("bevel" if treatment == "bevel" else "tilt")
		_mat.shader = TILE_SHADER
	body.material = _mat
	shadow.texture = TileTextures.shadow()
	shadow.scale = body.scale
	shadow.position = Vector2(0.4, 1.0) * float(_tun["tile.shadowOffset"]) * plane_scale
	shadow.light_mask = 2
	glyph.light_mask = 2
	if treatment == "flat":
		body.light_mask = 2
		_mat.set_shader_parameter("unlit_gain", FLAT_GAIN)
	glyph.text = ch.to_upper()
	glyph.size = Vector2(size_px, size_px)
	glyph.position = -glyph.size * 0.5
	glyph.pivot_offset = glyph.size * 0.5
	glyph.add_theme_font_size_override("font_size", int(size_px * 0.62))
	if treatment == "glass":
		# White glyph with a thin dark ink halo; modulate undoes the ambient tint (glyph is unlit).
		glyph.add_theme_color_override("font_color", Color.WHITE)
		glyph.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.12, 0.6))
		glyph.add_theme_constant_override("outline_size", maxi(2, int(size_px * 0.035)))
		glyph.modulate = Color(GLASS_GAIN.x, GLASS_GAIN.y, GLASS_GAIN.z, 1.0)
	else:
		glyph.add_theme_color_override("font_color", GLYPH_COLOR)


## Back plane: blank debris (a shard, no letter). Dim, desaturated, unlit, shadowless, never tilted.
func set_back(alpha: float, desaturate: float) -> void:
	is_back = true
	modulate = Color(1.0, 1.0, 1.0, alpha)
	glyph.visible = false
	body.rotation = fposmod(_phase, TAU)
	shadow.visible = false
	body.light_mask = 2
	if treatment == "glass":
		body.texture = TileTextures.shard()
		_mat.set_shader_parameter("shard", true)
		_mat.set_shader_parameter("tilt_deg", Vector2.ZERO)
		return
	body.texture = TileTextures.shard()
	_mat.set_shader_parameter("unlit_gain", FLAT_GAIN)
	_mat.set_shader_parameter("desaturate", desaturate)


## Places the tile and tilts it toward the lamp, plus a slow sway. nx is the tile's x in 0..1.
func place(screen_pos: Vector2, time: float, nx: float) -> void:
	if anim != "":
		return
	position = screen_pos
	var tilt := Vector2.ZERO
	if treatment != "flat" and not reduced_motion and not is_back:
		var maxd: float = _tun["tile.maxTiltDeg"]
		var sway_deg: float = _tun["tile.swayDeg"]
		var w := TAU * float(_tun["tile.swaySpeed"])
		tilt.y = clampf(clampf((nx - 0.5) * 2.0, -1.0, 1.0) * maxd * 0.6 + sway_deg * sin(time * w + _phase), -maxd, maxd)
		tilt.x = clampf(sway_deg * cos(time * w * 0.8 + _phase * 1.3) - maxd * 0.15, -maxd, maxd)
	current_tilt = tilt
	_mat.set_shader_parameter("tilt_deg", tilt)


func flash(dur: float) -> void:
	_flash_dur = maxf(0.01, dur)
	_flash_t = _flash_dur


func fly_to(target: Vector2, target_size_px: float, dur: float) -> void:
	anim = "fly"
	_from = position
	_to = target
	_to_scale = target_size_px / size_px
	_anim_dur = maxf(0.01, dur)
	_anim_t = 0.0
	z_index = 20
	shadow.visible = false


func dissolve(dur: float) -> void:
	anim = "dissolve"
	_anim_dur = maxf(0.01, dur)
	_anim_t = 0.0
	z_index = 5


## Advances flash and animation; true when a fly or dissolve has finished.
func tick(delta: float) -> bool:
	if _flash_t > 0.0:
		_flash_t = maxf(0.0, _flash_t - delta)
		_mat.set_shader_parameter("flash", _flash_t / _flash_dur)
	if anim == "":
		return false
	_anim_t += delta
	var u := clampf(_anim_t / _anim_dur, 0.0, 1.0)
	if anim == "fly":
		var e := u * u * (3.0 - 2.0 * u)
		position = _from.lerp(_to, e)
		scale = Vector2.ONE * lerpf(1.0, _to_scale, e)
		_mat.set_shader_parameter("tilt_deg", current_tilt * (1.0 - e))
	else:
		modulate.a = 1.0 - u
		scale = Vector2.ONE * (1.0 + 0.25 * u)
	return u >= 1.0

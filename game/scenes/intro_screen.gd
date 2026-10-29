extends Control
## Intro screen (WP-F.28): the first thing on launch. A painted starfield with a diagonal nebula band,
## the chrome AstroLex logo and the four Catchers in glass bubbles that pop in one after another and
## bob out of step. A gleam sweeps the logo, "Tap to start" pulses. A tap anywhere, or intro.holdSec
## seconds, emits `finished` (after a short fade). Reduced motion shows everything still at rest.
## The art comes from scripts/art/make_intro.py (placeholder until the final key art lands).

const Ui := preload("res://scenes/ui.gd")
const GameData := preload("res://rules/game_data.gd")
const AppSettings := preload("res://scenes/app_settings.gd")

const SKY_TEX := "res://art/intro/sky.jpg"
const LOGO_TEX := "res://art/intro/logo.png"
const DESIGN := Vector2(1080, 1920)
const LOGO_W := 1000.0
const LOGO_CENTER := Vector2(540, 905)
const TAP_Y := 1790.0
## id -> [centre in design px, diameter, bob amplitude, bob speed, phase, tilt degrees]
const BUBBLES := {
	"wren": [Vector2(300, 330), 390.0, 14.0, 1.15, 0.0, 3.0],
	"juno": [Vector2(775, 555), 530.0, 12.0, 0.85, 1.9, 2.5],
	"ash": [Vector2(315, 1420), 570.0, 13.0, 0.95, 3.6, 3.0],
	"pip": [Vector2(805, 1335), 390.0, 16.0, 1.30, 5.0, 4.0],
}
const ORDER := ["juno", "wren", "ash", "pip"]
const POP_START := 0.25
const POP_STEP := 0.28
const POP_SEC := 0.55
const GLEAM_EVERY := 3.6
const GLEAM_SEC := 1.1

const GLEAM_SHADER := """
shader_type canvas_item;
uniform float sweep = -1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float d = (UV.x + UV.y * 0.30) - sweep;
	float band = exp(-pow(d / 0.045, 2.0)) * 0.9 + exp(-pow(d / 0.16, 2.0)) * 0.18;
	COLOR = vec4(c.rgb + vec3(band) * c.a, c.a);
}
"""

signal finished

var settings: AppSettings = AppSettings.new()
## Seconds before the intro moves on by itself (tunable intro.holdSec).
var hold_sec: float = 6.0
## Length of the fade to black when it ends; 0 emits `finished` at once.
var fade_sec: float = 0.35
var _t: float = 0.0
var _done: bool = false
var _stage: Control
var _bubbles: Array = []  # [node, rest position, amplitude, speed, phase, tilt degrees]
var _twinkles: Array = []  # [sprite, speed, phase, base alpha]
var _logo: TextureRect
var _gleam: ShaderMaterial
var _tap: Label
var _fade: ColorRect


func _ready() -> void:
	name = "IntroScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hold_sec = float(GameData.load_tunables().get("intro.holdSec", hold_sec))
	var view := get_viewport_rect().size
	_build_sky(view)
	_stage = Control.new()
	_stage.name = "IntroStage"
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.size = DESIGN
	_stage.position = ((view - DESIGN) * 0.5).floor()
	add_child(_stage)
	_build_bubbles()
	_build_logo()
	_build_tap()
	_fade = ColorRect.new()
	_fade.name = "IntroFade"
	_fade.color = Color(0.01, 0.02, 0.08, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


## The sky covers the whole view, whatever its aspect; twinkling sparkles ride on top of it.
func _build_sky(view: Vector2) -> void:
	var back := ColorRect.new()
	back.name = "IntroBack"
	back.color = Color("07102b")
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var tex := _tex(SKY_TEX)
	var k := maxf(view.x / DESIGN.x, view.y / DESIGN.y)
	var sky := TextureRect.new()
	sky.name = "IntroSky"
	sky.texture = tex
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.size = DESIGN * k
	sky.position = ((view - DESIGN * k) * 0.5).floor()
	add_child(sky)
	var star := _sparkle_texture()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2810
	for i in 16:
		var s := TextureRect.new()
		s.name = "Twinkle_%d" % i
		s.texture = star
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var px := rng.randf_range(18.0, 40.0)
		s.size = Vector2(px, px)
		s.pivot_offset = s.size * 0.5
		s.position = Vector2(rng.randf_range(0.0, view.x), rng.randf_range(0.0, view.y)) - s.size * 0.5
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		s.material = mat
		var a := rng.randf_range(0.35, 0.8)
		s.modulate = Color(0.85, 0.93, 1.0, a)
		add_child(s)
		_twinkles.append([s, rng.randf_range(0.8, 2.2), rng.randf_range(0.0, TAU), a])


func _build_bubbles() -> void:
	for n in ORDER.size():
		var id: String = ORDER[n]
		var d: Array = BUBBLES[id]
		var b := TextureRect.new()
		b.name = "IntroBubble_%s" % id
		b.texture = _tex("res://art/intro/%s.png" % id)
		b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		b.stretch_mode = TextureRect.STRETCH_SCALE
		b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dia: float = d[1]
		b.size = Vector2(dia, dia)
		b.pivot_offset = b.size * 0.5
		var rest: Vector2 = d[0] - b.size * 0.5
		b.position = rest
		_stage.add_child(b)
		_bubbles.append([b, rest, d[2], d[3], d[4], d[5]])
		if not settings.reduced_motion:
			b.scale = Vector2.ZERO
			b.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_interval(POP_START + POP_STEP * n)
			tw.tween_property(b, "modulate:a", 1.0, 0.18)
			tw.parallel().tween_property(b, "scale", Vector2.ONE, POP_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_logo() -> void:
	var tex := _tex(LOGO_TEX)
	_logo = TextureRect.new()
	_logo.name = "IntroLogo"
	_logo.texture = tex
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_SCALE
	_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sz := tex.get_size() if tex != null else Vector2(1900, 435)
	_logo.size = Vector2(LOGO_W, LOGO_W * sz.y / sz.x)
	_logo.pivot_offset = _logo.size * 0.5
	_logo.position = LOGO_CENTER - _logo.size * 0.5
	var sh := Shader.new()
	sh.code = GLEAM_SHADER
	_gleam = ShaderMaterial.new()
	_gleam.shader = sh
	_gleam.set_shader_parameter("sweep", -1.0)
	_logo.material = _gleam
	_stage.add_child(_logo)
	if not settings.reduced_motion:
		_logo.scale = Vector2(0.86, 0.86)
		_logo.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.05)
		tw.tween_property(_logo, "modulate:a", 1.0, 0.4)
		tw.parallel().tween_property(_logo, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_tap() -> void:
	_tap = Ui.text("Tap to start", 58, Color("f4f7ff"))
	_tap.name = "TapToStart"
	_tap.size = Vector2(DESIGN.x, 90)
	_tap.position = Vector2(0, TAP_Y)
	_tap.add_theme_color_override("font_shadow_color", Color(0.02, 0.05, 0.25, 0.9))
	_tap.add_theme_constant_override("shadow_outline_size", 14)
	_tap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_tap)
	if not settings.reduced_motion:
		_tap.modulate.a = 0.0


## A soft 4-point star, drawn once.
func _sparkle_texture() -> Texture2D:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) * 0.5
	for y in n:
		for x in n:
			var dx := absf(x - c) / c
			var dy := absf(y - c) / c
			var arm := exp(-pow(dy / 0.06, 2.0)) * pow(maxf(1.0 - dx, 0.0), 2.0) + exp(-pow(dx / 0.06, 2.0)) * pow(maxf(1.0 - dy, 0.0), 2.0)
			var core := exp(-(dx * dx + dy * dy) / 0.02)
			var v := clampf(arm + core, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, v))
	return ImageTexture.create_from_image(img)


func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _process(delta: float) -> void:
	_t += delta
	if not _done and _t >= hold_sec:
		finish()
	if settings.reduced_motion:
		return
	for e in _bubbles:
		var b: Control = e[0]
		var ph: float = _t * e[3] + e[4]
		b.position = e[1] + Vector2(sin(ph * 0.7) * e[2] * 0.4, sin(ph) * e[2])
		b.rotation = deg_to_rad(sin(ph * 0.8 + 1.0) * e[5])
	for e in _twinkles:
		var s: Control = e[0]
		var k := 0.5 + 0.5 * sin(_t * e[1] + e[2])
		s.modulate.a = e[3] * (0.15 + 0.85 * k)
		s.scale = Vector2.ONE * (0.6 + 0.5 * k)
	var phase := fmod(_t - 1.2, GLEAM_EVERY)
	if _t > 1.2 and phase < GLEAM_SEC:
		_gleam.set_shader_parameter("sweep", lerpf(-0.25, 1.35, phase / GLEAM_SEC))
	else:
		_gleam.set_shader_parameter("sweep", -1.0)
	var pulse := 0.5 + 0.5 * sin(_t * 3.4)
	var appear := clampf((_t - 1.1) / 0.5, 0.0, 1.0)
	_tap.modulate.a = appear * (0.55 + 0.45 * pulse)
	_tap.scale = Vector2.ONE * (1.0 + 0.03 * pulse)
	_tap.pivot_offset = _tap.size * 0.5


func _gui_input(event: InputEvent) -> void:
	var press := false
	if event is InputEventMouseButton:
		press = event.pressed
	elif event is InputEventScreenTouch:
		press = event.pressed
	if press:
		accept_event()
		finish()


## Ends the intro once: fades out, then emits `finished`.
func finish() -> void:
	if _done:
		return
	_done = true
	if fade_sec <= 0.0 or not is_inside_tree():
		finished.emit()
		return
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, fade_sec)
	tw.tween_callback(func() -> void: finished.emit())

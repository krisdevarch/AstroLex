extends Control
## Intro screen (WP-F.29): the first thing on launch, built from the game's own kit. The title's painted
## Low Orbit sky, an "AstroLex" wordmark in Fredoka (cream, navy outline, a soft cyan glow), and the four
## Catchers' busts under the game's glass bubbles (the title logo's `TileView`, no glyph, so the glass
## refracts over the bust). The bubbles pop in one after another and bob out of step; the standard
## orange "Tap to start" button sits low. A tap anywhere, or intro.holdSec seconds, emits `finished`
## (after a short fade). Reduced motion shows everything still at rest.

const Ui := preload("res://scenes/ui.gd")
const LightRig := preload("res://scenes/light_rig.gd")
const HudArt := preload("res://scenes/hud_art.gd")
const TileViewScene: PackedScene = preload("res://scenes/tile_view.tscn")
const GameData := preload("res://rules/game_data.gd")
const AppSettings := preload("res://scenes/app_settings.gd")

const WORDMARK := "AstroLex"
const TAGLINE := "Catch the letters. Bring the words home."
const GLOW := Color("4fe3ff")  # field.gd's NEON cyan
const OUTLINE := Color("0b1a4a")
const WORD_PX := 210
const CLEAR_GLASS := {"glass.dark": 0.0, "glass.refractPx": 0.0, "glass.blur": 0.0, "glass.magnify": 0.0, "glass.rimBend": 0.12, "glass.chroma": 0.25, "glass.milk": 0.03, "glass.frost": 0.0, "glass.film": 0.45}
## id -> [centre x share, centre y share of the view, diameter px (1080 wide), bob amplitude, bob speed, phase, suit colour]
const BUBBLES := {
	"wren": [0.27, 0.150, 380.0, 14.0, 1.15, 0.0, "#4fd8eb"],
	"juno": [0.72, 0.245, 520.0, 12.0, 0.85, 1.9, "#f2b544"],
	"ash": [0.29, 0.640, 540.0, 13.0, 0.95, 3.6, "#5fd3b0"],
	"pip": [0.75, 0.625, 380.0, 16.0, 1.30, 5.0, "#f27fb2"],
}
const ORDER := ["juno", "wren", "ash", "pip"]
const POP_START := 0.25
const POP_STEP := 0.28
const POP_SEC := 0.55

signal finished

var settings: AppSettings = AppSettings.new()
## Seconds before the intro moves on by itself (tunable intro.holdSec).
var hold_sec: float = 6.0
## Length of the fade to black when it ends; 0 emits `finished` at once.
var fade_sec: float = 0.35
var _t: float = 0.0
var _done: bool = false
var _bubbles: Array = []  # [holder, tile view, rest position, amplitude, speed, phase, index]
var _logo: Control
var _tap: Button
var _fade: ColorRect


func _ready() -> void:
	name = "IntroScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hold_sec = float(GameData.load_tunables().get("intro.holdSec", hold_sec))
	var view := get_viewport_rect().size
	Ui.add_sky(self, view, 0.3)
	_build_bubbles(view)
	_build_logo(view)
	_build_tap(view)
	_fade = ColorRect.new()
	_fade.name = "IntroFade"
	_fade.color = Color(0.01, 0.02, 0.08, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


## The bubbles live on a canvas layer under the labels, like the title's logo row: a bust, a
## glyph-less glass bubble over it, and a thin rim in the Catcher's suit colour.
func _build_bubbles(view: Vector2) -> void:
	var layer := CanvasLayer.new()
	layer.name = "IntroWorld"
	layer.layer = -1
	add_child(layer)
	# The glass refracts a screen copy taken once per frame, so every bust sits on its own layer
	# behind all the glass, or the later bubbles would look empty.
	var back := CanvasLayer.new()
	back.name = "IntroBusts"
	back.layer = -2
	add_child(back)
	var rig: Node2D = LightRig.new()
	layer.add_child(rig)
	rig.configure(Vector2(view.x * 0.5, view.y * 0.3), 1200.0, layer.layer)
	var tun := GameData.load_tunables().duplicate()
	# A clear window: the in-round bubble darkens and bends what is behind it; here the bust must read.
	for key: String in CLEAR_GLASS:
		tun[key] = CLEAR_GLASS[key]
	var k := view.x / 1080.0
	var bubble_scale := float(tun["glass.bubbleScale"])
	for n in ORDER.size():
		var id: String = ORDER[n]
		var d: Array = BUBBLES[id]
		var dia: float = float(d[2]) * k
		var holder := Node2D.new()
		holder.name = "IntroBubble_%s" % id
		layer.add_child(holder)
		var rest := Vector2(view.x * float(d[0]), view.y * float(d[1]))
		holder.position = rest
		var bust_holder := Node2D.new()
		bust_holder.name = "IntroBust_%s" % id
		bust_holder.position = rest
		back.add_child(bust_holder)
		var path := "res://art/intro/%s.png" % id
		if ResourceLoader.exists(path):
			var bust := TextureRect.new()
			bust.name = "Bust"
			bust.texture = load(path)
			bust.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bust.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			bust.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			bust.material = HudArt.clip_material()
			bust.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bust.size = Vector2(dia, dia) * 0.94
			bust.position = -bust.size * 0.5
			bust_holder.add_child(bust)
		var px := dia / bubble_scale
		var v: Node2D = TileViewScene.instantiate()
		v.name = "Glass"
		holder.add_child(v)
		v.setup("a", px, px / (float(tun["tile.size"]) * view.x), 0, "bubble", settings.reduced_motion, tun, float(n) * 1.7)
		v.glyph.visible = false
		v.place(Vector2.ZERO, 0.0, 0.5)
		var rim := Rim.new()
		rim.name = "Rim"
		rim.radius = dia * 0.5
		rim.colour = Color(str(d[6]))
		holder.add_child(rim)
		_bubbles.append([holder, v, rest, float(d[3]), float(d[4]), float(d[5]), bust_holder])
		if not settings.reduced_motion:
			_pop(0.0, holder, bust_holder)
			var tw := create_tween()
			tw.tween_interval(POP_START + POP_STEP * n)
			tw.tween_method(_pop.bind(holder, bust_holder), 0.0, 1.0, POP_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## One pop-in step for a bubble and its bust (v 0..1, overshooting with the back ease).
func _pop(v: float, holder: Node2D, bust: Node2D) -> void:
	for n: Node2D in [holder, bust]:
		n.scale = Vector2.ONE * v
		n.modulate.a = clampf(v * 4.0, 0.0, 1.0)


## A thin ring in the suit colour around a bubble.
class Rim extends Node2D:
	var radius: float = 100.0
	var colour: Color = Color.WHITE

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius * 0.985, 0.0, TAU, 96, Color(colour, 0.22), radius * 0.05, true)
		draw_arc(Vector2.ZERO, radius * 0.97, 0.0, TAU, 96, Color(colour, 0.75), maxf(3.0, radius * 0.014), true)


## The wordmark: cream Fredoka with a navy outline over a few soft cyan copies, and the tagline.
func _build_logo(view: Vector2) -> void:
	var k := view.x / 1080.0
	_logo = Control.new()
	_logo.name = "IntroLogo"
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w := view.x
	var h := WORD_PX * k * 1.3
	_logo.size = Vector2(w, h + 110.0 * k)
	_logo.position = Vector2(0.0, view.y * 0.435 - h * 0.5)
	add_child(_logo)
	var glow_levels := [[96, 0.04], [72, 0.05], [52, 0.07], [34, 0.1]]
	for g in glow_levels:
		var gl := Ui.text(WORDMARK, int(WORD_PX * k), Color(GLOW, 0.0))
		gl.add_theme_color_override("font_outline_color", Color(GLOW, float(g[1])))
		gl.add_theme_constant_override("outline_size", int(float(g[0]) * k))
		gl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		gl.size = Vector2(w, h)
		gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_logo.add_child(gl)
	var word := Ui.text(WORDMARK, int(WORD_PX * k), Ui.CREAM)
	word.name = "Wordmark"
	word.add_theme_color_override("font_outline_color", OUTLINE)
	word.add_theme_constant_override("outline_size", int(22.0 * k))
	word.add_theme_color_override("font_shadow_color", Color(0.0, 0.02, 0.1, 0.6))
	word.add_theme_constant_override("shadow_offset_y", int(10.0 * k))
	word.add_theme_constant_override("shadow_outline_size", int(22.0 * k))
	word.size = Vector2(w, h)
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.add_child(word)
	var tag := Ui.text(TAGLINE, 46, Ui.CREAM)
	tag.name = "Tagline"
	tag.position = Vector2((w - 1000.0) * 0.5, h - 10.0 * k)
	tag.size = Vector2(1000, 70)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.add_child(tag)
	if not settings.reduced_motion:
		_logo.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.1)
		tw.tween_property(_logo, "modulate:a", 1.0, 0.7)


func _build_tap(view: Vector2) -> void:
	_tap = Ui.primary("Tap to start", 62, Vector2(600, 156))
	_tap.name = "TapToStart"
	_tap.position = Vector2((view.x - 600.0) * 0.5, view.y - 380.0)
	_tap.size = Vector2(600, 156)
	_tap.pivot_offset = _tap.size * 0.5
	_tap.pressed.connect(finish)
	add_child(_tap)
	if not settings.reduced_motion:
		_tap.modulate.a = 0.0


func _process(delta: float) -> void:
	_t += delta
	if not _done and _t >= hold_sec:
		finish()
	if settings.reduced_motion:
		return
	for e in _bubbles:
		var b: Node2D = e[0]
		var ph: float = _t * e[4] + e[5]
		b.position = e[2] + Vector2(sin(ph * 0.7) * e[3] * 0.4, sin(ph) * e[3])
		b.rotation = deg_to_rad(sin(ph * 0.8 + 1.0) * 2.0)
		(e[6] as Node2D).position = b.position
		(e[6] as Node2D).rotation = b.rotation
		(e[1] as Node2D).call("place", Vector2.ZERO, _t, 0.5)
	var appear := clampf((_t - 1.1) / 0.5, 0.0, 1.0)
	_tap.modulate.a = appear
	_tap.scale = Vector2.ONE * (1.0 + 0.02 * (0.5 + 0.5 * sin(_t * 3.0)))


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

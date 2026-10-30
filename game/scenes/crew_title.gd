extends RefCounted
## The look the intro and the title share (WP-F.29): the "AstroLex" wordmark (cream Fredoka, navy
## outline, a soft cyan glow, the tagline) and the four Catchers' busts under the game's glass bubbles,
## over the painted sky. Both screens build it with the same layout numbers, so a bubble or the wordmark
## never sits in a different place on one of them. Only the lower menu area differs.

const Ui := preload("res://scenes/ui.gd")
const LightRig := preload("res://scenes/light_rig.gd")
const HudArt := preload("res://scenes/hud_art.gd")
const TileViewScene: PackedScene = preload("res://scenes/tile_view.tscn")
const GameData := preload("res://rules/game_data.gd")

const WORDMARK := "AstroLex"
const TAGLINE := "Catch the letters. Bring the words home."
const GLOW := Color("4fe3ff")  # field.gd's NEON cyan
const OUTLINE := Color("0b1a4a")
const WORD_PX := 210
const LOGO_Y := 0.405  # wordmark centre, share of the view height
const CLEAR_GLASS := {"glass.dark": 0.0, "glass.refractPx": 0.0, "glass.blur": 0.0, "glass.magnify": 0.0, "glass.rimBend": 0.12, "glass.chroma": 0.25, "glass.milk": 0.03, "glass.frost": 0.0, "glass.film": 0.45}
## id -> [centre x share, centre y share of the view, diameter px (1080 wide), bob amplitude, bob speed, phase, suit colour]
const BUBBLES := {
	"wren": [0.27, 0.130, 380.0, 14.0, 1.15, 0.0, "#4fd8eb"],
	"juno": [0.72, 0.225, 520.0, 12.0, 0.85, 1.9, "#f2b544"],
	"ash": [0.27, 0.625, 440.0, 13.0, 0.95, 3.6, "#5fd3b0"],
	"pip": [0.75, 0.600, 340.0, 16.0, 1.30, 5.0, "#f27fb2"],
}
const ORDER := ["juno", "wren", "ash", "pip"]
const POP_START := 0.25
const POP_STEP := 0.28
const POP_SEC := 0.55
## The menu area under the lower bubbles: the intro's button and the title's first button start here.
const MENU_FROM_BOTTOM := 450.0
const MENU_W := 600.0

var settings: RefCounted
## Top-left of the 1080x1920 design box (scaled by view height) inside the view; x is negative on tall
## phones, where the box is cover-fitted like the web loader's still (scripts/web/make_loading.py).
var origin: Vector2 = Vector2.ZERO
var logo: Control
## [holder, tile view, rest position, amplitude, speed, phase, bust holder]
var bubbles: Array = []


## Top of the menu area in view pixels.
static func menu_top(view: Vector2) -> float:
	return view.y - MENU_FROM_BOTTOM


## The design box in view pixels: the 1080x1920 layout scaled to the view's height. On a phone taller
## than 9:16 it is wider than the view and the sides are cropped (cover fit); on a wide view it is
## centred. Everything is placed inside it, so the web loader's still of the intro matches on any phone.
static func box_size(view: Vector2) -> Vector2:
	return Vector2(1080.0 * view.y / 1920.0, view.y)


static func box_origin(view: Vector2) -> Vector2:
	return Vector2((view.x - box_size(view).x) * 0.5, 0.0)


## Builds everything under `host`. `pop` plays the intro's pop-in and fade; otherwise all is at rest.
func build(host: Control, view: Vector2, app_settings: RefCounted, pop: bool) -> void:
	settings = app_settings
	origin = box_origin(view)
	var box := box_size(view)
	_build_bubbles(host, box, pop)
	_build_logo(host, box, pop)


## Screen-space circles of the bubbles at rest (centre, radius), for layout checks.
func rest_circles() -> Array:
	var out: Array = []
	for e in bubbles:
		out.append([e[2], float(e[7])])
	return out


## The bubbles live on a canvas layer under the labels: a bust, a glyph-less glass bubble over it, and a
## thin rim in the Catcher's suit colour.
func _build_bubbles(host: Control, view: Vector2, pop: bool) -> void:
	var layer := CanvasLayer.new()
	layer.name = "CrewWorld"
	layer.layer = -1
	host.add_child(layer)
	# The glass refracts a screen copy taken once per frame, so every bust sits on its own layer
	# behind all the glass, or the later bubbles would look empty.
	var back := CanvasLayer.new()
	back.name = "CrewBusts"
	back.layer = -2
	host.add_child(back)
	var rig: Node2D = LightRig.new()
	layer.add_child(rig)
	rig.configure(origin + Vector2(view.x * 0.5, view.y * 0.3), 1200.0, layer.layer)
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
		holder.name = "CrewBubble_%s" % id
		layer.add_child(holder)
		var rest := origin + Vector2(view.x * float(d[0]), view.y * float(d[1]))
		holder.position = rest
		var bust_holder := Node2D.new()
		bust_holder.name = "CrewBust_%s" % id
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
		bubbles.append([holder, v, rest, float(d[3]), float(d[4]), float(d[5]), bust_holder, dia * 0.5])
		if pop and not settings.reduced_motion:
			_pop(0.0, holder, bust_holder)
			var tw := host.create_tween()
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
func _build_logo(host: Control, view: Vector2, pop: bool) -> void:
	var k := view.x / 1080.0
	logo = Control.new()
	logo.name = "CrewLogo"
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w := view.x
	var h := WORD_PX * k * 1.3
	logo.size = Vector2(w, h + 110.0 * k)
	logo.position = origin + Vector2(0.0, view.y * LOGO_Y - h * 0.5)
	host.add_child(logo)
	var glow_levels := [[96, 0.04], [72, 0.05], [52, 0.07], [34, 0.1]]
	for g in glow_levels:
		var gl := Ui.text(WORDMARK, int(WORD_PX * k), Color(GLOW, 0.0))
		gl.add_theme_color_override("font_outline_color", Color(GLOW, float(g[1])))
		gl.add_theme_constant_override("outline_size", int(float(g[0]) * k))
		gl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		gl.size = Vector2(w, h)
		gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo.add_child(gl)
	var word := Ui.text(WORDMARK, int(WORD_PX * k), Ui.CREAM)
	word.name = "Wordmark"
	word.add_theme_color_override("font_outline_color", OUTLINE)
	word.add_theme_constant_override("outline_size", int(22.0 * k))
	word.add_theme_color_override("font_shadow_color", Color(0.0, 0.02, 0.1, 0.6))
	word.add_theme_constant_override("shadow_offset_y", int(10.0 * k))
	word.add_theme_constant_override("shadow_outline_size", int(22.0 * k))
	word.size = Vector2(w, h)
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.add_child(word)
	var tag := Ui.text(TAGLINE, int(46.0 * k), Ui.CREAM)
	tag.name = "Tagline"
	tag.position = Vector2((w - 1000.0 * k) * 0.5, h - 10.0 * k)
	tag.size = Vector2(1000.0 * k, 70.0 * k)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.add_child(tag)
	if pop and not settings.reduced_motion:
		logo.modulate.a = 0.0
		var tw := host.create_tween()
		tw.tween_interval(0.1)
		tw.tween_property(logo, "modulate:a", 1.0, 0.7)


## Bob the bubbles for scene time `t` (not called under reduced motion).
func bob(t: float) -> void:
	for e in bubbles:
		var b: Node2D = e[0]
		var ph: float = t * e[4] + e[5]
		b.position = e[2] + Vector2(sin(ph * 0.7) * e[3] * 0.4, sin(ph) * e[3])
		b.rotation = deg_to_rad(sin(ph * 0.8 + 1.0) * 2.0)
		(e[6] as Node2D).position = b.position
		(e[6] as Node2D).rotation = b.rotation
		(e[1] as Node2D).call("place", Vector2.ZERO, t, 0.5)

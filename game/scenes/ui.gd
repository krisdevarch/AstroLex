extends RefCounted
## The game's UI kit (WP-3.R, polish pass): one palette and one set of controls for every menu, taken
## from the game screen's HUD (owner mock v3): the slot tray's navy and slate, the teal socket
## outline, the Hint button's orange for the main action, warm cream text and gold stars. Built from
## StyleBoxFlat and _draw, no art assets.

const INK := Color(0.93, 0.95, 1.0)
const DIM := Color(0.6, 0.66, 0.8)
const ACCENT := Color(0.45, 0.8, 1.0)
const PANEL := Color(0.09, 0.12, 0.24, 0.92)

# The HUD palette (field.gd and level_card.gd use the same values).
const CREAM := Color("efe8d6")  # body text
const MUTED := Color("aab3cc")  # secondary text
const NAVY := Color(0.09, 0.12, 0.2, 0.95)  # cards and panels
const NAVY_DEEP := Color("0b1226")
const SLATE := Color("2f3b58")  # card edges
const TEAL := Color("3cbfd2")  # selection and focus
const ORANGE := Color("f7a21d")  # the main action
const ORANGE_LIGHT := Color("ffb941")
const ORANGE_RIM := Color("9c540c")
const BUTTON_INK := Color("1c2740")  # text on orange
const GOLD := Color("F8BC04")
const GOLD_LIGHT := Color("ffe27a")
const LOCKED := Color(0.5, 0.55, 0.68, 0.55)


static func box(bg: Color, radius: int = 18, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(border_w)
	s.anti_aliasing = true
	return s


## A card or panel in the HUD's navy, with a soft drop shadow.
static func card_box(edge: Color = SLATE, radius: int = 40, edge_w: int = 4, fill: Color = NAVY) -> StyleBoxFlat:
	var s := box(fill, radius, edge, edge_w)
	s.shadow_color = Color(0.0, 0.02, 0.08, 0.45)
	s.shadow_size = 18
	s.shadow_offset = Vector2(0, 8)
	return s


static func label(text: String, size: int, color: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", maxi(2, size / 10))
	return l


## Menu text: cream, no hard outline, a soft shadow so it reads on the painted sky.
static func text(t: String, size: int, color: Color = CREAM, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := label(t, size, color, align)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0.0, 0.02, 0.1, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", maxi(2, size / 18))
	l.add_theme_constant_override("shadow_outline_size", maxi(2, size / 12))
	return l


## A small caps-style section heading in muted cream, letter-spaced by hand.
static func heading(t: String, size: int = 34) -> Label:
	var l := text(t.to_upper(), size, MUTED)
	l.add_theme_constant_override("shadow_outline_size", 0)
	return l


## The old placeholder button; kept for the frame-rate bench and dev screens. Menus use primary(),
## secondary() and choice().
static func button(t: String, size: int = 44, min_size: Vector2 = Vector2(420, 110), toggle: bool = false) -> Button:
	var b := secondary(t, size, min_size)
	b.toggle_mode = toggle
	if toggle:
		_choice_styles(b, TEAL)
	return b


## The main action: an orange pill with a darker lip, dark ink text (the Hint button and Next).
static func primary(t: String, size: int = 52, min_size: Vector2 = Vector2(560, 136)) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	var r := int(min_size.y * 0.5)
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var fill := ORANGE
		var lip := 10
		match st:
			"hover":
				fill = ORANGE_LIGHT
			"pressed", "hover_pressed":
				fill = ORANGE.darkened(0.08)
				lip = 3
			"disabled":
				fill = Color(0.45, 0.42, 0.38)
		var s := box(fill, r, ORANGE_RIM, 0)
		s.border_width_bottom = lip
		s.content_margin_top = 10 - lip + 4
		if st == "focus":
			s = box(Color(0, 0, 0, 0), r, Color(1, 1, 1, 0.8), 3)
		elif st == "normal" or st == "hover":
			s.shadow_color = Color(0.97, 0.63, 0.11, 0.28)
			s.shadow_size = 22
		b.add_theme_stylebox_override(st, s)
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, BUTTON_INK)
	b.add_theme_color_override("font_disabled_color", Color(0.2, 0.2, 0.25))
	return b


## A quiet action: navy glass with a slate edge, cream text; the edge turns teal on hover.
static func secondary(t: String, size: int = 44, min_size: Vector2 = Vector2(420, 110)) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	var r := int(minf(min_size.y * 0.5, 40.0))
	b.add_theme_stylebox_override("normal", box(NAVY, r, SLATE, 4))
	b.add_theme_stylebox_override("hover", box(Color(0.12, 0.16, 0.27, 0.97), r, TEAL, 4))
	b.add_theme_stylebox_override("pressed", box(Color(0.06, 0.09, 0.16, 0.97), r, TEAL, 4))
	b.add_theme_stylebox_override("hover_pressed", box(Color(0.06, 0.09, 0.16, 0.97), r, TEAL, 4))
	b.add_theme_stylebox_override("disabled", box(Color(0.07, 0.09, 0.15, 0.7), r, Color(0.25, 0.3, 0.42, 0.6), 3))
	b.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), r, Color(1, 1, 1, 0.6), 2))
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, CREAM)
	b.add_theme_color_override("font_disabled_color", LOCKED)
	return b


## A text-only link (Map under Next, Back on a sub-screen).
static func link(t: String, size: int = 38, min_size: Vector2 = Vector2(300, 80)) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", MUTED)
	for c: String in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, CREAM)
	return b


## A toggle in a group (suit, difficulty, pronouns, settings): navy when off; when on, a lit edge
## in `accent` over a slightly lifted fill.
static func choice(t: String, size: int = 42, min_size: Vector2 = Vector2(260, 100), accent: Color = TEAL) -> Button:
	var b := secondary(t, size, min_size)
	b.toggle_mode = true
	_choice_styles(b, accent)
	return b


static func _choice_styles(b: Button, accent: Color) -> void:
	var r := int(minf(b.custom_minimum_size.y * 0.5, 40.0))
	var on := box(Color(accent.r * 0.22 + 0.06, accent.g * 0.22 + 0.08, accent.b * 0.22 + 0.14, 0.97), r, accent, 6)
	on.shadow_color = Color(accent.r, accent.g, accent.b, 0.35)
	on.shadow_size = 20
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)


## A rounded on/off switch row: label left, a pill switch right. Returns the CheckButton.
static func switch(t: String, on: bool, size: int = 42, width: float = 820.0) -> CheckButton:
	var c := CheckButton.new()
	c.text = t
	c.button_pressed = on
	c.custom_minimum_size = Vector2(width, 104)
	c.add_theme_font_size_override("font_size", size)
	for col: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		c.add_theme_color_override(col, CREAM)
	c.add_theme_stylebox_override("normal", box(NAVY, 32, SLATE, 4))
	c.add_theme_stylebox_override("hover", box(Color(0.12, 0.16, 0.27, 0.97), 32, TEAL, 4))
	c.add_theme_stylebox_override("pressed", box(NAVY, 32, SLATE, 4))
	c.add_theme_stylebox_override("hover_pressed", box(Color(0.12, 0.16, 0.27, 0.97), 32, TEAL, 4))
	c.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
		(c.get_theme_stylebox(st) as StyleBoxFlat).content_margin_left = 36
		(c.get_theme_stylebox(st) as StyleBoxFlat).content_margin_right = 30
	c.add_theme_icon_override("checked", _switch_icon(true))
	c.add_theme_icon_override("unchecked", _switch_icon(false))
	return c


static func _switch_icon(on: bool) -> Texture2D:
	var w := 112
	var h := 60
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var track := TEAL if on else Color("3a4560")
	var r := float(h) * 0.5
	var knob_x := float(w) - r if on else r
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var cx := clampf(p.x, r, float(w) - r)
			var d := p.distance_to(Vector2(cx, r))
			var col := Color(track, clampf(r + 0.5 - d, 0.0, 1.0))
			var dk := p.distance_to(Vector2(knob_x, r))
			var ka := clampf(r - 6.0 + 0.5 - dk, 0.0, 1.0)
			col = col.lerp(Color(CREAM, 1.0), ka) if ka > 0.0 else col
			if ka > 0.0:
				col.a = maxf(col.a, ka)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


## A rounded chip: icon-free label in a navy pill (map top bar, counters).
static func chip(t: String, size: int = 38, edge: Color = SLATE) -> PanelContainer:
	var p := PanelContainer.new()
	var s := box(NAVY, 40, edge, 4)
	s.content_margin_left = 30
	s.content_margin_right = 30
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", s)
	var l := text(t, size)
	l.name = "ChipLabel"
	p.add_child(l)
	return p


## The menus' sky: the act's painted backdrop at full colour, its sparkles and shooting stars, under
## a navy veil (`veil` 0..1) so cards and text read. Added on its own canvas layer behind `parent`.
static func add_sky(parent: Node, view: Vector2, veil: float = 0.45, horizon_share: float = 0.86) -> Node2D:
	var layer := CanvasLayer.new()
	layer.name = "MenuSky"
	layer.layer = -3
	parent.add_child(layer)
	var sky: Node2D = load("res://scenes/act_backdrop.gd").new()
	sky.name = "MenuBackdrop"
	sky.set("view_size", view)
	sky.set("horizon_y", view.y * horizon_share)
	sky.set("restore", 1.0)
	layer.add_child(sky)
	var v := Veil.new()
	v.name = "MenuVeil"
	v.amount = veil
	v.size = view
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(v)
	return sky


## A vertical veil: darkest at the top where titles sit, lighter over Earth's lights.
class Veil extends Control:
	var amount: float = 0.45

	func _draw() -> void:
		var top := Color(NAVY_DEEP, clampf(amount + 0.15, 0.0, 1.0))
		var mid := Color(NAVY_DEEP, amount)
		var low := Color(NAVY_DEEP, amount * 0.5)
		var h := size.y
		var w := size.x
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.55), Vector2(0, h * 0.55)]), PackedColorArray([top, top, mid, mid]))
		draw_polygon(PackedVector2Array([Vector2(0, h * 0.55), Vector2(w, h * 0.55), Vector2(w, h), Vector2(0, h)]), PackedColorArray([mid, mid, low, low]))


## A gold star (filled or an empty socket), drawn: the level card's look in miniature.
class StarIcon extends Control:
	var filled: bool = true:
		set(v):
			filled = v
			queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		var outer := _points(c, r, r * 0.48)
		if filled:
			draw_colored_polygon(_points(c + Vector2(0, r * 0.08), r, r * 0.48), Color(0.35, 0.2, 0.0, 0.5))
			draw_colored_polygon(outer, GOLD)
			draw_colored_polygon(_points(c + Vector2(-r * 0.06, -r * 0.08), r * 0.62, r * 0.3), GOLD_LIGHT)
		else:
			draw_colored_polygon(outer, Color("121826"))
			var ring := outer.duplicate()
			ring.append(outer[0])
			draw_polyline(ring, Color(0.45, 0.52, 0.7, 0.8), maxf(2.0, r * 0.1), true)

	static func _points(c: Vector2, r: float, ri: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 10:
			var a := -PI * 0.5 + TAU * float(i) / 10.0
			pts.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else ri))
		return pts


## A padlock glyph for locked levels.
class LockIcon extends Control:
	var colour: Color = LOCKED

	func _draw() -> void:
		var c := size * 0.5
		var s := minf(size.x, size.y)
		var body := Rect2(c.x - s * 0.32, c.y - s * 0.05, s * 0.64, s * 0.45)
		draw_arc(c + Vector2(0, -s * 0.05), s * 0.2, PI, TAU, 20, colour, s * 0.09, true)
		draw_rect(body, colour)
		draw_circle(c + Vector2(0, s * 0.15), s * 0.06, Color(0.05, 0.07, 0.14))

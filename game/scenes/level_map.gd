extends Control
## Level map (WP-3.R): the four acts on the painted sky, each a header card (act number, name, its
## stars out of 36) over a grid of round level badges: number, three star sockets and the level's
## name. Locked badges show a padlock; the next level to play glows orange and the map opens
## scrolled to it. A top bar holds the star total and round buttons for suit, difficulty, settings
## and the title screen.

const Ui := preload("res://scenes/ui.gd")

const ACT_TITLES := {
	"act1_low_orbit": "Act I · Low Orbit",
	"act2_nebula": "Act II · The Nebula",
	"act3_tower": "Act III · The Tower",
	"act4_core": "Act IV · Babel Core",
}
## One colour per act (design direction §9, the act palettes): orbit cyan, nebula pink, tower
## amber, core periwinkle.
const ACT_TONES := {
	"act1_low_orbit": Color("4fd8eb"),
	"act2_nebula": Color("f27fb2"),
	"act3_tower": Color("F8BC04"),
	"act4_core": Color("8f93ff"),
}
const COLUMNS := 4
const BADGE := Vector2(236, 286)
const DISC_D := 156.0
const BAR_H := 150.0

signal level_chosen(act: String, index: int)
signal character_pressed
signal difficulty_pressed
signal settings_pressed
signal back_pressed
signal daily_pressed

var dictionary: RefCounted
var save: RefCounted
var _scroll: ScrollContainer
var _focus: Control


static func stars_text(n: int) -> String:
	return "*".repeat(n) + "-".repeat(3 - n)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view := get_viewport_rect().size
	Ui.add_sky(self, view, 0.55)
	_scroll = ScrollContainer.new()
	_scroll.name = "MapScroll"
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_top = BAR_H + 20.0
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(_scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 36)
	pad.add_theme_constant_override("margin_right", 36)
	pad.add_theme_constant_override("margin_bottom", 80)
	_scroll.add_child(pad)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 26)
	pad.add_child(list)
	for act: String in dictionary.act_order():
		_add_act(list, act)
	_build_bar(view)
	_scroll_to_focus.call_deferred()


func _build_bar(view: Vector2) -> void:
	var bar := Panel.new()
	bar.name = "TopBar"
	var sb := Ui.box(Color(Ui.NAVY_DEEP, 0.82), 0)
	sb.border_color = Color(Ui.SLATE, 0.9)
	sb.border_width_bottom = 3
	bar.add_theme_stylebox_override("panel", sb)
	bar.size = Vector2(view.x, BAR_H)
	add_child(bar)
	var y := (BAR_H - 110.0) * 0.5
	var home := _round_button("BackButton", "home", Vector2(30, y))
	home.pressed.connect(func() -> void: back_pressed.emit())
	bar.add_child(home)
	var stars := Ui.chip("", 44, Color(Ui.GOLD, 0.6))
	stars.name = "StarsChip"
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 12)
	var icon := Ui.StarIcon.new()
	icon.custom_minimum_size = Vector2(56, 56)
	srow.add_child(icon)
	var total := Ui.text(str(save.total_stars()), 46, Ui.GOLD_LIGHT)
	total.name = "StarsTotal"
	srow.add_child(total)
	stars.get_child(0).queue_free()
	stars.add_child(srow)
	bar.add_child(stars)
	stars.reset_size()
	stars.position = Vector2(170, (BAR_H - 96.0) * 0.5)
	var x := view.x - 30.0 - 110.0
	for spec: Array in [["DailyButton", "signal", daily_pressed], ["SettingsButton", "settings", settings_pressed], ["DifficultyButton", "gauge", difficulty_pressed], ["CharacterButton", "suit", character_pressed]]:
		var b := _round_button(spec[0], spec[1], Vector2(x, y))
		var sig: Signal = spec[2]
		b.pressed.connect(func() -> void: sig.emit())
		bar.add_child(b)
		x -= 126.0


func _round_button(node_name: String, kind: String, pos: Vector2) -> Button:
	var b := Ui.secondary("", 30, Vector2(110, 110))
	b.name = node_name
	for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var s := (b.get_theme_stylebox(st) as StyleBoxFlat).duplicate() as StyleBoxFlat
		s.set_corner_radius_all(55)
		b.add_theme_stylebox_override(st, s)
	b.position = pos
	b.size = Vector2(110, 110)
	var ic := MapIcon.new()
	ic.kind = kind
	ic.size = b.size
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == "suit":
		ic.colour = _suit_colour()
	b.add_child(ic)
	return b


func _suit_colour() -> Color:
	var id := str(save.profile().get("character", ""))
	for c: Dictionary in dictionary.content().get("characters", []):
		if str(c["id"]) == id:
			return Color(str(c["colour"]))
	return Ui.CREAM


func _add_act(list: VBoxContainer, act: String) -> void:
	var tone: Color = ACT_TONES.get(act, Ui.TEAL)
	var lv: Array = dictionary.levels(act)
	var got := 0
	for l: Dictionary in lv:
		got += int(save.stars(act, str(l["id"])))
	var open: bool = not lv.is_empty() and bool(save.unlocked(act, 0))
	var head := PanelContainer.new()
	head.name = "ActHeader_%s" % act
	var hs := Ui.card_box(Color(tone, 0.55 if open else 0.2), 36, 4)
	hs.content_margin_left = 40
	hs.content_margin_right = 40
	hs.content_margin_top = 22
	hs.content_margin_bottom = 22
	head.add_theme_stylebox_override("panel", hs)
	list.add_child(head)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	head.add_child(row)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 0)
	row.add_child(names)
	var full := str(ACT_TITLES.get(act, act))
	var parts := full.split(" · ")
	var num := Ui.text(parts[0].to_upper(), 30, Color(tone, 0.95 if open else 0.5), HORIZONTAL_ALIGNMENT_LEFT)
	num.name = "ActNumber"
	names.add_child(num)
	var t := Ui.text(parts[parts.size() - 1], 58, Ui.CREAM if open else Ui.LOCKED, HORIZONTAL_ALIGNMENT_LEFT)
	t.name = "ActTitle_%s" % act
	t.set_meta("full_title", full)
	names.add_child(t)
	var tally := HBoxContainer.new()
	tally.add_theme_constant_override("separation", 10)
	tally.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(tally)
	var st := Ui.StarIcon.new()
	st.custom_minimum_size = Vector2(46, 46)
	st.filled = got > 0
	st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tally.add_child(st)
	var tl := Ui.text("%d / %d" % [got, lv.size() * 3], 38, Ui.CREAM if got > 0 else Ui.MUTED)
	tl.name = "ActStars"
	tally.add_child(tl)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	list.add_child(grid)
	for i in lv.size():
		grid.add_child(_level_button(act, i, lv[i], tone))


func _level_button(act: String, i: int, level: Dictionary, tone: Color) -> Button:
	var id := str(level["id"])
	var open: bool = save.unlocked(act, i)
	var n: int = save.stars(act, id)
	var b := Button.new()
	b.name = "Level_%s" % id
	b.custom_minimum_size = BADGE
	b.disabled = not open
	b.set_meta("stars", n)
	b.tooltip_text = "%s %s" % [id, stars_text(n) if n > 0 else ("new" if open else "locked")]
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var is_next: bool = open and n == 0 and _focus == null
	if is_next:
		_focus = b
	var badge := Badge.new()
	badge.name = "Badge"
	badge.number = int(id.split("-")[1])
	badge.tone = tone
	badge.state = "locked" if not open else ("next" if is_next else ("won" if n > 0 else "open"))
	badge.size = Vector2(DISC_D, DISC_D)
	badge.position = Vector2((BADGE.x - DISC_D) * 0.5, 12)
	b.add_child(badge)
	b.button_down.connect(func() -> void: badge.scale = Vector2.ONE * 0.94)
	b.button_up.connect(func() -> void: badge.scale = Vector2.ONE)
	badge.pivot_offset = badge.size * 0.5
	var srow := HBoxContainer.new()
	srow.name = "Stars"
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_theme_constant_override("separation", 4)
	srow.position = Vector2(0, DISC_D + 18.0)
	srow.size = Vector2(BADGE.x, 40)
	b.add_child(srow)
	if open:
		for k in 3:
			var s := Ui.StarIcon.new()
			s.filled = k < n
			s.custom_minimum_size = Vector2(38, 38)
			srow.add_child(s)
		var t := Ui.text(str(level.get("title", "")), 26, Ui.CREAM if n > 0 or is_next else Ui.MUTED)
		t.name = "LevelTitle"
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		t.position = Vector2(8, DISC_D + 62.0)
		t.size = Vector2(BADGE.x - 16.0, 70)
		b.add_child(t)
	for ch in b.get_children():
		if ch is Control:
			(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.pressed.connect(func() -> void:
		if save.unlocked(act, i):
			level_chosen.emit(act, i))
	return b


func _scroll_to_focus() -> void:
	if _focus == null or _scroll == null or not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_instance_valid(_focus):
		return
	var y := _focus.global_position.y - _scroll.global_position.y + _scroll.scroll_vertical
	_scroll.scroll_vertical = int(maxf(0.0, y - _scroll.size.y * 0.35))


## A round level badge: a disc in the act's colour (won), navy with an act-coloured ring (open), an
## orange glow and ring (the next level), or dim with a padlock (locked). The level number in the
## middle.
class Badge extends Control:
	var number: int = 1
	var tone: Color = Color.WHITE
	var state: String = "open"
	var _t: float = 0.0

	func _process(delta: float) -> void:
		if state == "next":
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 8.0
		var font := ThemeDB.fallback_font
		match state:
			"locked":
				draw_circle(c, r, Color(0.06, 0.08, 0.14, 0.75))
				draw_arc(c, r, 0.0, TAU, 48, Color(0.35, 0.4, 0.55, 0.5), 4.0, true)
				_lock(c, r * 0.9)
				return
			"won":
				draw_circle(c + Vector2(0, 6), r, Color(0, 0, 0, 0.35))
				draw_circle(c, r, tone.darkened(0.15))
				draw_circle(c + Vector2(0, -r * 0.08), r * 0.86, tone)
				draw_arc(c, r * 0.72, PI * 1.15, PI * 1.6, 16, Color(1, 1, 1, 0.45), 6.0, true)
			"next":
				var pulse := 0.5 + 0.5 * sin(_t * 3.0)
				for i in 6:
					draw_circle(c, r + 4.0 + float(i) * 3.0 * (0.6 + pulse * 0.4), Color(Ui.ORANGE, 0.06))
				draw_circle(c + Vector2(0, 6), r, Color(0, 0, 0, 0.35))
				draw_circle(c, r, Ui.ORANGE_RIM)
				draw_circle(c + Vector2(0, -5), r - 3.0, Ui.ORANGE)
				draw_arc(c, r * 0.72, PI * 1.15, PI * 1.6, 16, Color(1, 1, 1, 0.45), 6.0, true)
			_:
				draw_circle(c + Vector2(0, 6), r, Color(0, 0, 0, 0.35))
				draw_circle(c, r, Color("121826"))
				draw_arc(c, r - 3.0, 0.0, TAU, 48, Color(tone, 0.85), 6.0, true)
		var ink := Ui.BUTTON_INK if state != "open" else Ui.CREAM
		var s := str(number)
		var fs := int(r * 0.95)
		var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var asc := font.get_ascent(fs)
		var desc := font.get_descent(fs)
		draw_string(font, c + Vector2(-w * 0.5, (asc - desc) * 0.5 - (5.0 if state == "next" else 0.0)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)

	func _lock(c: Vector2, s: float) -> void:
		var col := Color(0.55, 0.6, 0.75, 0.7)
		draw_arc(c + Vector2(0, -s * 0.1), s * 0.24, PI, TAU, 20, col, s * 0.09, true)
		draw_line(c + Vector2(-s * 0.24, -s * 0.1), c + Vector2(-s * 0.24, s * 0.02), col, s * 0.09)
		draw_line(c + Vector2(s * 0.24, -s * 0.1), c + Vector2(s * 0.24, s * 0.02), col, s * 0.09)
		var body := Rect2(c.x - s * 0.36, c.y, s * 0.72, s * 0.5)
		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		sb.set_corner_radius_all(int(s * 0.1))
		draw_style_box(sb, body)
		draw_circle(c + Vector2(0, s * 0.22), s * 0.07, Color(0.06, 0.08, 0.14))


## Small line icons for the map's round buttons: home, gauge (difficulty), suit (a helmet in the
## Catcher's colour) and the HUD's settings gear.
class MapIcon extends Control:
	var kind: String = "home"
	var colour: Color = Color("efe8d6")

	func _draw() -> void:
		var c := size * 0.5
		var col := colour
		match kind:
			"home":
				var roof := PackedVector2Array([c + Vector2(-28, -2), c + Vector2(0, -28), c + Vector2(28, -2)])
				draw_polyline(roof, col, 7.0, true)
				draw_rect(Rect2(c.x - 19, c.y - 4, 38, 30), col, false, 7.0)
				draw_rect(Rect2(c.x - 6, c.y + 8, 12, 18), col)
			"gauge":
				draw_arc(c + Vector2(0, 10), 28.0, PI, TAU, 24, col, 7.0, true)
				draw_line(c + Vector2(0, 10), c + Vector2(15, -10), col, 7.0, true)
				draw_circle(c + Vector2(0, 10), 7.0, col)
			"suit":
				draw_circle(c, 30.0, col)
				var visor := StyleBoxFlat.new()
				visor.bg_color = Color("1b2333")
				visor.set_corner_radius_all(12)
				draw_style_box(visor, Rect2(c.x - 21, c.y - 13, 42, 26))
				draw_arc(c + Vector2(-6, -2), 8.0, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.6), 4.0, true)
			"signal":
				draw_circle(c + Vector2(0, 14), 6.0, col)
				for k in 3:
					draw_arc(c + Vector2(0, 14), 14.0 + 11.0 * k, PI * 1.2, PI * 1.8, 12, col, 6.0, true)
			"settings":
				draw_arc(c, 18.0, 0.0, TAU, 32, col, 6.0, true)
				draw_arc(c, 6.0, 0.0, TAU, 20, col, 5.0, true)
				for i in 8:
					var d := Vector2.from_angle(TAU * float(i) / 8.0)
					draw_line(c + d * 20.0, c + d * 30.0, col, 9.0)

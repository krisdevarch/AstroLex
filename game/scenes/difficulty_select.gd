extends Control
## Pick Easy / Normal / Hard (WP-3.R): three cards, each with a gauge of one to three bars, the name
## and what changes; Normal carries a "Recommended" tag. Confirm saves the choice (main does that).

const Ui := preload("res://scenes/ui.gd")

const CARD := Vector2(900, 200)
## Gauge colour per difficulty: teal, gold, coral.
const TONES := {"easy": Color("5fd3b0"), "normal": Color("F8BC04"), "hard": Color("FF6B35")}

signal confirmed(difficulty_id: String)
signal cancelled

## content.json difficulty.levels: [{id, label, blurb, mod}].
var options: Array = []
var selected: String = ""
var can_cancel: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Ui.add_sky(self, get_viewport_rect().size, 0.62)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	centre.add_child(box)
	box.add_child(Ui.heading("Mission settings"))
	var title := Ui.text("Choose difficulty", 84)
	title.name = "DifficultyTitle"
	box.add_child(title)
	var sub := Ui.text("You can change it any time from the map.", 34, Ui.MUTED)
	box.add_child(sub)
	var group := ButtonGroup.new()
	for i in options.size():
		box.add_child(_card(options[i], i, group))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	if can_cancel:
		var back := Ui.secondary("Back", 44, Vector2(300, 136))
		back.name = "BackButton"
		back.pressed.connect(func() -> void: cancelled.emit())
		row.add_child(back)
	var ok := Ui.primary("Launch" if not can_cancel else "Save", 56, Vector2(560 if not can_cancel else 460, 136))
	ok.name = "ConfirmButton"
	ok.pressed.connect(func() -> void: confirmed.emit(selected))
	row.add_child(ok)


func _card(o: Dictionary, index: int, group: ButtonGroup) -> Button:
	var id := str(o["id"])
	var tone: Color = TONES.get(id, Ui.TEAL)
	var b := Ui.choice("", 34, CARD, tone)
	b.name = "Difficulty_%s" % id
	b.button_group = group
	b.button_pressed = id == selected
	b.pressed.connect(func() -> void: selected = id)
	var g := Gauge.new()
	g.name = "Gauge"
	g.bars = index + 1
	g.tone = tone
	g.size = Vector2(110, 110)
	g.position = Vector2(46, (CARD.y - 110.0) * 0.5)
	b.add_child(g)
	var nm := Ui.text(str(o["label"]), 56, Ui.CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	nm.name = "Label"
	nm.position = Vector2(190, 30)
	nm.size = Vector2(500, 70)
	b.add_child(nm)
	var bl := Ui.text(str(o["blurb"]), 31, Ui.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	bl.name = "Blurb"
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	bl.position = Vector2(190, 102)
	bl.size = Vector2(CARD.x - 230.0, 84)
	b.add_child(bl)
	if id == "normal":
		var tag := Ui.chip("Recommended", 26, Color(tone, 0.8))
		tag.name = "RecommendedTag"
		b.add_child(tag)
		tag.reset_size()
		tag.position = Vector2(CARD.x - tag.size.x - 34.0, 34)
	for ch in b.get_children():
		if ch is Control:
			(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## One to three rising bars in the difficulty's tone, the rest as empty sockets.
class Gauge extends Control:
	var bars: int = 1
	var tone: Color = Color.WHITE

	func _draw() -> void:
		var w := size.x / 3.0
		for i in 3:
			var h := size.y * (0.45 + 0.275 * float(i))
			var r := Rect2(i * w + w * 0.14, size.y - h, w * 0.72, h)
			var sb := StyleBoxFlat.new()
			sb.set_corner_radius_all(int(w * 0.3))
			sb.bg_color = tone if i < bars else Color("121826")
			sb.border_color = tone.darkened(0.35) if i < bars else Color(0.4, 0.47, 0.65, 0.7)
			sb.set_border_width_all(3)
			draw_style_box(sb, r)

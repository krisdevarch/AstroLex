extends Control
## Tomas's inbox (WP-F.5): a chat-style list, one coral bubble per act, oldest first. A message reads
## with blanks until its act is complete, then in full with the filled words in coral. The prologue
## entry shows a pulsing typing mark until Act I's first level is won. Opening the inbox marks the
## completed acts' messages read.

const Ui := preload("res://scenes/ui.gd")
const CrewArt := preload("res://scenes/crew_art.gd")
const StoryData := preload("res://rules/story_data.gd")

const CORAL := Color("ff7f6e")

signal closed

var save: RefCounted
var dictionary: RefCounted
var show_sky: bool = true
var reduced_motion: bool = false
var _typing: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if show_sky:
		Ui.add_sky(self, get_viewport_rect().size, 0.66)
	var done := StoryData.completed_acts(save, dictionary)
	var order: Array = dictionary.act_order()
	var first_won: bool = not order.is_empty() and save.has_progress(str(order[0]))
	var catcher := str(save.profile().get("name", ""))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	margin.add_child(col)
	var title := Ui.text("Messages", 80)
	title.name = "InboxTitle"
	col.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.name = "InboxScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 24)
	scroll.add_child(list)
	for m: Dictionary in StoryData.tomas():
		var a: Variant = m.get("act")
		if a is String:  # the prologue
			list.add_child(_bubble("Message_prologue", m, first_won, "", true))
		else:
			var n := int(a)
			list.add_child(_bubble("Message_%d" % n, m, done >= n, catcher, false))
	save.set_inbox_read(maxi(save.inbox_read(), done))
	var back := Ui.primary("Back", 52, Vector2(560, 120))
	back.name = "BackButton"
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: closed.emit())
	col.add_child(back)


func _process(_delta: float) -> void:
	if _typing != null:
		var t := Time.get_ticks_msec() / 1000.0
		_typing.modulate.a = 1.0 if reduced_motion else 0.45 + 0.55 * (0.5 + 0.5 * sin(t * 4.0))


func _bubble(node_name: String, m: Dictionary, full: bool, catcher: String, prologue: bool) -> Control:
	var row := HBoxContainer.new()
	row.name = node_name
	row.add_theme_constant_override("separation", 20)
	var art := CrewArt.new()
	art.who = "tomas"
	art.colour = CORAL
	art.custom_minimum_size = Vector2(110, 110)
	art.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(art)
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := Ui.card_box(CORAL, 32, 4, Color(CORAL.r * 0.3, CORAL.g * 0.2, CORAL.b * 0.22, 0.92))
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	bubble.add_theme_stylebox_override("panel", sb)
	row.add_child(bubble)
	if prologue:
		var dots := Ui.text("…", 64, CORAL, HORIZONTAL_ALIGNMENT_LEFT)
		dots.name = "Text" if full else "Typing"
		if not full:
			_typing = dots
		bubble.add_child(dots)
		return row
	var rt := RichTextLabel.new()
	rt.name = "Text"
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.custom_minimum_size = Vector2(1, 0)
	rt.add_theme_font_size_override("normal_font_size", 40)
	rt.add_theme_color_override("default_color", Ui.CREAM)
	if full:
		rt.text = StoryData.filled_bbcode(m, catcher, "#" + CORAL.to_html(false))
		rt.set_meta("state", "full")
	else:
		rt.text = str(m.get("text_blank", "")).replace("[", "[lb]")
		rt.set_meta("state", "blank")
	bubble.add_child(rt)
	return row

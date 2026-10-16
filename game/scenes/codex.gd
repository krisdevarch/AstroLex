extends Control
## Rhee's Codex (WP-F.5): a scrolling list of the 48 level notes grouped by act. A won level's card
## shows the word in big cream letters, Rhee's note and her amber portrait; an unwon level shows
## "???" and its title. The header counts the words filed.

const Ui := preload("res://scenes/ui.gd")
const CrewArt := preload("res://scenes/crew_art.gd")
const StoryData := preload("res://rules/story_data.gd")
const LevelMap := preload("res://scenes/level_map.gd")

signal closed

var save: RefCounted
var dictionary: RefCounted
var show_sky: bool = true
var filed: int = 0
var total: int = 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if show_sky:
		Ui.add_sky(self, get_viewport_rect().size, 0.66)
	var notes: Dictionary = StoryData.codex()
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
	var title := Ui.text("Rhee's Codex", 80)
	title.name = "CodexTitle"
	col.add_child(title)
	var counter := Ui.text("", 44, Ui.ORANGE_LIGHT)
	counter.name = "CodexCounter"
	col.add_child(counter)
	var scroll := ScrollContainer.new()
	scroll.name = "CodexScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)
	for a: String in dictionary.act_order():
		var h := Ui.heading(str(LevelMap.ACT_TITLES.get(a, a)), 34)
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		list.add_child(h)
		for lv: Dictionary in dictionary.levels(a):
			var id := str(lv["id"])
			total += 1
			var won: bool = save.stars(a, id) > 0 and notes.has(id)
			if won:
				filed += 1
			list.add_child(_card(id, str(lv.get("title", id)), notes.get(id, {}), won))
	counter.text = "%d / %d words filed" % [filed, total]
	var back := Ui.primary("Back", 52, Vector2(560, 120))
	back.name = "BackButton"
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: closed.emit())
	col.add_child(back)


func _card(id: String, level_title: String, note: Dictionary, won: bool) -> Control:
	var card := PanelContainer.new()
	card.name = ("Note_%s" if won else "Locked_%s") % id
	var sb := Ui.card_box(Ui.ORANGE_RIM if won else Ui.SLATE, 28, 4, Ui.NAVY if won else Color(Ui.NAVY, 0.6))
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	card.add_child(row)
	var art := CrewArt.new()
	art.who = "rhee" if won else "plain"
	art.colour = Ui.ORANGE if won else Ui.LOCKED
	art.custom_minimum_size = Vector2(130, 130)
	art.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(art)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	row.add_child(col)
	var word := Ui.text(str(note.get("word", "")).to_upper() if won else "???", 72 if won else 60, Ui.CREAM if won else Ui.LOCKED, HORIZONTAL_ALIGNMENT_LEFT)
	word.name = "Word"
	col.add_child(word)
	var body := Ui.text(str(note.get("text", "")) if won else "%s  ·  %s" % [id, level_title], 32, Ui.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	body.name = "Note"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(1, 0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	return card

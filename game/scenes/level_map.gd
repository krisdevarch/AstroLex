extends Control
## Level map: four acts of 12 levels. Locked, open, or won with 1 to 3 stars.

const Ui := preload("res://scenes/ui.gd")

const ACT_TITLES := {
	"act1_low_orbit": "Act I · Low Orbit",
	"act2_nebula": "Act II · The Nebula",
	"act3_tower": "Act III · The Tower",
	"act4_core": "Act IV · Babel Core",
}
const COLUMNS := 4

signal level_chosen(act: String, index: int)
signal character_pressed
signal difficulty_pressed
signal settings_pressed
signal back_pressed

var dictionary: RefCounted
var save: RefCounted


static func stars_text(n: int) -> String:
	return "*".repeat(n) + "-".repeat(3 - n)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 30
	outer.offset_right = -30
	outer.offset_top = 40
	outer.offset_bottom = -30
	outer.add_theme_constant_override("separation", 16)
	add_child(outer)
	var head := Ui.label("Stars  %d" % save.total_stars(), 64)
	head.name = "StarsTotal"
	outer.add_child(head)
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 12)
	outer.add_child(bar)
	for spec: Array in [["CharacterButton", "Suit", character_pressed], ["DifficultyButton", "Difficulty", difficulty_pressed], ["SettingsButton", "Settings", settings_pressed], ["BackButton", "Title", back_pressed]]:
		var b := Ui.button(spec[1], 34, Vector2(240, 90))
		b.name = spec[0]
		var sig: Signal = spec[2]
		b.pressed.connect(func() -> void: sig.emit())
		bar.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.name = "MapScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)
	for act: String in dictionary.act_order():
		var t := Ui.label(str(ACT_TITLES.get(act, act)), 54, Ui.ACCENT)
		t.name = "ActTitle_%s" % act
		list.add_child(t)
		var grid := GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		list.add_child(grid)
		var lv: Array = dictionary.levels(act)
		for i in lv.size():
			grid.add_child(_level_button(act, i, str((lv[i] as Dictionary)["id"])))


func _level_button(act: String, i: int, id: String) -> Button:
	var open: bool = save.unlocked(act, i)
	var n: int = save.stars(act, id)
	var sub := "locked" if not open else (stars_text(n) if n > 0 else "new")
	var b := Ui.button("%s\n%s" % [id, sub], 36, Vector2(240, 130))
	b.name = "Level_%s" % id
	b.disabled = not open
	b.pressed.connect(func() -> void:
		if save.unlocked(act, i):
			level_chosen.emit(act, i))
	return b

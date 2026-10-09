extends Control
## Pick Easy / Normal / Hard. Confirm saves the choice (main does that).

const Ui := preload("res://scenes/ui.gd")

signal confirmed(difficulty_id: String)
signal cancelled

## content.json difficulty.levels: [{id, label, blurb, mod}].
var options: Array = []
var selected: String = ""
var can_cancel: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	centre.add_child(box)
	var title := Ui.label("Choose difficulty", 90)
	title.name = "DifficultyTitle"
	box.add_child(title)
	var group := ButtonGroup.new()
	for o: Dictionary in options:
		var b := Ui.button("%s\n%s" % [o["label"], o["blurb"]], 38, Vector2(880, 190), true)
		b.name = "Difficulty_%s" % o["id"]
		b.button_group = group
		b.button_pressed = str(o["id"]) == selected
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func() -> void: selected = str(o["id"]))
		box.add_child(b)
	var ok := Ui.button("Confirm", 54, Vector2(560, 130))
	ok.name = "ConfirmButton"
	ok.pressed.connect(func() -> void: confirmed.emit(selected))
	box.add_child(ok)
	if can_cancel:
		var back := Ui.button("Back", 42, Vector2(560, 100))
		back.name = "BackButton"
		back.pressed.connect(func() -> void: cancelled.emit())
		box.add_child(back)

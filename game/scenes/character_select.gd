extends Control
## Pick a suit (colour, name, perk) and a pronoun. Confirm saves the choice (main does that).

const Ui := preload("res://scenes/ui.gd")

const PRONOUNS := ["they", "she", "he"]

signal confirmed(character_id: String, pronouns: String)
signal cancelled

## content.json "characters": [{id, name, colour, perk, mod}].
var characters: Array = []
var selected: String = ""
var pronouns: String = "they"
## Shows a Back button (when changing from the map or settings).
var can_cancel: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if selected == "" and not characters.is_empty():
		selected = str((characters[0] as Dictionary)["id"])
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	centre.add_child(box)
	var title := Ui.label("Choose your suit", 90)
	title.name = "CharacterTitle"
	box.add_child(title)
	var group := ButtonGroup.new()
	for c: Dictionary in characters:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var sw := ColorRect.new()
		sw.name = "Swatch_%s" % c["id"]
		sw.color = Color(str(c["colour"]))
		sw.custom_minimum_size = Vector2(70, 170)
		row.add_child(sw)
		var b := Ui.button("%s\n%s" % [c["name"], c["perk"]], 34, Vector2(820, 170), true)
		b.name = "Character_%s" % c["id"]
		b.button_group = group
		b.button_pressed = str(c["id"]) == selected
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func() -> void: selected = str(c["id"]))
		row.add_child(b)
		box.add_child(row)
	box.add_child(Ui.label("Pronouns", 40, Ui.DIM))
	var prow := HBoxContainer.new()
	prow.alignment = BoxContainer.ALIGNMENT_CENTER
	prow.add_theme_constant_override("separation", 12)
	box.add_child(prow)
	var pgroup := ButtonGroup.new()
	for p: String in PRONOUNS:
		var pb := Ui.button(p, 42, Vector2(260, 100), true)
		pb.name = "Pronoun_%s" % p
		pb.button_group = pgroup
		pb.button_pressed = pronouns == p
		pb.pressed.connect(func() -> void: pronouns = p)
		prow.add_child(pb)
	var ok := Ui.button("Confirm", 54, Vector2(560, 130))
	ok.name = "ConfirmButton"
	ok.pressed.connect(func() -> void: confirmed.emit(selected, pronouns))
	box.add_child(ok)
	if can_cancel:
		var back := Ui.button("Back", 42, Vector2(560, 100))
		back.name = "BackButton"
		back.pressed.connect(func() -> void: cancelled.emit())
		box.add_child(back)

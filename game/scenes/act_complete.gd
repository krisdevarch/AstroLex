extends Control
## After the last level of an act. With final = true it is the end of the beta.

const Ui := preload("res://scenes/ui.gd")

signal next_act
signal back_to_map

var title_text: String = "Act complete"
var total_stars: int = 0
var final: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 30)
	centre.add_child(box)
	var t := Ui.label("Beta complete" if final else title_text, 100, Ui.ACCENT)
	t.name = "CompleteTitle"
	box.add_child(t)
	if final:
		var msg := Ui.label("You restored every word in the beta. Story, art and music are on the way.", 48)
		msg.name = "BetaMessage"
		msg.custom_minimum_size = Vector2(880, 220)
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(msg)
	var s := Ui.label("Total stars  %d" % total_stars, 64)
	s.name = "TotalStars"
	box.add_child(s)
	if not final:
		var n := Ui.button("Next act", 56, Vector2(560, 140))
		n.name = "NextActButton"
		n.pressed.connect(func() -> void: next_act.emit())
		box.add_child(n)
	var m := Ui.button("Back to map", 52, Vector2(560, 130))
	m.name = "MapButton"
	m.pressed.connect(func() -> void: back_to_map.emit())
	box.add_child(m)

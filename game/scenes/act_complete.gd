extends Control
## After the last level of an act (WP-3.R look: a navy card on the painted sky, a gold star count,
## Next act in the main-action orange). With final = true it is the end of the beta.

const Ui := preload("res://scenes/ui.gd")

signal next_act
signal back_to_map

var title_text: String = "Act complete"
var total_stars: int = 0
var final: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Ui.add_sky(self, get_viewport_rect().size, 0.4)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var card := PanelContainer.new()
	card.name = "CompleteCard"
	var sb := Ui.card_box()
	sb.content_margin_left = 64
	sb.content_margin_right = 64
	sb.content_margin_top = 60
	sb.content_margin_bottom = 56
	card.add_theme_stylebox_override("panel", sb)
	centre.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	card.add_child(box)
	box.add_child(Ui.heading("Sector restored" if not final else "Signal restored"))
	var t := Ui.text("Beta complete" if final else title_text, 90, Ui.CREAM)
	t.name = "CompleteTitle"
	box.add_child(t)
	if final:
		var msg := Ui.text("You restored every word in the beta. Story, art and music are on the way.", 40, Ui.MUTED)
		msg.name = "BetaMessage"
		msg.custom_minimum_size = Vector2(800, 150)
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(msg)
	var srow := HBoxContainer.new()
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_theme_constant_override("separation", 18)
	box.add_child(srow)
	var star := Ui.StarIcon.new()
	star.custom_minimum_size = Vector2(96, 96)
	srow.add_child(star)
	var s := Ui.text("Total stars  %d" % total_stars, 60, Ui.GOLD_LIGHT)
	s.name = "TotalStars"
	srow.add_child(s)
	if not final:
		var n := Ui.primary("Next act", 56, Vector2(640, 140))
		n.name = "NextActButton"
		n.pressed.connect(func() -> void: next_act.emit())
		box.add_child(n)
	var m := Ui.secondary("Back to map", 46, Vector2(640, 118))
	m.name = "MapButton"
	m.pressed.connect(func() -> void: back_to_map.emit())
	box.add_child(m)

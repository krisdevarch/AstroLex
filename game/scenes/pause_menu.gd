extends Control
## Overlay on the field: Resume, Restart level, Quit to map (WP-3.R look: a navy card on a dimmed
## field, Resume in the main-action orange). Main pauses the field around it.

const Ui := preload("res://scenes/ui.gd")

signal resumed
signal restarted
signal quit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var card := PanelContainer.new()
	card.name = "PauseCard"
	var sb := Ui.card_box()
	sb.content_margin_left = 70
	sb.content_margin_right = 70
	sb.content_margin_top = 56
	sb.content_margin_bottom = 56
	card.add_theme_stylebox_override("panel", sb)
	centre.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	card.add_child(box)
	var title := Ui.text("Paused", 96)
	title.name = "PauseTitle"
	box.add_child(title)
	box.add_child(Ui.text("The clock is holding.", 36, Ui.MUTED))
	var resume := Ui.primary("Resume", 56, Vector2(620, 140))
	resume.name = "ResumeButton"
	resume.pressed.connect(func() -> void: resumed.emit())
	box.add_child(resume)
	for spec: Array in [["RestartButton", "Restart level", restarted], ["QuitButton", "Quit to map", quit]]:
		var b := Ui.secondary(spec[1], 46, Vector2(620, 118))
		b.name = spec[0]
		var sig: Signal = spec[2]
		b.pressed.connect(func() -> void: sig.emit())
		box.add_child(b)

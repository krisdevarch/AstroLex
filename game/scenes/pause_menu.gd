extends Control
## Overlay on the field: Resume, Restart level, Quit to map. Main pauses the field around it.

const Ui := preload("res://scenes/ui.gd")

signal resumed
signal restarted
signal quit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	centre.add_child(box)
	var title := Ui.label("Paused", 110)
	title.name = "PauseTitle"
	box.add_child(title)
	for spec: Array in [["ResumeButton", "Resume", resumed], ["RestartButton", "Restart level", restarted], ["QuitButton", "Quit to map", quit]]:
		var b := Ui.button(spec[1], 52, Vector2(640, 130))
		b.name = spec[0]
		var sig: Signal = spec[2]
		b.pressed.connect(func() -> void: sig.emit())
		box.add_child(b)

extends Control
## Settings: tile treatment (flat / tilt / bevel) and reduced motion. Saves on every change.

const Ui := preload("res://scenes/ui.gd")
const AppSettings := preload("res://scenes/app_settings.gd")

signal closed

var settings: AppSettings = AppSettings.new()
var save_path: String = AppSettings.PATH


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 30)
	centre.add_child(box)
	var title := Ui.label("Settings", 96)
	title.name = "SettingsTitle"
	box.add_child(title)
	box.add_child(Ui.label("Tile look", 40, Ui.DIM))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var group := ButtonGroup.new()
	for t in AppSettings.TREATMENTS:
		var b := Ui.button(t.capitalize(), 42, Vector2(250, 110), true)
		b.name = "Treatment_%s" % t
		b.button_group = group
		b.button_pressed = settings.treatment == t
		b.pressed.connect(_set_treatment.bind(t))
		row.add_child(b)
	var rm := CheckButton.new()
	rm.name = "ReducedMotion"
	rm.text = "Reduced motion"
	rm.add_theme_font_size_override("font_size", 44)
	rm.button_pressed = settings.reduced_motion
	rm.custom_minimum_size = Vector2(760, 110)
	rm.toggled.connect(_set_reduced)
	box.add_child(rm)
	box.add_child(Ui.label("Tilt, sway and particles turn off.", 30, Ui.DIM))
	box.add_child(Ui.label("Hint", 40, Ui.DIM))
	var hrow := VBoxContainer.new()
	hrow.add_theme_constant_override("separation", 12)
	box.add_child(hrow)
	var hgroup := ButtonGroup.new()
	for h in AppSettings.HINTS:
		var hb := Ui.button(str(AppSettings.HINT_LABELS[h]), 40, Vector2(760, 100), true)
		hb.name = "Hint_%s" % h
		hb.button_group = hgroup
		hb.button_pressed = settings.hint == h
		hb.pressed.connect(_set_hint.bind(h))
		hrow.add_child(hb)
	var back := Ui.button("Back", 48, Vector2(460, 120))
	back.name = "BackButton"
	back.pressed.connect(func() -> void: closed.emit())
	box.add_child(back)


func _set_treatment(t: String) -> void:
	settings.treatment = t
	settings.save_to(save_path)


func _set_hint(h: String) -> void:
	settings.hint = h
	settings.save_to(save_path)


func _set_reduced(on: bool) -> void:
	settings.reduced_motion = on
	settings.save_to(save_path)

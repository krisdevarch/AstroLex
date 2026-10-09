extends Control
## Settings: tile treatment (bubble / glass) and reduced motion. Saves on every change.

const Ui := preload("res://scenes/ui.gd")
const AppSettings := preload("res://scenes/app_settings.gd")

signal closed
## The player asked for the frame-rate bench.
signal bench_pressed
## Change-entry buttons (shown when a save is set).
signal character_pressed
signal difficulty_pressed

var settings: AppSettings = AppSettings.new()
var save_path: String = AppSettings.PATH
## Progress save (services/save.gd); null hides Reset progress.
var save: RefCounted
var _confirm: HBoxContainer
var _reset_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	centre.add_child(box)
	var title := Ui.label("Settings", 96)
	title.name = "SettingsTitle"
	box.add_child(title)
	box.add_child(Ui.label("Tile look", 40, Ui.DIM))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var group := ButtonGroup.new()
	for t in AppSettings.TREATMENTS:
		var b := Ui.button(t.capitalize(), 42, Vector2(300, 110), true)
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
	var fps := CheckButton.new()
	fps.name = "ShowFps"
	fps.text = "Show frame rate"
	fps.add_theme_font_size_override("font_size", 44)
	fps.button_pressed = settings.show_fps
	fps.custom_minimum_size = Vector2(760, 110)
	fps.toggled.connect(_set_fps)
	box.add_child(fps)
	var bench := Ui.button("Frame-rate test", 42, Vector2(760, 100))
	bench.name = "BenchButton"
	bench.pressed.connect(func() -> void: bench_pressed.emit())
	box.add_child(bench)
	if save != null:
		var ch := Ui.button("Change character", 42, Vector2(760, 100))
		ch.name = "ChangeCharacterButton"
		ch.pressed.connect(func() -> void: character_pressed.emit())
		box.add_child(ch)
		var df := Ui.button("Change difficulty", 42, Vector2(760, 100))
		df.name = "ChangeDifficultyButton"
		df.pressed.connect(func() -> void: difficulty_pressed.emit())
		box.add_child(df)
		_reset_btn = Ui.button("Reset progress", 42, Vector2(760, 100))
		_reset_btn.name = "ResetButton"
		_reset_btn.pressed.connect(_ask_reset)
		box.add_child(_reset_btn)
		_confirm = HBoxContainer.new()
		_confirm.name = "ResetConfirm"
		_confirm.alignment = BoxContainer.ALIGNMENT_CENTER
		_confirm.add_theme_constant_override("separation", 16)
		_confirm.visible = false
		var q := Ui.label("Reset all progress?", 40)
		q.name = "ResetQuestion"
		_confirm.add_child(q)
		var yes := Ui.button("Yes", 42, Vector2(180, 100))
		yes.name = "ResetYes"
		yes.pressed.connect(_do_reset)
		_confirm.add_child(yes)
		var no := Ui.button("No", 42, Vector2(180, 100))
		no.name = "ResetNo"
		no.pressed.connect(_cancel_reset)
		_confirm.add_child(no)
		box.add_child(_confirm)
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


func _set_fps(on: bool) -> void:
	settings.show_fps = on
	settings.save_to(save_path)


func _set_reduced(on: bool) -> void:
	settings.reduced_motion = on
	settings.save_to(save_path)


func _ask_reset() -> void:
	_reset_btn.visible = false
	_confirm.visible = true


func _cancel_reset() -> void:
	_reset_btn.visible = true
	_confirm.visible = false


func _do_reset() -> void:
	save.reset()
	_reset_btn.text = "Progress reset"
	_cancel_reset()

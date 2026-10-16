extends Control
## Settings (WP-3.R look): letter look, word hint, comfort switches and profile, in sections on the
## painted sky. Saves on every change.

const Ui := preload("res://scenes/ui.gd")
const AppSettings := preload("res://scenes/app_settings.gd")

signal closed
## The player asked for the frame-rate bench.
signal bench_pressed
## Change-entry buttons (shown when a save is set).
signal character_pressed
signal difficulty_pressed
## The player asked to see the Prologue again.
signal prologue_pressed

var settings: AppSettings = AppSettings.new()
var save_path: String = AppSettings.PATH
## Progress save (services/save.gd); null hides Reset progress.
var save: RefCounted
var _confirm: HBoxContainer
var _reset_btn: Button


## False when shown over the game screen (main draws its own dim behind it).
var show_sky: bool = true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if show_sky:
		Ui.add_sky(self, get_viewport_rect().size, 0.66)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(scroll)
	var centre := CenterContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centre.custom_minimum_size = Vector2(0, get_viewport_rect().size.y)
	scroll.add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	centre.add_child(box)
	var title := Ui.text("Settings", 88)
	title.name = "SettingsTitle"
	box.add_child(title)
	box.add_child(_section("Letter look"))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var group := ButtonGroup.new()
	for t in AppSettings.TREATMENTS:
		var b := Ui.choice(t.capitalize(), 42, Vector2(402, 100))
		b.name = "Treatment_%s" % t
		b.button_group = group
		b.button_pressed = settings.treatment == t
		b.pressed.connect(_set_treatment.bind(t))
		row.add_child(b)
	box.add_child(_section("Word hint in the slots"))
	var hgrid := GridContainer.new()
	hgrid.columns = 2
	hgrid.add_theme_constant_override("h_separation", 16)
	hgrid.add_theme_constant_override("v_separation", 14)
	box.add_child(hgrid)
	var hgroup := ButtonGroup.new()
	for h in AppSettings.HINTS:
		var hb := Ui.choice(str(AppSettings.HINT_LABELS[h]), 34, Vector2(402, 96))
		hb.name = "Hint_%s" % h
		hb.button_group = hgroup
		hb.button_pressed = settings.hint == h
		hb.pressed.connect(_set_hint.bind(h))
		hgrid.add_child(hb)
	box.add_child(_section("Comfort"))
	var rm := Ui.switch("Reduced motion", settings.reduced_motion)
	rm.name = "ReducedMotion"
	rm.toggled.connect(_set_reduced)
	box.add_child(rm)
	var rmn := Ui.text("Tilt, sway, shake and particles turn off.", 30, Ui.MUTED)
	box.add_child(rmn)
	var fps := Ui.switch("Show frame rate", settings.show_fps)
	fps.name = "ShowFps"
	fps.toggled.connect(_set_fps)
	box.add_child(fps)
	if save != null:
		box.add_child(_section("Profile"))
		var prow := HBoxContainer.new()
		prow.alignment = BoxContainer.ALIGNMENT_CENTER
		prow.add_theme_constant_override("separation", 16)
		box.add_child(prow)
		var ch := Ui.secondary("Catcher", 40, Vector2(402, 100))
		ch.name = "ChangeCharacterButton"
		ch.pressed.connect(func() -> void: character_pressed.emit())
		prow.add_child(ch)
		var df := Ui.secondary("Difficulty", 40, Vector2(402, 100))
		df.name = "ChangeDifficultyButton"
		df.pressed.connect(func() -> void: difficulty_pressed.emit())
		prow.add_child(df)
		_reset_btn = Ui.secondary("Reset progress", 40, Vector2(820, 100))
		_reset_btn.name = "ResetButton"
		_reset_btn.add_theme_color_override("font_color", Color(1.0, 0.62, 0.55))
		_reset_btn.pressed.connect(_ask_reset)
		box.add_child(_reset_btn)
		_confirm = HBoxContainer.new()
		_confirm.name = "ResetConfirm"
		_confirm.alignment = BoxContainer.ALIGNMENT_CENTER
		_confirm.add_theme_constant_override("separation", 16)
		_confirm.visible = false
		var q := Ui.text("Erase all stars?", 40, Color(1.0, 0.62, 0.55))
		q.name = "ResetQuestion"
		_confirm.add_child(q)
		var yes := Ui.secondary("Yes", 40, Vector2(180, 100))
		yes.name = "ResetYes"
		yes.pressed.connect(_do_reset)
		_confirm.add_child(yes)
		var no := Ui.secondary("No", 40, Vector2(180, 100))
		no.name = "ResetNo"
		no.pressed.connect(_cancel_reset)
		_confirm.add_child(no)
		box.add_child(_confirm)
	var bench := Ui.link("Frame-rate test", 32, Vector2(400, 70))
	bench.name = "BenchButton"
	bench.pressed.connect(func() -> void: bench_pressed.emit())
	box.add_child(bench)
	var pro := Ui.link("Replay the Prologue", 32, Vector2(400, 70))
	pro.name = "PrologueButton"
	pro.pressed.connect(func() -> void: prologue_pressed.emit())
	box.add_child(pro)
	var back := Ui.primary("Done", 52, Vector2(560, 136))
	back.name = "BackButton"
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: closed.emit())
	box.add_child(back)


func _section(t: String) -> Control:
	var l := Ui.heading(t, 30)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.custom_minimum_size = Vector2(820, 56)
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return l


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

extends Control
## Title screen: ASTROLEX, Drift or Pressure, Start, Settings.

const Ui := preload("res://scenes/ui.gd")
const LightRig := preload("res://scenes/light_rig.gd")
const TileViewScene: PackedScene = preload("res://scenes/tile_view.tscn")
const GameData := preload("res://rules/game_data.gd")
const AppSettings := preload("res://scenes/app_settings.gd")

const TITLE := "ASTROLEX"
const TILE_PX := 112.0
const TILE_GAP := 12.0
const TILE_Y := 380.0
const HINTS := {
	"drift": "Drift: no clock. Tether the letters, take your time.",
	"pressure": "Pressure: your air drains. Restoring a word refills it.",
}

signal start_pressed(mode: String)
signal settings_pressed

var mode: String = "drift"
var settings: AppSettings = AppSettings.new()
var tile_count: int = 0
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view := get_viewport_rect().size
	_build_tiles(view)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.offset_top = 120
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	centre.add_child(box)
	var title := Ui.label(TITLE, 150, Ui.INK)
	title.name = "Title"
	box.add_child(title)
	var modes := HBoxContainer.new()
	modes.alignment = BoxContainer.ALIGNMENT_CENTER
	modes.add_theme_constant_override("separation", 24)
	box.add_child(modes)
	var group := ButtonGroup.new()
	var drift := Ui.button("Drift", 48, Vector2(300, 120), true)
	drift.name = "DriftButton"
	drift.button_group = group
	var pressure := Ui.button("Pressure", 48, Vector2(300, 120), true)
	pressure.name = "PressureButton"
	pressure.button_group = group
	modes.add_child(drift)
	modes.add_child(pressure)
	drift.button_pressed = mode == "drift"
	pressure.button_pressed = mode == "pressure"
	drift.pressed.connect(_pick.bind("drift"))
	pressure.pressed.connect(_pick.bind("pressure"))
	_hint = Ui.label(HINTS[mode], 30, Ui.DIM)
	_hint.name = "ModeHint"
	_hint.custom_minimum_size = Vector2(840, 90)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint)
	var start := Ui.button("Start", 60, Vector2(560, 140))
	start.name = "StartButton"
	start.pressed.connect(func() -> void: start_pressed.emit(mode))
	box.add_child(start)
	var sett := Ui.button("Settings", 40, Vector2(560, 100))
	sett.name = "SettingsButton"
	sett.pressed.connect(func() -> void: settings_pressed.emit())
	box.add_child(sett)


func _pick(m: String) -> void:
	mode = m
	_hint.text = HINTS[m]


func _build_tiles(view: Vector2) -> void:
	var layer := CanvasLayer.new()
	layer.name = "TitleWorld"
	layer.layer = -1
	add_child(layer)
	var rig: Node2D = LightRig.new()
	layer.add_child(rig)
	rig.configure(Vector2(view.x * 0.5, TILE_Y - 120.0), 900.0, layer.layer)
	var tun := GameData.load_tunables()
	var total := TITLE.length() * TILE_PX + (TITLE.length() - 1) * TILE_GAP
	var x0 := (view.x - total) * 0.5 + TILE_PX * 0.5
	for i in TITLE.length():
		var v: Node2D = TileViewScene.instantiate()
		v.name = "TitleTile_%d" % i
		layer.add_child(v)
		v.setup(TITLE[i].to_lower(), TILE_PX, TILE_PX / (float(tun["tile.size"]) * view.x), 0, settings.treatment, settings.reduced_motion, tun, float(i) * 1.1)
		v.place(Vector2(x0 + i * (TILE_PX + TILE_GAP), TILE_Y + (8.0 if i % 2 == 0 else -8.0)), 0.0, float(i) / 7.0)
		tile_count += 1

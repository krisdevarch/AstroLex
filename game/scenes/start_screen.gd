extends Control
## Title screen: ASTROLEX, Start, Settings.

const Ui := preload("res://scenes/ui.gd")
const LightRig := preload("res://scenes/light_rig.gd")
const Starfield := preload("res://scenes/starfield.gd")
const TileViewScene: PackedScene = preload("res://scenes/tile_view.tscn")
const GameData := preload("res://rules/game_data.gd")
const AppSettings := preload("res://scenes/app_settings.gd")

const TITLE := "ASTROLEX"
const TILE_PX := 112.0
const TILE_GAP := 12.0
const TILE_Y := 380.0
signal start_pressed
signal settings_pressed

var settings: AppSettings = AppSettings.new()
## Start button text; main sets "Continue" when a save has a profile, else "New game".
var start_label: String = "New game"
var tile_count: int = 0


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
	var start := Ui.button(start_label, 60 if start_label.length() < 12 else 48, Vector2(560, 140))
	start.name = "StartButton"
	start.pressed.connect(func() -> void: start_pressed.emit())
	box.add_child(start)
	var sett := Ui.button("Settings", 40, Vector2(560, 100))
	sett.name = "SettingsButton"
	sett.pressed.connect(func() -> void: settings_pressed.emit())
	box.add_child(sett)


func _build_tiles(view: Vector2) -> void:
	# The glass samples the baked sky, so the title shows the same sky behind it.
	var backdrop := CanvasLayer.new()
	backdrop.name = "TitleBackdrop"
	backdrop.layer = -2
	add_child(backdrop)
	var stars: Node2D = Starfield.new()
	stars.view_size = view
	backdrop.add_child(stars)
	var layer := CanvasLayer.new()
	layer.name = "TitleWorld"
	layer.layer = -1
	add_child(layer)
	var rig: Node2D = LightRig.new()
	layer.add_child(rig)
	rig.configure(Vector2(view.x * 0.5, TILE_Y - 120.0), 900.0, layer.layer)
	var tun := GameData.load_tunables()
	# A bubble is drawn bigger than its tile, so shrink the tile to keep the title row from overlapping.
	var px := TILE_PX / float(tun["glass.bubbleScale"]) if settings.treatment == "bubble" else TILE_PX
	var total := TITLE.length() * TILE_PX + (TITLE.length() - 1) * TILE_GAP
	var x0 := (view.x - total) * 0.5 + TILE_PX * 0.5
	for i in TITLE.length():
		var v: Node2D = TileViewScene.instantiate()
		v.name = "TitleTile_%d" % i
		layer.add_child(v)
		v.setup(TITLE[i].to_lower(), px, px / (float(tun["tile.size"]) * view.x), 0, settings.treatment, settings.reduced_motion, tun, float(i) * 1.1)
		v.place(Vector2(x0 + i * (TILE_PX + TILE_GAP), TILE_Y + (8.0 if i % 2 == 0 else -8.0)), 0.0, float(i) / 7.0)
		tile_count += 1

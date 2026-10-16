extends Control
## Title screen (WP-3.R): the painted Low Orbit sky, the ASTROLEX logo as a row of the game's own
## letter bubbles, a tagline, Babel hovering in the corner with a dry line, Play/Continue in the
## main-action orange and Settings under it.

const Ui := preload("res://scenes/ui.gd")
const LightRig := preload("res://scenes/light_rig.gd")
const TileViewScene: PackedScene = preload("res://scenes/tile_view.tscn")
const GameData := preload("res://rules/game_data.gd")
const AppSettings := preload("res://scenes/app_settings.gd")

const TITLE := "ASTROLEX"
const TAGLINE := "Catch the letters. Bring the words home."
const TILE_PX := 112.0
const TILE_GAP := 12.0
const TILE_Y_SHARE := 0.30  # the logo row's height on screen
const BABEL_TEX := "res://art/babel/babel.png"
const BABEL_H := 330.0
const BABEL_LINE := "Back for more?"
const BABEL_FIRST_LINE := "Oh. A new one."
signal start_pressed
signal settings_pressed

var settings: AppSettings = AppSettings.new()
## Start button text; main sets "Continue" when a save has a profile, else "New game".
var start_label: String = "New game"
var tile_count: int = 0
var _babel: Control
var _t: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view := get_viewport_rect().size
	Ui.add_sky(self, view, 0.3)
	_build_tiles(view)
	_build_babel(view)
	var title := Ui.text(TITLE, 40, Color(0, 0, 0, 0))
	title.name = "Title"  # the logo is the tile row; this label names it for tests and screen readers
	title.visible = false
	add_child(title)
	var tag := Ui.text(TAGLINE, 46, Ui.CREAM)
	tag.name = "Tagline"
	tag.position = Vector2((view.x - 1000.0) * 0.5, view.y * TILE_Y_SHARE + 110.0)
	tag.size = Vector2(1000, 70)
	add_child(tag)
	var box := VBoxContainer.new()
	box.name = "Buttons"
	box.add_theme_constant_override("separation", 30)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size = Vector2(600, 320)
	box.position = Vector2((view.x - 600.0) * 0.5, view.y * 0.64)
	add_child(box)
	var start := Ui.primary(start_label, 62 if start_label.length() < 12 else 50, Vector2(600, 156))
	start.name = "StartButton"
	start.pressed.connect(func() -> void: start_pressed.emit())
	box.add_child(start)
	var sett := Ui.secondary("Settings", 44, Vector2(600, 116))
	sett.name = "SettingsButton"
	sett.pressed.connect(func() -> void: settings_pressed.emit())
	box.add_child(sett)
	var foot := Ui.text("Beta  ·  v%s" % str(ProjectSettings.get_setting("application/config/version", "0")), 30, Color(Ui.MUTED, 0.8))
	foot.name = "VersionLabel"
	foot.position = Vector2(0, view.y - 110.0)
	foot.size = Vector2(view.x, 60)
	add_child(foot)


func _build_tiles(view: Vector2) -> void:
	var layer := CanvasLayer.new()
	layer.name = "TitleWorld"
	layer.layer = -1
	add_child(layer)
	var y := view.y * TILE_Y_SHARE
	var rig: Node2D = LightRig.new()
	layer.add_child(rig)
	rig.configure(Vector2(view.x * 0.5, y - 120.0), 900.0, layer.layer)
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
		v.place(Vector2(x0 + i * (TILE_PX + TILE_GAP), y + (8.0 if i % 2 == 0 else -8.0)), 0.0, float(i) / 7.0)
		tile_count += 1


## Babel in the top corner, idling, with one dry line in his periwinkle bubble.
func _build_babel(view: Vector2) -> void:
	if not ResourceLoader.exists(BABEL_TEX):
		return
	var tex: Texture2D = load(BABEL_TEX)
	var holder := Control.new()
	holder.name = "TitleBabel"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var k := BABEL_H / tex.get_size().y
	holder.size = tex.get_size() * k
	holder.position = Vector2(view.x - holder.size.x - 70.0, view.y * TILE_Y_SHARE + 230.0)
	add_child(holder)
	var spr := TextureRect.new()
	spr.texture = tex
	spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spr.size = holder.size
	spr.flip_h = true  # he faces the logo
	spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(spr)
	var line := BABEL_LINE if start_label == "Continue" else BABEL_FIRST_LINE
	var bubble := PanelContainer.new()
	bubble.name = "TitleBabelBubble"
	var sb := Ui.box(Color(0.08, 0.12, 0.29, 0.95), 30, Color("7579f0"), 4)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	bubble.add_theme_stylebox_override("panel", sb)
	var bl := Ui.text(line, 36)
	bl.name = "TitleBabelLine"
	bubble.add_child(bl)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble)
	bubble.reset_size()
	bubble.position = Vector2(holder.position.x - bubble.size.x + 20.0, holder.position.y + 60.0)
	_babel = holder


func _process(delta: float) -> void:
	if _babel == null or settings.reduced_motion:
		return
	_t += delta
	_babel.position.y += sin(_t * 1.6) * 0.35
	_babel.rotation = sin(_t * 0.9) * 0.025

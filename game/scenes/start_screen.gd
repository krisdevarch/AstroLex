extends Control
## Title screen (WP-F.29): the intro's look, built by the same `crew_title.gd` (the painted Low Orbit sky,
## the AstroLex wordmark and the four Catcher bubbles, at rest and bobbing), with the menu where the
## intro's "Tap to start" sits: New game / Continue in the main-action orange, Daily Signal, Settings.

const Ui := preload("res://scenes/ui.gd")
const CrewTitle := preload("res://scenes/crew_title.gd")
const AppSettings := preload("res://scenes/app_settings.gd")

const TITLE := "ASTROLEX"
signal start_pressed
signal settings_pressed
signal daily_pressed

var settings: AppSettings = AppSettings.new()
## Start button text; main sets "Continue" when a save has a profile, else "New game".
var start_label: String = "New game"
## Daily Signal button text and the streak line under it (main fills them from the save).
var daily_label: String = "Daily Signal"
var daily_note: String = ""
## The bubbles on screen (main prints it as the ready count).
var tile_count: int = 0
var _crew: RefCounted = CrewTitle.new()
## Layout size; zero means the viewport (tests set it to check other phone shapes).
var view_size: Vector2 = Vector2.ZERO
var _t: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view := view_size if view_size != Vector2.ZERO else get_viewport_rect().size
	Ui.add_sky(self, view, 0.3)
	_crew.build(self, view, settings, false)
	tile_count = _crew.bubbles.size()
	var title := Ui.text(TITLE, 40, Color(0, 0, 0, 0))
	title.name = "Title"  # the wordmark is drawn by the crew look; this label names it for tests and screen readers
	title.visible = false
	add_child(title)
	var box := VBoxContainer.new()
	box.name = "Buttons"
	box.add_theme_constant_override("separation", 20)
	box.size = Vector2(CrewTitle.MENU_W, 0)
	box.position = Vector2((view.x - CrewTitle.MENU_W) * 0.5, CrewTitle.menu_top(view))
	add_child(box)
	var start := Ui.primary(start_label, 62 if start_label.length() < 12 else 50, Vector2(CrewTitle.MENU_W, 150))
	start.name = "StartButton"
	start.pressed.connect(func() -> void: start_pressed.emit())
	box.add_child(start)
	var daily := Ui.secondary(daily_label, 40, Vector2(CrewTitle.MENU_W, 90))
	daily.name = "DailyButton"
	daily.pressed.connect(func() -> void: daily_pressed.emit())
	box.add_child(daily)
	if daily_note != "":
		var note := Ui.text(daily_note, 28, Ui.MUTED)
		note.name = "DailyStreak"
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(CrewTitle.MENU_W, 0)
		box.add_child(note)
	var sett := Ui.secondary("Settings", 40, Vector2(CrewTitle.MENU_W, 90))
	sett.name = "SettingsButton"
	sett.pressed.connect(func() -> void: settings_pressed.emit())
	box.add_child(sett)
	var foot := Ui.text("Beta  ·  v%s" % str(ProjectSettings.get_setting("application/config/version", "0")), 28, Color(Ui.CREAM, 0.85))
	foot.name = "VersionLabel"
	foot.position = Vector2(0, view.y - 52.0)
	foot.size = Vector2(view.x, 40)
	add_child(foot)


func _process(delta: float) -> void:
	if settings.reduced_motion:
		return
	_t += delta
	_crew.bob(_t)

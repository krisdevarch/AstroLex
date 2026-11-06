extends Control
## Title screen (WP-F.29): the intro's look, built by the same `crew_title.gd` (the painted Low Orbit sky,
## the AstroLex wordmark and the four Catcher bubbles, at rest and bobbing), with the menu where the
## intro's "Tap to start" sits: New game / Continue in the main-action orange, Daily Signal, Settings.
##
## WP-F.31: the intro is this same screen. With `intro` set it opens with only the orange "Tap to start"
## (where the web loader's disabled button is); a tap anywhere, or intro.holdSec seconds, fades that button
## out and the menu in, on the same sky and bubbles. Nothing is rebuilt and nothing dips to black, so the
## loader, the intro and the title read as one screen. `revealed` fires once the menu is in.

const Ui := preload("res://scenes/ui.gd")
const CrewTitle := preload("res://scenes/crew_title.gd")
const AppSettings := preload("res://scenes/app_settings.gd")
const GameData := preload("res://rules/game_data.gd")

const TITLE := "ASTROLEX"
## The intro's button top edge is this far above the view's bottom (scripts/web/make_loading.py's
## BTN_FROM_BOTTOM; the web loader draws its disabled copy there).
const TAP_FROM_BOTTOM := 330.0
## Cross-fade from "Tap to start" to the menu.
const REVEAL_SEC := 0.4
signal start_pressed
signal settings_pressed
signal daily_pressed
signal revealed

var settings: AppSettings = AppSettings.new()
## Start button text; main sets "Continue" when a save has a profile, else "New game".
var start_label: String = "New game"
## Daily Signal button text and the streak line under it (main fills them from the save).
var daily_label: String = "Daily Signal"
var daily_note: String = ""
## The bubbles on screen (main prints it as the ready count).
var tile_count: int = 0
## Opens as the intro: "Tap to start" first, the menu after a tap or the hold time.
var intro: bool = false
## Plays the bubbles' pop-in (the intro off the web; on the web the loader already shows them at rest).
var pop: bool = false
## Seconds before the intro reveals the menu by itself (tunable intro.holdSec).
var hold_sec: float = 6.0
## Reveal length; tests set 0 to swap at once.
var reveal_sec: float = REVEAL_SEC
var _crew: RefCounted = CrewTitle.new()
## Layout size; zero means the viewport (tests set it to check other phone shapes).
var view_size: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _menu: Array[Control] = []
var _tap: Button
var _waiting: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hold_sec = float(GameData.load_tunables().get("intro.holdSec", hold_sec))
	var view := view_size if view_size != Vector2.ZERO else get_viewport_rect().size
	# The sky spans the design box (cover fit, like the loader's still), so it never shifts at the hand-off.
	var sky_box := Vector2(maxf(CrewTitle.box_size(view).x, view.x), view.y)
	var sky := Ui.add_sky(self, sky_box, 0.3)
	(sky.get_parent() as CanvasLayer).offset = Vector2((view.x - sky_box.x) * 0.5, 0.0)
	_crew.build(self, view, settings, intro and pop)
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
	_menu = [box, foot]
	if intro:
		_build_tap(view)
		for c in _menu:
			c.visible = false
			c.modulate.a = 0.0
		_waiting = true


func _build_tap(view: Vector2) -> void:
	_tap = Ui.primary("Tap to start", 62, Vector2(CrewTitle.MENU_W, 150))
	_tap.name = "TapToStart"
	_tap.position = Vector2((view.x - CrewTitle.MENU_W) * 0.5, view.y - TAP_FROM_BOTTOM)
	_tap.size = Vector2(CrewTitle.MENU_W, 150)
	_tap.pivot_offset = _tap.size * 0.5
	_tap.pressed.connect(reveal)
	add_child(_tap)
	if pop and not settings.reduced_motion:
		_tap.modulate.a = 0.0


## True while the intro's "Tap to start" is up and the menu is hidden.
func waiting() -> bool:
	return _waiting


func _process(delta: float) -> void:
	_t += delta
	if _waiting and _t >= hold_sec:
		reveal()
	if settings.reduced_motion:
		return
	_crew.bob(_t)
	if _waiting and _tap != null:
		_tap.modulate.a = clampf((_t - 1.1) / 0.5, 0.0, 1.0) if pop else 1.0
		_tap.scale = Vector2.ONE * (1.0 + 0.02 * (0.5 + 0.5 * sin(_t * 3.0)))


func _gui_input(event: InputEvent) -> void:
	if not _waiting:
		return
	var press := false
	if event is InputEventMouseButton:
		press = event.pressed
	elif event is InputEventScreenTouch:
		press = event.pressed
	if press:
		accept_event()
		reveal()


## Ends the intro once: "Tap to start" fades out and the menu fades in where it was.
func reveal() -> void:
	if not _waiting:
		return
	_waiting = false
	for c in _menu:
		c.visible = true
	var tap := _tap
	_tap = null
	if reveal_sec <= 0.0 or settings.reduced_motion or not is_inside_tree():
		for c in _menu:
			c.modulate.a = 1.0
		tap.queue_free()
		revealed.emit()
		return
	tap.disabled = true
	# No clicks on the menu while it fades in, so a quick double tap cannot start the game unseen.
	_menu_input(false)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(tap, "modulate:a", 0.0, reveal_sec * 0.6)
	for c in _menu:
		tw.tween_property(c, "modulate:a", 1.0, reveal_sec).set_delay(reveal_sec * 0.25)
	tw.chain().tween_callback(func() -> void:
		_menu_input(true)
		tap.queue_free()
		revealed.emit())


func _menu_input(on: bool) -> void:
	for b: Node in (_menu[0] as Node).get_children():
		if b is Button:
			(b as Button).mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE

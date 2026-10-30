extends Control
## Intro screen (WP-F.29): the first thing on launch, built from the game's own kit. The painted Low
## Orbit sky and the crew look it shares with the title (`crew_title.gd`: the wordmark and the four
## Catchers' busts under glass bubbles). The bubbles pop in one after another and bob out of step; the
## standard orange "Tap to start" button sits where the title's menu starts. A tap anywhere, or intro.holdSec seconds, emits `finished`
## (after a short fade). Reduced motion shows everything still at rest.

const Ui := preload("res://scenes/ui.gd")
const CrewTitle := preload("res://scenes/crew_title.gd")
const GameData := preload("res://rules/game_data.gd")
const AppSettings := preload("res://scenes/app_settings.gd")

signal finished

var settings: AppSettings = AppSettings.new()
## Seconds before the intro moves on by itself (tunable intro.holdSec).
var hold_sec: float = 6.0
## Length of the fade to black when it ends; 0 emits `finished` at once.
var fade_sec: float = 0.35
var _t: float = 0.0
var _done: bool = false
var _crew: RefCounted = CrewTitle.new()
var _tap: Button
var _fade: ColorRect


func _ready() -> void:
	name = "IntroScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hold_sec = float(GameData.load_tunables().get("intro.holdSec", hold_sec))
	var view := get_viewport_rect().size
	Ui.add_sky(self, view, 0.3)
	_crew.build(self, view, settings, true)
	_build_tap(view)
	_fade = ColorRect.new()
	_fade.name = "IntroFade"
	_fade.color = Color(0.01, 0.02, 0.08, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func _build_tap(view: Vector2) -> void:
	_tap = Ui.primary("Tap to start", 62, Vector2(CrewTitle.MENU_W, 150))
	_tap.name = "TapToStart"
	_tap.position = Vector2((view.x - CrewTitle.MENU_W) * 0.5, CrewTitle.menu_top(view))
	_tap.size = Vector2(CrewTitle.MENU_W, 150)
	_tap.pivot_offset = _tap.size * 0.5
	_tap.pressed.connect(finish)
	add_child(_tap)
	if not settings.reduced_motion:
		_tap.modulate.a = 0.0


func _process(delta: float) -> void:
	_t += delta
	if not _done and _t >= hold_sec:
		finish()
	if settings.reduced_motion:
		return
	_crew.bob(_t)
	var appear := clampf((_t - 1.1) / 0.5, 0.0, 1.0)
	_tap.modulate.a = appear
	_tap.scale = Vector2.ONE * (1.0 + 0.02 * (0.5 + 0.5 * sin(_t * 3.0)))


func _gui_input(event: InputEvent) -> void:
	var press := false
	if event is InputEventMouseButton:
		press = event.pressed
	elif event is InputEventScreenTouch:
		press = event.pressed
	if press:
		accept_event()
		finish()


## Ends the intro once: fades out, then emits `finished`.
func finish() -> void:
	if _done:
		return
	_done = true
	if fade_sec <= 0.0 or not is_inside_tree():
		finished.emit()
		return
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, fade_sec)
	tw.tween_callback(func() -> void: finished.emit())

extends Control
## Intro screen (WP-F.29): the first thing on launch, built from the game's own kit. The painted Low
## Orbit sky and the crew look it shares with the title (`crew_title.gd`: the wordmark and the four
## Catchers' busts under glass bubbles). The bubbles pop in one after another and bob out of step; the
## standard orange "Tap to start" button sits where the title's menu starts. A tap anywhere, or intro.holdSec seconds, emits `finished`
## (after a short fade). Reduced motion shows everything still at rest.
## On the web the HTML loader (scripts/web/make_loading.py) already shows this screen's art with a
## disabled button and a load bar, so `pop` is off there: it appears at rest, bobbing, button enabled.
## `still` (?intro=still) draws the art at rest with no button, for the loader's still image.

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
## Plays the pop-in and fades (off on the web, where the loader is already on screen).
var pop: bool = true
## Art only, at rest, no button and no timer: the capture mode for game/brand/intro_still.jpg.
var still: bool = false
## The button's top edge is this far above the view's bottom (also read by make_loading.py).
const TAP_FROM_BOTTOM := 330.0
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
	var sky_box := Vector2(maxf(CrewTitle.box_size(view).x, view.x), view.y)
	var sky := Ui.add_sky(self, sky_box, 0.3)
	(sky.get_parent() as CanvasLayer).offset = Vector2((view.x - sky_box.x) * 0.5, 0.0)
	_crew.build(self, view, settings, pop and not still)
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
	_tap.position = Vector2((view.x - CrewTitle.MENU_W) * 0.5, view.y - TAP_FROM_BOTTOM)
	_tap.size = Vector2(CrewTitle.MENU_W, 150)
	_tap.pivot_offset = _tap.size * 0.5
	_tap.pressed.connect(finish)
	add_child(_tap)
	if still:
		_tap.visible = false
	elif pop and not settings.reduced_motion:
		_tap.modulate.a = 0.0


func _process(delta: float) -> void:
	if still:
		return
	_t += delta
	if not _done and _t >= hold_sec:
		finish()
	if settings.reduced_motion:
		return
	_crew.bob(_t)
	var appear := clampf((_t - 1.1) / 0.5, 0.0, 1.0) if pop else 1.0
	_tap.modulate.a = appear
	_tap.scale = Vector2.ONE * (1.0 + 0.02 * (0.5 + 0.5 * sin(_t * 3.0)))


func _gui_input(event: InputEvent) -> void:
	var press := false
	if event is InputEventMouseButton:
		press = event.pressed
	elif event is InputEventScreenTouch:
		press = event.pressed
	if press and not still:
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

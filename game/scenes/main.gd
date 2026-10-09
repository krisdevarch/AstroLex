extends Node
## App root: Start screen, Play (the field), End screen, Settings.
## Autoplay (--autoplay, or ?autoplay=1 on the web) skips Start and plays a Drift round.

const AppSettings := preload("res://scenes/app_settings.gd")
const StartScreen := preload("res://scenes/start_screen.gd")
const SettingsScreen := preload("res://scenes/settings_screen.gd")
const GlassBench := preload("res://scenes/glass_bench.gd")
const EndScreen := preload("res://scenes/end_screen.gd")
const Telemetry := preload("res://services/telemetry.gd")
const FieldScene: PackedScene = preload("res://scenes/field.tscn")

const CommsScreen := preload("res://scenes/comms_screen.gd")
const GameData := preload("res://rules/game_data.gd")

const AUTOPLAY_SEED := 20261008  # random (non-level) rounds only
const ACT := "act1_low_orbit"

## Act I levels (from content.json) and the one being played; not saved between sessions.
var levels: Array = []
var level_index: int = 0

var settings: AppSettings = AppSettings.new()
var mode: String = "drift"
var round_no: int = 1
var autoplay: bool = false
var screen: Node
var telemetry: RefCounted
var _ready_printed: bool = false


static func autoplay_requested() -> bool:
	if OS.get_cmdline_user_args().has("--autoplay"):
		return true
	if OS.has_feature("web"):
		var q: Variant = JavaScriptBridge.eval("window.location.search")
		return str(q).contains("autoplay=1")
	return false


func _ready() -> void:
	telemetry = Telemetry.new()
	levels = GameData.load_content().get("levels", {}).get(ACT, [])
	settings.load_from()
	telemetry.set_settings(settings.treatment, settings.reduced_motion, settings.hint)
	autoplay = autoplay_requested()
	if GlassBench.bench_requested():
		_show_bench(GlassBench.auto_requested())
	elif autoplay:
		mode = "drift"
		_start_level()
	else:
		_show_start()
	telemetry.mark_ready()


func _process(delta: float) -> void:
	if telemetry != null and telemetry.playing:
		telemetry.sample_frame(delta)


func _swap(node: Node) -> void:
	if screen != null:
		remove_child(screen)
		screen.queue_free()
	screen = node
	add_child(node)


func _show_start() -> void:
	var s: Control = StartScreen.new()
	s.name = "StartScreen"
	s.settings = settings
	s.mode = mode
	s.start_pressed.connect(func(m: String) -> void:
		mode = m
		round_no = 1
		_begin_level_with_comms())
	s.settings_pressed.connect(_show_settings)
	_swap(s)
	if not _ready_printed:
		_ready_printed = true
		print("AstroLex ready: %d tiles" % s.tile_count)


func _show_settings() -> void:
	var s: Control = SettingsScreen.new()
	s.name = "SettingsScreen"
	s.settings = settings
	s.closed.connect(_show_start)
	s.bench_pressed.connect(func() -> void: _show_bench(false))
	_swap(s)


func _show_bench(auto: bool) -> void:
	var b: Node = GlassBench.new()
	b.name = "GlassBench"
	b.auto = auto
	b.view_size = get_viewport().get_visible_rect().size
	b.closed.connect(_show_start)
	_swap(b)
	if not _ready_printed:
		_ready_printed = true
		print("AstroLex ready: %d tiles" % b.tile_count())


func _comms_of(index: int, key: String) -> Array:
	if index < 0 or index >= levels.size():
		return []
	return (levels[index] as Dictionary).get(key, [])


## Shows a comms exchange, then calls `then`. An empty exchange is skipped.
func _show_comms(messages: Array, then: Callable) -> void:
	if messages.is_empty():
		then.call()
		return
	var c: Control = CommsScreen.new()
	c.name = "CommsScreen"
	c.messages = messages
	c.reduced_motion = settings.reduced_motion
	c.finished.connect(then)
	_swap(c)


## Start pressed: the current level's comms, then play.
func _begin_level_with_comms() -> void:
	_show_comms(_comms_of(level_index, "commsBefore"), _start_level)


func _start_level() -> void:
	if levels.is_empty():
		push_error("main: no levels in content.json; playing a free round")
		_start_round(mode, 1)
		return
	var level: Dictionary = levels[level_index]
	var f: Node2D = FieldScene.instantiate()
	f.name = "Field"
	f.settings = settings
	f.autoplay = autoplay
	f.view_size = get_viewport().get_visible_rect().size
	f.print_ready = not _ready_printed
	_ready_printed = true
	f.round_finished.connect(_on_level_finished.bind(level))
	_swap(f)
	telemetry.set_settings(settings.treatment, settings.reduced_motion, settings.hint)
	telemetry.begin_round(f, mode, level_index + 1, int(level["seed"]), str(level["id"]))
	f.begin_level(mode, level)


func _on_level_finished(summary: Dictionary, level: Dictionary) -> void:
	summary["level"] = str(level["id"])
	if summary.get("won", false):
		if level_index >= levels.size() - 1:
			summary["act_complete"] = true
		else:
			level_index += 1
		if autoplay:
			_show_end(summary)
		else:
			_show_comms(level.get("commsAfter", []), func() -> void: _show_end(summary))
	else:
		_show_end(summary)


## Next level (after a win), the same level (after a loss) or back to 1-01 (Act I done).
func _continue_from(summary: Dictionary) -> void:
	if summary.get("act_complete", false):
		level_index = 0
		_begin_level_with_comms()
	elif summary.get("won", false):
		_begin_level_with_comms()
	else:
		_start_level()


func _start_round(m: String, n: int) -> void:
	mode = m
	round_no = n
	var f: Node2D = FieldScene.instantiate()
	f.name = "Field"
	f.settings = settings
	f.autoplay = autoplay
	f.view_size = get_viewport().get_visible_rect().size
	f.print_ready = not _ready_printed
	_ready_printed = true
	f.round_finished.connect(_show_end)
	_swap(f)
	var seed_value := AUTOPLAY_SEED if autoplay else int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec()
	telemetry.set_settings(settings.treatment, settings.reduced_motion, settings.hint)
	telemetry.begin_round(f, m, n, seed_value)
	f.begin(m, n, seed_value)


func _show_end(summary: Dictionary) -> void:
	var s: Control = EndScreen.new()
	s.name = "EndScreen"
	s.summary = summary
	s.telemetry = telemetry
	s.play_again.connect(func() -> void:
		if str(summary.get("level", "")) != "":
			_continue_from(summary)
		else:
			_start_round(mode, round_no + 1))
	s.switch_mode.connect(func() -> void:
		mode = "pressure" if mode == "drift" else "drift"
		if str(summary.get("level", "")) != "":
			_continue_from(summary)
		else:
			_start_round(mode, 1))
	_swap(s)

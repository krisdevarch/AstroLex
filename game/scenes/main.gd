extends Node
## App root: Start screen, Play (the field), End screen, Settings.
## Autoplay (--autoplay, or ?autoplay=1 on the web) skips Start and plays a Drift round.

const AppSettings := preload("res://scenes/app_settings.gd")
const StartScreen := preload("res://scenes/start_screen.gd")
const SettingsScreen := preload("res://scenes/settings_screen.gd")
const EndScreen := preload("res://scenes/end_screen.gd")
const Telemetry := preload("res://services/telemetry.gd")
const FieldScene: PackedScene = preload("res://scenes/field.tscn")

const AUTOPLAY_SEED := 20261008

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
	settings.load_from()
	telemetry.set_settings(settings.treatment, settings.reduced_motion)
	autoplay = autoplay_requested()
	if autoplay:
		_start_round("drift", 1)
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
		_start_round(m, 1))
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
	_swap(s)


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
	telemetry.set_settings(settings.treatment, settings.reduced_motion)
	telemetry.begin_round(f, m, n, seed_value)
	f.begin(m, n, seed_value)


func _show_end(summary: Dictionary) -> void:
	var s: Control = EndScreen.new()
	s.name = "EndScreen"
	s.summary = summary
	s.telemetry = telemetry
	s.play_again.connect(func() -> void: _start_round(mode, round_no + 1))
	s.switch_mode.connect(func() -> void: _start_round("pressure" if mode == "drift" else "drift", 1))
	_swap(s)

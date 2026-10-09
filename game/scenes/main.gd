extends Node
## App root. Flow: Start -> (first time: Character -> Difficulty) -> Level map -> level comms -> field
## -> End screen -> Next / Retry / Map. Pause overlay on the field. Settings from Start and the map.
## Autoplay (--autoplay, or ?autoplay=1 on the web) skips every menu and plays level 1-01 with a fake save.

const AppSettings := preload("res://scenes/app_settings.gd")
const StartScreen := preload("res://scenes/start_screen.gd")
const SettingsScreen := preload("res://scenes/settings_screen.gd")
const GlassBench := preload("res://scenes/glass_bench.gd")
const EndScreen := preload("res://scenes/end_screen.gd")
const CharacterSelect := preload("res://scenes/character_select.gd")
const DifficultySelect := preload("res://scenes/difficulty_select.gd")
const LevelMap := preload("res://scenes/level_map.gd")
const PauseMenu := preload("res://scenes/pause_menu.gd")
const ActComplete := preload("res://scenes/act_complete.gd")
const Telemetry := preload("res://services/telemetry.gd")
const Save := preload("res://services/save.gd")
const DictService := preload("res://services/dictionary.gd")
const FieldScene: PackedScene = preload("res://scenes/field.tscn")
const CommsScreen := preload("res://scenes/comms_screen.gd")

const AUTOPLAY_SEED := 20261008  # random (non-level) rounds only
const SAVETEST_PATH := "user://save_test.json"

## The act being played, its levels (from the dictionary) and the level in play.
var act: String = "act1_low_orbit"
var levels: Array = []
var level_index: int = 0

var settings: AppSettings = AppSettings.new()
var round_no: int = 1
var autoplay: bool = false
var screen: Node
var telemetry: RefCounted
## Progress save. Tests may set a Save.fake() before _ready; autoplay always uses a fake.
var save: RefCounted
## Words and levels. Tests may set DictService.fake(...) before _ready.
var dictionary: RefCounted
var pause_menu: Control
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
	autoplay = autoplay_requested()
	var offline: bool = autoplay or DisplayServer.get_name() == "headless"
	if dictionary == null:
		dictionary = DictService.bundled(not offline)
		if not offline:
			dictionary.start_remote(self)
	act = str(dictionary.act_order()[0]) if not dictionary.act_order().is_empty() else act
	levels = dictionary.levels(act)
	settings.load_from()
	telemetry.set_settings(settings.treatment, settings.reduced_motion, settings.hint)
	if save == null:
		if offline:
			save = Save.fake()
		elif _savetest_query() != "":
			save = Save.real(SAVETEST_PATH)  # never the real player's save
		else:
			save = Save.real()
	_sync_layout()
	_sync_level_index()
	_save_debug_hook()
	if GlassBench.bench_requested():
		_show_bench(GlassBench.auto_requested())
	elif autoplay:
		_start_level()
	else:
		_show_start()
	telemetry.mark_ready()


static func _savetest_query() -> String:
	if not OS.has_feature("web") or autoplay_requested():
		return ""
	var q := str(JavaScriptBridge.eval("window.location.search"))
	return q if q.contains("savetest=1") else ""


## Tells the save how many acts and levels there are, so it can answer unlocked().
func _sync_layout() -> void:
	var order: Array = dictionary.act_order()
	save.act_order = order
	for a: String in order:
		save.act_sizes[a] = dictionary.levels(a).size()


func _sync_level_index() -> void:
	level_index = clampi(save.next_level(act), 0, maxi(levels.size() - 1, 0))


## Web-only test hook: ?savetest=1 (own save file) prints the saved next level, &win=1 first records 1-01 as won.
func _save_debug_hook() -> void:
	var q := _savetest_query()
	if q == "" or autoplay or levels.is_empty():
		return
	if q.contains("win=1"):
		save.record_level(act, str((levels[0] as Dictionary)["id"]), 0, true, 100, 1)
		_sync_level_index()
	print("AstroLex save next=%s" % str((levels[level_index] as Dictionary)["id"]))


# --- profile helpers ---------------------------------------------------------------------

func _characters() -> Array:
	return dictionary.content().get("characters", [])


func _difficulty_options() -> Array:
	return (dictionary.content().get("difficulty", {}) as Dictionary).get("levels", [])


func _default_difficulty() -> String:
	return str((dictionary.content().get("difficulty", {}) as Dictionary).get("default", "normal"))


func _profile_character() -> Dictionary:
	var id: String = str(save.profile().get("character", ""))
	for c: Dictionary in _characters():
		if str(c["id"]) == id:
			return c
	return {}


func _profile_difficulty() -> Dictionary:
	var id: String = str(save.profile().get("difficulty", ""))
	if id == "":
		id = _default_difficulty()
	for o: Dictionary in _difficulty_options():
		if str(o["id"]) == id:
			return o
	return {}


## [difficulty mod, character mod]; none in autoplay so the CI smoke plays the plain level.
func _mods() -> Array:
	if autoplay:
		return []
	var out: Array = []
	for src: Dictionary in [_profile_difficulty(), _profile_character()]:
		var m: Variant = src.get("mod")
		if m is Dictionary and not (m as Dictionary).is_empty():
			out.append(m)
	return out


func _process(delta: float) -> void:
	if telemetry != null and telemetry.playing:
		telemetry.sample_frame(delta)


func _swap(node: Node) -> void:
	_close_pause()
	if screen != null:
		remove_child(screen)
		screen.queue_free()
	screen = node
	add_child(node)


# --- screens -----------------------------------------------------------------------------

func _show_start() -> void:
	var s: Control = StartScreen.new()
	s.name = "StartScreen"
	s.settings = settings
	s.start_label = "Continue" if save.has_profile() else "New game"
	s.start_pressed.connect(func() -> void:
		if save.has_profile():
			_show_map()
		else:
			_show_character(false, func() -> void: _show_difficulty(false, _show_map)))
	s.settings_pressed.connect(_show_settings.bind(_show_start))
	_swap(s)
	if not _ready_printed:
		_ready_printed = true
		print("AstroLex ready: %d tiles" % s.tile_count)


func _show_character(can_cancel: bool, then: Callable) -> void:
	var s: Control = CharacterSelect.new()
	s.name = "CharacterSelect"
	s.characters = _characters()
	s.selected = str(save.profile().get("character", ""))
	s.pronouns = str(save.profile().get("pronouns", "they"))
	s.can_cancel = can_cancel
	s.confirmed.connect(func(id: String, pron: String) -> void:
		var diff: String = str(save.profile().get("difficulty", ""))
		save.set_profile(id, pron, diff if diff != "" else _default_difficulty())
		then.call())
	s.cancelled.connect(then)
	_swap(s)


func _show_difficulty(can_cancel: bool, then: Callable) -> void:
	var s: Control = DifficultySelect.new()
	s.name = "DifficultySelect"
	s.options = _difficulty_options()
	var cur: String = str(save.profile().get("difficulty", ""))
	s.selected = cur if cur != "" else _default_difficulty()
	s.can_cancel = can_cancel
	s.confirmed.connect(func(id: String) -> void:
		var p: Dictionary = save.profile()
		save.set_profile(str(p.get("character", "")), str(p.get("pronouns", "they")), id)
		then.call())
	s.cancelled.connect(then)
	_swap(s)


func _show_map() -> void:
	_sync_layout()
	var m: Control = LevelMap.new()
	m.name = "LevelMap"
	m.dictionary = dictionary
	m.save = save
	m.level_chosen.connect(func(a: String, i: int) -> void:
		act = a
		levels = dictionary.levels(a)
		level_index = i
		_begin_level_with_comms())
	m.character_pressed.connect(_show_character.bind(true, _show_map))
	m.difficulty_pressed.connect(_show_difficulty.bind(true, _show_map))
	m.settings_pressed.connect(_show_settings.bind(_show_map))
	m.back_pressed.connect(_show_start)
	_swap(m)


func _show_settings(back: Callable) -> void:
	var s: Control = SettingsScreen.new()
	s.name = "SettingsScreen"
	s.settings = settings
	s.save = save
	s.closed.connect(back)
	s.character_pressed.connect(func() -> void: _show_character(true, _show_settings.bind(back)))
	s.difficulty_pressed.connect(func() -> void: _show_difficulty(true, _show_settings.bind(back)))
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


## The current level's comms, then play.
func _begin_level_with_comms() -> void:
	_show_comms(_comms_of(level_index, "commsBefore"), _start_level)


func _start_level() -> void:
	if levels.is_empty():
		push_error("main: no levels for %s; back to the map" % act)
		_show_map()
		return
	var level: Dictionary = levels[level_index]
	var f: Node2D = FieldScene.instantiate()
	f.name = "Field"
	f.settings = settings
	f.autoplay = autoplay
	f.view_size = get_viewport().get_visible_rect().size
	f.print_ready = not _ready_printed
	_ready_printed = true
	var ch := _profile_character()
	if not autoplay and ch.has("colour"):
		f.tether_colour = Color(str(ch["colour"]))
	f.content_override = dictionary.content()
	f.round_finished.connect(_on_level_finished.bind(level))
	f.pause_requested.connect(_show_pause.bind(f))
	_swap(f)
	telemetry.set_settings(settings.treatment, settings.reduced_motion, settings.hint)
	var diff_id := "" if autoplay else str(_profile_difficulty().get("id", ""))
	var char_id := "" if autoplay else str(ch.get("id", ""))
	telemetry.begin_round(f, level_index + 1, int(level["seed"]), str(level["id"]), act, char_id, diff_id)
	f.begin_level(level, act, _mods())


func _is_final_level() -> bool:
	var order: Array = dictionary.act_order()
	return not order.is_empty() and act == str(order[order.size() - 1]) and level_index >= levels.size() - 1


func _on_level_finished(summary: Dictionary, level: Dictionary) -> void:
	summary["level"] = str(level["id"])
	summary["act"] = act
	var won: bool = summary.get("won", false)
	var stars: int = int(summary.get("stars", 1 if won else 0))
	save.record_level(act, str(level["id"]), level_index, won, int(summary.get("score", 0)), stars)
	if not won:
		_show_end(summary)
	elif autoplay:
		_show_end(summary)
	else:
		_show_comms(level.get("commsAfter", []), func() -> void: _show_end(summary))


func _show_end(summary: Dictionary) -> void:
	var s: Control = EndScreen.new()
	s.name = "EndScreen"
	s.summary = summary
	s.telemetry = telemetry
	s.next.connect(_go_next)
	s.retry.connect(_start_level)
	s.map.connect(_show_map)
	_swap(s)


## Next after a win: the next level, or the act-complete screen after the last level of an act
## (the beta-complete screen after the very last level).
func _go_next() -> void:
	if _is_final_level():
		_show_complete(true)
	elif level_index < levels.size() - 1:
		level_index += 1
		_begin_level_with_comms()
	else:
		_show_complete(false)


func _show_complete(final: bool) -> void:
	var c: Control = ActComplete.new()
	c.name = "BetaComplete" if final else "ActComplete"
	c.final = final
	c.total_stars = save.total_stars()
	var order: Array = dictionary.act_order()
	var at := order.find(act)
	c.title_text = "%s complete" % str(LevelMap.ACT_TITLES.get(act, act)).split(" · ")[0]
	c.next_act.connect(func() -> void:
		if at + 1 < order.size():
			act = str(order[at + 1])
			levels = dictionary.levels(act)
			level_index = 0
			_begin_level_with_comms()
		else:
			_show_map())
	c.back_to_map.connect(_show_map)
	_swap(c)


# --- pause -------------------------------------------------------------------------------

func _show_pause(f: Node) -> void:
	if pause_menu != null:
		return
	f.set_paused(true)
	var p: Control = PauseMenu.new()
	p.name = "PauseMenu"
	p.resumed.connect(func() -> void:
		_close_pause()
		f.set_paused(false))
	p.restarted.connect(func() -> void:
		_close_pause()
		_start_level())
	p.quit.connect(func() -> void:
		_close_pause()
		telemetry.playing = false
		_show_map())
	pause_menu = p
	add_child(p)


func _close_pause() -> void:
	if pause_menu != null:
		pause_menu.queue_free()
		pause_menu = null

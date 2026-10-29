extends Node
## App root. Flow: Start -> (first time: Character -> Difficulty) -> Level map -> field. From there
## one game screen carries the whole act (WP-3.O): the crew's chatter plays on it, Babel throws the
## letters, and at the end the level card rises on it with the stars; Next plays the chatter between
## levels and the next level's throw on the same screen, Retry replays in place, Map leaves.
## Pause overlay on the field. Settings from Start and the map.
## Autoplay (--autoplay, or ?autoplay=1 on the web) skips every menu and the chatter and plays level
## 1-01 with a fake save. Demo (?demo=1, for clips) is autoplay with a Catcher, the chatter and a
## Next press a few seconds after each win.

const AppSettings := preload("res://scenes/app_settings.gd")
const GameFont := preload("res://scenes/game_font.gd")
const StartScreen := preload("res://scenes/start_screen.gd")
const SettingsScreen := preload("res://scenes/settings_screen.gd")
const GlassBench := preload("res://scenes/glass_bench.gd")
const LevelCard := preload("res://scenes/level_card.gd")
const CharacterSelect := preload("res://scenes/character_select.gd")
const DifficultySelect := preload("res://scenes/difficulty_select.gd")
const LevelMap := preload("res://scenes/level_map.gd")
const PauseMenu := preload("res://scenes/pause_menu.gd")
const ActComplete := preload("res://scenes/act_complete.gd")
const Ending := preload("res://scenes/ending.gd")
const Credits := preload("res://scenes/credits.gd")
const PlayerName := preload("res://rules/player_name.gd")
const CodexScreen := preload("res://scenes/codex.gd")
const InboxScreen := preload("res://scenes/inbox.gd")
const StoryData := preload("res://rules/story_data.gd")
const Flashback := preload("res://scenes/flashback.gd")
const Telemetry := preload("res://services/telemetry.gd")
const Save := preload("res://services/save.gd")
const GameData := preload("res://rules/game_data.gd")
const Daily := preload("res://rules/daily.gd")
const DailyHooks := preload("res://scenes/daily_hooks.gd")
const DictService := preload("res://services/dictionary.gd")
const FieldScene: PackedScene = preload("res://scenes/field.tscn")

const IntroScreen := preload("res://scenes/intro_screen.gd")
const MusicScript := preload("res://scenes/music.gd")
const AUTOPLAY_SEED := 20261008  # random (non-level) rounds only
const SAVETEST_PATH := "user://save_test.json"
const DEMO_NEXT_SEC := 3.5

## The act being played, its levels (from the dictionary) and the level in play.
var act: String = "act1_low_orbit"
var levels: Array = []
var level_index: int = 0

var settings: AppSettings = AppSettings.new()
var round_no: int = 1
var autoplay: bool = false
var demo: bool = false
var screen: Node
var telemetry: RefCounted
## Progress save. Tests may set a Save.fake() before _ready; autoplay always uses a fake.
var save: RefCounted
## Words and levels. Tests may set DictService.fake(...) before _ready.
var dictionary: RefCounted
var pause_menu: Control
## The UTC date of the Daily Signal being played ("" when none). Tests may set daily_today.
var daily_date: String = ""
var daily_today: String = ""
## Placeholder music (WP-F.8): menu bed on the menu screens, the act's bed on the game screen.
var music: MusicScript
var _ready_printed: bool = false
## The intro screen (WP-F.29) shows once per launch before the title. Off in headless runs, so the
## tests start on the title, and with ?intro=0 on the web (the smoke scripts).
var show_intro: bool = intro_default()
## Fade-out length of the intro; tests set 0 to finish it at once.
var intro_fade_sec: float = 0.35
## Tests set this before _ready to stand in for the page's recovery flag ("1" = reloaded by the recovery).
var recover_override: String = ""


static func intro_default() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	if OS.has_feature("web"):
		return not str(JavaScriptBridge.eval("window.location.search")).contains("intro=0")
	return not OS.get_cmdline_user_args().has("--no-intro")


static func autoplay_requested() -> bool:
	if OS.get_cmdline_user_args().has("--autoplay"):
		return true
	if OS.has_feature("web"):
		var q: Variant = JavaScriptBridge.eval("window.location.search")
		return str(q).contains("autoplay=1") or str(q).contains("demo=1")
	return false


static func demo_requested() -> bool:
	if OS.get_cmdline_user_args().has("--demo"):
		return true
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("window.location.search")).contains("demo=1")
	return false


func _ready() -> void:
	GameFont.apply()
	telemetry = Telemetry.new()
	demo = demo_requested()
	autoplay = demo or autoplay_requested()
	var offline: bool = autoplay or DisplayServer.get_name() == "headless"
	if dictionary == null:
		dictionary = DictService.bundled(not offline)
		if not offline:
			dictionary.start_remote(self)
	act = str(dictionary.act_order()[0]) if not dictionary.act_order().is_empty() else act
	levels = dictionary.levels(act)
	settings.load_from()
	settings.apply_audio()
	music = MusicScript.new()
	music.name = "Music"
	add_child(music)
	telemetry.set_settings(settings.treatment, settings.reduced_motion, settings.hint)
	if save == null:
		if offline:
			save = Save.fake()
			if demo:
				save.set_profile("wren", _default_difficulty(), "ADA")
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
		_autoplay_level_hook()
		_begin_level_with_comms()
	elif _recovered() and not save.resume().is_empty():
		_resume_level(false)
	elif show_intro:
		_show_intro()
	else:
		_show_start()
	telemetry.mark_ready()


## True when the page reloaded itself after losing graphics (WP-F.20); reads and clears the flag.
func _recovered() -> bool:
	if recover_override != "":
		return recover_override == "1"
	if not OS.has_feature("web"):
		return false
	var v: Variant = JavaScriptBridge.eval("(function(){try{var v=sessionStorage.getItem('alx_recover');sessionStorage.removeItem('alx_recover');return v||''}catch(e){return ''}})()", true)
	return str(v) == "1"


## Drops into the remembered level from its start. `with_comms` plays the level's opening chatter.
func _resume_level(with_comms: bool) -> void:
	var r: Dictionary = save.resume()
	var lv: Array = dictionary.levels(str(r["act"]))
	# Found by id: a content update may have moved the level; gone means back to the map.
	var at := -1
	for i in lv.size():
		if str((lv[i] as Dictionary).get("id", "")) == str(r["level_id"]):
			at = i
	if at < 0:
		save.clear_resume()
		_show_map()
		return
	act = str(r["act"])
	levels = lv
	level_index = at
	print("AstroLex resumed level=%s" % str(r["level_id"]))
	if with_comms:
		_begin_level_with_comms()
	else:
		_start_level([])


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


## Web-only test hook: ?savetest=1 (own save file) prints the saved next level, &win=1 first records 1-01 as won,
## &ending=1 opens the ending screen straight away (a preview for the owner; no save is changed),
## &setresume=<id> remembers that level as the one being played (the recovery check, WP-F.20).
func _save_debug_hook() -> void:
	var q := _savetest_query()
	if q == "" or autoplay or levels.is_empty():
		return
	if q.contains("win=1"):
		save.record_level(act, str((levels[0] as Dictionary)["id"]), 0, true, 100, 1)
		_sync_level_index()
	var at := q.find("setresume=")
	if at >= 0:
		var want := q.substr(at + 10).get_slice("&", 0)
		for i in levels.size():
			if str((levels[i] as Dictionary).get("id", "")) == want:
				save.set_resume(act, i, want)
	if q.contains("ending=1"):
		if save.player_name() == "":
			save.set_profile("wren", _default_difficulty(), "KIT")
		_show_ending.call_deferred()
	print("AstroLex save next=%s" % str((levels[level_index] as Dictionary)["id"]))


## Web-only autoplay hook: ?autoplay=1&level=4-05 plays that level instead of 1-01 (evidence clips of later acts).
func _autoplay_level_hook() -> void:
	if not OS.has_feature("web"):
		return
	var q := str(JavaScriptBridge.eval("window.location.search"))
	var at := q.find("level=")
	if at < 0:
		return
	var want := q.substr(at + 6).get_slice("&", 0)
	for a: String in dictionary.act_order():
		var lv: Array = dictionary.levels(a)
		for i in lv.size():
			if str((lv[i] as Dictionary).get("id", "")) == want:
				act = a
				levels = lv
				level_index = i
				return


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


## Frame cap from the tunables: the play rate on the field, the lower menu rate everywhere else.
func _cap_fps(play: bool) -> void:
	Engine.max_fps = int(GameData.load_tunables()["perf.playFps" if play else "perf.menuFps"])


func _swap(node: Node) -> void:
	_close_pause()
	if screen != null:
		remove_child(screen)
		screen.queue_free()
	screen = node
	if node.name != "Field":
		_cap_fps(false)
		daily_date = ""
		music.play(MusicScript.MENU)
	add_child(node)


# --- screens -----------------------------------------------------------------------------

## The once-per-launch intro: a tap or its timer goes to the title.
func _show_intro() -> void:
	show_intro = false
	var s: Control = IntroScreen.new()
	s.settings = settings
	s.fade_sec = intro_fade_sec
	s.finished.connect(_show_start)
	_swap(s)


func _show_start() -> void:
	var s: Control = StartScreen.new()
	s.name = "StartScreen"
	s.settings = settings
	s.start_label = "Continue" if save.has_profile() else "New game"
	s.start_pressed.connect(func() -> void:
		if save.has_profile():
			if save.resume().is_empty():
				_show_map()
			else:
				_resume_level(true)
		else:
			_show_character(false, func() -> void: _show_difficulty(false, _show_map)))
	s.settings_pressed.connect(_show_settings.bind(_show_start))
	DailyHooks.decorate_start(self, s)
	_swap(s)
	if not _ready_printed:
		_ready_printed = true
		print("AstroLex ready: %d tiles" % s.tile_count)


func _start_daily() -> void:
	DailyHooks.start(self)


func _on_daily_finished(summary: Dictionary) -> void:
	DailyHooks.finished(self, summary)


func _show_character(can_cancel: bool, then: Callable) -> void:
	var s: Control = CharacterSelect.new()
	s.name = "CharacterSelect"
	s.reduced_motion = settings.reduced_motion
	s.characters = _characters()
	s.selected = str(save.profile().get("character", ""))
	s.can_cancel = can_cancel
	s.player_name = save.player_name()
	s.blocklist = dictionary.content().get("blocklist", [])
	s.confirmed.connect(func(id: String, nm: String) -> void:
		var diff: String = str(save.profile().get("difficulty", ""))
		save.set_profile(id, diff if diff != "" else _default_difficulty(), nm)
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
		save.set_profile(str(p.get("character", "")), id, str(p.get("name", "")))
		then.call())
	s.cancelled.connect(then)
	_swap(s)


func _show_map() -> void:
	if save.has_profile() and save.player_name() == "" and not autoplay:
		# An older save, or a profile without a name: ask for it before the map (WP-F.2).
		_show_character(false, _show_map)
		return
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
	m.codex_pressed.connect(_show_codex.bind(_show_map))
	m.inbox_pressed.connect(_show_inbox.bind(_show_map))
	m.daily_pressed.connect(_start_daily)
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
	s.codex_pressed.connect(_show_codex.bind(_show_settings.bind(back)))
	s.credits_pressed.connect(func() -> void: _show_credits(_show_settings.bind(back)))
	_wire_report(s, "settings")
	_swap(s)


## Report a problem / Copy report on a settings screen (WP-F.20).
func _wire_report(s: Control, screen_name: String) -> void:
	s.report_pressed.connect(func() -> void: telemetry.send_bug_report(_report_context(screen_name)))
	s.copy_report_pressed.connect(func() -> void: telemetry.copy_bug_report(_report_context(screen_name)))


func _report_context(screen_name: String) -> Dictionary:
	var next: Dictionary = {}
	for a: String in save.act_order:
		next[a] = save.next_level(a)
	var level_id := ""
	if _field() != null and not levels.is_empty():
		level_id = "daily-%s" % daily_date if daily_date != "" else str((levels[level_index] as Dictionary).get("id", ""))
	return {
		"act": act, "level": level_id, "screen": screen_name, "next": next,
		"difficulty": str(save.profile().get("difficulty", "")), "character": str(save.profile().get("character", "")),
	}


func _show_codex(back: Callable) -> void:
	var c: Control = CodexScreen.new()
	c.name = "CodexScreen"
	c.save = save
	c.dictionary = dictionary
	c.closed.connect(back)
	_swap(c)


func _show_inbox(back: Callable) -> void:
	var c: Control = InboxScreen.new()
	c.name = "InboxScreen"
	c.save = save
	c.dictionary = dictionary
	c.reduced_motion = settings.reduced_motion
	c.closed.connect(back)
	_swap(c)


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
	return catcher_comms((levels[index] as Dictionary).get(key, []), _profile_character(), save.player_name())


## The Catcher's lines (WP-F.27) in the picked suit's voice: its own reply, its colour, and the
## player's name over the bubble (the suit's name when there is none). Other lines pass through.
static func catcher_comms(messages: Array, character: Dictionary, player_name: String) -> Array:
	var out: Array = []
	for m: Dictionary in messages:
		if str(m.get("who", "")) != "catcher":
			out.append(m)
			continue
		var suit := str(character.get("id", ""))
		var lines: Dictionary = m.get("lines", {})
		out.append({
			"who": "catcher",
			"text": str(lines.get(suit, m.get("text", ""))),
			"suit": suit,
			"colour": str(character.get("colour", "#00ddff")),
			"name": player_name.capitalize() if player_name != "" else str(character.get("name", "You")),
		})
	return out


## The chatter to play: none in autoplay (the CI smoke), all of it otherwise and in the demo.
func _story(messages: Array) -> Array:
	return [] if autoplay and not demo else messages


func _field() -> Node:
	if screen != null and is_instance_valid(screen) and screen.name == "Field":
		return screen
	return null


## Plays `messages` on the game screen, then calls `then` (at once when there is nothing to play).
func _story_then(messages: Array, then: Callable) -> void:
	var f := _field()
	var m := _story(messages)
	if f == null or m.is_empty():
		then.call()
		return
	f.play_story(m, then)


## The current level's chatter, then play.
func _begin_level_with_comms() -> void:
	_start_level(_comms_of(level_index, "commsBefore"))


## Plays the current level. The game screen stays up when it already is (next level, retry,
## restart) and changes over in place; `story` plays on it before Babel throws the letters.
func _start_level(story: Array = []) -> void:
	if levels.is_empty():
		push_error("main: no levels for %s; back to the map" % act)
		_show_map()
		return
	var level: Dictionary = levels[level_index]
	if daily_date != "":
		level = Daily.make_level(daily_date, dictionary.content())
	elif _is_final_level():
		level = finale_level(level, save.player_name())
	if not autoplay and daily_date == "":
		save.set_resume(act, level_index, str(level["id"]))
	if act == "act3_tower" and str(level["id"]) == "3-06" and not autoplay and not save.flag("flashback_seen"):
		_play_flashback(_start_level.bind(story))  # the Loud Wars flashback, once
		return
	var ch := _profile_character()
	var cosmetic := not autoplay or demo
	_close_pause()
	var f: Node = _field()
	if f == null:
		f = FieldScene.instantiate()
		f.name = "Field"
		f.settings = settings
		f.music = music
		f.autoplay = autoplay
		f.view_size = get_viewport().get_visible_rect().size
		f.print_ready = not _ready_printed
		_ready_printed = true
		if cosmetic and ch.has("colour"):
			f.tether_colour = Color(str(ch["colour"]))
		if cosmetic and ch.has("id"):
			f.character_id = str(ch["id"])
			f.character_name = str(ch.get("name", ch["id"]))
		f.content_override = dictionary.content()
		f.round_finished.connect(_on_level_finished)
		f.pause_requested.connect(func() -> void: _show_pause(f))
		f.settings_requested.connect(func() -> void: _show_field_settings(f))
		_swap(f)
	else:
		f.set_paused(false)
	_cap_fps(true)
	music.play(act)
	f.level_counter = Daily.short_date(daily_date) if daily_date != "" else "Level %d / %d" % [level_index + 1, levels.size()]
	telemetry.set_settings(settings.treatment, settings.reduced_motion, settings.hint)
	var diff_id := "" if autoplay else str(_profile_difficulty().get("id", ""))
	var char_id := "" if autoplay else str(ch.get("id", ""))
	telemetry.begin_round(f, level_index + 1, int(level["seed"]), str(level["id"]), Daily.TELEMETRY_ACT if daily_date != "" else act, char_id, diff_id)
	f.coach_enabled = not autoplay and save.total_stars() == 0  # first-play coach (WP-3.Q)
	f.coach_drones = not autoplay and save.next_level(act) <= 3  # nobody past 1-03 has met the drones
	f.begin_level(level, Daily.ROUND_ACT if daily_date != "" else act, _mods(), _story(story))


## 4-12: the level's words become LISTEN, then the Catcher's name (the file keeps a placeholder).
## Without a name (autoplay) the placeholder stays.
static func finale_level(level: Dictionary, player_name: String) -> Dictionary:
	var l: Dictionary = level.duplicate(true)
	var w: Array = l["words"]
	if player_name != "":
		w[w.size() - 1] = PlayerName.clean(player_name).to_lower()
	l["finale"] = true
	return l


func _is_final_level() -> bool:
	var order: Array = dictionary.act_order()
	return not order.is_empty() and act == str(order[order.size() - 1]) and level_index >= levels.size() - 1


func _on_level_finished(summary: Dictionary, level: Dictionary = {}) -> void:
	if daily_date != "":
		_on_daily_finished(summary)
		return
	if level.is_empty():
		level = levels[level_index]
	summary["level"] = str(level["id"])
	summary["act"] = act
	if level.has("vanta"):
		summary["vanta"] = float(level["vanta"])  # VANTA's time to beat (WP-F.27)
	var won: bool = summary.get("won", false)
	var stars: int = int(summary.get("stars", 1 if won else 0))
	save.record_level(act, str(level["id"]), level_index, won, int(summary.get("score", 0)), stars)
	_show_card(summary)


## The level card on the game screen: the stars fly in; Next, Retry or Map.
func _show_card(summary: Dictionary) -> void:
	var f := _field()
	if f == null:
		_show_map()
		return
	var c: Control = LevelCard.new()
	c.name = "LevelCard"
	c.summary = summary
	c.telemetry = telemetry
	c.next.connect(_go_next)
	c.retry.connect(_start_level)
	c.map.connect(_show_map)
	f.show_card(c)
	if demo and bool(summary.get("won", false)) and is_inside_tree():
		get_tree().create_timer(DEMO_NEXT_SEC).timeout.connect(func() -> void:
			if is_instance_valid(c) and c.is_inside_tree():
				c.call("choose", "next"))


## Next after a win: the level's closing chatter and the next level's opening chatter on the game
## screen, then its letters; after the last level of an act, the closing chatter, then the
## act-complete screen (the ending after the very last level).
func _go_next() -> void:
	var after: Array = _comms_of(level_index, "commsAfter")
	if _is_final_level():
		_show_ending()  # the ending carries Rhee's and Tomas's closing lines itself
	elif level_index < levels.size() - 1:
		level_index += 1
		_start_level(after + _comms_of(level_index, "commsBefore"))
	else:
		_story_then(after, _show_complete.bind(false))


func _show_ending() -> void:
	var e: Control = Ending.new()
	e.name = "Ending"
	e.player_name = save.player_name()
	e.total_stars = save.total_stars()
	e.reduced_motion = settings.reduced_motion
	e.back_to_map.connect(_show_map)
	e.credits_pressed.connect(func() -> void: _show_credits(_show_map))
	_swap(e)


func _show_credits(back: Callable) -> void:
	var c: Control = Credits.new()
	c.name = "Credits"
	c.closed.connect(back)
	_swap(c)


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
	c.new_message = StoryData.unread(save, dictionary) > 0
	c.open_inbox.connect(_show_inbox.bind(_show_map))
	_swap(c)


# --- pause -------------------------------------------------------------------------------

func _show_pause(f: Node) -> void:
	if pause_menu != null:
		return
	f.set_paused(true)
	_cap_fps(false)
	var p: Control = PauseMenu.new()
	p.name = "PauseMenu"
	p.resumed.connect(func() -> void:
		_close_pause()
		_cap_fps(true)
		f.set_paused(false))
	p.restarted.connect(func() -> void:
		_close_pause()
		_start_level())
	p.quit.connect(func() -> void:
		_close_pause()
		telemetry.playing = false
		save.clear_resume()
		_show_map())
	pause_menu = p
	var layer := CanvasLayer.new()  # above the field's HUD layer
	layer.name = "PauseLayer"
	layer.layer = 40
	layer.add_child(p)
	add_child(layer)


## The field's settings button: pause, then settings on top; closing returns to the pause menu.
func _show_field_settings(f: Node) -> void:
	if pause_menu == null:
		_show_pause(f)
	if pause_menu == null or has_node("FieldSettings"):
		return
	pause_menu.visible = false
	var layer := CanvasLayer.new()
	layer.name = "FieldSettings"
	layer.layer = 45
	var back := ColorRect.new()
	back.color = Color(0.03, 0.05, 0.12, 0.94)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(back)
	var s: Control = SettingsScreen.new()
	s.name = "SettingsScreen"
	s.settings = settings
	s.show_sky = false
	_wire_report(s, "field")
	s.closed.connect(func() -> void:
		layer.queue_free()
		if pause_menu != null:
			pause_menu.visible = true)
	layer.add_child(s)
	add_child(layer)


func _close_pause() -> void:
	var fs := get_node_or_null("FieldSettings")
	if fs != null:
		fs.queue_free()
	if pause_menu != null:
		var holder := pause_menu.get_parent()
		if holder is CanvasLayer:
			holder.queue_free()
		else:
			pause_menu.queue_free()
		pause_menu = null


# --- flashback (WP-F.7) --------------------------------------------------------------------

## The wordless Act III flashback over whatever is showing; `then` runs when it ends.
func _play_flashback(then: Callable) -> void:
	var p: Control = Flashback.new()
	p.reduced_motion = settings.reduced_motion
	var layer := CanvasLayer.new()
	layer.name = "AnimaticLayer"
	layer.layer = 60
	layer.add_child(p)
	add_child(layer)
	var music: Variant = get("music")
	if music != null and (music as Object).has_method("duck"):
		music.duck(true)
	p.finished.connect(func(_skipped: bool) -> void:
		save.set_flag("flashback_seen")
		if music != null and is_instance_valid(music as Object) and (music as Object).has_method("duck"):
			music.duck(false)
		remove_child(layer)
		layer.queue_free()
		if then.is_valid():
			then.call())

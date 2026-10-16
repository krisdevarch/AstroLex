extends Node2D
## The play field: owns one Round, maps field units to the screen, animates its events and
## shows the HUD. All rules live in res://rules/; this file only draws and forwards taps.

const Targeting := preload("res://rules/targeting.gd")
const RoundScript := preload("res://rules/round.gd")
const GameData := preload("res://rules/game_data.gd")
const TileViewScript := preload("res://scenes/tile_view.gd")
const TileViewScene: PackedScene = preload("res://scenes/tile_view.tscn")
const LightRig := preload("res://scenes/light_rig.gd")
const ActBackdrop := preload("res://scenes/act_backdrop.gd")
const AppSettings := preload("res://scenes/app_settings.gd")
const Ui := preload("res://scenes/ui.gd")
const FpsMeter := preload("res://scenes/fps_meter.gd")
const HudArt := preload("res://scenes/hud_art.gd")
const GameFont := preload("res://scenes/game_font.gd")

const BabelViewScript := preload("res://scenes/babel_view.gd")
const ThiefViewScript := preload("res://scenes/thief_view.gd")
const Sfx := preload("res://scenes/sfx.gd")
const Coach := preload("res://scenes/coach.gd")
const StoryStrip := preload("res://scenes/story_strip.gd")
const DEFAULT_ACT := "act1_low_orbit"
const LOW_TIME := 5.0
const FLOAT_SEC := 0.9
const POP_SEC := 0.8
const AMBER := Color("F8BC04")
const SLOT_EDGE := Color("3cbfd2")  # the mock's teal slot outline
# The owner's tray mock (16:51): a navy tray with a slate rim, near-black slots with a teal outline,
# cream letter tiles with a darker bottom lip, and an orange Hint button with a glowing bulb.
const TRAY_FILL := Color(0.09, 0.12, 0.2, 0.95)
const TRAY_EDGE := Color("2f3b58")
const SLOT_FILL := Color("121826")
const TILE_CREAM := Color("f6ebcd")
const TILE_LIP := Color("d4bf92")
const TILE_INK := Color("1c2740")
const HINT_FILL := Color("f7a21d")
const HINT_RIM := Color("9c540c")
const CLOCK_TEXT := Color(1.0, 0.85, 0.78)
const PERIWINKLE := Color("7579f0")
const TEXT_CREAM := Color("efe8d6")  # the mock's warm off-white for HUD text
const BAND_FILL := Color(0.15, 0.15, 0.3, 0.92)
const RED := Color(1.0, 0.3, 0.3)
# Pure layout and pacing constants (screen pixels at 1080 wide, seconds). Bottom items are offsets
# up from the real bottom of the visible viewport, so taller phones just add field height.
const END_DELAY := 1.0
const TOAST_SEC := 1.1
const TYPE_CPS := 38.0
const TETHER_FADE := 0.12
const PULSE_SEC := 0.45
const HINT_GLOW_SEC := 1.5
const HINT_FLASH_SEC := 0.45
# Layout from the owner's mock (13 Oct 2026), in pixels at 1080 wide. Bottom items are offsets up
# from the real bottom of the visible viewport, so taller phones just add field height.
const SIDE_PAD := 44.0
const EDGE := 44.0
const CHIP_Y := 55.0
const CHIP_H := 80.0
const CHIP_MID_W := 356.0  # the centre chip: the level name
const BAND_Y := 180.0  # Babel's speech bubble
const BAND_H := 102.0
const BAND_INSET := 105.0
const BAND_TAIL := 26.0
const FIELD_TOP := 320.0  # top of the play field (below Babel's bubble)
const FIELD_BOTTOM_UP := 560.0  # bottom of the play field, just above Earth's rim
const PANEL_TOP_UP := 530.0  # highest point of Earth's rim
const PORTRAIT_X := 223.0
const PORTRAIT_UP := 290.0
const PORTRAIT_D := 300.0
const NAME_UP := 76.0  # centre of the name pill
const NAME_W := 256.0
const NAME_H := 64.0
const TRAY_X := 412.0  # left edge of the slot tray; it runs to the right margin
const TRAY_TOP_UP := 378.0
const TRAY_BOTTOM_UP := 156.0
const TRAY_PAD := 20.0
const ROW1_UP := 320.0  # centre of the active word's row
const ROW2_UP := 216.0  # centre of the next word's row
const SLOT_MAX := 78.0
const SLOT_GAP := 10.0
const SLOTS_PER_ROW := 7
const HINT_D := 88.0  # round Hint button at the right end of the next word's row
const BOTTOM_UP := 76.0  # centre of the timer pill and the round buttons
const BTN_SIZE := 88.0
const BTN_GAP := 14.0
const TIMER_H := 70.0
const CLOCK_LABEL_W := 110.0
const COST_FLOAT_UP := 600.0
# Babel's throw: look of a single flight (timing and perch are tunables under babel.*).
const THROW_START_SCALE := 0.15
const INTRO_MAX_STEP := 0.1  # a load hitch (up to 0.25 s) must not skip the first launches; slow phones still run at speed
const EXIT_LEAD := 0.12  # Babel leaves this long after the last launch

signal round_finished(summary: Dictionary)
## Every rules event, as the field applies it (for telemetry and other listeners).
signal game_event(e: Dictionary)
## A tap that fired nothing; nearest_px is the distance to the nearest catchable tile, or -1.
signal tap_missed(nearest_px: float)
## The pause button, Escape or Android back was pressed; the flow decides and calls set_paused.
signal pause_requested
## The settings button was pressed; the flow pauses and opens the settings screen.
signal settings_requested

## Colour of the tether and the catch flash (the flow sets it per character).
var tether_colour: Color = Color(0.55, 0.9, 1.0, 1.0)
## The chosen Catcher (the flow sets them); an empty id shows no portrait (autoplay).
var character_id: String = ""
var character_name: String = ""
## "Level n / N" within the act (the flow sets it); empty hides the chip.
var level_counter: String = ""
## Where the sound switch saves.
var settings_path: String = AppSettings.PATH
## When non-empty, used instead of GameData.load_content().
var content_override: Dictionary = {}
var paused: bool = false
var autoplay: bool = false
var print_ready: bool = true
var view_size: Vector2 = Vector2(1080, 1920)
var settings: AppSettings = AppSettings.new()
var game_round: RoundScript
var last_babel: String = ""
var finished: bool = false
## Babel flies in, speaks and shoots the round's letters before play starts (visual only).
var intro_enabled: bool = true
## First-play coach (WP-3.Q): main turns it on for a save with no win yet, and the drone hint for a
## player who has not got past level 1-03. Never in autoplay.
var coach_enabled: bool = false
var coach_drones: bool = false

var _intro_on: bool = false
var _settle_t: float = 99.0  # time since the throw ended, while the letters ease into their drift
var _intro_t: float = 0.0
var _intro_dur: float = 0.0
var _intro_order: Dictionary = {}  # tile_id -> launch index
var _intro_origin: Dictionary = {}  # tile_id -> muzzle position at launch (launched tiles only)
var _intro_quote: String = ""  # this level's Babel line; empty for the endless rounds
var _intro_throw_at: float = 0.0  # intro time the first letter leaves
var _intro_exiting: bool = false
var _spawn_grow: bool = false  # letters made mid-play grow in
var _babel: Node2D
var _coach: Coach
var _coach_stage: int = 0  # 0 waiting for the throw, 1 pointing at a letter, 2 slot caption, 3 done
var _coach_left: float = 0.0
var _coach_drone_seen: bool = false  # the drone hint is shown once per screen
var _coach_drone_on: bool = false

var _level_title: String = ""
var _level_label: Label
var _counter_label: Label
var _tun: Dictionary = {}
var _content: Dictionary = {}
var _scale: float = 1080.0
var _ft: float = FIELD_TOP  # screen y of the field top (field y = topMargin)
var _field_x: float = 0.0  # screen x of the field left edge (the field is centred)
var _time: float = 0.0
var _ap_timer: float = 0.0
var _views: Dictionary = {}  # tile_id -> TileView
var _pending: Dictionary = {}  # Vector2i(absolute word, slot) -> true while a caught tile flies
var _view_word: int = 0
var _end_t: float = -1.0
var _toast_t: float = 0.0
## Hazards that have bitten already this run: each gets its one-line toast the first time only (WP-F.1).
var _hazard_seen: Dictionary = {}
var _babel_t: float = 99.0
var _pulse_t: float = 99.0
var _tether_fade: float = 0.0
var _tether_end: Vector2 = Vector2.ZERO
var _fx: Array = []  # [node, ttl]
var _thief_views: Dictionary = {}  # thief_id -> ThiefView
var _floats: Array = []  # [Label, age] floating "-1 s" texts
var _clock_label: Label
var _time_bar: ProgressBar
var _pause_button: Button
var _pause_icon: Control
var _hint_button: Button
var _sound_button: Button
var _sound_icon: Control
var _settings_button: Button
var _hint_flash_t: float = 0.0
var _fill_coral: StyleBoxTexture
var _fill_crimson: StyleBoxTexture
var _portrait: Control
var _fly_layer: CanvasLayer
var _score_row: HBoxContainer
var _low: bool = false
var _active_key: String = ""
var _preview_key: String = ""
var _active_n: int = 0
var _preview_n: int = 0

var _world: CanvasLayer
var _backdrop: Node2D
var _item_deck: Array = []  # back-plane item art, dealt in a seeded order so items rarely repeat
var _seed: int = 0
var _night: Control
var _tiles_root: Node2D
var _fx_layer: CanvasLayer
var _hud: CanvasLayer
var _tether: Line2D
var _active_row: Control
var _preview_row: Control
var _score_label: Label
var _combo_label: Label
var _toast: Label
var _band: Panel
var _band_label: Label
var _fps_meter: CanvasLayer
## Game feel (WP-3.N): placeholder sounds, the combo pop, the restored-word banner, the shake.
var sfx: Sfx
var _pops: Array = []  # [Label, age, start_pos] rising combo pops
var _banner: Label
var _banner_t: float = 99.0
var _shake_t: float = 0.0
var _shake_px: float = 0.0
var _beat_sec: int = -1
## Browsers refuse (and log an error for) a vibration before the player has touched the page.
var _touched: bool = false
## Between levels (WP-3.O): the field stays up from one level to the next. When a level ends the
## leftover letters drift away and the level card rises here; on Next the crew's chatter plays here,
## the chips, slots and clock change over, and Babel throws the next level's letters.
var _launcher: Node2D
var _cleared: bool = false
var _card_layer: CanvasLayer
var _card: Control
var _story: Control
var _story_on: bool = false
var _refill_t: float = -1.0
var _refill_from: float = 0.0
var _chip_t: float = 99.0
var _slots_in_t: float = 99.0
const CHIP_SWAP_SEC := 0.5
const SLOT_IN_SEC := 0.28
const SLOT_IN_STAGGER := 0.05


func _process(delta: float) -> void:
	if game_round != null:
		advance(minf(delta, 0.25))


func _n(key: String) -> float:
	return float(_tun[key])


## Starts a round. Call after the field is in the tree.
func begin(round_no: int, seed_value: int) -> void:
	_tun = GameData.load_tunables()
	_content = content_override if not content_override.is_empty() else GameData.load_content()
	game_round = RoundScript.create(_tun, _content, DEFAULT_ACT, seed_value, round_no)
	_intro_quote = ""
	_start(seed_value)


## Starts an authored level (its words in order, its tuning and seed). Call after the field is in the tree.
## Called again on the same field for the next level (or a retry): the screen stays and changes over
## in place. `story` is the crew's chatter to play on this screen before Babel throws the letters.
func begin_level(level: Dictionary, act: String = DEFAULT_ACT, mods: Array = [], story: Array = []) -> void:
	_tun = GameData.load_tunables()
	_content = content_override if not content_override.is_empty() else GameData.load_content()
	game_round = RoundScript.create_level(_tun, _content, act, level, mods)
	_intro_quote = str(level.get("babelIntro", "")) if bool(level.get("babel", false)) else ""
	_level_title = str(level.get("title", level.get("id", "")))  # the mock shows the name; "Level n / N" gives the number
	_start(int(level["seed"]), story)


func _start(seed_value: int, story: Array = []) -> void:
	GameFont.apply()
	_seed = seed_value
	_spawn_grow = false
	if _hud != null:
		_reset_for_level()
	else:
		_build_once()
	_apply_events()
	_sync_views()
	_update_hud()
	if story.is_empty():
		_start_intro(seed_value)
	else:
		play_story(story, _start_intro.bind(seed_value))
	if print_ready:
		print_ready = false
		print("AstroLex ready: %d tiles" % game_round.tiles.size())


func _build_once() -> void:
	_scale = view_size.x
	# One uniform scale for x and y: the field fits between Babel's band and the bottom HUD and is
	# centred sideways (the backdrop still fills the screen). Layout maths assume at least 1600 high.
	view_size.y = maxf(view_size.y, 1600.0)
	var avail := view_size.y - FIELD_BOTTOM_UP - FIELD_TOP
	var span := _n("field.height") - _n("field.topMargin")
	_scale = minf(view_size.x, avail / span)
	_field_x = (view_size.x - _scale) * 0.5
	_ft = FIELD_TOP + (avail - span * _scale) * 0.5
	_build_world()
	_build_hud()
	if sfx == null:
		sfx = Sfx.new()
		sfx.name = "Sfx"
		add_child(sfx)
	sfx.volume_db = _n("sfx.volumeDb")


## The next level (or a retry) on the same screen: what the last level left behind goes, the chips
## cross-fade to the new name and number, the slots pop in empty and the clock bar refills.
func _reset_for_level() -> void:
	_drop_story()  # a Restart from the pause menu during the chatter
	if _backdrop != null:
		_backdrop.set_act(game_round.act)
	last_babel = ""  # a new level: Babel has not spoken yet
	_babel_t = 99.0
	_cleared = false
	_intro_on = false
	_coach_reset()
	if _babel != null:
		_babel.hide_now()
	for id in _views.keys():
		(_views[id] as Node).queue_free()
	_views.clear()
	for id in _thief_views.keys():
		(_thief_views[id] as Node).queue_free()
	_thief_views.clear()
	for f in _floats:
		(f[0] as Node).queue_free()
	_floats.clear()
	for p in _pops:
		(p[0] as Node).queue_free()
	_pops.clear()
	_pending.clear()
	_fly_keys.clear()
	_item_deck.clear()
	_view_word = 0
	_active_key = ""
	_preview_key = ""
	_end_t = -1.0
	finished = false
	_beat_sec = -1
	_shake_t = 0.0
	_banner_t = 99.0
	_banner.visible = false
	_world.offset = Vector2.ZERO
	_toast_t = 0.0
	_toast.modulate.a = 0.0
	_tether.visible = false
	_tether_fade = 0.0
	_tiles_root.visible = true
	if _low:
		_low = false
		_time_bar.add_theme_stylebox_override("fill", _fill_coral)
		_clock_label.add_theme_color_override("font_color", CLOCK_TEXT)
		_clock_label.scale = Vector2.ONE
	_launcher.position = to_screen(game_round.origin())
	_level_label.text = _level_title
	_fit_title()
	_counter_label.text = level_counter
	_chip_t = 0.0
	_slots_in_t = 0.0
	_refill_from = _time_bar.value
	_refill_t = 0.0 if not settings.reduced_motion else -1.0
	if _card != null and is_instance_valid(_card):
		_card.call("dismiss")
	_card = null


## The crew's chatter on this screen; the letters wait until it ends (or is skipped), then `then`.
func play_story(messages: Array, then: Callable) -> void:
	_drop_story()
	_story_on = true
	_tiles_root.visible = false
	var s: Control = StoryStrip.new()
	s.name = "StoryStrip"
	s.messages = messages
	s.reduced_motion = settings.reduced_motion
	s.read_sec = _n("flow.storyReadSec")
	s.cps = _n("flow.storyCps")
	s.sfx = sfx
	s.position = Vector2(0.0, FIELD_TOP)
	s.size = Vector2(view_size.x, view_size.y - FIELD_BOTTOM_UP - FIELD_TOP)
	s.babel_line.connect(func(text: String) -> void:
		last_babel = text
		_babel_t = 0.0)
	s.finished.connect(func() -> void:
		_story_on = false
		_story = null
		_tiles_root.visible = not _cleared  # the act's closing chatter: the old letters stay gone
		then.call())
	_story = s
	_hud.add_child(s)


## Ends a strip that is still playing without running what was to follow it.
func _drop_story() -> void:
	if _story != null and is_instance_valid(_story):
		for c in _story.finished.get_connections():
			_story.finished.disconnect(c["callable"])
		_story.queue_free()
	_story = null
	_story_on = false


## True while the crew are talking between levels; the rules do not step meanwhile.
func story_active() -> bool:
	return _story_on


## The level card (WP-3.O) over the play field, above the HUD. The flow builds it; the field places
## it and tells it where the stars come from (the clock bar, where the time left ends).
func show_card(card: Control) -> void:
	if _card_layer == null:
		_card_layer = CanvasLayer.new()
		_card_layer.name = "CardLayer"
		_card_layer.layer = 12
		add_child(_card_layer)
	if _card != null and is_instance_valid(_card):
		_card.queue_free()
	var bar := _time_bar.get_rect()
	var share := clampf(_time_bar.value / maxf(0.01, _time_bar.max_value), 0.0, 1.0)
	card.set("star_from", Vector2(bar.position.x + maxf(TIMER_H * 0.5, bar.size.x * share - TIMER_H * 0.5), bar.get_center().y))
	card.set("centre", Vector2(view_size.x * 0.5, (FIELD_TOP + view_size.y - FIELD_BOTTOM_UP) * 0.5))
	card.set("reduced_motion", settings.reduced_motion)
	card.set("star_sec", _n("flow.starSec"))
	card.set("star_gap", _n("flow.starGapSec"))
	card.set("sfx", sfx)
	_card = card
	_card_layer.add_child(card)


## The level card now up, or null.
func card() -> Control:
	return _card if _card != null and is_instance_valid(_card) else null


func _fit_title() -> void:
	var fs := 42
	while fs > 24 and ThemeDB.fallback_font.get_string_size(_level_title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > CHIP_MID_W - 40.0:
		fs -= 2
	_level_label.add_theme_font_size_override("font_size", fs)


func to_screen(p: Vector2) -> Vector2:
	return Vector2(_field_x + p.x * _scale, _ft + (p.y - _n("field.topMargin")) * _scale)


func radius_px(t: Object) -> float:
	return float(t.get("radius")) * _scale


## Screen-space circle hit test: nearest catchable tile inside radius + margin; fires it.
## Returns the tile id, or -1 on a miss (a miss does nothing).
func tap(screen_pos: Vector2) -> int:
	if paused:
		return -1
	if _intro_on:
		skip_intro()
		return -1
	if _story_on:
		return -1
	if game_round == null or game_round.state != "play":
		return -1
	var margin := _n("tap.marginPx")
	margin *= _n("tap.driftMarginMul")
	var best_id := -1
	var best_d := INF
	var nearest := INF
	# Thieves first: a drone under the finger wins over a tile.
	for th in game_round.thieves:
		var d := to_screen(th.pos).distance_to(screen_pos)
		nearest = minf(nearest, d)
		if d <= _n("thief.radius") * _scale + margin and d < best_d:
			best_d = d
			best_id = th.id
	if best_id >= 0:
		return best_id if game_round.fire(best_id) else -1
	# Letters sit on two layers (2.5D): under the finger, the front layer wins, then the nearest.
	var best_plane := 99
	for t in game_round.tiles:
		if not t.alive or t.plane >= 2:
			continue
		var d := to_screen(t.pos).distance_to(screen_pos)
		nearest = minf(nearest, d)
		if d <= radius_px(t) + margin and (t.plane < best_plane or (t.plane == best_plane and d < best_d)):
			best_plane = t.plane
			best_d = d
			best_id = t.id
	if best_id < 0:
		tap_missed.emit(-1.0 if nearest == INF else nearest)
		return -1
	if not game_round.fire(best_id):
		return -1
	return best_id


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_touched = true
		tap(event.position)
	elif event.is_action_pressed("ui_cancel"):
		pause_requested.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		pause_requested.emit()


## Freezes or resumes everything: rules, intro, effects; taps are ignored while paused.
func set_paused(on: bool) -> void:
	paused = on
	if _coach != null:
		_coach.modulate.a = 0.0 if on else 1.0
	if _pause_icon != null:
		_pause_icon.set("kind", "play" if on else "pause")


func advance(delta: float) -> void:
	if game_round == null or paused:
		return
	_time += delta
	if _babel != null:
		_babel.tick(minf(delta, INTRO_MAX_STEP))
	if _story_on or _intro_on:
		if _story != null:
			_story.call("tick", delta)
		if _intro_on:
			_tick_intro(minf(delta, INTRO_MAX_STEP))
		_update_hud()
		_tick_hud(delta)
		return
	if autoplay:
		_autoplay_tick(delta)
	# After the throw the letters ease from still into their drift (babel.settleSec) rather than
	# all starting to move on one frame.
	var settle := _n("babel.settleSec")
	if _settle_t < settle:
		_settle_t += delta
		game_round.drift_scale = smoothstep(0.0, settle, _settle_t)
	else:
		game_round.drift_scale = 1.0
	game_round.step(delta)
	_apply_events()
	_sync_views()
	if _fps_meter != null:
		_fps_meter.tiles = _views.size()
	_tick_views(delta)
	_update_tether(delta)
	_update_hud()
	_tick_hud(delta)
	_tick_feel(delta)
	_tick_coach(delta)
	if _end_t >= 0.0 and not finished:
		_end_t += delta
		if _end_t >= END_DELAY:
			finished = true
			round_finished.emit(summary())


func summary() -> Dictionary:
	return {
		"won": game_round.state == "won",
		"mode": game_round.mode,
		"round_no": game_round.round_no,
		"score": int(round(game_round.score)),
		"words_done": game_round.restored_words.size(),
		"words_total": game_round.words.size(),
		"secs": float(game_round.stats["secs"]),
		"catches": int(game_round.stats["catches"]),
		"wrong": int(game_round.stats["wrong"]),
		"babel": last_babel,
		"stars": game_round.stars(),
		"time_left": game_round.time_left,
		"act": game_round.act,
		"stolen": int(game_round.stats["stolen"]),
		"thieves_down": int(game_round.stats["thieves_down"]),
		"counterfeits": int(game_round.stats["counterfeits"]),
		"traps": int(game_round.stats["traps"]),
		"jams": int(game_round.stats["jams"]),
	}


# --- Babel throws the letters ------------------------------------------------------------

## True while Babel is still throwing the letters; the rules do not step meanwhile.
func intro_active() -> bool:
	return _intro_on


func _start_intro(seed_value: int) -> void:
	if not intro_enabled:
		_spawn_grow = true
		_coach_begin()
		return
	_ensure_babel()
	_babel.hide_now()
	_intro_order.clear()
	_intro_origin.clear()
	var ids: Array = []
	for t in game_round.tiles:
		ids.append(t.id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in range(ids.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = ids[i]
		ids[i] = ids[j]
		ids[j] = tmp
	for i in ids.size():
		_intro_order[ids[i]] = i
	var throw_sec := _n("babel.throwSec")
	var talk := 0.0
	if _intro_quote != "":
		talk = _babel.typing_sec(_intro_quote) + _n("babel.quoteSec")
	_intro_throw_at = maxf(_n("babel.enterSec"), talk)  # the bubble types while he flies in
	var spread := 0.0 if settings.reduced_motion else _n("babel.throwStagger") * float(maxi(ids.size() - 1, 0))
	_intro_dur = _intro_throw_at + throw_sec + spread
	_intro_t = 0.0
	_intro_on = true
	_intro_exiting = false
	_babel.fly_in()
	if _intro_quote != "":
		_babel.say(_intro_quote)
	_pose_intro()


func _ensure_babel() -> void:
	if _babel != null:
		return
	_babel = BabelViewScript.new()
	_babel.name = "Babel"
	_babel.cps = TYPE_CPS
	_babel.setup(view_size, _tun, settings.reduced_motion)
	_fx_layer.add_child(_babel)


## Ends the intro at once: Babel is gone, every tile snaps to its place and play starts.
func skip_intro() -> void:
	_end_intro(true)


func _end_intro(babel_leaves_now: bool) -> void:
	if not _intro_on:
		return
	_intro_on = false
	_coach_begin()
	_spawn_grow = true
	_settle_t = 0.0 if not settings.reduced_motion else 99.0
	if _babel != null and babel_leaves_now:
		_babel.hide_now()
	for id in _views.keys():
		var v: TileViewScript = _views[id]
		v.scale = Vector2.ONE
		v.visible = true
		v.modulate.a = _n("plane.backAlpha") if v.is_back else 1.0
	_sync_views()


func _tick_intro(delta: float) -> void:
	_intro_t += delta
	if _intro_t >= _intro_dur:
		_end_intro(false)  # Babel may still be flying out; he finishes on his own
		return
	_sync_views()
	_pose_intro()


func _pose_intro() -> void:
	var throw_sec := maxf(_n("babel.throwSec"), 0.01)
	var stagger := _n("babel.throwStagger")
	var s := _n("babel.throwOvershoot")
	var last_launch := _intro_throw_at + stagger * float(maxi(_intro_order.size() - 1, 0))
	if _babel.is_talking() and _intro_t >= _intro_throw_at:
		_babel.close_bubble()
	if not _intro_exiting and _intro_t >= (_intro_throw_at + throw_sec if settings.reduced_motion else last_launch + EXIT_LEAD):
		_intro_exiting = true
		_babel.fly_out()
	for id in _views.keys():
		var v: TileViewScript = _views[id]
		var real := to_screen(game_round.find_tile(id).pos)
		var base_a := _n("plane.backAlpha") if v.is_back else 1.0
		if settings.reduced_motion:
			var f := clampf((_intro_t - _intro_throw_at) / throw_sec, 0.0, 1.0)
			v.position = real
			v.scale = Vector2.ONE
			v.modulate.a = base_a * f
			continue
		var start: float = _intro_throw_at + float(_intro_order.get(id, 0)) * stagger
		if _intro_t < start:
			v.visible = false
			continue
		if not _intro_origin.has(id):
			_intro_origin[id] = _babel.muzzle_position()
			_babel.shoot(real)
		var u := clampf((_intro_t - start) / throw_sec, 0.0, 1.0)
		v.visible = true
		var w := u - 1.0
		var e := 1.0 + (s + 1.0) * w * w * w + s * w * w  # back ease-out
		v.position = (_intro_origin[id] as Vector2).lerp(real, e)
		var grow := clampf(u * 2.0, 0.0, 1.0)
		# One smooth flight: a gentle overshoot on the landing, no shake (the old 40 Hz wobble
		# flickered at phone frame rates and read as a glitch).
		v.scale = Vector2.ONE * lerpf(THROW_START_SCALE, 1.0, grow * grow * (3.0 - 2.0 * grow))
		v.modulate.a = base_a * clampf(u * 6.0, 0.0, 1.0)


# --- autoplay --------------------------------------------------------------------------

func _autoplay_tick(delta: float) -> void:
	_ap_timer += delta
	if _ap_timer < _n("autoplay.tapInterval"):
		return
	if game_round.state != "play" or not game_round.shot.is_empty():
		return
	_ap_timer = 0.0
	var id := Targeting.target(game_round)
	if id >= 0:
		game_round.fire(id)


# --- world -----------------------------------------------------------------------------

func _build_world() -> void:
	var backdrop := CanvasLayer.new()
	backdrop.name = "Backdrop"
	backdrop.layer = 0
	add_child(backdrop)
	_backdrop = ActBackdrop.new()
	_backdrop.name = "ActScene"
	_backdrop.act = game_round.act
	_backdrop.view_size = view_size
	_backdrop.horizon_y = view_size.y - HudArt.PANEL_H + HudArt.CREST
	_backdrop.reduced_motion = settings.reduced_motion
	backdrop.add_child(_backdrop)
	if settings.show_fps or FpsMeter.fps_requested():
		_fps_meter = FpsMeter.new()
		add_child(_fps_meter)

	_world = CanvasLayer.new()
	_world.name = "World"
	_world.layer = 1
	add_child(_world)
	var rig: Node2D = LightRig.new()
	rig.name = "LightRig"
	_world.add_child(rig)
	rig.configure(Vector2(view_size.x * 0.5, _ft + (_n("field.height") - _n("field.topMargin")) * _scale * 0.45), view_size.y * 1.1, _world.layer)
	_tiles_root = Node2D.new()
	_tiles_root.name = "Tiles"
	_world.add_child(_tiles_root)

	_fx_layer = CanvasLayer.new()
	_fx_layer.name = "Fx"
	_fx_layer.layer = 2
	add_child(_fx_layer)
	_tether = Line2D.new()
	_tether.name = "Tether"
	_tether.width = 7.0
	_tether.default_color = tether_colour
	_tether.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_tether.end_cap_mode = Line2D.LINE_CAP_ROUND
	_tether.visible = false
	_fx_layer.add_child(_tether)
	_fly_layer = CanvasLayer.new()  # above the HUD so a caught tile is seen flying into its slot
	_fly_layer.name = "Fly"
	_fly_layer.layer = 11
	add_child(_fly_layer)
	_launcher = Launcher.new()
	_launcher.name = "Launcher"
	_launcher.position = to_screen(game_round.origin())
	_fx_layer.add_child(_launcher)


class Launcher extends Node2D:
	func _draw() -> void:
		draw_circle(Vector2.ZERO, 26.0, Color(0.1, 0.16, 0.3, 0.9))
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 40, Color(0.55, 0.9, 1.0), 4.0)


func _ensure_view(t: Object) -> TileViewScript:
	if _views.has(t.id):
		return _views[t.id]
	var v: TileViewScript = TileViewScene.instantiate()
	_tiles_root.add_child(v)
	var size_px: float = t.radius * 2.0 * _scale
	var plane_scale: float = size_px / (_n("tile.size") * _scale)
	v.setup(t.ch, size_px, plane_scale, t.plane, settings.treatment, settings.reduced_motion, _tun, float(t.id) * 1.7)
	v.z_index = 2 - t.plane
	v.name = "Tile_%d" % t.id
	if t.plane == 2:
		v.set_back(_n("plane.backAlpha"), _next_item())
	elif t.plane == 1:
		v.set_depth(_n("plane.midDim"))
	if t.kind != "":
		v.set_kind(t.kind)
	v.place(to_screen(t.pos), _time, t.pos.x)
	_views[t.id] = v
	return v


## The back plane shows the owner's sticker items (owner, 13 Oct 2026: "keep the decoys in the
## background moving"), dealt from a deck shuffled by the level seed so none shows twice at once.
func _next_item() -> String:
	if _item_deck.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed + _view_word * 7919 + _views.size()
		_item_deck = TileViewScript.ITEMS.duplicate()
		for i in _item_deck.size():
			var j := rng.randi_range(i, _item_deck.size() - 1)
			var tmp = _item_deck[i]
			_item_deck[i] = _item_deck[j]
			_item_deck[j] = tmp
	return _item_deck.pop_back()


func _sync_views() -> void:
	if _cleared:
		return  # the level is over: the leftover letters are drifting off
	var live: Dictionary = {}
	for t in game_round.tiles:
		live[t.id] = true
		var v := _ensure_view(t)
		v.set_jam(game_round.jammed and t.plane < 2, t.decoy)
		v.place(to_screen(t.pos), _time, t.pos.x)
	for id in _views.keys():
		var v: TileViewScript = _views[id]
		if not live.has(id) and v.anim == "":
			v.queue_free()
			_views.erase(id)
	_sync_thieves()


func _tick_views(delta: float) -> void:
	for tv in _thief_views.values():
		(tv as ThiefViewScript).tick(delta)
		if (tv as Node2D).has_meta("fade"):
			(tv as Node2D).modulate.a = maxf(0.0, (tv as Node2D).modulate.a - delta / maxf(0.01, _n("flow.clearSec") * 0.5))
	for i in range(_floats.size() - 1, -1, -1):
		_floats[i][1] += delta
		var lab: Label = _floats[i][0]
		var k: float = float(_floats[i][1]) / FLOAT_SEC
		lab.modulate.a = clampf(1.0 - k, 0.0, 1.0)
		lab.position.y = view_size.y - COST_FLOAT_UP + (0.0 if settings.reduced_motion else 60.0 * k)
		if k >= 1.0:
			lab.queue_free()
			_floats.remove_at(i)
	for id in _views.keys():
		var v: TileViewScript = _views[id]
		if v.tick(delta):
			if v.anim == "fly":
				_unpend_for(id)
			v.queue_free()
			_views.erase(id)
	for i in range(_fx.size() - 1, -1, -1):
		_fx[i][1] -= delta
		if _fx[i][1] <= 0.0:
			(_fx[i][0] as Node).queue_free()
			_fx.remove_at(i)


func _sync_thieves() -> void:
	var live: Dictionary = {}
	for th in game_round.thieves:
		live[th.id] = true
		var v: ThiefViewScript = _thief_views.get(th.id)
		if v == null:
			v = ThiefViewScript.new()
			v.name = "Thief_%d" % th.id
			v.setup(_n("thief.radius") * _scale, settings.reduced_motion, float(th.id) * 1.3)
			_tiles_root.add_child(v)
			v.place(to_screen(th.pos))
			_thief_views[th.id] = v
		v.set_carrying(th.carrying_id >= 0)
		v.place(to_screen(th.pos))
	for id in _thief_views.keys():
		if not live.has(id):
			(_thief_views[id] as Node).queue_free()
			_thief_views.erase(id)


func thief_view_count() -> int:
	return _thief_views.size()


var _fly_keys: Dictionary = {}  # tile_id -> pending key


func _unpend_for(id: int) -> void:
	if _fly_keys.has(id):
		_pending.erase(_fly_keys[id])
		_fly_keys.erase(id)


func _update_tether(delta: float) -> void:
	var shot: Dictionary = game_round.shot
	if not shot.is_empty():
		var u := clampf(float(shot["elapsed"]) / float(shot["dur"]), 0.0, 1.0)
		var a: Vector2 = shot["from"]
		var b: Vector2 = shot["to"]
		_tether_end = to_screen(a.lerp(b, u))
		_tether_fade = TETHER_FADE
		_tether.visible = true
		_tether.modulate.a = 1.0
		_tether.points = PackedVector2Array([to_screen(a), _tether_end])
	elif _tether_fade > 0.0:
		_tether_fade -= delta
		_tether.modulate.a = clampf(_tether_fade / TETHER_FADE, 0.0, 1.0)
		if _tether_fade <= 0.0:
			_tether.visible = false


# --- events ----------------------------------------------------------------------------

func _apply_events() -> void:
	for e in game_round.drain_events():
		var type: String = e["type"]
		game_event.emit(e)
		match type:
			"spawn":
				var t := game_round.find_tile(int(e["tile_id"]))
				if t != null:
					var fresh := not _views.has(t.id)
					var nv := _ensure_view(t)
					if fresh and _spawn_grow and not _intro_on:
						nv.grow_in(_n("tile.spawnInSec"))
			"fire":
				sfx.fire()
			"catch":
				_on_catch(e)
			"dissolve":
				var dv: TileViewScript = _views.get(int(e["tile_id"]))
				if dv != null:
					dv.dissolve(_n("fx.dissolveSec"))
			"wrong":
				var wv: TileViewScript = _views.get(int(e["tile_id"]))
				if wv != null:
					wv.flash(0.45)
				var msg := "Not in the record   −%d s" % int(_n("burst.wrongCost"))
				_show_toast(msg, Color(1.0, 0.5, 0.45))
				sfx.wrong()
				_shake(_n("fx.shakePx") * 0.5)
				_buzz(60)
			"escape":
				_show_toast("It drifted off", Ui.DIM)
			"counterfeit":
				var fv: TileViewScript = _views.get(int(e["tile_id"]))
				if fv != null:
					fv.flash(0.45)
					fv.dissolve(_n("fx.dissolveSec"))
				_burst(to_screen(e["pos"]), PERIWINKLE, 18)
				_hazard_toast("counterfeit", "Forged letter   −%d s" % int(_n("burst.wrongCost")))
				sfx.wrong()
				_shake(_n("fx.shakePx") * 0.5)
				_buzz(60)
			"trap":
				_hazard_toast("trap", "Babel's trap   −%d s" % int(round(float(e["cost"]))))
				_shake(_n("fx.shakePx") * 0.7)
				_buzz(90)
			"jam_on":
				_hazard_toast("jam", "Visor jammed")
			"hint":
				var hv: TileViewScript = _views.get(int(e["tile_id"]))
				if hv != null and hv.anim == "":
					hv.glow(HINT_GLOW_SEC)
			"time_cost":
				_float_cost(float(e["amount"]))
			"thief_grab":
				var gv: ThiefViewScript = _thief_views.get(int(e["thief_id"]))
				if gv != null:
					gv.set_carrying(true)
					gv.flash()
				_show_toast("A drone grabbed a letter!", PERIWINKLE)
			"stolen":
				_show_toast("Letter stolen  −%d s" % int(_n("thief.stealCost")), Color(1.0, 0.5, 0.45))
				sfx.stolen()
			"thief_down":
				_burst(to_screen(e["pos"]), PERIWINKLE, 22)
				_show_toast("Drone down", PERIWINKLE)
				sfx.thief_down()
				_shake(_n("fx.shakePx") * 0.5)
			"restore":
				_view_word += 1
				_pulse_t = 0.0
				_celebrate(str(e["word"]))
			"babel":
				last_babel = str(e["text"])
				_babel_t = 0.0
			"round_end":
				_end_t = 0.0
				_coach_reset()
				_coach_stage = 3
				_clear_field()
				if bool(e["won"]):
					print("AstroLex round won: score=%d" % int(round(game_round.score)))


## The level is over: every letter and item still drifting lets go and floats out of the field, and
## the drones fade, so the level card has a clear sky to rise into.
func _clear_field() -> void:
	_cleared = true
	var mid := Vector2(view_size.x * 0.5, (_ft + panel_top()) * 0.5)
	var sec := _n("flow.clearSec")
	for id in _views.keys():
		var v: TileViewScript = _views[id]
		if v.anim != "":
			continue
		if settings.reduced_motion:
			v.dissolve(sec * 0.5)
			continue
		var away := v.position - mid
		if away.length() < 1.0:
			away = Vector2.from_angle(float(id) * 2.4)
		var k := 0.85 + 0.3 * fposmod(float(id) * 0.618, 1.0)
		v.scatter(away.normalized() * view_size.y * 0.55 + Vector2(0.0, -80.0), sec * k)
	for tv in _thief_views.values():
		(tv as Node2D).set_meta("fade", 1.0)


func _on_catch(e: Dictionary) -> void:
	_coach_caught()
	var id := int(e["tile_id"])
	var v: TileViewScript = _views.get(id)
	var where: String = e["where"]
	var slot := int(e["slot"])
	var key := Vector2i(_view_word + (1 if where == "preview" else 0), slot)
	_pending[key] = true
	if v != null:
		v.clear_glow()
	_fly_keys[id] = key
	if v == null:
		_unpend_for(id)
		return
	var row_n := _active_n if where == "active" else _preview_n
	var target := _slot_center(where, slot, row_n)
	var slot_px := _slot_size(where, row_n)
	if _fly_layer != null and v.get_parent() != _fly_layer:
		v.reparent(_fly_layer, false)
	v.fly_to(target, slot_px, _n("fx.flyToSlotSec"))
	_burst(target, tether_colour.lightened(0.3))
	if where == "active":
		sfx.catch_note(slot)
	else:
		sfx.catch_note(0)
	_buzz(15)
	if game_round.combo > 1.0 + 0.001:
		_combo_pop(v.position, game_round.combo)


## A rising "×1.3" where the letter was caught; it grows warmer and bigger as the combo climbs.
func _combo_pop(at: Vector2, combo: float) -> void:
	var cmax := _n("combo.max")
	var k := clampf((combo - 1.0) / maxf(0.01, cmax - 1.0), 0.0, 1.0)
	var maxed := combo >= cmax - 0.001
	var lab := Ui.label(("×%.1f  MAX" if maxed else "×%.1f") % combo, int(lerpf(44.0, 68.0, k)), AMBER.lerp(Color(1.0, 0.45, 0.25), k))
	lab.name = "ComboPop"
	lab.size = Vector2(320, 80)
	lab.pivot_offset = lab.size * 0.5
	lab.position = at - lab.size * 0.5
	_fly_layer.add_child(_ignore(lab))  # above the letters and the HUD
	_pops.append([lab, 0.0, lab.position])


## A word restored: the word bursts across the field, a chord plays and the world gives a jolt.
func _celebrate(word: String) -> void:
	sfx.restore()
	_buzz(40)
	_shake(_n("fx.shakePx"))
	_banner.text = word.to_upper() + "!"
	_banner_t = 0.0
	_burst(Vector2(view_size.x * 0.5, _banner.position.y + _banner.size.y * 0.5), AMBER, 40)


## Shakes the play field (not the HUD) for fx.shakeSec; reduced motion turns it off.
func _shake(px: float) -> void:
	if settings.reduced_motion or px <= 0.0:
		return
	_shake_px = maxf(_shake_px if _shake_t > 0.0 else 0.0, px)
	_shake_t = _n("fx.shakeSec")


## A short vibration where the device has one (Android browsers; a no-op elsewhere), once the
## player has touched the screen (never in autoplay).
func _buzz(ms: int) -> void:
	if _touched and not autoplay and not settings.reduced_motion:
		Input.vibrate_handheld(ms)


func _tick_feel(delta: float) -> void:
	if _shake_t > 0.0:
		_shake_t = maxf(0.0, _shake_t - delta)
		var a := _shake_px * _shake_t / maxf(0.01, _n("fx.shakeSec"))
		_world.offset = Vector2(sin(_time * 91.0), cos(_time * 77.0)) * a
	elif _world.offset != Vector2.ZERO:
		_world.offset = Vector2.ZERO
	for i in range(_pops.size() - 1, -1, -1):
		_pops[i][1] += delta
		var lab: Label = _pops[i][0]
		var u: float = float(_pops[i][1]) / POP_SEC
		var grow := 1.0 if settings.reduced_motion else 1.0 + 0.5 * sin(PI * minf(1.0, u * 3.0))
		lab.scale = Vector2(grow, grow)
		lab.position = _pops[i][2] - Vector2(0, 0.0 if settings.reduced_motion else 120.0 * u)
		lab.modulate.a = clampf((1.0 - u) * 2.0, 0.0, 1.0)
		if u >= 1.0:
			lab.queue_free()
			_pops.remove_at(i)
	_banner_t += delta
	var bsec := _n("fx.bannerSec")
	_banner.visible = _banner_t < bsec
	if _banner.visible:
		var u := _banner_t / bsec
		var x := minf(1.0, u / 0.2)  # a quick overshoot pop in the first fifth
		var pop := 1.0 if settings.reduced_motion else lerpf(0.4, 1.0, x) + 0.25 * sin(PI * x)
		_banner.scale = Vector2(pop, pop)
		_banner.modulate.a = clampf((1.0 - u) * 3.0, 0.0, 1.0)
	# Heartbeat once a second in the last stretch of the clock.
	if game_round.state == "play" and game_round.time_left < _n("fx.heartbeatSec"):
		var sec := int(ceil(game_round.time_left))
		if sec != _beat_sec:
			_beat_sec = sec
			sfx.heartbeat()
	else:
		_beat_sec = -1


func _float_cost(amount: float) -> void:
	var lab := Ui.label("−%s s" % (str(int(amount)) if is_equal_approx(amount, round(amount)) else "%.1f" % amount), 48, RED)
	lab.name = "CostFloat"
	lab.position = Vector2(view_size.x * 0.5 + 100.0, view_size.y - COST_FLOAT_UP)
	lab.size = Vector2(240, 60)
	_hud.add_child(lab)
	_floats.append([lab, 0.0])


func _burst(at: Vector2, colour: Color = Color(0.7, 0.95, 1.0), amount: int = 14) -> void:
	if settings.reduced_motion:
		return
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.emitting = true
	p.amount = amount
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 320.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0
	p.color = colour
	_fx_layer.add_child(p)
	_fx.append([p, 0.8])


## The one-line toast for a hazard, the first time it bites.
func _hazard_toast(key: String, text: String) -> void:
	if _hazard_seen.has(key):
		return
	_hazard_seen[key] = true
	_show_toast(text, PERIWINKLE)


func _show_toast(text: String, color: Color) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast_t = TOAST_SEC


# --- HUD -------------------------------------------------------------------------------

## Screen y of the highest point of the night panel; no catchable tile is drawn below it.
func panel_top() -> float:
	return view_size.y - PANEL_TOP_UP


## The slot tray: from TRAY_X to the right margin.
func _tray_rect() -> Rect2:
	var top := view_size.y - TRAY_TOP_UP
	return Rect2(TRAY_X, top, view_size.x - EDGE - TRAY_X, TRAY_TOP_UP - TRAY_BOTTOM_UP)


## Active word: first row of the tray, full width. Next word: second row, leaving room for Hint.
func _row_width(where: String) -> float:
	var inner := _tray_rect().size.x - 2.0 * TRAY_PAD
	return inner if where == "active" else inner - HINT_D - SLOT_GAP


## One slot size for both rows, as in the owner's tray mock (16:51): seven slots fill the first row.
## Longer words shrink to fit their row.
func _slot_size(where: String, n: int) -> float:
	var per_row := float(SLOTS_PER_ROW)
	var s := minf(SLOT_MAX, (_row_width("active") - SLOT_GAP * (per_row - 1.0)) / per_row)
	var k := float(maxi(n, 1))
	return minf(s, (_row_width(where) - SLOT_GAP * (k - 1.0)) / k)


## The active word is centred in the first row; the next word starts at the left of the second.
func _slot_center(where: String, idx: int, n: int) -> Vector2:
	var size := _slot_size(where, n)
	var x0 := _tray_rect().position.x + TRAY_PAD
	if where == "active":
		x0 += (_row_width("active") - (float(n) * size + float(maxi(n - 1, 0)) * SLOT_GAP)) * 0.5
	var x := x0 + size * 0.5 + float(idx) * (size + SLOT_GAP)
	return Vector2(x, view_size.y - (ROW1_UP if where == "active" else ROW2_UP))


func _ignore(c: Control) -> Control:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## A rounded chip with one label inside; returns the panel (the label is its child `label_name`).
func _chip(panel_name: String, label_name: String, text: String, min_w: float = 0.0) -> Panel:
	var p := Panel.new()
	p.name = panel_name
	p.add_theme_stylebox_override("panel", Ui.box(Color(0.13, 0.15, 0.25, 0.86), int(CHIP_H * 0.5)))
	var l := Ui.label(text, 42, TEXT_CREAM)
	l.name = label_name
	l.add_theme_constant_override("outline_size", 0)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_child(l)
	# Side chips share the room left by the centre chip; long names shrink their font to fit.
	var max_w := (view_size.x - CHIP_MID_W) * 0.5 - SIDE_PAD - 16.0
	var fs := 42
	while fs > 24 and ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 56.0 > max_w:
		fs -= 2
	l.add_theme_font_size_override("font_size", fs)
	p.size = Vector2(maxf(min_w, minf(max_w, ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 56.0)), CHIP_H)
	_ignore(p)
	_ignore(l)
	return p


## A round icon button centred at `centre`.
func _icon_button(node_name: String, kind: String, centre: Vector2, d: float, border: Color, icon_colour: Color, bg: Color, border_w: int = 3) -> Button:
	var b := Button.new()
	b.name = node_name
	b.focus_mode = Control.FOCUS_NONE
	var r := int(d * 0.5)
	b.add_theme_stylebox_override("normal", Ui.box(bg, r, border, border_w))
	b.add_theme_stylebox_override("hover", Ui.box(bg.lightened(0.08), r, border, border_w))
	b.add_theme_stylebox_override("pressed", Ui.box(bg.lightened(0.2), r, border, border_w))
	b.size = Vector2(d, d)
	b.position = centre - b.size * 0.5
	var ic: Control = HudArt.Icon.new()
	ic.name = "Icon"
	ic.set("kind", kind)
	ic.set("colour", icon_colour)
	ic.size = Vector2(BTN_SIZE, BTN_SIZE)
	ic.scale = Vector2.ONE * (d / BTN_SIZE) * 0.8
	ic.position = (b.size - ic.size * ic.scale) * 0.5
	_ignore(ic)
	b.add_child(ic)
	_hud.add_child(b)
	return b


func _build_portrait() -> void:
	var centre := Vector2(PORTRAIT_X, view_size.y - PORTRAIT_UP)
	var holder := Control.new()
	holder.name = "Portrait"
	# The art is drawn at HudArt.ART_D and scaled to PORTRAIT_D.
	holder.size = Vector2(HudArt.ART_D, HudArt.ART_D)
	holder.scale = Vector2.ONE * (PORTRAIT_D / HudArt.ART_D)
	holder.position = centre - holder.size * 0.5 * holder.scale
	_ignore(holder)
	var art: Control = HudArt.PortraitArt.new()
	art.name = "PortraitArt"
	art.set("colour", tether_colour)
	art.size = holder.size
	_ignore(art)
	holder.add_child(art)
	var path := "res://brand/characters/%s.png" % character_id
	if ResourceLoader.exists(path):
		var bust := TextureRect.new()
		bust.name = "PortraitBust"
		bust.texture = load(path)
		bust.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bust.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bust.size = Vector2(HudArt.DISC_R * 2.0, HudArt.DISC_R * 2.0)
		bust.position = (holder.size - bust.size) * 0.5
		bust.material = HudArt.clip_material()
		_ignore(bust)
		holder.add_child(bust)
	_hud.add_child(holder)
	_portrait = holder
	var nm := character_name if character_name != "" else character_id.capitalize()
	var pill := Panel.new()
	pill.name = "PortraitName"
	pill.add_theme_stylebox_override("panel", Ui.box(Color("0f1a3e"), int(NAME_H * 0.5), tether_colour, 4))
	pill.size = Vector2(maxf(NAME_W, ThemeDB.fallback_font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x + 64.0), NAME_H)
	pill.position = Vector2(centre.x - pill.size.x * 0.5, view_size.y - NAME_UP - NAME_H * 0.5)
	var pl := Ui.label(nm, 38, TEXT_CREAM)
	pl.name = "PortraitNameLabel"
	pl.add_theme_constant_override("outline_size", 0)
	pl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pill.add_child(_ignore(pl))
	_hud.add_child(_ignore(pill))


func _build_hud() -> void:
	var w := view_size.x
	var h := view_size.y
	_hud = CanvasLayer.new()
	_hud.name = "Hud"
	_hud.layer = 10
	add_child(_hud)
	var night: Control = HudArt.NightPanel.new()
	night.name = "NightPanel"
	night.size = Vector2(w, HudArt.PANEL_H)
	night.position = Vector2(0.0, h - HudArt.PANEL_H)
	_hud.add_child(_ignore(night))
	_night = night
	if character_id != "":
		_build_portrait()
	# Top (owner mock v3): the level's name in the middle, Level n / N at right.
	var cc := _chip("LevelCounterChip", "LevelCounter", level_counter)
	cc.position = Vector2(w - SIDE_PAD - cc.size.x, CHIP_Y)
	cc.visible = level_counter != ""
	_hud.add_child(cc)
	_counter_label = cc.get_node("LevelCounter")
	var mid := _chip("LevelChip", "LevelLabel", _level_title, CHIP_MID_W)
	mid.size.x = CHIP_MID_W
	mid.position = Vector2((w - CHIP_MID_W) * 0.5, CHIP_Y)
	_hud.add_child(mid)
	_level_label = mid.get_node("LevelLabel") as Label
	_fit_title()
	_score_row = HBoxContainer.new()
	_score_row.name = "ScoreRow"
	_score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_score_row.position = Vector2(0, 50)
	_score_row.size = Vector2(CHIP_MID_W, 34)
	_score_row.visible = false  # the mock shows no points in play; the end screen has them
	_score_row.add_theme_constant_override("separation", 10)
	mid.add_child(_ignore(_score_row))
	_score_label = Ui.label("0", 24, Color(0.8, 0.86, 1.0))
	_score_label.name = "ScoreLabel"
	_score_label.add_theme_constant_override("outline_size", 0)
	_score_row.add_child(_ignore(_score_label))
	_combo_label = Ui.label("×1.0", 24, Ui.ACCENT)
	_combo_label.name = "ComboLabel"
	_combo_label.add_theme_constant_override("outline_size", 0)
	_score_row.add_child(_ignore(_combo_label))
	# Babel's speech bubble under the chips, its tail pointing up toward the level counter.
	_band = Panel.new()
	_band.name = "BabelBand"
	_band.position = Vector2(BAND_INSET, BAND_Y)
	_band.size = Vector2(w - 2.0 * BAND_INSET, BAND_H)
	_band.add_theme_stylebox_override("panel", Ui.box(BAND_FILL, int(BAND_H * 0.5), PERIWINKLE, 6))
	_band.visible = false
	_hud.add_child(_ignore(_band))
	var tail: Control = HudArt.BubbleTail.new()
	tail.name = "BabelTail"
	tail.set("colour", PERIWINKLE)
	tail.set("fill", BAND_FILL)
	tail.size = Vector2(BAND_TAIL * 1.6, BAND_TAIL + 6.0)
	tail.position = Vector2(cc.position.x + cc.size.x * 0.5 - BAND_INSET - tail.size.x * 0.5, -BAND_TAIL + 2.0)
	_band.add_child(_ignore(tail))
	var tag := Ui.label("Babel:", 40, PERIWINKLE, HORIZONTAL_ALIGNMENT_LEFT)
	tag.name = "BabelTag"
	tag.add_theme_constant_override("outline_size", 0)
	tag.position = Vector2(40, 0)
	tag.size = Vector2(130, BAND_H)
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_band.add_child(_ignore(tag))
	_band_label = Ui.label("", 40, TEXT_CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	_band_label.name = "BabelText"
	_band_label.add_theme_constant_override("outline_size", 0)
	_band_label.position = Vector2(40 + ThemeDB.fallback_font.get_string_size("Babel: ", HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x, 4)
	_band_label.size = Vector2(_band.size.x - _band_label.position.x - 36, BAND_H - 8)
	_band_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_band_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_band.add_child(_band_label)
	_toast = Ui.label("", 44, Ui.INK)
	_toast.name = "Toast"
	_toast.position = Vector2(0, _ft + 24.0)
	_toast.size = Vector2(w, 70)
	_toast.modulate.a = 0.0
	_hud.add_child(_toast)
	_banner = Ui.label("", 110, AMBER)
	_banner.name = "WordBanner"
	_banner.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.15, 0.9))
	_banner.add_theme_constant_override("outline_size", 18)
	_banner.size = Vector2(w, 160)
	_banner.position = Vector2(0, _ft + (view_size.y - FIELD_BOTTOM_UP - _ft) * 0.38)
	_banner.pivot_offset = _banner.size * 0.5
	_banner.visible = false
	_fly_layer.add_child(_ignore(_banner))  # above the letters
	# Slot tray: the active word on the first row, the next word on the second, Hint at its end.
	var tr := _tray_rect()
	var tray := Panel.new()
	tray.name = "SlotTray"
	tray.position = tr.position
	tray.size = tr.size
	tray.add_theme_stylebox_override("panel", Ui.box(TRAY_FILL, 40, TRAY_EDGE, 5))
	_hud.add_child(_ignore(tray))
	_active_row = Control.new()
	_active_row.name = "ActiveSlots"
	_hud.add_child(_ignore(_active_row))
	_preview_row = Control.new()
	_preview_row.name = "PreviewSlots"
	_hud.add_child(_ignore(_preview_row))
	_hint_button = _icon_button("HintButton", "hint", Vector2(tr.end.x - TRAY_PAD - HINT_D * 0.5, h - ROW2_UP), HINT_D, HINT_RIM, Color.WHITE, HINT_FILL, 4)
	# Bottom row under the tray: the timer pill, then Pause, Sound and Settings as round buttons.
	var by := h - BOTTOM_UP
	var bx := w - EDGE - BTN_SIZE * 0.5
	var plain := Color("15214d")
	var edge := Color(0.6, 0.7, 0.95, 0.6)
	_settings_button = _icon_button("SettingsButton", "settings", Vector2(bx, by), BTN_SIZE, edge, Ui.INK, plain)
	_sound_button = _icon_button("SoundButton", "sound", Vector2(bx - (BTN_SIZE + BTN_GAP), by), BTN_SIZE, edge, Ui.INK, plain)
	_pause_button = _icon_button("PauseButton", "pause", Vector2(bx - 2.0 * (BTN_SIZE + BTN_GAP), by), BTN_SIZE, edge, Ui.INK, plain)
	_pause_icon = _pause_button.get_node("Icon")
	_sound_icon = _sound_button.get_node("Icon")
	_hint_button.pressed.connect(request_hint)
	_pause_button.pressed.connect(func() -> void: pause_requested.emit())
	_sound_button.pressed.connect(toggle_sound)
	_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	_sync_sound_icon()
	_fill_coral = HudArt.bar_fill_box(HudArt.CORAL, HudArt.CORAL_LIGHT, int(TIMER_H))
	_fill_crimson = HudArt.bar_fill_box(HudArt.CRIMSON, HudArt.CRIMSON_LIGHT, int(TIMER_H))
	_time_bar = ProgressBar.new()
	_time_bar.name = "TimeBar"
	var timer_right := _pause_button.position.x - BTN_GAP
	_time_bar.position = Vector2(tr.position.x, by - TIMER_H * 0.5)
	_time_bar.custom_minimum_size = Vector2(0, TIMER_H)
	_time_bar.size = Vector2(timer_right - tr.position.x, TIMER_H)
	_time_bar.show_percentage = false
	_time_bar.min_value = 0.0
	_time_bar.max_value = _n("burst.seconds")
	_time_bar.add_theme_stylebox_override("background", Ui.box(Color("15214d"), int(TIMER_H * 0.5), Color(0.6, 0.7, 0.95, 0.6), 3))
	_time_bar.add_theme_stylebox_override("fill", _fill_coral)
	_hud.add_child(_ignore(_time_bar))
	_clock_label = Ui.label("", 32, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_clock_label.name = "ClockLabel"
	_clock_label.position = Vector2(timer_right - 24.0 - CLOCK_LABEL_W, by - 24.0)
	_clock_label.size = Vector2(CLOCK_LABEL_W, 48)
	_clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_clock_label.pivot_offset = Vector2(CLOCK_LABEL_W, 24)
	_hud.add_child(_ignore(_clock_label))
	_coach = Coach.new()
	_coach.setup(_tun, settings.reduced_motion, view_size)
	_hud.add_child(_coach)


# --- first-play coach ------------------------------------------------------------------

func _coach_active() -> bool:
	return (coach_enabled or coach_drones) and not autoplay and _coach != null


func _coach_reset() -> void:
	_coach_stage = 0
	_coach_left = 0.0
	_coach_drone_on = false
	if _coach != null:
		_coach.clear()


## The throw is over and play starts: the letter hint begins (only when the coach is on).
func _coach_begin() -> void:
	if coach_enabled and _coach_active() and _coach_stage == 0:
		_coach_stage = 1


func _coach_caught() -> void:
	if _coach_stage == 1:
		_coach_stage = 2
		_coach_left = _n("coach.afterCatchSec")
		_coach.clear()


func _tick_coach(delta: float) -> void:
	if not _coach_active() or finished or _cleared:
		return
	# A drone beats the letter hint: point at the first one, until it is gone.
	var thief: ThiefViewScript = null
	if not _coach_drone_seen or _coach_drone_on:
		for th in game_round.thieves:
			thief = _thief_views.get(th.id)
			if thief != null:
				break
	if thief != null:
		_coach_drone_on = true
		_coach_drone_seen = true
		_coach.show_at(thief.position, "Tap the drone to save the letter")
		return
	if _coach_drone_on:
		_coach_drone_on = false
		_coach.clear()
	if _coach_stage == 1:
		var id := Targeting.letter_target(game_round)
		var v: TileViewScript = _views.get(id)
		if v != null:
			_coach.show_at(v.position, "Tap a letter you need")
		else:
			_coach.clear()
	elif _coach_stage == 2:
		_coach_left -= delta
		if _coach_left <= 0.0:
			_coach_stage = 3
			_coach.clear()
		else:
			var tray := _tray_rect()
			_coach.show_at(Vector2(tray.position.x + tray.size.x * 0.5, tray.position.y - 70.0), "Fill every slot before the clock runs out", false)


## Hint button: asks the rules for a hint. Returns the tile id, or -1 (the button flashes).
func request_hint() -> int:
	if paused or _intro_on or _story_on or game_round == null or game_round.state != "play":
		return -1
	var id: int = game_round.use_hint()
	if id < 0:
		_hint_flash_t = HINT_FLASH_SEC
		_hint_button.modulate = Color(1.0, 0.35, 0.35)
	_apply_events()
	_update_hud()
	return id


## Sound button: flips the mute switch, applies it to the master bus and saves it.
func toggle_sound() -> void:
	settings.sound_on = not settings.sound_on
	settings.apply_audio()
	settings.save_to(settings_path)
	_sync_sound_icon()


func _sync_sound_icon() -> void:
	if _sound_icon != null:
		_sound_icon.set("kind", "sound" if settings.sound_on else "muted")


func _slot_text_filled(where: String, idx: int, filled: bool) -> bool:
	var abs_word := game_round.word_index + (1 if where == "preview" else 0)
	return filled and not _pending.has(Vector2i(abs_word, idx))


func _rebuild_row(row: Control, where: String, slots: Array[Dictionary]) -> void:
	for c in row.get_children():
		row.remove_child(c)
		c.queue_free()
	var n := slots.size()
	var size := _slot_size(where, n)
	for i in n:
		var p := Panel.new()
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.name = "Slot_%d" % i
		p.size = Vector2(size, size)
		p.pivot_offset = p.size * 0.5
		p.position = _slot_center(where, i, n) - p.size * 0.5
		var l := Ui.label("", int(size * 0.6), TILE_INK)
		l.name = "Glyph"
		l.size = p.size
		l.add_theme_constant_override("outline_size", 0)
		p.add_child(l)
		row.add_child(p)


func _style_slot(p: Panel, filled: bool, where: String) -> void:
	var r := int(p.size.x * 0.24)
	if filled:
		# A cream tile with a darker lip along the bottom, so it reads as a raised key.
		var sb := Ui.box(TILE_CREAM, r, TILE_LIP, 0)
		sb.border_width_bottom = maxi(4, int(p.size.y * 0.08))
		p.add_theme_stylebox_override("panel", sb)
	else:
		p.add_theme_stylebox_override("panel", Ui.box(SLOT_FILL, r, SLOT_EDGE, 5))


## Share of the level's words restored so far: colour and city lights come back with it.
func restored_share() -> float:
	if game_round == null or game_round.words.is_empty():
		return 0.0
	if game_round.state == "won":
		return 1.0
	return clampf(float(game_round.word_index) / float(game_round.words.size()), 0.0, 1.0)


func _update_hud() -> void:
	var share := restored_share()
	if _backdrop != null:
		_backdrop.restore = share
	if _night != null and share > float(_night.get("lit")):
		_night.set("lit", share)  # lights come up at once; a new level dims them slowly (_tick_hud)
	_score_label.text = "%d" % int(round(game_round.score))
	_combo_label.text = "×%.1f" % game_round.combo
	_time_bar.max_value = game_round.burst_seconds
	if _refill_t >= 0.0:
		var r := clampf(_refill_t / maxf(0.01, _n("flow.refillSec")), 0.0, 1.0)
		_time_bar.value = lerpf(_refill_from, game_round.time_left, r * r * (3.0 - 2.0 * r))
	else:
		_time_bar.value = game_round.time_left
	_clock_label.text = "%ds" % int(ceil(game_round.time_left))
	var low: bool = game_round.time_left < LOW_TIME
	if low != _low:
		_low = low
		_time_bar.add_theme_stylebox_override("fill", _fill_crimson if low else _fill_coral)
		_clock_label.add_theme_color_override("font_color", HudArt.CRIMSON if low else CLOCK_TEXT)
		if not low:
			_clock_label.scale = Vector2.ONE
	var akey := "%d:%s" % [game_round.word_index, "".join(game_round.active.map(func(s: Dictionary) -> String: return s["ch"]))]
	if akey != _active_key:
		_active_key = akey
		_active_n = game_round.active.size()
		_rebuild_row(_active_row, "active", game_round.active)
	var pkey := "%d:%s" % [game_round.word_index, "".join(game_round.preview.map(func(s: Dictionary) -> String: return s["ch"]))]
	if pkey != _preview_key:
		_preview_key = pkey
		_preview_n = game_round.preview.size()
		_rebuild_row(_preview_row, "preview", game_round.preview)
	_fill_row(_active_row, "active", game_round.active)
	_fill_row(_preview_row, "preview", game_round.preview)


## True when the Hint setting reveals the ghost letter of slot idx in a word of n letters.
func hint_shown(idx: int, n: int) -> bool:
	match settings.hint:
		"full":
			return true
		"edges":
			return n <= 2 or idx == 0 or idx == n - 1
		"one":
			return idx == 0
	return false


func _fill_row(row: Control, where: String, slots: Array[Dictionary]) -> void:
	for i in mini(slots.size(), row.get_child_count()):
		var p := row.get_child(i) as Panel
		var filled := _slot_text_filled(where, i, bool(slots[i]["filled"]))
		var g := p.get_node("Glyph") as Label
		var ch := str(slots[i]["ch"]).to_upper()
		g.text = ch if filled or (hint_shown(i, slots.size()) and not game_round.jammed) else ""
		g.modulate.a = 1.0 if filled else _n("hud.hintAlpha")
		g.add_theme_color_override("font_color", TILE_INK if filled else Color.WHITE)
		_style_slot(p, filled, where)


func _tick_hud(delta: float) -> void:
	if _refill_t >= 0.0:
		_refill_t += delta
		if _refill_t >= _n("flow.refillSec"):
			_refill_t = -1.0
	if _night != null and float(_night.get("lit")) > restored_share():
		_night.set("lit", move_toward(float(_night.get("lit")), restored_share(), delta * 0.8))
	if _chip_t < CHIP_SWAP_SEC:
		_chip_t += delta
		var c := clampf(_chip_t / CHIP_SWAP_SEC, 0.0, 1.0)
		var a := 1.0 if settings.reduced_motion else clampf(c * 1.4, 0.0, 1.0)
		_level_label.modulate.a = a
		_counter_label.modulate.a = a
	if _hint_flash_t > 0.0:
		_hint_flash_t = maxf(0.0, _hint_flash_t - delta)
		_hint_button.modulate = Color.WHITE.lerp(Color(1.0, 0.35, 0.35), _hint_flash_t / HINT_FLASH_SEC)
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.35, 0.0, 1.0)
	# Babel's bubble stays up once he has spoken; each new line types itself in.
	_babel_t += delta
	_band.visible = last_babel != ""
	if _band.visible:
		_band_label.text = "“%s”" % last_babel  # quoted, as in the mock
		_band_label.visible_characters = int(_babel_t * TYPE_CPS) + 1
	if _low and not settings.reduced_motion:
		var cp := 1.0 + 0.12 * absf(sin(_time * TAU))
		_clock_label.scale = Vector2(cp, cp)
	_pulse_t += delta
	var k := 1.0
	if _pulse_t < PULSE_SEC and not settings.reduced_motion:
		k = 1.0 + 0.18 * sin(PI * _pulse_t / PULSE_SEC)
	if _slots_in_t < 2.0 and not settings.reduced_motion:
		# A new level: the empty slots pop in one after another.
		_slots_in_t += delta
		var i := 0
		for row in [_active_row, _preview_row]:
			for c in row.get_children():
				var u := clampf((_slots_in_t - float(i) * SLOT_IN_STAGGER) / SLOT_IN_SEC, 0.0, 1.0)
				var w := u - 1.0
				var s := 1.0 + 2.7 * w * w * w + 1.7 * w * w  # back ease-out
				(c as Control).scale = Vector2.ONE * maxf(0.0, s)
				i += 1
		return
	for c in _active_row.get_children():
		(c as Control).scale = Vector2(k, k)

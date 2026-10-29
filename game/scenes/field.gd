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
const BabelMovesFx := preload("res://scenes/babel_moves_fx.gd")
const Coach := preload("res://scenes/coach.gd")
const StoryStrip := preload("res://scenes/story_strip.gd")
const DEFAULT_ACT := "act1_low_orbit"
const LOW_TIME := 5.0
const FLOAT_SEC := 0.9
const POP_SEC := 0.8
const AMBER := Color("F8BC04")
# The owner's tray mock (16:51): a navy tray with a slate rim, near-black slots with a teal outline,
# cream letter tiles with a darker bottom lip, and an orange Hint button with a glowing bulb.
const TILE_CREAM := Color("f8eccc")  # the mock's letter tile: cream, a tan lip, a dark brown line
const TILE_LIP := Color("cdae8f")
const TILE_INK_LINE := Color("3a2a2c")
const TILE_INK := Color("0d0626")  # its letters
const SLOT_EMPTY := Color(0.165, 0.306, 0.44, 0.92)  # the mock's empty slot: a teal well
const SLOT_RIM := Color("9ff8ff")  # with a bright cyan rim
const CLOCK_TEXT := Color(1.0, 0.85, 0.78)
const PERIWINKLE := Color("7579f0")
const TEXT_CREAM := Color("efe8d6")  # the mock's warm off-white for HUD text
const NEON := Color("4fe3ff")  # the console's cyan glow (target mock)
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
# Layout from the owner's target mock (19 Oct 2026), in pixels at 1080 wide. Bottom items are
# offsets up from the real bottom of the visible viewport, so taller phones just add field height.
const SIDE_PAD := 44.0
const EDGE := 44.0
const CHIP_Y := 50.0
const CHIP_H := 80.0
const MISTAKE_GAP := 14.0  # between the level counter and the wrong-catch counter under it
const CHIP_MID_W := 356.0  # widest the level name chip grows before its font shrinks
const FIELD_TOP := 320.0  # top of the play field (below Babel's bubble)
const FIELD_BOTTOM_UP := 560.0  # bottom of the play field, just above Earth's rim
const PANEL_TOP_UP := 530.0  # highest point of Earth's rim
## The console is the owner's target mock itself (19 Oct 2026: "make it pixel perfect"), cut out
## by scripts/art/cut_hud.py. Everything on it is placed in the mock's own pixels (572x1024, its
## bottom on the screen's bottom, scaled to 1080 wide and centred): see _m().
const MOCK_W := 572.0
const MOCK_H := 1024.0
const HUD_ART := "res://art/hud/"
const MOCK_CONSOLE := Vector2(0, 742)  # corner of console.png
const MOCK_PORT := Vector2(83.5, 832.5)  # the porthole's screen, where the Catcher sits
const MOCK_WINDOW_R := 52.5
const MOCK_SCREEN := Rect2(174, 777, 285, 127)  # the slot screen
const MOCK_ROW1_Y := 809.0  # centre of the active word's row
const MOCK_ROW2_Y := 871.5  # centre of the next word's row
const MOCK_SLOT := 42.4
const MOCK_SLOT_GAP := 12.0
const MOCK_BTN_X := 529.0  # the round buttons, stacked at the right (rim 11 px from the edge)
const MOCK_PAUSE_Y := 793.0
const MOCK_SOUND_Y := 874.0
const MOCK_SETTINGS_Y := 955.0
const MOCK_BTN_R := 37.0
const MOCK_ICON_R := 23.0  # the icon disc inside a button's neon ring
const MOCK_RING_R := 25.5
const BTN_ART := 150.0  # the round button textures, game px square
const MOCK_BULB := Rect2(502.0, 650, 54, 91)  # the hint bulb, on the buttons' centre line
const MOCK_BULB_GLASS := Vector2(529.0, 678.5)
const MOCK_CHANNEL := Rect2(72, 964, 389, 33)  # the clock bar's channel, where the liquid runs
const TRAY_PAD := 22.0
const SLOT_MAX := MOCK_SLOT * 1080.0 / MOCK_W
const GAP_RATIO := MOCK_SLOT_GAP / MOCK_SLOT
const MIN_COLS := 4
const CLOCK_LABEL_W := 110.0
const COST_FLOAT_UP := 600.0
# Babel's throw: look of a single flight (timing and perch are tunables under babel.*).
const THROW_START_SCALE := 0.15
const INTRO_MAX_STEP := 0.1  # a load hitch (up to 0.25 s) must not skip the first launches; slow phones still run at speed

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
var _ap_interval_v: float = -1.0  # seconds between autoplay taps; the web query ?tap=<sec> slows the bot for evidence clips
var _ap_wrong_left: int = 0  # web query ?wrong=<n>: the bot's first n taps catch letters the words do not need (evidence of the counter)
var _views: Dictionary = {}  # tile_id -> TileView
var _pending: Dictionary = {}  # Vector2i(absolute word, slot) -> true while a caught tile flies
var _view_word: int = 0
var _end_t: float = -1.0
var _toast_t: float = 0.0
## Hazards that have bitten already this run: each gets its one-line toast the first time only (WP-F.1).
var _hazard_seen: Dictionary = {}
var _babel_t: float = 99.0
var _gust_fx: Node2D  # WP-F.19: wind streaks while a gust blows (null otherwise)
var _babel_shown: String = ""  # the last_babel line already handed to the porthole bubble
var _pulse_t: float = 99.0
var _tether_fade: float = 0.0
var _tether_end: Vector2 = Vector2.ZERO
var _ripples: Array = []  # [RippleRing, seconds elapsed] landing ripples (WP-F.21)
var _fx: Array = []  # [node, ttl]
var _thief_views: Dictionary = {}  # thief_id -> ThiefView
var _floats: Array = []  # [Label, age] floating "-1 s" texts
var _clock_label: Label
var _mistakes: MistakeChip  # wrong catches so far, out of burst.maxWrong (WP-F.24: a pill under the level counter)
var _time_bar: ProgressBar
var _pause_button: Button
var _pause_icon: Control
var _hint_button: Button
var _sound_button: Button
var _sound_icon: Control
var _settings_button: Button
var _hint_flash_t: float = 0.0
var _portrait: Control
var _portrait_art: Control
var _bust: Control
var _console: Control
var _liquid: Control
var _hint_icon: Control
var _level_chip: Control
var _counter_chip: Control
var _slot_empty_sb: StyleBoxFlat
var _wires: Control
var _anim_t: float = 0.0  # idle animation clock for the HUD (stops while paused)
var _was_calm: bool = false
var _fly_layer: CanvasLayer
var _score_row: HBoxContainer
var _low: bool = false
var _active_key: String = ""
var _preview_key: String = ""
var _active_n: int = 0
var _preview_n: int = 0

var _world: CanvasLayer
var _backdrop: Node2D
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
var _fps_meter: CanvasLayer
## Game feel (WP-3.N): placeholder sounds, the combo pop, the restored-word banner, the shake.
var sfx: Sfx
## Optional Music node (main sets it): ducked during the chatter and pause, stings per speaker.
var music: Node
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
const LAND_SEC := 0.45


const ASLEEP_SEC := 2.0  # a frame this late means the tab was hidden; the player has been away


func _process(delta: float) -> void:
	if delta > ASLEEP_SEC and _in_play() and not _intro_on and not _story_on:
		pause_requested.emit()
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
	_sync_pips()
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
	var width := _n("field.width")
	_scale = minf(view_size.x / width, avail / span)
	_field_x = (view_size.x - width * _scale) * 0.5
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
	_babel_shown = ""
	_babel_t = 99.0
	_drop_gust()
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
		_set_clock_colours(false)
		_clock_label.add_theme_color_override("font_color", CLOCK_TEXT)
		_clock_label.scale = Vector2.ONE
		_clock_label.visible = false
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
	s.music = music
	if music != null:
		music.call("duck", true)
	s.position = Vector2(0.0, FIELD_TOP)
	s.size = Vector2(view_size.x, view_size.y - FIELD_BOTTOM_UP - FIELD_TOP)
	s.skip_top = CHIP_Y + CHIP_H + 16.0 - FIELD_TOP  # just under the top-right chip
	s.babel_line.connect(func(text: String) -> void:
		last_babel = text
		_babel_shown = ""
		_babel_t = 0.0)
	s.finished.connect(func() -> void:
		_story_on = false
		_story = null
		if music != null:
			music.call("duck", paused)
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
	card.set("star_from", Vector2(bar.position.x + maxf(bar.size.y * 0.5, bar.size.x * share - bar.size.y * 0.5), bar.get_center().y))
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


## The level name chip grows with its name; long names shrink their font to fit half the top row.
func _fit_title() -> void:
	var max_w := _chip_max_w()
	var fs := 42
	while fs > 24 and ThemeDB.fallback_font.get_string_size(_level_title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 64.0 > max_w:
		fs -= 2
	_level_label.add_theme_font_size_override("font_size", fs)
	if _level_chip != null:
		_level_chip.size.x = clampf(ThemeDB.fallback_font.get_string_size(_level_title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 64.0, 200.0, max_w)
		_level_chip.pivot_offset = _level_chip.size * 0.5


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
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and _in_play():
		pause_requested.emit()


## A round is running: not finished, not paused.
func _in_play() -> bool:
	return game_round != null and not finished and not paused


## Freezes or resumes everything: rules, intro, effects; taps are ignored while paused.
func set_paused(on: bool) -> void:
	paused = on
	if music != null:
		music.call("duck", on or _story_on)
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
	_tick_gust(delta)
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
		"reason": game_round.end_reason,
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
	_ensure_babel()
	_babel.hide_now()
	if not intro_enabled:
		_babel.fly_in()  # he still sits in his corner; there is no throw
		_spawn_grow = true
		_coach_begin()
		return
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
	_babel.fly_in()
	if _intro_quote != "":
		_babel.say(_intro_quote)
	_pose_intro()


## A letter made mid-play (a refill, a stolen letter coming back) is shot out of Babel's muzzle to
## its place. Reduced motion: it fades in where it is, and he does not recoil.
func _shoot_in(v: TileViewScript, t: Object) -> void:
	_ensure_babel()
	if settings.reduced_motion or _babel.state == "off":
		v.grow_in(_n("tile.spawnInSec"))
		return
	v.launch_from(_babel.muzzle_position(), _n("babel.throwSec"), _n("babel.throwOvershoot"))
	_babel.shoot(to_screen(t.pos))


## WP-F.19: one of Babel's move events (babel_tell, babel_move, shield_bounce) from the rules.
## A volley needs nothing here: each decoy also arrives as a spawn event and flies from the muzzle.
func _on_babel_move_event(e: Dictionary) -> void:
	var type: String = e["type"]
	match type:
		"babel_tell":
			_ensure_babel()
			if _babel.state == "off":
				_babel.fly_in()
			_babel.tell(str(e["move"]), float(e.get("sec", _n("babel.tellSec"))))
			sfx.babel_tell()
		"babel_move":
			var move := str(e["move"])
			sfx.babel_move(move)
			match move:
				"gust":
					_start_gust(e.get("dir", Vector2.RIGHT), float(e.get("sec", _n("babel.gustSec"))))
				"shield":
					var sv: TileViewScript = _views.get(int(e.get("tile_id", -1)))
					if sv != null:
						sv.shield(float(e.get("sec", _n("babel.shieldSec"))))
				"scramble":
					var sec := float(e.get("sec", _n("babel.scrambleSec")))
					for m in e.get("moves", []):
						var mv: TileViewScript = _views.get(int(m["tile_id"]))
						if mv != null:
							mv.scramble(to_screen(m["from"]), sec)
		"shield_bounce":
			var bv: TileViewScript = _views.get(int(e["tile_id"]))
			if bv != null:
				bv.shield_bounce()
				if not settings.reduced_motion:
					_burst(bv.position, PERIWINKLE, 8)
			sfx.shield_bounce()


func _start_gust(dir: Vector2, sec: float) -> void:
	_drop_gust()
	if settings.reduced_motion:
		return
	_gust_fx = BabelMovesFx.new()
	_gust_fx.name = "GustFx"
	_fx_layer.add_child(_gust_fx)
	_gust_fx.start(dir, sec, Rect2(0.0, _ft, view_size.x, maxf(100.0, panel_top() - _ft)))


func _tick_gust(delta: float) -> void:
	if _gust_fx != null and _gust_fx.tick(delta):
		_drop_gust()


func _drop_gust() -> void:
	if _gust_fx != null:
		_gust_fx.queue_free()
		_gust_fx = null


## Puts a new last_babel line (a story line, a taunt) into the porthole bubble.
func _sync_babel_line() -> void:
	if last_babel == _babel_shown:
		return
	_babel_shown = last_babel
	if last_babel == "":
		if _babel != null:
			_babel.close_bubble()
		return
	_ensure_babel()
	if _babel.state == "exit":
		return
	if _babel.state == "off":
		_babel.fly_in()
	if _babel.is_talking() and _babel.quote_text() == last_babel:
		return  # the intro already says it
	_babel.say(last_babel, _n("babel.showSeconds"))


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
		_babel.close_bubble()  # he stays in his corner; only the intro line closes
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
	if _babel.is_talking() and _intro_t >= _intro_throw_at:
		_babel.close_bubble()
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

## Seconds between autoplay taps: autoplay.tapInterval, or ?tap=<sec> on the web (slower bot for filming hops).
func _ap_interval() -> float:
	if _ap_interval_v < 0.0:
		_ap_interval_v = _n("autoplay.tapInterval")
		if OS.has_feature("web"):
			var q := str(JavaScriptBridge.eval("window.location.search")).trim_prefix("?")
			for part: String in q.split("&"):
				if part.begins_with("tap=") and part.substr(4).is_valid_float() and float(part.substr(4)) > 0.0:
					_ap_interval_v = maxf(0.05, float(part.substr(4)))
				if part.begins_with("wrong=") and part.substr(6).is_valid_int():
					_ap_wrong_left = maxi(0, int(part.substr(6)))
	return _ap_interval_v


## A catchable letter no slot needs (for ?wrong=<n>), -1 when every letter on the field is needed.
func _ap_wrong_target() -> int:
	var need := {}
	for s in game_round.active:
		need[s["ch"]] = true
	for s in game_round.preview:
		need[s["ch"]] = true
	for t in game_round.tiles:
		if t.alive and t.plane < 2 and t.carried_by < 0 and t.landing <= 0.0 and t.shield_t <= 0.0 and not need.has(t.ch):
			return t.id
	return -1


func _autoplay_tick(delta: float) -> void:
	_ap_timer += delta
	if _ap_timer < _ap_interval():
		return
	if game_round.state != "play" or not game_round.shot.is_empty():
		return
	_ap_timer = 0.0
	var id := -1
	if _ap_wrong_left > 0:
		id = _ap_wrong_target()
		if id >= 0:
			_ap_wrong_left -= 1
	if id < 0:
		id = Targeting.target(game_round)
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
		v.set_back(_n("plane.backAlpha"))
	elif t.plane == 1:
		v.set_depth(_n("plane.midDim"))
	if t.kind != "":
		v.set_kind(t.kind)
	v.place(to_screen(game_round.view_pos(t)), _time, t.pos.x)
	_views[t.id] = v
	return v


func _sync_views() -> void:
	if _cleared:
		return  # the level is over: the leftover letters are drifting off
	var live: Dictionary = {}
	for t in game_round.tiles:
		live[t.id] = true
		var v := _ensure_view(t)
		v.set_jam(game_round.jammed and t.plane < 2, t.decoy)
		v.sync_shield(float(t.get("shield_t") if t.get("shield_t") != null else 0.0))
		v.place(to_screen(game_round.view_pos(t)), _time, t.pos.x)  # WP-F.24: between the last two steps, so motion is even at any frame rate
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
			v.set_entry(th.entry)
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


## WP-F.21: the letter nearest where the shot ended flinches (not in reduced motion).
func _flinch_nearest(aim: Vector2) -> void:
	if settings.reduced_motion:
		return
	var best: TileViewScript = null
	var bd := INF
	for id in _views:
		var v: TileViewScript = _views[id]
		if v.anim != "" or v.is_star:
			continue
		var d := v.position.distance_squared_to(aim)
		if d < bd:
			bd = d
			best = v
	if best != null:
		best.flinch()


## The landing ripple: an expanding, fading ring from the landing point.
## The mistake pips: one ring per wrong catch the round allows; a used one fills coral.
## The wrong-catch counter (WP-F.24, owner: "make counter of wrong moves"): a pill under the level
## counter with one pip per allowed mistake (used ones coral with a cross) and "n / N". It pops and
## flashes coral on every wrong catch; with no cap (burst.maxWrong 0) it counts "n wrong".
class MistakeChip extends Panel:
	var total: int = 0
	var used: int = 0
	var calm: bool = false
	const R := 14.0
	const STEP := 40.0
	const PAD := 26.0
	const POP_SEC := 0.45
	const H := 72.0
	var _pop_t: float = POP_SEC
	var _pips: Control
	var _label: Label
	var _box: StyleBoxFlat
	const EDGE := Color(0.72, 0.78, 0.95, 0.55)
	const CORAL := Color(1.0, 0.5, 0.45)

	func _init() -> void:
		name = "MistakeChip"
		_box = Ui.box(Color(0.08, 0.1, 0.2, 0.78), int(H * 0.5), EDGE, 3)
		_box.shadow_color = Color(0.0, 0.02, 0.08, 0.35)
		_box.shadow_size = 10
		add_theme_stylebox_override("panel", _box)
		_pips = Control.new()
		_pips.name = "Pips"
		_pips.draw.connect(_draw_pips)
		add_child(_pips)
		_label = Ui.label("", 38, Color("efe8d6"), HORIZONTAL_ALIGNMENT_LEFT)
		_label.name = "Count"
		_label.add_theme_constant_override("outline_size", 0)
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_label)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_state(total_in: int, used_in: int) -> void:
		var was := used
		total = maxi(0, total_in)
		used = clampi(used_in, 0, total) if total > 0 else maxi(0, used_in)
		var pips_w := STEP * float(total) - (STEP - R * 2.0) if total > 0 else 0.0
		_pips.position = Vector2(PAD, 0.0)
		_pips.size = Vector2(pips_w, H)
		_pips.visible = total > 0
		var text := ("%d / %d" % [used, total]) if total > 0 else ("%d wrong" % used)
		_label.text = text
		var tw := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x
		_label.position = Vector2(PAD + pips_w + (18.0 if total > 0 else 0.0), 0.0)
		_label.size = Vector2(tw + 4.0, H)
		size = Vector2(_label.position.x + tw + PAD, H)
		pivot_offset = size * 0.5
		var last := total > 0 and used >= total - 1
		_label.add_theme_color_override("font_color", CORAL if last else Color("efe8d6"))
		_pips.queue_redraw()
		if used > was:
			pop()

	## One wrong catch left before the round is lost.
	func on_last() -> bool:
		return total > 0 and used == total - 1

	func pop() -> void:
		_pop_t = 0.0

	func tick(delta: float) -> void:
		if _pop_t >= POP_SEC:
			return
		_pop_t = minf(POP_SEC, _pop_t + delta)
		var u := _pop_t / POP_SEC
		var k := 0.0 if calm else sin(PI * u) * (1.0 - 0.5 * u)
		scale = Vector2.ONE * (1.0 + 0.22 * k)
		_box.border_color = EDGE.lerp(CORAL, (1.0 - u) * (1.0 - u))
		_box.bg_color = Color(0.08, 0.1, 0.2, 0.78).lerp(Color(0.5, 0.16, 0.18, 0.9), (1.0 - u) * (1.0 - u))

	func _draw_pips() -> void:
		for i in total:
			var c := Vector2(R + STEP * float(i), H * 0.5)
			if i < used:
				_pips.draw_circle(c, R, CORAL)
				_pips.draw_line(c + Vector2(-6, -6), c + Vector2(6, 6), Color(0.1, 0.05, 0.1), 3.5, true)
				_pips.draw_line(c + Vector2(-6, 6), c + Vector2(6, -6), Color(0.1, 0.05, 0.1), 3.5, true)
			else:
				_pips.draw_circle(c, R, Color(0.1, 0.16, 0.3, 0.8))
				_pips.draw_arc(c, R, 0.0, TAU, 28, Color(0.46, 0.47, 0.94), 3.0, true)


class RippleRing extends Node2D:
	var radius: float = 0.0
	var alpha: float = 0.0
	var colour: Color = Color.WHITE

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(colour.r, colour.g, colour.b, alpha), 5.0, true)


func _add_ripple(at: Vector2) -> void:
	var r := RippleRing.new()
	r.name = "HopRipple"
	r.position = at
	r.colour = tether_colour
	_fx_layer.add_child(r)
	_ripples.append([r, 0.0])


func _tick_ripples(delta: float) -> void:
	var sec := maxf(0.05, _n("hop.ringSec"))
	var i := _ripples.size() - 1
	while i >= 0:
		var rp: Array = _ripples[i]
		rp[1] = float(rp[1]) + delta
		var u := clampf(float(rp[1]) / sec, 0.0, 1.0)
		var node: Node2D = rp[0]
		node.radius = _n("hop.ringPx") * _scale * (1.0 - pow(1.0 - u, 2.0))
		node.alpha = 0.45 * (1.0 - u)
		node.queue_redraw()
		if u >= 1.0:
			node.queue_free()
			_ripples.remove_at(i)
		i -= 1


## Tether colour: the Catcher colour warms toward coral with the combo (tether.comboWarm).
func warm_tether_colour() -> Color:
	var cmax := _n("combo.max")
	var k := 0.0
	if cmax > 1.0:
		k = clampf((game_round.combo - 1.0) / (cmax - 1.0), 0.0, 1.0)
	return tether_colour.lerp(Color(1.0, 0.42, 0.21), k * _n("tether.comboWarm"))


func _update_tether(delta: float) -> void:
	_tick_ripples(delta)
	var shot: Dictionary = game_round.shot
	if not shot.is_empty():
		var u := clampf(float(shot["elapsed"]) / float(shot["dur"]), 0.0, 1.0)
		var a: Vector2 = shot["from"]
		var b: Vector2 = shot["to"]
		_tether_end = to_screen(a.lerp(b, u))
		_tether_fade = TETHER_FADE
		_tether.visible = true
		_tether.default_color = warm_tether_colour()
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
						_shoot_in(nv, t)
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
				var left := int(e.get("left", -1))
				var msg := "Not in the record   −%d s" % int(_n("burst.wrongCost"))
				if left == 1:
					msg += "   ·   one more loses the sector"
				elif left > 1:
					msg += "   ·   %d more allowed" % left
				_show_toast(msg, Color(1.0, 0.5, 0.45))
				_sync_pips()
				sfx.wrong()
				_shake(_n("fx.shakePx") * 0.5)
				_buzz(60)
			"escape":
				_show_toast("It drifted off", Ui.DIM)
				_flinch_nearest(_tether_end)
			"hop_tell":
				var tv: TileViewScript = _views.get(int(e["tile_id"]))
				if tv != null:
					tv.hop_tell(_n("hop.windSec"))
			"hop":
				var hv2: TileViewScript = _views.get(int(e["tile_id"]))
				if hv2 != null:
					hv2.hop(to_screen(e["from"]), float(e.get("sec", _n("hop.flySec"))))
			"hop_land":
				var lv: TileViewScript = _views.get(int(e["tile_id"]))
				if lv != null:
					lv.hop_land()
					if not settings.reduced_motion:
						_add_ripple(lv.position)
			"counterfeit":
				var fv: TileViewScript = _views.get(int(e["tile_id"]))
				if fv != null:
					fv.flash(0.45)
					fv.dissolve(_n("fx.dissolveSec"))
				_burst(to_screen(e["pos"]), PERIWINKLE, 18)
				_hazard_toast("counterfeit", "Forged letter   −%d s" % int(_n("burst.wrongCost")))
				_sync_pips()
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
				_babel_shown = ""  # the same taunt twice still pops the bubble again
				_babel_t = 0.0
			"babel_tell", "babel_move", "shield_bounce":
				_on_babel_move_event(e)
			"round_end":
				_end_t = 0.0
				_drop_gust()
				if _babel != null:
					_babel.fly_out()
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
	_burst(target, warm_tether_colour().lightened(0.3))
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


func _sync_pips() -> void:
	if _mistakes != null and game_round != null:
		var cap := int(_n("burst.maxWrong"))
		var used := cap - maxi(0, game_round.mistakes_left()) if cap > 0 else int(game_round.stats["wrong"]) + int(game_round.stats["counterfeits"])
		_mistakes.set_state(cap, used)


func _show_toast(text: String, color: Color) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast_t = TOAST_SEC


# --- HUD -------------------------------------------------------------------------------

## Screen y of the highest point of the night panel; no catchable tile is drawn below it.
func panel_top() -> float:
	return view_size.y - PANEL_TOP_UP


## Mock px per game px (the HUD is laid out at 1080 wide).
func _mk() -> float:
	return 1080.0 / MOCK_W


## A point of the target mock on screen: its bottom on the screen's bottom, centred across.
func _m(p: Vector2) -> Vector2:
	return Vector2((view_size.x - 1080.0) * 0.5 + p.x * _mk(), view_size.y - (MOCK_H - p.y) * _mk())


func _m_rect(r: Rect2) -> Rect2:
	return Rect2(_m(r.position), r.size * _mk())


func _hud_tex(file: String) -> Texture2D:
	return load(HUD_ART + file) as Texture2D


## The slot screen inside the console.
func _tray_rect() -> Rect2:
	return _m_rect(MOCK_SCREEN)


## Both rows use the slot screen's full inner width (the hint bulb sits outside, above the buttons).
func _row_width(_where: String) -> float:
	return _tray_rect().size.x - 2.0 * TRAY_PAD


## The slot grid (owner, 19 Oct 2026): both rows share one grid of columns, so every letter has
## its slot straight under it and the wires run straight. The grid has as many columns as the
## level's longest word (words run 3 to 8 letters), at least MIN_COLS, and keeps the mock's look:
## its tile size (SLOT_MAX) and gap ratio, shrinking only as far as the longest word needs to fit
## the screen. Words start in the grid's first column, as the mock's do.
func _grid_cols(n: int) -> int:
	var cols := maxi(MIN_COLS, n)
	if game_round != null:
		for w in game_round.words:
			cols = maxi(cols, w.length())
	return cols


func _slot_size(_where: String, n: int) -> float:
	var k := float(_grid_cols(n))
	return minf(SLOT_MAX, _row_width("active") / (k + GAP_RATIO * (k - 1.0)))


func _slot_gap(n: int) -> float:
	return _slot_size("active", n) * GAP_RATIO


## The grid is centred in the slot screen (it fills it from five columns up); words sit left on it.
func _slot_center(where: String, idx: int, n: int) -> Vector2:
	var size := _slot_size(where, n)
	var gap := _slot_gap(n)
	var k := float(_grid_cols(n))
	var x0 := _tray_rect().position.x + TRAY_PAD + (_row_width(where) - (k * size + (k - 1.0) * gap)) * 0.5
	var x := x0 + size * 0.5 + float(idx) * (size + gap)
	return Vector2(x, _m(Vector2(0, MOCK_ROW1_Y if where == "active" else MOCK_ROW2_Y)).y)


func _ignore(c: Control) -> Control:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## A rounded chip with one label inside; returns the panel (the label is its child `label_name`).
## Target mock: a dark glassy pill with a pale rim.
func _chip(panel_name: String, label_name: String, text: String, min_w: float = 0.0) -> Panel:
	var p := Panel.new()
	p.name = panel_name
	var sb := Ui.box(Color(0.08, 0.1, 0.2, 0.78), int(CHIP_H * 0.5), Color(0.72, 0.78, 0.95, 0.55), 3)
	sb.shadow_color = Color(0.0, 0.02, 0.08, 0.35)
	sb.shadow_size = 10
	p.add_theme_stylebox_override("panel", sb)
	var l := Ui.label(text, 42, TEXT_CREAM)
	l.name = label_name
	l.add_theme_constant_override("outline_size", 0)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_child(l)
	# The two chips share the top row; long names shrink their font to fit.
	var max_w := _chip_max_w()
	var fs := 42
	while fs > 24 and ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 64.0 > max_w:
		fs -= 2
	l.add_theme_font_size_override("font_size", fs)
	p.size = Vector2(maxf(min_w, minf(max_w, ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 64.0)), CHIP_H)
	p.pivot_offset = p.size * 0.5
	_ignore(p)
	_ignore(l)
	return p


func _chip_max_w() -> float:
	return (view_size.x - 2.0 * SIDE_PAD - 24.0) * 0.5


## A round console button centred on a mock point: an invisible Button over the mock's ring
## ("Ring", its icon painted out) and the icon ("Icon", the mock's own where it has one).
func _icon_button(node_name: String, kind: String, mock_y: float, ring: Color) -> Button:
	var b := _hud_button(node_name)
	var d := MOCK_BTN_R * 2.0 * _mk()
	b.size = Vector2(d, d)
	b.position = _m(Vector2(MOCK_BTN_X, mock_y)) - b.size * 0.5
	b.pivot_offset = b.size * 0.5
	# The button textures are 150 game px square (scripts/art/hud/gen_hud_svgs.py), centred on the button.
	var tex_pos := b.size * 0.5 - Vector2(BTN_ART, BTN_ART) * 0.5
	var art: Control = HudArt.RingArt.new()
	art.name = "Ring"
	art.set("tex", _hud_tex("btn_%s.png" % kind))
	art.set("tex_pos", tex_pos)
	art.set("ring", ring)
	art.set("ring_r", MOCK_RING_R * _mk())
	art.set("calm", settings.reduced_motion)
	art.size = b.size
	b.add_child(_ignore(art))
	var ic: Control = HudArt.Icon.new()
	ic.name = "Icon"
	ic.set("art", {kind: _hud_tex("btn_%s_icon.png" % kind)})
	ic.set("art_pos", tex_pos)
	ic.set("clip_r", MOCK_ICON_R * _mk())
	ic.set("colour", Color("ffd2b0") if kind == "pause" else Color("d8faff"))
	ic.set("kind", kind)
	ic.size = b.size
	ic.pivot_offset = ic.size * 0.5
	b.add_child(_ignore(ic))
	return b


## The hint bulb above the buttons: the mock's bulb, glowing.
func _hint_bulb() -> Button:
	var b := _hud_button("HintButton")
	var r := _m_rect(MOCK_BULB)
	b.position = r.position
	b.size = r.size
	b.pivot_offset = b.size * Vector2(0.5, 0.9)
	var ic: Control = HudArt.Icon.new()
	ic.name = "Icon"
	ic.set("art", {"hint": _hud_tex("bulb.png")})
	ic.set("halo", (MOCK_BULB_GLASS - MOCK_BULB.position) * _mk())
	ic.set("halo_r", 24.8 * _mk())
	ic.set("kind", "hint")
	ic.size = b.size
	ic.pivot_offset = b.size * Vector2(0.5, 0.95)  # it wobbles on its screw base
	b.add_child(_ignore(ic))
	return b


func _hud_button(node_name: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.button_down.connect(_squish.bind(b, 0.86))
	b.button_up.connect(_squish.bind(b, 1.0))
	_hud.add_child(b)
	return b


## A press squishes a button and lets it spring back.
func _squish(b: Control, to: float) -> void:
	if settings.reduced_motion or not b.is_inside_tree():
		return
	var old: Variant = b.get_meta("squish", null)
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	var tw := b.create_tween()
	b.set_meta("squish", tw)
	tw.tween_property(b, "scale", Vector2.ONE * to, 0.08 if to < 1.0 else 0.32).set_trans(Tween.TRANS_BACK if to >= 1.0 else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## The Catcher in the porthole's round screen (where the mock has its astronaut), under the glass.
func _build_portrait() -> void:
	var r := MOCK_WINDOW_R * _mk()
	var holder := Control.new()
	holder.name = "Portrait"
	holder.size = Vector2(r, r) * 2.0
	holder.position = _m(MOCK_PORT) - holder.size * 0.5
	_ignore(holder)
	var path := "res://brand/characters/%s.png" % character_id
	if ResourceLoader.exists(path):
		var bust := TextureRect.new()
		bust.name = "PortraitBust"
		bust.texture = load(path)
		bust.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bust.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bust.size = holder.size
		bust.pivot_offset = bust.size * Vector2(0.5, 0.9)
		bust.material = HudArt.clip_material()
		bust.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_ignore(bust)
		holder.add_child(bust)
		_bust = bust
	var glass: Control = HudArt.PortholeGlass.new()
	glass.name = "PortraitArt"
	glass.set("calm", settings.reduced_motion)
	glass.size = holder.size
	holder.add_child(_ignore(glass))
	_hud.add_child(holder)
	_portrait = holder
	_portrait_art = glass


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
	# The console tray, the mock's own art: porthole at its left end, the slot screen in the middle.
	var con: Control = HudArt.Console.new()
	con.name = "Console"
	var ctex := _hud_tex("console.png")
	con.set("tex", ctex)
	con.set("k", _mk())
	con.set("origin", MOCK_CONSOLE)
	con.position = _m(MOCK_CONSOLE)
	con.size = ctex.get_size() / HudArt.ART_SCALE
	con.set("screen", Rect2(_tray_rect().position - con.position, _tray_rect().size))
	con.set("calm", settings.reduced_motion)
	_hud.add_child(_ignore(con))
	_console = con
	if character_id != "":
		_build_portrait()
	# Top (target mock): the level's name at left, Level n / N at right, both pills.
	var cc := _chip("LevelCounterChip", "LevelCounter", level_counter)
	cc.position = Vector2(w - SIDE_PAD - cc.size.x, CHIP_Y)
	cc.visible = level_counter != ""
	_hud.add_child(cc)
	_counter_label = cc.get_node("LevelCounter")
	_counter_chip = cc
	var mid := _chip("LevelChip", "LevelLabel", _level_title)
	mid.position = Vector2(SIDE_PAD, CHIP_Y)
	_hud.add_child(mid)
	_level_chip = mid
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
	# Slot screen: the active word on the first row, the next word on the second. The console draws it.
	var tr := _tray_rect()
	var tray := Panel.new()
	tray.name = "SlotTray"
	tray.position = tr.position
	tray.size = tr.size
	tray.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_hud.add_child(_ignore(tray))
	_active_row = Control.new()
	_active_row.name = "ActiveSlots"
	_hud.add_child(_ignore(_active_row))
	_preview_row = Control.new()
	_preview_row.name = "PreviewSlots"
	_hud.add_child(_ignore(_preview_row))
	# The wires sit under the slots: amber links along the active word, cyan wires down to the next.
	_wires = HudArt.SlotWires.new()
	_wires.name = "SlotWires"
	_wires.set("top_row", _active_row)
	_wires.set("bottom_row", _preview_row)
	_wires.set("calm", settings.reduced_motion)
	_wires.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.add_child(_ignore(_wires))
	_hud.move_child(_wires, _active_row.get_index())
	# The mock's empty slot: a teal well with a bright cyan rim and a soft glow.
	_slot_empty_sb = Ui.box(SLOT_EMPTY, 12, SLOT_RIM, 4)
	_slot_empty_sb.shadow_color = Color(SLOT_RIM.r, SLOT_RIM.g, SLOT_RIM.b, 0.35)
	_slot_empty_sb.shadow_size = 9
	# Right column (target mock): the hint bulb, then Pause, Sound and Settings stacked.
	_hint_button = _hint_bulb()
	_pause_button = _icon_button("PauseButton", "pause", MOCK_PAUSE_Y, Color("ff9a4a"))
	_sound_button = _icon_button("SoundButton", "sound", MOCK_SOUND_Y, NEON)
	_settings_button = _icon_button("SettingsButton", "settings", MOCK_SETTINGS_Y, NEON)
	_pause_icon = _pause_button.get_node("Icon")
	_sound_icon = _sound_button.get_node("Icon")
	_hint_icon = _hint_button.get_node("Icon")
	_hint_button.pressed.connect(request_hint)
	_pause_button.pressed.connect(func() -> void: pause_requested.emit())
	_sound_button.pressed.connect(toggle_sound)
	_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	_sync_sound_icon()
	# The clock: liquid in the console art's bar channel (the frame is in the art).
	var ch := _m_rect(MOCK_CHANNEL)
	_time_bar = ProgressBar.new()
	_time_bar.name = "TimeBar"
	_time_bar.position = ch.position
	_time_bar.custom_minimum_size = Vector2(0, ch.size.y)
	_time_bar.size = ch.size
	_time_bar.show_percentage = false
	_time_bar.min_value = 0.0
	_time_bar.max_value = _n("burst.seconds")
	_time_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	_time_bar.add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	_hud.add_child(_ignore(_time_bar))
	_liquid = HudArt.Liquid.new()
	_liquid.name = "Liquid"
	_liquid.set("calm", settings.reduced_motion)
	_liquid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_time_bar.add_child(_ignore(_liquid))
	_set_clock_colours(false)
	# The mock shows no number on the clock; the seconds appear, pulsing, only when time runs low.
	_clock_label = Ui.label("", 34, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_clock_label.name = "ClockLabel"
	_clock_label.position = Vector2(ch.end.x - 16.0 - CLOCK_LABEL_W, ch.get_center().y - 24.0)
	_clock_label.size = Vector2(CLOCK_LABEL_W, 48)
	_clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_clock_label.pivot_offset = Vector2(CLOCK_LABEL_W, 24)
	_clock_label.visible = false
	_hud.add_child(_ignore(_clock_label))
	# The wrong-catch counter sits under the level counter, right-aligned with it (WP-F.24).
	_mistakes = MistakeChip.new()
	_mistakes.calm = settings.reduced_motion
	_mistakes.set_state(int(_n("burst.maxWrong")), 0)
	_mistakes.position = Vector2(w - SIDE_PAD - _mistakes.size.x, CHIP_Y + CHIP_H + MISTAKE_GAP)
	_hud.add_child(_ignore(_mistakes))
	_coach = Coach.new()
	_coach.setup(_tun, settings.reduced_motion, view_size)
	_hud.add_child(_coach)


## Coral liquid normally, crimson in the last seconds.
func _set_clock_colours(low: bool) -> void:
	if _liquid == null:
		return
	_liquid.set("c1", HudArt.CRIMSON if low else HudArt.CORAL)
	_liquid.set("c2", HudArt.CRIMSON_LIGHT if low else HudArt.CORAL_LIGHT)



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
		# A filled slot is the mock's tile: a dark line round a cream face with a tan lip.
		var r := int(size * 0.13)
		p.set_meta("tile_sb", Ui.box(TILE_INK_LINE, r + 2, TILE_INK_LINE, 0))
		var face := Panel.new()
		face.name = "Face"
		var line := maxf(2.0, size * 0.045)
		face.position = Vector2(line, line)
		face.size = p.size - Vector2(line, line) * 2.0
		var fsb := Ui.box(TILE_CREAM, r, TILE_LIP, 0)
		fsb.border_width_bottom = maxi(3, int(size * 0.075))
		face.add_theme_stylebox_override("panel", fsb)
		face.visible = false
		p.add_child(_ignore(face))
		var l := Ui.label("", int(size * 0.62), TILE_INK)
		l.name = "Glyph"
		l.size = p.size
		l.add_theme_constant_override("outline_size", 0)
		p.add_child(l)
		row.add_child(p)


func _style_slot(p: Panel, filled: bool, _where: String) -> void:
	p.add_theme_stylebox_override("panel", p.get_meta("tile_sb") if filled else _slot_empty_sb)
	(p.get_node("Face") as Control).visible = filled


## Share of the level's words restored so far: colour and city lights come back with it.
func restored_share() -> float:
	if game_round == null or game_round.words.is_empty():
		return 0.0
	if game_round.state == "won" or (game_round.finale and game_round.word_index >= 1):
		return 1.0  # in the finale, LISTEN brings every colour back at once
	return clampf(float(game_round.word_index) / float(game_round.words.size()), 0.0, 1.0)


func _update_hud() -> void:
	var share := restored_share()
	if _backdrop != null:
		_backdrop.restore = share
		if game_round.finale and share >= 1.0 and game_round.word_index == 1:
			_backdrop.snap()
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
		_set_clock_colours(low)
		_clock_label.add_theme_color_override("font_color", HudArt.CRIMSON_LIGHT if low else CLOCK_TEXT)
		_clock_label.visible = low
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


## True for the row that holds the Catcher's name in the finale: its ghosts show in full (the player knows it).
func _name_row(where: String) -> bool:
	if not game_round.finale:
		return false
	return (where == "active" and game_round.word_index == 1) or (where == "preview" and game_round.word_index == 0)


func _fill_row(row: Control, where: String, slots: Array[Dictionary]) -> void:
	for i in mini(slots.size(), row.get_child_count()):
		var p := row.get_child(i) as Panel
		var filled := _slot_text_filled(where, i, bool(slots[i]["filled"]))
		var g := p.get_node("Glyph") as Label
		var ch := str(slots[i]["ch"]).to_upper()
		g.text = ch if filled or _name_row(where) or (hint_shown(i, slots.size()) and not game_round.jammed) else ""
		g.modulate.a = 1.0 if filled else _n("hud.hintAlpha")
		g.add_theme_color_override("font_color", TILE_INK if filled else Color.WHITE)
		if filled and not bool(p.get_meta("was_filled", false)):
			p.set_meta("land_t", 0.0)
		p.set_meta("was_filled", filled)
		_style_slot(p, filled, where)


func _tick_hud(delta: float) -> void:
	if _mistakes != null:
		_mistakes.tick(delta)
		_mistakes.position.x = view_size.x - SIDE_PAD - _mistakes.size.x  # the pill grows with its count
	if _refill_t >= 0.0:
		_refill_t += delta
		if _refill_t >= _n("flow.refillSec"):
			_refill_t = -1.0
	if _night != null and float(_night.get("lit")) > restored_share():
		_night.set("lit", move_toward(float(_night.get("lit")), restored_share(), delta * 0.8))
	var calm := settings.reduced_motion
	_anim_t += delta
	var t := _anim_t
	if _chip_t < CHIP_SWAP_SEC:
		_chip_t += delta
		var c := clampf(_chip_t / CHIP_SWAP_SEC, 0.0, 1.0)
		var a := 1.0 if calm else clampf(c * 1.4, 0.0, 1.0)
		_level_label.modulate.a = a
		_counter_label.modulate.a = a
	# The pills pop in with a little overshoot on a new level, then bob gently out of step.
	if not calm:
		var pop := _back_ease(clampf(_chip_t / CHIP_SWAP_SEC, 0.0, 1.0))
		_level_chip.scale = Vector2.ONE * lerpf(0.7, 1.0, pop)
		_counter_chip.scale = Vector2.ONE * lerpf(0.7, 1.0, _back_ease(clampf((_chip_t - 0.08) / CHIP_SWAP_SEC, 0.0, 1.0)))
		_level_chip.position.y = CHIP_Y + 3.0 * sin(t * 1.2)
		_counter_chip.position.y = CHIP_Y + 3.0 * sin(t * 1.2 + 1.7)
	elif calm != _was_calm:
		_level_chip.scale = Vector2.ONE
		_counter_chip.scale = Vector2.ONE
		_level_chip.position.y = CHIP_Y
		_counter_chip.position.y = CHIP_Y
	# Console idle life: the porthole arcs drift, the Catcher breathes, lights blink, the liquid sloshes.
	# Reduced motion can change mid-level (Settings), so the arts read it every frame.
	var redraw := not calm or calm != _was_calm
	for n in [_console, _portrait_art, _liquid, _wires]:
		if n != null:
			n.set("t", t)
			n.set("calm", calm)
			if redraw or n == _liquid or n == _wires:
				n.queue_redraw()
	if _bust != null:
		var br := 1.0 if calm else 1.0 + 0.025 * sin(t * 2.1)
		_bust.scale = Vector2(2.0 - br, br)  # a soft breath: a touch taller, a touch narrower
	for b in [_pause_button, _sound_button, _settings_button]:
		var ring := (b as Node).get_node_or_null("Ring")
		if ring != null:
			ring.set("t", t + float(b.get_index()) * 0.9)
			ring.set("calm", calm)
			if redraw:
				ring.queue_redraw()
	# Hint bulb: a warm pulse and a little wobble; a hop every few seconds says "tap me".
	if _hint_icon != null:
		_hint_icon.set("glow", 0.6 if calm else 0.5 + 0.5 * sin(t * 2.4))
		if not calm:
			var hop := fposmod(t, 6.0)
			var up := 0.0 if hop > 0.6 else sin(hop / 0.6 * PI) * 14.0
			_hint_icon.rotation = deg_to_rad(5.0 * sin(t * 1.8)) + (deg_to_rad(8.0) * sin(hop * 25.0) * (1.0 - hop / 0.6) if hop < 0.6 else 0.0)
			_hint_icon.position.y = (_hint_button.size.y - _hint_icon.size.y * _hint_icon.scale.y) * 0.5 - up
		elif calm != _was_calm:
			_hint_icon.rotation = 0.0
			_hint_icon.position.y = (_hint_button.size.y - _hint_icon.size.y * _hint_icon.scale.y) * 0.5
	_was_calm = calm
	if _hint_flash_t > 0.0:
		_hint_flash_t = maxf(0.0, _hint_flash_t - delta)
		_hint_button.modulate = Color.WHITE.lerp(Color(1.0, 0.35, 0.35), _hint_flash_t / HINT_FLASH_SEC)
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.35, 0.0, 1.0)
	# Babel's line types itself into the bubble at his porthole and stays for babel.showSeconds.
	_babel_t += delta
	_sync_babel_line()
	if _low and not calm:
		var cp := 1.0 + 0.12 * absf(sin(_time * TAU))
		_clock_label.scale = Vector2(cp, cp)
	# Empty slots breathe a soft cyan glow.
	if _slot_empty_sb != null:
		var g := 0.7 if calm else 0.55 + 0.45 * (0.5 + 0.5 * sin(t * 2.0))
		_slot_empty_sb.border_color = Color(SLOT_RIM.r, SLOT_RIM.g, SLOT_RIM.b, 0.8 + 0.2 * g)
		_slot_empty_sb.shadow_color = Color(SLOT_RIM.r, SLOT_RIM.g, SLOT_RIM.b, 0.38 * g)
	_pulse_t += delta
	var k := 1.0
	if _pulse_t < PULSE_SEC and not calm:
		k = 1.0 + 0.18 * sin(PI * _pulse_t / PULSE_SEC)
	if _slots_in_t < 2.0 and not calm:
		# A new level: the empty slots pop in one after another.
		_slots_in_t += delta
		var i := 0
		for row in [_active_row, _preview_row]:
			for c in row.get_children():
				var u := clampf((_slots_in_t - float(i) * SLOT_IN_STAGGER) / SLOT_IN_SEC, 0.0, 1.0)
				(c as Control).scale = Vector2.ONE * maxf(0.0, _back_ease(u))
				i += 1
		return
	for row in [_active_row, _preview_row]:
		for c in row.get_children():
			var sq := Vector2.ONE
			var lt := float((c as Node).get_meta("land_t", 99.0))
			if lt < LAND_SEC and not calm:
				lt += delta
				c.set_meta("land_t", lt)
				# A letter lands: squash wide, then spring tall and settle.
				var u := lt / LAND_SEC
				var wob := sin(u * PI * 2.5) * (1.0 - u) * 0.22
				sq = Vector2(1.0 + wob, 1.0 - wob)
			(c as Control).scale = sq * (k if row == _active_row else 1.0)


## Back ease-out (overshoots a little, then settles): 0 -> 0, 1 -> 1.
static func _back_ease(u: float) -> float:
	var w := u - 1.0
	return 1.0 + 2.7 * w * w * w + 1.7 * w * w

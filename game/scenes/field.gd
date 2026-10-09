extends Node2D
## The play field: owns one Round, maps field units to the screen, animates its events and
## shows the HUD. All rules live in res://rules/; this file only draws and forwards taps.

const Targeting := preload("res://rules/targeting.gd")
const RoundScript := preload("res://rules/round.gd")
const GameData := preload("res://rules/game_data.gd")
const TileViewScript := preload("res://scenes/tile_view.gd")
const TileViewScene: PackedScene = preload("res://scenes/tile_view.tscn")
const LightRig := preload("res://scenes/light_rig.gd")
const Starfield := preload("res://scenes/starfield.gd")
const AppSettings := preload("res://scenes/app_settings.gd")
const Ui := preload("res://scenes/ui.gd")
const FpsMeter := preload("res://scenes/fps_meter.gd")

const ThiefViewScript := preload("res://scenes/thief_view.gd")
const DEFAULT_ACT := "act1_low_orbit"
const LOW_TIME := 5.0
const FLOAT_SEC := 0.9
const PAUSE_SIZE := 100.0
const PERIWINKLE := Color(0.561, 0.612, 0.949)
const RED := Color(1.0, 0.3, 0.3)
# Pure layout and pacing constants (screen pixels at 1080 wide, seconds).
const BOTTOM_PAD := 40.0
const END_DELAY := 1.0
const TOAST_SEC := 1.1
const LEVEL_TITLE_SEC := 2.0
const TYPE_CPS := 38.0
const TETHER_FADE := 0.12
const PULSE_SEC := 0.45
const ACTIVE_Y := 225.0
const PREVIEW_Y := 328.0
const ACTIVE_MAX := 118.0
const PREVIEW_SIZE := 52.0
const SIDE_PAD := 40.0
const BAND_Y := 372.0
const BAND_H := 120.0
# Babel's throw: look of a single flight (timing and origin are tunables under babel.*).
const THROW_START_SCALE := 0.15
const THROW_WOBBLE := 0.12
const THROW_WOBBLE_HZ := 40.0
const THROW_FLARE_SEC := 0.12
const THROW_TAIL := 0.25  # rift fade after the last landing, as a share of babel.throwSec

signal round_finished(summary: Dictionary)
## Every rules event, as the field applies it (for telemetry and other listeners).
signal game_event(e: Dictionary)
## A tap that fired nothing; nearest_px is the distance to the nearest catchable tile, or -1.
signal tap_missed(nearest_px: float)
## The pause button, Escape or Android back was pressed; the flow decides and calls set_paused.
signal pause_requested

## Colour of the tether and the catch flash (the flow sets it per character).
var tether_colour: Color = Color(0.55, 0.9, 1.0, 1.0)
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
## Babel throws the round's letters out of a rift before play starts (visual only).
var intro_enabled: bool = true

var _intro_on: bool = false
var _intro_t: float = 0.0
var _intro_dur: float = 0.0
var _intro_order: Dictionary = {}  # tile_id -> launch index
var _rift: Node2D

var _level_title: String = ""
var _level_t: float = 0.0
var _level_label: Label
var _tun: Dictionary = {}
var _content: Dictionary = {}
var _scale: float = 1080.0
var _off: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _ap_timer: float = 0.0
var _views: Dictionary = {}  # tile_id -> TileView
var _pending: Dictionary = {}  # Vector2i(absolute word, slot) -> true while a caught tile flies
var _view_word: int = 0
var _end_t: float = -1.0
var _toast_t: float = 0.0
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
var _low: bool = false
var _active_key: String = ""
var _preview_key: String = ""
var _active_n: int = 0
var _preview_n: int = 0

var _world: CanvasLayer
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
	_start(seed_value)


## Starts an authored level (its words in order, its tuning and seed). Call after the field is in the tree.
func begin_level(level: Dictionary, act: String = DEFAULT_ACT, mods: Array = []) -> void:
	_tun = GameData.load_tunables()
	_content = content_override if not content_override.is_empty() else GameData.load_content()
	game_round = RoundScript.create_level(_tun, _content, act, level, mods)
	_level_title = "%s  %s" % [str(level.get("id", "")), str(level.get("title", ""))]
	_level_t = LEVEL_TITLE_SEC
	_start(int(level["seed"]))


func _start(seed_value: int) -> void:
	_scale = view_size.x
	_off = Vector2(0.0, view_size.y - _n("field.height") * _scale - BOTTOM_PAD)
	_build_world()
	_build_hud()
	_apply_events()
	_sync_views()
	_update_hud()
	_start_intro(seed_value)
	if print_ready:
		print("AstroLex ready: %d tiles" % game_round.tiles.size())


func to_screen(p: Vector2) -> Vector2:
	return _off + p * _scale


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
	for t in game_round.tiles:
		if not t.alive or t.plane >= 2:
			continue
		var d := to_screen(t.pos).distance_to(screen_pos)
		nearest = minf(nearest, d)
		if d <= radius_px(t) + margin and d < best_d:
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
		tap(event.position)
	elif event.is_action_pressed("ui_cancel"):
		pause_requested.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		pause_requested.emit()


## Freezes or resumes everything: rules, intro, effects; taps are ignored while paused.
func set_paused(on: bool) -> void:
	paused = on
	if _pause_button != null:
		_pause_button.text = "▶" if on else "II"


func advance(delta: float) -> void:
	if game_round == null or paused:
		return
	_time += delta
	if _intro_on:
		_tick_intro(delta)
		return
	if autoplay:
		_autoplay_tick(delta)
	game_round.step(delta)
	_apply_events()
	_sync_views()
	if _fps_meter != null:
		_fps_meter.tiles = _views.size()
	_tick_views(delta)
	_update_tether(delta)
	_update_hud()
	_tick_hud(delta)
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
	}


# --- Babel throws the letters ------------------------------------------------------------

## True while Babel is still throwing the letters; the rules do not step meanwhile.
func intro_active() -> bool:
	return _intro_on


func _start_intro(seed_value: int) -> void:
	if not intro_enabled:
		return
	if _rift != null:
		_rift.queue_free()
		_rift = null
	_intro_order.clear()
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
	_intro_dur = throw_sec if settings.reduced_motion else throw_sec + _n("babel.throwStagger") * float(maxi(ids.size() - 1, 0))
	_intro_t = 0.0
	_intro_on = true
	_rift = Rift.new()
	_rift.name = "BabelRift"
	_rift.position = to_screen(Vector2(_n("babel.throwOriginX"), _n("babel.throwOriginY")))
	_rift.radius = _n("babel.riftRadius") * _scale
	_rift.animated = not settings.reduced_motion
	_fx_layer.add_child(_rift)
	_pose_intro()


## Ends the intro at once: every tile snaps to its place and play starts.
func skip_intro() -> void:
	if not _intro_on:
		return
	_intro_on = false
	if _rift != null:
		_rift.queue_free()
		_rift = null
	for id in _views.keys():
		var v: TileViewScript = _views[id]
		v.scale = Vector2.ONE
		v.visible = true
		v.modulate.a = _n("plane.backAlpha") if v.is_back else 1.0
	_sync_views()


func _tick_intro(delta: float) -> void:
	_intro_t += delta
	if _intro_t >= _intro_dur + _n("babel.throwSec") * THROW_TAIL:
		skip_intro()
		return
	_sync_views()
	_pose_intro()


func _pose_intro() -> void:
	var throw_sec := maxf(_n("babel.throwSec"), 0.01)
	var stagger := _n("babel.throwStagger")
	var s := _n("babel.throwOvershoot")
	var origin := _rift.position
	var flare := 0.0
	for id in _views.keys():
		var v: TileViewScript = _views[id]
		var real := to_screen(game_round.find_tile(id).pos)
		var base_a := _n("plane.backAlpha") if v.is_back else 1.0
		if settings.reduced_motion:
			var f := clampf(_intro_t / throw_sec, 0.0, 1.0)
			v.position = real
			v.scale = Vector2.ONE
			v.modulate.a = base_a * f
			continue
		var start: float = float(_intro_order.get(id, 0)) * stagger
		var u := clampf((_intro_t - start) / throw_sec, 0.0, 1.0)
		if _intro_t < start:
			v.visible = false
			continue
		v.visible = true
		var w := u - 1.0
		var e := 1.0 + (s + 1.0) * w * w * w + s * w * w  # back ease-out
		v.position = origin.lerp(real, e)
		var grow := clampf(u * 2.0, 0.0, 1.0)
		var wobble := THROW_WOBBLE * sin(PI * clampf((u - 0.7) / 0.3, 0.0, 1.0)) * sin(u * THROW_WOBBLE_HZ)
		v.scale = Vector2.ONE * lerpf(THROW_START_SCALE, 1.0, grow) * (1.0 + wobble)
		v.modulate.a = base_a * clampf(u * 4.0, 0.0, 1.0)
		if _intro_t - start < THROW_FLARE_SEC:
			flare = 1.0
	if _rift != null:
		var rest := clampf((_intro_dur + throw_sec * THROW_TAIL - _intro_t) / (throw_sec * THROW_TAIL), 0.0, 1.0)
		_rift.flare = flare
		_rift.fade = minf(1.0, rest) if not settings.reduced_motion else 1.0
		_rift.t = _time
		_rift.queue_redraw()


class Rift extends Node2D:
	var radius: float = 60.0
	var flare: float = 0.0
	var fade: float = 1.0
	var t: float = 0.0
	var animated: bool = true

	func _draw() -> void:
		var c := Color(0.439, 0.439, 1.0)  # periwinkle #7070FF
		var pulse := 1.0 + (0.12 * sin(t * 6.0) if animated else 0.0)
		var r := radius * pulse * (1.0 + 0.35 * flare)
		for i in 5:
			var k := float(i) / 4.0
			draw_circle(Vector2.ZERO, r * (2.2 - 1.6 * k), Color(c.r, c.g, c.b, 0.10 * fade * (0.6 + flare)))
		draw_circle(Vector2.ZERO, r * 0.6, Color(0.85, 0.85, 1.0, 0.85 * fade))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(c.r, c.g, c.b, fade), 5.0)
		draw_arc(Vector2.ZERO, r * 1.5, t * 0.8, t * 0.8 + TAU * 0.7, 40, Color(c.r, c.g, c.b, 0.5 * fade), 3.0)


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
	var stars: Node2D = Starfield.new()
	stars.view_size = view_size
	backdrop.add_child(stars)
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
	rig.configure(Vector2(view_size.x * 0.5, _off.y + _n("field.height") * _scale * 0.45), view_size.y * 1.1, _world.layer)
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
	var launcher := Launcher.new()
	launcher.name = "Launcher"
	launcher.position = to_screen(game_round.origin())
	_fx_layer.add_child(launcher)


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
		v.set_back(_n("plane.backAlpha"), _n("plane.backDesaturate"))
	v.place(to_screen(t.pos), _time, t.pos.x)
	_views[t.id] = v
	return v


func _sync_views() -> void:
	var live: Dictionary = {}
	for t in game_round.tiles:
		live[t.id] = true
		var v := _ensure_view(t)
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
	for i in range(_floats.size() - 1, -1, -1):
		_floats[i][1] += delta
		var lab: Label = _floats[i][0]
		var k: float = float(_floats[i][1]) / FLOAT_SEC
		lab.modulate.a = clampf(1.0 - k, 0.0, 1.0)
		lab.position.y = _clock_label.position.y + 40.0 + (0.0 if settings.reduced_motion else 60.0 * k)
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
					_ensure_view(t)
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
			"escape":
				_show_toast("It drifted off", Ui.DIM)
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
			"thief_down":
				_burst(to_screen(e["pos"]), PERIWINKLE, 22)
				_show_toast("Drone down", PERIWINKLE)
			"restore":
				_view_word += 1
				_pulse_t = 0.0
			"babel":
				last_babel = str(e["text"])
				_babel_t = 0.0
			"round_end":
				_end_t = 0.0
				if bool(e["won"]):
					print("AstroLex round won: score=%d" % int(round(game_round.score)))


func _on_catch(e: Dictionary) -> void:
	var id := int(e["tile_id"])
	var v: TileViewScript = _views.get(id)
	var where: String = e["where"]
	var slot := int(e["slot"])
	var key := Vector2i(_view_word + (1 if where == "preview" else 0), slot)
	_pending[key] = true
	_fly_keys[id] = key
	if v == null:
		_unpend_for(id)
		return
	var row_n := _active_n if where == "active" else _preview_n
	var target := _slot_center(where, slot, row_n)
	var slot_px := _slot_size(where, row_n)
	v.fly_to(target, slot_px, _n("fx.flyToSlotSec"))
	_burst(target, tether_colour.lightened(0.3))


func _float_cost(amount: float) -> void:
	var lab := Ui.label("−%s s" % (str(int(amount)) if is_equal_approx(amount, round(amount)) else "%.1f" % amount), 48, RED)
	lab.name = "CostFloat"
	lab.position = Vector2(view_size.x * 0.5 + 100.0, _clock_label.position.y + 40.0)
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


func _show_toast(text: String, color: Color) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast_t = TOAST_SEC


# --- HUD -------------------------------------------------------------------------------

func _slot_size(where: String, n: int) -> float:
	if where == "preview":
		return PREVIEW_SIZE
	var gap := 12.0
	return minf(ACTIVE_MAX, (view_size.x - 2.0 * SIDE_PAD - gap * float(maxi(n - 1, 0))) / float(maxi(n, 1)))


func _slot_center(where: String, idx: int, n: int) -> Vector2:
	var size := _slot_size(where, n)
	var gap := 12.0 if where == "active" else 8.0
	var total := size * n + gap * (n - 1)
	var x := (view_size.x - total) * 0.5 + size * 0.5 + float(idx) * (size + gap)
	return Vector2(x, ACTIVE_Y if where == "active" else PREVIEW_Y)


func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.name = "Hud"
	_hud.layer = 10
	add_child(_hud)
	_score_label = Ui.label("0", 62, Ui.INK, HORIZONTAL_ALIGNMENT_LEFT)
	_score_label.name = "ScoreLabel"
	_score_label.position = Vector2(SIDE_PAD, 24)
	_score_label.size = Vector2(300, 80)
	_hud.add_child(_score_label)
	_combo_label = Ui.label("×1.0", 52, Ui.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT)
	_combo_label.name = "ComboLabel"
	_combo_label.position = Vector2(view_size.x - SIDE_PAD - PAUSE_SIZE - 20.0 - 260.0, 28)
	_combo_label.size = Vector2(260, 80)
	_hud.add_child(_combo_label)
	_clock_label = Ui.label("", 96, Ui.INK)
	_clock_label.name = "ClockLabel"
	_clock_label.position = Vector2((view_size.x - 240.0) * 0.5, 0)
	_clock_label.size = Vector2(240, 112)
	_clock_label.pivot_offset = _clock_label.size * 0.5
	_hud.add_child(_clock_label)
	_time_bar = ProgressBar.new()
	_time_bar.name = "TimeBar"
	_time_bar.position = Vector2(SIDE_PAD, 118)
	_time_bar.size = Vector2(view_size.x - 2.0 * SIDE_PAD, 22)
	_time_bar.show_percentage = false
	_time_bar.min_value = 0.0
	_time_bar.max_value = _n("burst.seconds")
	_time_bar.add_theme_stylebox_override("background", Ui.box(Color(0.1, 0.13, 0.25), 11))
	_time_bar.add_theme_stylebox_override("fill", Ui.box(Color(0.35, 0.85, 0.95), 11))
	_hud.add_child(_time_bar)
	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "II"
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.add_theme_font_size_override("font_size", 44)
	_pause_button.add_theme_color_override("font_color", Ui.INK)
	for sb in ["normal", "hover", "pressed"]:
		_pause_button.add_theme_stylebox_override(sb, Ui.box(Color(0.1, 0.13, 0.25, 0.85), 24, Color(0.5, 0.9, 1.0), 2))
	_pause_button.position = Vector2(view_size.x - SIDE_PAD - PAUSE_SIZE, 8)
	_pause_button.size = Vector2(PAUSE_SIZE, PAUSE_SIZE)
	_pause_button.pressed.connect(func() -> void: pause_requested.emit())
	_hud.add_child(_pause_button)
	_active_row = Control.new()
	_active_row.name = "ActiveSlots"
	_hud.add_child(_active_row)
	_preview_row = Control.new()
	_preview_row.name = "PreviewSlots"
	_hud.add_child(_preview_row)
	_band = Panel.new()
	_band.name = "BabelBand"
	_band.position = Vector2(SIDE_PAD, BAND_Y)
	_band.size = Vector2(view_size.x - 2.0 * SIDE_PAD, BAND_H)
	_band.add_theme_stylebox_override("panel", Ui.box(Color(0.12, 0.05, 0.16, 0.85), 16, Color(0.75, 0.35, 0.85), 2))
	_band.visible = false
	_hud.add_child(_band)
	_band_label = Ui.label("", 36, Color(0.95, 0.8, 1.0))
	_band_label.name = "BabelText"
	_band_label.position = Vector2(20, 6)
	_band_label.size = _band.size - Vector2(40, 12)
	_band_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_band.add_child(_band_label)
	_toast = Ui.label("", 44, Ui.INK)
	_toast.name = "Toast"
	_toast.position = Vector2(0, _off.y + _n("field.topMargin") * _scale + 24.0)
	_toast.size = Vector2(view_size.x, 70)
	_toast.modulate.a = 0.0
	_hud.add_child(_toast)
	_level_label = Ui.label(_level_title, 36, Ui.DIM)
	_level_label.name = "LevelLabel"
	_level_label.position = Vector2(0, BAND_Y)  # under the slot rows; Babel's band is empty at round start
	_level_label.size = Vector2(view_size.x, 50)
	_level_label.visible = _level_title != ""
	_hud.add_child(_level_label)


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
		p.name = "Slot_%d" % i
		p.size = Vector2(size, size)
		p.pivot_offset = p.size * 0.5
		p.position = _slot_center(where, i, n) - p.size * 0.5
		var l := Ui.label("", int(size * 0.64), Color(0.05, 0.07, 0.16))
		l.name = "Glyph"
		l.size = p.size
		l.add_theme_constant_override("outline_size", 0)
		p.add_child(l)
		row.add_child(p)


func _style_slot(p: Panel, filled: bool, where: String) -> void:
	var bg := Color(0.94, 0.92, 0.84) if filled else Color(0.08, 0.1, 0.2, 0.8)
	var border := Color(0.5, 0.9, 1.0) if where == "active" else Color(0.35, 0.42, 0.65)
	p.add_theme_stylebox_override("panel", Ui.box(bg, int(p.size.x * 0.18), border, 3 if not filled else 0))


func _update_hud() -> void:
	_score_label.text = "%d" % int(round(game_round.score))
	_combo_label.text = "×%.1f" % game_round.combo
	_time_bar.value = game_round.time_left
	_clock_label.text = "%d" % int(ceil(game_round.time_left))
	var low: bool = game_round.time_left < LOW_TIME
	if low != _low:
		_low = low
		var col: Color = RED if low else Color(0.35, 0.85, 0.95)
		_time_bar.add_theme_stylebox_override("fill", Ui.box(col, 11))
		_clock_label.add_theme_color_override("font_color", RED if low else Ui.INK)
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
	return false


func _fill_row(row: Control, where: String, slots: Array[Dictionary]) -> void:
	for i in mini(slots.size(), row.get_child_count()):
		var p := row.get_child(i) as Panel
		var filled := _slot_text_filled(where, i, bool(slots[i]["filled"]))
		var g := p.get_node("Glyph") as Label
		var ch := str(slots[i]["ch"]).to_upper()
		g.text = ch if filled or hint_shown(i, slots.size()) else ""
		g.modulate.a = 1.0 if filled else _n("hud.hintAlpha")
		g.add_theme_color_override("font_color", Color(0.05, 0.07, 0.16) if filled else Color(0.8, 0.92, 1.0))
		_style_slot(p, filled, where)


func _tick_hud(delta: float) -> void:
	if _level_t > 0.0 and _level_label != null:
		_level_t -= delta
		_level_label.modulate.a = clampf(_level_t / 0.5, 0.0, 1.0)
		if _level_t <= 0.0:
			_level_label.visible = false
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.35, 0.0, 1.0)
	_babel_t += delta
	var show_sec := _n("babel.showSeconds")
	_band.visible = _babel_t < show_sec and last_babel != ""
	if _band.visible:
		_band_label.text = last_babel
		_band_label.visible_characters = int(_babel_t * TYPE_CPS)
		_band.modulate.a = clampf((show_sec - _babel_t) / 0.3, 0.0, 1.0)
	if _low and not settings.reduced_motion:
		var cp := 1.0 + 0.12 * absf(sin(_time * TAU))
		_clock_label.scale = Vector2(cp, cp)
	_pulse_t += delta
	var k := 1.0
	if _pulse_t < PULSE_SEC and not settings.reduced_motion:
		k = 1.0 + 0.18 * sin(PI * _pulse_t / PULSE_SEC)
	for c in _active_row.get_children():
		(c as Control).scale = Vector2(k, k)

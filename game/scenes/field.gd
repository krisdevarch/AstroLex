extends Node2D
## The play field: owns one Round, maps field units to the screen, animates its events and
## shows the HUD. All rules live in res://rules/; this file only draws and forwards taps.

const RoundScript := preload("res://rules/round.gd")
const GameData := preload("res://rules/game_data.gd")
const TileViewScript := preload("res://scenes/tile_view.gd")
const TileViewScene: PackedScene = preload("res://scenes/tile_view.tscn")
const LightRig := preload("res://scenes/light_rig.gd")
const Starfield := preload("res://scenes/starfield.gd")
const AppSettings := preload("res://scenes/app_settings.gd")
const Ui := preload("res://scenes/ui.gd")

const ACT := "act1_low_orbit"
# Pure layout and pacing constants (screen pixels at 1080 wide, seconds).
const BOTTOM_PAD := 40.0
const END_DELAY := 1.0
const TOAST_SEC := 1.1
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

signal round_finished(summary: Dictionary)

var autoplay: bool = false
var print_ready: bool = true
var view_size: Vector2 = Vector2(1080, 1920)
var settings: AppSettings = AppSettings.new()
var game_round: RoundScript
var last_babel: String = ""
var finished: bool = false

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
var _oxygen_bar: ProgressBar
var _toast: Label
var _band: Panel
var _band_label: Label


func _process(delta: float) -> void:
	if game_round != null:
		advance(minf(delta, 0.25))


func _n(key: String) -> float:
	return float(_tun[key])


## Starts a round. Call after the field is in the tree.
func begin(mode: String, round_no: int, seed_value: int) -> void:
	_tun = GameData.load_tunables()
	_content = GameData.load_content()
	game_round = RoundScript.create(_tun, _content, ACT, mode, seed_value, round_no)
	_scale = view_size.x
	_off = Vector2(0.0, view_size.y - _n("field.height") * _scale - BOTTOM_PAD)
	_build_world()
	_build_hud()
	_apply_events()
	_sync_views()
	_update_hud()
	if print_ready:
		print("AstroLex ready: %d tiles" % game_round.tiles.size())


func to_screen(p: Vector2) -> Vector2:
	return _off + p * _scale


func radius_px(t: Object) -> float:
	return float(t.get("radius")) * _scale


## Screen-space circle hit test: nearest catchable tile inside radius + margin; fires it.
## Returns the tile id, or -1 on a miss (a miss does nothing).
func tap(screen_pos: Vector2) -> int:
	if game_round == null or game_round.state != "play":
		return -1
	var margin := _n("tap.marginPx")
	if game_round.mode == "drift":
		margin *= _n("tap.driftMarginMul")
	var best_id := -1
	var best_d := INF
	for t in game_round.tiles:
		if not t.alive or t.plane >= 2:
			continue
		var d := to_screen(t.pos).distance_to(screen_pos)
		if d <= radius_px(t) + margin and d < best_d:
			best_d = d
			best_id = t.id
	if best_id < 0:
		_maybe_out_of_reach(screen_pos)
		return -1
	if not game_round.fire(best_id):
		return -1
	return best_id


## A tap on a back tile and on no catchable tile: a faint ring, nothing else.
func _maybe_out_of_reach(screen_pos: Vector2) -> void:
	if settings.reduced_motion:
		return
	for t in game_round.tiles:
		if t.alive and t.plane >= 2 and to_screen(t.pos).distance_to(screen_pos) <= radius_px(t) + _n("tap.marginPx"):
			var r := Ripple.new()
			r.name = "Ripple"
			r.position = screen_pos
			r.max_radius = _n("tap.rippleRadiusPx")
			r.dur = _n("tap.rippleSec")
			_fx_layer.add_child(r)
			_fx.append([r, r.dur])
			return


class Ripple extends Node2D:
	var max_radius: float = 70.0
	var dur: float = 0.3
	var _t: float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var u := clampf(_t / maxf(dur, 0.01), 0.0, 1.0)
		var e := 1.0 - (1.0 - u) * (1.0 - u)
		draw_arc(Vector2.ZERO, maxf(2.0, max_radius * e), 0.0, TAU, 40, Color(0.75, 0.9, 1.0, 0.35 * (1.0 - u)), 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap(event.position)


func advance(delta: float) -> void:
	if game_round == null:
		return
	_time += delta
	if autoplay:
		_autoplay_tick(delta)
	game_round.step(delta)
	_apply_events()
	_sync_views()
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
	}


# --- autoplay --------------------------------------------------------------------------

func _autoplay_tick(delta: float) -> void:
	_ap_timer += delta
	if _ap_timer < _n("autoplay.tapInterval"):
		return
	if game_round.state != "play" or not game_round.shot.is_empty():
		return
	_ap_timer = 0.0
	var need: Dictionary = {}
	for s in game_round.active:
		if not s["filled"]:
			need[s["ch"]] = true
	var best_id := -1
	var best_d := INF
	for t in game_round.tiles:
		if t.alive and t.plane < 2 and need.has(t.ch):
			var d: float = t.pos.distance_to(game_round.origin())
			if d < best_d:
				best_d = d
				best_id = t.id
	if best_id >= 0:
		game_round.fire(best_id)


# --- world -----------------------------------------------------------------------------

func _build_world() -> void:
	var backdrop := CanvasLayer.new()
	backdrop.name = "Backdrop"
	backdrop.layer = 0
	add_child(backdrop)
	var stars: Node2D = Starfield.new()
	stars.view_size = view_size
	backdrop.add_child(stars)

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
	_tether.default_color = Color(0.55, 0.9, 1.0, 1.0)
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
		v.set_back(_n("plane.backAlpha"), _n("plane.backGlyphAlpha"), _n("plane.backDesaturate"))
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


func _tick_views(delta: float) -> void:
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
				var msg := "Not in the record"
				if game_round.mode == "pressure":
					msg += "   −%d air" % int(_n("oxygen.wrongCost"))
				_show_toast(msg, Color(1.0, 0.5, 0.45))
			"escape":
				_show_toast("It drifted off", Ui.DIM)
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
	_burst(target)


func _burst(at: Vector2) -> void:
	if settings.reduced_motion:
		return
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.emitting = true
	p.amount = 14
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 320.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0
	p.color = Color(0.7, 0.95, 1.0)
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
	_score_label.size = Vector2(500, 80)
	_hud.add_child(_score_label)
	_combo_label = Ui.label("×1.0", 52, Ui.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT)
	_combo_label.name = "ComboLabel"
	_combo_label.position = Vector2(view_size.x - SIDE_PAD - 400, 28)
	_combo_label.size = Vector2(400, 80)
	_hud.add_child(_combo_label)
	_oxygen_bar = ProgressBar.new()
	_oxygen_bar.name = "OxygenBar"
	_oxygen_bar.position = Vector2(SIDE_PAD, 112)
	_oxygen_bar.size = Vector2(view_size.x - 2.0 * SIDE_PAD, 22)
	_oxygen_bar.show_percentage = false
	_oxygen_bar.min_value = 0.0
	_oxygen_bar.max_value = _n("oxygen.max")
	_oxygen_bar.add_theme_stylebox_override("background", Ui.box(Color(0.1, 0.13, 0.25), 11))
	_oxygen_bar.add_theme_stylebox_override("fill", Ui.box(Color(0.35, 0.85, 0.95), 11))
	_oxygen_bar.visible = game_round.mode == "pressure"
	_hud.add_child(_oxygen_bar)
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
	_oxygen_bar.value = game_round.oxygen
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


func _fill_row(row: Control, where: String, slots: Array[Dictionary]) -> void:
	for i in mini(slots.size(), row.get_child_count()):
		var p := row.get_child(i) as Panel
		var filled := _slot_text_filled(where, i, bool(slots[i]["filled"]))
		(p.get_node("Glyph") as Label).text = str(slots[i]["ch"]).to_upper() if filled else ""
		_style_slot(p, filled, where)


func _tick_hud(delta: float) -> void:
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
	_pulse_t += delta
	var k := 1.0
	if _pulse_t < PULSE_SEC and not settings.reduced_motion:
		k = 1.0 + 0.18 * sin(PI * _pulse_t / PULSE_SEC)
	for c in _active_row.get_children():
		(c as Control).scale = Vector2(k, k)

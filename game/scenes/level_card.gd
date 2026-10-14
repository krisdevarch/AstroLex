extends Control
## The level result, shown on the game screen itself (WP-3.O): when a level ends the leftover letters
## drift away and this card rises in the play field, in the HUD's own look (the slot tray's navy and
## slate, teal-outlined sockets, the Hint button's orange). Each earned star flies out of the clock
## bar (stars come from time left) into its socket with a note and a burst. Next, Retry and Map sit
## under the stars; the playtest Send and Copy buttons under those.
## Full-screen and see-through: only the card itself takes taps.

const Ui := preload("res://scenes/ui.gd")
const HudArt := preload("res://scenes/hud_art.gd")

signal next
signal retry
signal map

const CARD_W := 820.0
const CARD_H := 720.0
const STAR_D := 150.0
const STAR_MID_D := 180.0
const STAR_GAP := 34.0
const IN_SEC := 0.35  # the card rising in
const OUT_SEC := 0.3  # the card folding away
const POP_SEC := 0.3  # a star's landing pop
const CARD_FILL := Color(0.09, 0.12, 0.2, 0.95)  # the slot tray's navy and rim
const CARD_EDGE := Color("2f3b58")
const SOCKET_FILL := Color("121826")
const SOCKET_EDGE := Color("3cbfd2")
const GOLD := Color("F8BC04")
const GOLD_LIGHT := Color("ffe27a")
const NEXT_FILL := Color("f7a21d")
const NEXT_RIM := Color("9c540c")
const NEXT_INK := Color("1c2740")
const TEXT_CREAM := Color("efe8d6")
const LOSS := Color(1.0, 0.55, 0.5)

## The round summary (won, stars, score, time_left, words_done, words_total).
var summary: Dictionary = {}
## Optional; the Send and Copy results buttons show only when set.
var telemetry: RefCounted
var reduced_motion: bool = false
## Screen point the stars fly out of (the clock bar), and the card's centre.
var star_from: Vector2 = Vector2(540, 1800)
var centre: Vector2 = Vector2(540, 900)
var star_sec: float = 0.45
var star_gap: float = 0.3
## Optional Sfx node: a rising note per star.
var sfx: Node

var _card: Panel
var _sockets: Array[Control] = []
var _flying: Array = []  # [Star, start_t, index] in flight
var _landed: int = 0
var _earned: int = 0
var _t: float = 0.0
var _out_t: float = -1.0
var _toast: Label
var _toast_t: float = 0.0
var _chosen: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var won: bool = summary.get("won", false)
	_earned = clampi(int(summary.get("stars", 1 if won else 0)), 0, 3)
	_card = Panel.new()
	_card.name = "LevelCardPanel"
	_card.add_theme_stylebox_override("panel", Ui.box(CARD_FILL, 44, CARD_EDGE, 5))
	_card.size = Vector2(CARD_W, CARD_H if telemetry != null else CARD_H - 110.0)
	_card.position = centre - _card.size * 0.5
	_card.pivot_offset = _card.size * 0.5
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_card)
	var title := Ui.label("Sector cleared" if won else "Out of time", 66, TEXT_CREAM if won else LOSS)
	title.name = "EndTitle"
	title.add_theme_constant_override("outline_size", 0)
	title.position = Vector2(0, 34)
	title.size = Vector2(CARD_W, 80)
	_card.add_child(title)
	# Three sockets in a gentle arc, the middle one larger and higher.
	var xs := [-(STAR_MID_D * 0.5 + STAR_GAP + STAR_D * 0.5), 0.0, STAR_MID_D * 0.5 + STAR_GAP + STAR_D * 0.5]
	var row := Control.new()
	row.name = "StarsRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(row)
	for i in 3:
		var d := STAR_MID_D if i == 1 else STAR_D
		var s := Star.new()
		s.name = "Star_%d" % i
		s.size = Vector2(d, d)
		s.pivot_offset = s.size * 0.5
		s.position = Vector2(CARD_W * 0.5 + float(xs[i]) - d * 0.5, (205.0 if i == 1 else 225.0) - d * 0.5)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(s)
		_sockets.append(s)
	var stats := Ui.label(_stats_text(won), 38, Color(0.8, 0.84, 0.95))
	stats.name = "ScoreStat"
	stats.add_theme_constant_override("outline_size", 0)
	stats.position = Vector2(0, 318)
	stats.size = Vector2(CARD_W, 50)
	_card.add_child(stats)
	# Buttons: the primary one in the Hint button's orange, the others in the HUD's navy.
	# Won: Next (orange) and Retry, with a quiet Map link under them. Lost: Retry (orange) and Map.
	var y := 392.0
	var first := _pill("NextButton" if won else "RetryButton", "Next" if won else "Retry", Vector2(CARD_W * 0.5 - 300.0, y), Vector2(340, 112), true)
	var second := _pill("RetryButton" if won else "MapButton", "Retry" if won else "Map", Vector2(CARD_W * 0.5 + 60.0, y), Vector2(240, 112), false)
	if won:
		first.pressed.connect(choose.bind("next"))
		second.pressed.connect(choose.bind("retry"))
		var mp := _pill("MapButton", "Map", Vector2(CARD_W * 0.5 - 120.0, y + 118.0), Vector2(240, 64), false, 34)
		for st in ["normal", "hover", "pressed", "hover_pressed"]:
			mp.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			mp.add_theme_color_override(c, Color(0.7, 0.76, 0.9))
		mp.pressed.connect(choose.bind("map"))
	else:
		first.pressed.connect(choose.bind("retry"))
		second.pressed.connect(choose.bind("map"))
	if telemetry != null:
		var ry := _card.size.y - 92.0
		var send := _pill("SendResultsButton", "Send results", Vector2(CARD_W * 0.5 - 330.0, ry), Vector2(310, 66), false, 30)
		send.pressed.connect(func() -> void: telemetry.send_results())
		var copy := _pill("CopyResultsButton", "Copy results", Vector2(CARD_W * 0.5 + 20.0, ry), Vector2(310, 66), false, 30)
		copy.pressed.connect(_on_copy)
		_toast = Ui.label("", 34, Color(0.45, 0.8, 1.0))
		_toast.name = "CopyToast"
		_toast.add_theme_constant_override("outline_size", 0)
		_toast.position = Vector2(0, ry - 46.0)
		_toast.size = Vector2(CARD_W, 40)
		_toast.modulate.a = 0.0
		_card.add_child(_toast)
	if reduced_motion:
		finish_now()
	else:
		_card.modulate.a = 0.0
		_card.scale = Vector2.ONE * 0.9


func _stats_text(won: bool) -> String:
	var left := int(ceil(float(summary.get("time_left", 0.0))))
	var score := int(summary.get("score", 0))
	if won:
		return "Score %d   ·   %d s left" % [score, left]
	return "Words %d / %d   ·   Score %d" % [int(summary.get("words_done", 0)), int(summary.get("words_total", 0)), score]


func _pill(node_name: String, text: String, pos: Vector2, sz: Vector2, primary: bool, font: int = 46) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.position = pos
	b.size = sz
	b.add_theme_font_size_override("font_size", font)
	var r := int(sz.y * 0.5)
	var fill := NEXT_FILL if primary else Color("15214d")
	var rim := NEXT_RIM if primary else Color(0.6, 0.7, 0.95, 0.6)
	var ink := NEXT_INK if primary else TEXT_CREAM
	b.add_theme_stylebox_override("normal", Ui.box(fill, r, rim, 4 if primary else 3))
	b.add_theme_stylebox_override("hover", Ui.box(fill.lightened(0.08), r, rim, 4 if primary else 3))
	b.add_theme_stylebox_override("pressed", Ui.box(fill.lightened(0.2), r, rim, 4 if primary else 3))
	b.add_theme_stylebox_override("hover_pressed", Ui.box(fill.lightened(0.2), r, rim, 4 if primary else 3))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, ink)
	_card.add_child(b)
	return b


## How many stars have landed in their sockets so far.
func stars_shown() -> int:
	return _landed


func stars_earned() -> int:
	return _earned


## Skips the animation: the card in place, every earned star in its socket.
func finish_now() -> void:
	_t = 99.0
	for f in _flying:
		(f[0] as Node).queue_free()
	_flying.clear()
	_card.modulate.a = 1.0
	_card.scale = Vector2.ONE
	for i in 3:
		var s: Star = _sockets[i]
		s.filled = i < _earned
		s.scale = Vector2.ONE
		s.queue_redraw()
	_landed = _earned


## A button: "next", "retry" or "map". Only the first choice counts; the card folds away.
func choose(which: String) -> void:
	if _chosen:
		return
	_chosen = true
	dismiss()
	match which:
		"next":
			next.emit()
		"retry":
			retry.emit()
		"map":
			map.emit()


## Folds the card away and frees it; the flow does not wait for it.
func dismiss() -> void:
	if _out_t >= 0.0:
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for b in _card.find_children("*", "Button", true, false):
		(b as Button).disabled = true
	if reduced_motion:
		queue_free()
		return
	_out_t = 0.0


func _on_copy() -> void:
	telemetry.copy_results()
	_toast.text = "Copied"
	_toast_t = 1.4


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)
	if _out_t >= 0.0:
		_out_t += delta
		var u := clampf(_out_t / OUT_SEC, 0.0, 1.0)
		_card.modulate.a = 1.0 - u
		_card.scale = Vector2.ONE * (1.0 - 0.12 * u)
		_card.position.y = centre.y - _card.size.y * 0.5 - 60.0 * u * u
		if u >= 1.0:
			queue_free()
		return
	if _t >= 99.0:
		return
	_t += delta
	# The card rises in with a soft overshoot.
	var k := clampf(_t / IN_SEC, 0.0, 1.0)
	var w := k - 1.0
	var e := 1.0 + 2.2 * w * w * w + 1.2 * w * w
	_card.modulate.a = clampf(k * 1.6, 0.0, 1.0)
	_card.scale = Vector2.ONE * lerpf(0.9, 1.0, e)
	_card.position.y = centre.y - _card.size.y * 0.5 + 40.0 * (1.0 - e)
	# Stars launch one after another once the card is up.
	var launched := _landed + _flying.size()
	if launched < _earned and _t >= IN_SEC + float(launched) * (star_sec + star_gap) * 0.75:
		_launch(launched)
	for j in range(_flying.size() - 1, -1, -1):
		var f: Array = _flying[j]
		var s: Star = f[0]
		var i: int = f[2]
		var u := clampf((_t - float(f[1])) / maxf(0.01, star_sec), 0.0, 1.0)
		var target := _socket_centre(i)
		var mid := star_from.lerp(target, 0.5) + Vector2(0, -260.0)  # an arc up and over
		var p := star_from.lerp(mid, u).lerp(mid.lerp(target, u), u)
		s.position = p - s.size * 0.5
		s.rotation = TAU * 0.5 * (1.0 - u)
		s.scale = Vector2.ONE * lerpf(0.35, 1.0, u)
		if u >= 1.0:
			s.queue_free()
			_flying.remove_at(j)
			_land(i)
	for i in 3:
		var sk: Star = _sockets[i]
		if sk.pop_t >= 0.0:
			sk.pop_t += delta
			var q := clampf(sk.pop_t / POP_SEC, 0.0, 1.0)
			sk.scale = Vector2.ONE * (1.0 + 0.35 * sin(PI * q))
			sk.glow = 1.0 - q
			sk.queue_redraw()
			if q >= 1.0:
				sk.pop_t = -1.0
	if _landed >= _earned and _flying.is_empty() and k >= 1.0 and _t > IN_SEC + float(_earned) * (star_sec + star_gap) + POP_SEC:
		_t = 99.0


func _socket_centre(i: int) -> Vector2:
	var s: Star = _sockets[i]
	return _card.position + (s.position + s.size * 0.5)


func _launch(i: int) -> void:
	var s := Star.new()
	s.name = "FlyingStar"
	s.filled = true
	var d := (_sockets[i] as Control).size.x
	s.size = Vector2(d, d)
	s.pivot_offset = s.size * 0.5
	s.position = star_from - s.size * 0.5
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(s)
	_flying.append([s, _t, i])


func _land(i: int) -> void:
	var sk: Star = _sockets[i]
	sk.filled = true
	sk.pop_t = 0.0
	sk.queue_redraw()
	_landed += 1
	if sfx != null:
		sfx.call("star", i)
	var p := CPUParticles2D.new()
	p.name = "StarBurst"
	p.position = sk.size * 0.5
	p.one_shot = true
	p.emitting = true
	p.amount = 18
	p.lifetime = 0.55
	p.explosiveness = 1.0
	p.initial_velocity_min = 160.0
	p.initial_velocity_max = 360.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0
	p.color = GOLD_LIGHT
	sk.add_child(p)


## A five-pointed star: an empty socket (the slots' near-black with a teal outline) or gold.
class Star extends Control:
	var filled: bool = false
	var glow: float = 0.0
	var pop_t: float = -1.0

	func _draw() -> void:
		var c := size * 0.5
		var r := size.x * 0.5
		var pts := PackedVector2Array()
		for k in 10:
			var a := -PI * 0.5 + PI * float(k) / 5.0
			var rr := r if k % 2 == 0 else r * 0.47
			pts.append(c + Vector2(cos(a), sin(a)) * rr)
		var outline := pts.duplicate()
		outline.append(pts[0])
		if filled:
			for i in 4:
				draw_circle(c, r * (0.9 + 0.12 * float(i)) * (1.0 + 0.3 * glow), Color(1.0, 0.85, 0.3, 0.07 + 0.08 * glow))
			draw_colored_polygon(pts, GOLD)
			var inner := PackedVector2Array()
			for p in pts:
				inner.append(c + (p - c) * 0.62 + Vector2(0, -r * 0.08))
			draw_colored_polygon(inner, GOLD_LIGHT)
			draw_polyline(outline, Color("9c540c"), maxf(3.0, r * 0.05), true)
		else:
			draw_colored_polygon(pts, SOCKET_FILL)
			draw_polyline(outline, SOCKET_EDGE, maxf(3.0, r * 0.06), true)

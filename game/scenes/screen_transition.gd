extends CanvasLayer
## Screen-to-screen transitions (WP-F.33, reworked in WP-F.34). Before WP-F.33 every menu change was a
## one-frame hard cut.
##
## How it works: main swaps the screens at once (so the game logic and the tests see the new screen
## straight away) but hands the old screen to take_outgoing() instead of freeing it. The old screen
## stops processing and is lifted above the new one (its root goes into a canvas layer here, its own
## canvas layers move up by OUT_LAYER), then play() animates the hand-over:
##   FORWARD  deeper into the menus: the old screen grows a touch and fades; the new screen rises in.
##   BACK     back out: the old screen shrinks a touch and fades; the new one settles from slightly large.
##   PLAY     a menu into the game screen: the old screen zooms toward the player and dissolves.
##   FADE     a story beat (act complete, ending): a slow dissolve, nothing moves.
##   CUT      no transition.
## WP-F.33 took a still of the last frame with get_image(), a GPU-to-CPU read-back that stalled every
## tap by 40-70 ms; keeping the old screen live costs nothing up front. Reduced motion (the setting,
## or the OS asking for less motion) turns every kind into a short plain cross-fade. A blocker
## swallows taps while a change runs, so a double tap cannot fire twice. Headless runs (tests) change
## at once unless `allow_headless` is set. Every number is a `transition.*` tunable.

const GameData := preload("res://rules/game_data.gd")

enum { FORWARD, BACK, PLAY, FADE, CUT }

var reduced_motion: bool = false
var _tun: Dictionary = {}
var _tween: Tween
var _incoming: CanvasItem
var _incoming_pos: Vector2 = Vector2.ZERO
## The kind of the change in progress (-1 when none); tests and evidence read it.
var playing_kind: int = -1
## Tests set this to play changes without a renderer.
var allow_headless: bool = false
var _out: Node
var _out_root: CanvasLayer
var _out_layers: Array[CanvasLayer] = []
var _out_offsets: Array[Vector2] = []
var _out_items: Array = []  # [CanvasItem, its own alpha]
var _blocker: Control
var _view: Vector2 = Vector2.ZERO
## Stretches every duration (?slowtx=<n> on the web with ?tour=1), so evidence frames catch the motion.
var slow: float = 1.0


func _init() -> void:
	layer = 90  # above every screen, the pause menu (40) and the settings over the field (45)
	name = "ScreenTransition"


func _ready() -> void:
	_tun = GameData.load_tunables()


func num(key: String, fallback: float) -> float:
	var v := float(_tun.get("transition." + key, fallback))
	return v * slow if key.ends_with("Sec") else v


## Where the leaving screen's layers go: its own layers move up by this much (sky -3 -> 67, the game
## screen's HUD 10 -> 80); its root is drawn on a layer of exactly this number.
const OUT_LAYER := 70


## True when a change can play now (not headless, unless a test allows it).
func can_play(kind: int) -> bool:
	return kind != CUT and is_inside_tree() and (allow_headless or DisplayServer.get_name() != "headless")


## True while a change is on screen.
func busy() -> bool:
	return _out != null or _blocker != null


## Takes the screen that is leaving: it stops processing and is lifted above the incoming screen until
## the change ends, then freed. Call before adding the incoming screen; then call play().
func take_outgoing(old: Node) -> void:
	finish()
	_out = old
	old.process_mode = Node.PROCESS_MODE_DISABLED
	old.name = str(old.name) + "_Leaving"  # find_child never confuses it with the new screen
	_out_root = CanvasLayer.new()
	_out_root.name = "OutgoingLayer"
	_out_root.layer = OUT_LAYER
	add_child(_out_root)
	_out_layers = [_out_root]
	_out_items.clear()
	for l: Node in old.find_children("*", "CanvasLayer", true, false):
		var cl := l as CanvasLayer
		cl.layer = clampi(OUT_LAYER + cl.layer, 50, 89)
		_out_layers.append(cl)
	old.get_parent().remove_child(old)
	_out_root.add_child(old)
	if old is CanvasItem:
		_out_items.append([old, (old as CanvasItem).modulate.a])
	for cl: CanvasLayer in _out_layers:
		if cl == _out_root:
			continue
		for ch: Node in cl.get_children():
			if ch is CanvasItem:
				_out_items.append([ch, (ch as CanvasItem).modulate.a])
	_out_offsets.clear()
	for cl: CanvasLayer in _out_layers:
		_out_offsets.append(cl.offset)


## Plays a change from the screen given to take_outgoing() to `incoming` (the new screen, already in
## the tree). Returns its length in seconds (0 when nothing plays, and the old screen is freed).
func play(incoming: CanvasItem, kind: int) -> float:
	if _out == null or not can_play(kind):
		finish()
		return 0.0
	_view = get_viewport().get_visible_rect().size
	_blocker = Control.new()
	_blocker.name = "TapBlocker"
	_blocker.size = _view
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_blocker)
	_incoming = incoming
	_incoming_pos = _pos_of(incoming)
	playing_kind = kind
	_tween = create_tween().set_parallel(true)
	var total := 0.0
	if reduced_motion:
		total = num("calmSec", 0.15)
		_tween.tween_method(_out_alpha, 1.0, 0.0, total).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		match kind:
			FORWARD, BACK:
				total = _menu_change(incoming, kind == FORWARD)
			PLAY:
				total = num("playSec", 0.45)
				var z := 1.0 + num("playZoom", 0.14)
				_tween.tween_method(_out_zoom, 1.0, z, total).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
				_tween.tween_method(_out_alpha, 1.0, 0.0, total).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			_:
				total = num("playSec", 0.45)
				_tween.tween_method(_out_alpha, 1.0, 0.0, total).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				incoming.modulate.a = 0.0
				_tween.tween_property(incoming, "modulate:a", 1.0, total).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.chain().tween_callback(finish)
	return total


## A menu change: the old screen leaves first and fast (ease-in), the new one lands a beat later and
## slower (ease-out), so the eye follows the new content rather than a muddy double image.
func _menu_change(incoming: CanvasItem, forward: bool) -> float:
	var out_sec := num("outSec", 0.16)
	var in_sec := num("inSec", 0.3)
	var delay := num("inDelaySec", 0.03)
	var zoom := num("zoom", 0.05)
	var z := 1.0 + zoom if forward else 1.0 - zoom
	_tween.tween_method(_out_zoom, 1.0, z, out_sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_out_alpha, 1.0, 0.0, out_sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	incoming.modulate.a = 0.0
	_tween.tween_property(incoming, "modulate:a", 1.0, in_sec * 0.8).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if incoming is Control:
		var c := incoming as Control
		if forward:
			c.position = _incoming_pos + Vector2(0, num("rise", 36.0))
			_tween.tween_property(c, "position", _incoming_pos, in_sec).set_delay(delay).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		else:
			c.pivot_offset = c.size * 0.5
			var s := 1.0 + zoom * 0.6
			c.scale = Vector2(s, s)
			_tween.tween_property(c, "scale", Vector2.ONE, in_sec).set_delay(delay).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	return maxf(out_sec, delay + in_sec)


## Fades every part of the leaving screen to `k` of its own opacity.
func _out_alpha(k: float) -> void:
	for it: Array in _out_items:
		var ci := it[0] as CanvasItem
		if is_instance_valid(ci):
			ci.modulate.a = float(it[1]) * k


## Scales every layer of the leaving screen about the centre of the view.
func _out_zoom(z: float) -> void:
	for i in _out_layers.size():
		var cl := _out_layers[i]
		if is_instance_valid(cl):
			cl.scale = Vector2(z, z)
			cl.offset = _out_offsets[i] * z + _view * 0.5 * (1.0 - z)


## Ends the change in progress at once: the old screen is freed, the new one sits at rest.
func finish() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if _incoming != null and is_instance_valid(_incoming):
		_incoming.modulate.a = 1.0
		if _incoming is Control:
			(_incoming as Control).scale = Vector2.ONE
			(_incoming as Control).position = _incoming_pos
	_incoming = null
	if _out != null and is_instance_valid(_out):
		_out.queue_free()
	_out = null
	if _out_root != null:
		remove_child(_out_root)
		_out_root.queue_free()
		_out_root = null
	_out_layers.clear()
	_out_items.clear()
	if _blocker != null:
		remove_child(_blocker)
		_blocker.queue_free()
		_blocker = null
	playing_kind = -1


static func _pos_of(n: CanvasItem) -> Vector2:
	if n is Control:
		return (n as Control).position
	if n is Node2D:
		return (n as Node2D).position
	return Vector2.ZERO


## Fades an overlay in (the pause menu, the settings over the game screen): the dim and the card fade
## up while `card` (when given) scales from slightly small with a soft overshoot.
static func overlay_in(host: Node, items: Array, card: Control, calm: bool) -> void:
	var t := GameData.load_tunables()
	var sec := float(t.get("transition.overlaySec", 0.22))
	if calm or DisplayServer.get_name() == "headless" or not host.is_inside_tree():
		return
	var tw := host.create_tween().set_parallel(true)
	for it: CanvasItem in items:
		it.modulate.a = 0.0
		tw.tween_property(it, "modulate:a", 1.0, sec).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if card != null:
		card.pivot_offset = card.size * 0.5
		card.scale = Vector2(0.94, 0.94)
		tw.tween_property(card, "scale", Vector2.ONE, sec * 1.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

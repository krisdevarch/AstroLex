extends CanvasLayer
## Screen-to-screen transitions (WP-F.33). Before this every menu change was a one-frame hard cut.
##
## How it works: main takes a still of the last drawn frame (capture()), swaps the screens at once as
## before (so the game logic and the tests see the new screen straight away), then play() lays the
## still over the new screen and animates the hand-over:
##   FORWARD  deeper into the menus: the still grows a touch and fades; the new screen rises in.
##   BACK     back out: the still shrinks a touch and fades; the new screen settles from slightly large.
##   PLAY     a menu into the game screen: the still zooms toward the player and dissolves.
##   FADE     a story beat (act complete, ending): a slow dissolve, nothing moves.
##   CUT      no transition.
## The menus share the painted sky, so the sky holds still while only the cards and buttons move.
## Reduced motion (the setting, or the OS asking for less motion) turns every kind into a short
## plain cross-fade. The still swallows taps while it is up, so a double tap cannot fire twice.
## Headless runs (tests) get no still and change at once. Every number is a `transition.*` tunable.

const GameData := preload("res://rules/game_data.gd")

enum { FORWARD, BACK, PLAY, FADE, CUT }

var reduced_motion: bool = false
var _tun: Dictionary = {}
var _shot: TextureRect
var _tween: Tween
var _incoming: CanvasItem
var _incoming_pos: Vector2 = Vector2.ZERO
## The kind of the change in progress (-1 when none); tests and evidence read it.
var playing_kind: int = -1


func _init() -> void:
	layer = 90  # above every screen, the pause menu (40) and the settings over the field (45)
	name = "ScreenTransition"


func _ready() -> void:
	_tun = GameData.load_tunables()


func num(key: String, fallback: float) -> float:
	return float(_tun.get("transition." + key, fallback))


## A still of the frame on screen now, or null where the renderer cannot read it back (headless).
func capture() -> Texture2D:
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return null
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)


## True while a change is on screen.
func busy() -> bool:
	return _shot != null


## Plays a change from `still` (the old screen's last frame) to `incoming` (the new screen, already in
## the tree). Returns its length in seconds (0 when nothing plays).
func play(still: Texture2D, incoming: CanvasItem, kind: int) -> float:
	finish()
	if still == null or kind == CUT:
		return 0.0
	var view := get_viewport().get_visible_rect().size
	_shot = TextureRect.new()
	_shot.name = "OutgoingStill"
	_shot.texture = still
	_shot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shot.stretch_mode = TextureRect.STRETCH_SCALE
	_shot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_shot.size = view
	_shot.pivot_offset = view * 0.5
	_shot.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_shot)
	_incoming = incoming
	_incoming_pos = _pos_of(incoming)
	playing_kind = kind
	_tween = create_tween().set_parallel(true)
	var total := 0.0
	if reduced_motion:
		total = num("calmSec", 0.2)
		_tween.tween_property(_shot, "modulate:a", 0.0, total).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		match kind:
			FORWARD, BACK:
				total = _menu_change(incoming, kind == FORWARD)
			PLAY:
				total = num("playSec", 0.55)
				var z := 1.0 + num("playZoom", 0.14)
				_tween.tween_property(_shot, "scale", Vector2(z, z), total).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
				_tween.tween_property(_shot, "modulate:a", 0.0, total).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			_:
				total = num("playSec", 0.55)
				_tween.tween_property(_shot, "modulate:a", 0.0, total).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				incoming.modulate.a = 0.0
				_tween.tween_property(incoming, "modulate:a", 1.0, total).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.chain().tween_callback(finish)
	return total


## A menu change: the still leaves first and fast (ease-in), the new screen lands a beat later and
## slower (ease-out), so the eye follows the new content rather than a muddy double image.
func _menu_change(incoming: CanvasItem, forward: bool) -> float:
	var out_sec := num("outSec", 0.2)
	var in_sec := num("inSec", 0.38)
	var delay := num("inDelaySec", 0.05)
	var zoom := num("zoom", 0.05)
	var z := 1.0 + zoom if forward else 1.0 - zoom
	_tween.tween_property(_shot, "scale", Vector2(z, z), out_sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_shot, "modulate:a", 0.0, out_sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
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


## Ends the change in progress at once: the still goes, the new screen sits at rest.
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
	if _shot != null:
		if _shot.get_parent() == self:
			remove_child(_shot)
		_shot.queue_free()
		_shot = null
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

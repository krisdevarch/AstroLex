extends Node
## Finger and mouse drag scrolling for a ScrollContainer full of buttons (owner report, 17 Oct
## 2026: the level map did not scroll on a phone). Godot's ScrollContainer only drags when the press
## reaches it, and every level badge is a Button that keeps the press, so a swipe that starts on a
## badge never scrolled. This node watches the raw input instead: a press inside the scroll area that
## moves past DEADZONE becomes a drag, the content follows the finger, and on release it glides on
## and slows down. The press on the button under the finger is cancelled when the drag starts, so a
## swipe never opens a level or flips a switch; a short tap still reaches the button as before. The
## wheel scrolls too.

const DEADZONE := 22.0  # px of travel before a press counts as a drag (a tap wobbles less)
const FRICTION := 5.0  # per second: how fast a fling slows down
const MIN_FLING := 40.0  # px/s: below this the glide stops
const WHEEL_STEP := 160.0

var _scroll: ScrollContainer
var _down := false
var _dragging := false
var _start := Vector2.ZERO
var _start_scroll := 0.0
var _pos := 0.0  # the scroll offset as a float, so slow glides do not stall on whole pixels
var _vel := 0.0  # px/s of scroll offset
var _last_y := 0.0
var _last_t := 0
var _press_at := Vector2.ZERO


## Adds drag scrolling to `scroll`; returns the node (tests drive it through its handlers).
static func attach(scroll: ScrollContainer) -> Node:
	var n: Node = (load("res://scenes/drag_scroll.gd") as GDScript).new()
	n.name = "DragScroll"
	scroll.add_child(n)
	return n


func _ready() -> void:
	_scroll = get_parent() as ScrollContainer
	_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE  # this node does the dragging and the wheel


## True while a drag is under way or has just ended (until the next press).
func dragging() -> bool:
	return _dragging


func _input(event: InputEvent) -> void:
	if _scroll == null or not _scroll.is_visible_in_tree():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if mb.pressed and _scroll.get_global_rect().has_point(mb.position):
				_vel = 0.0
				_set_pos(float(_scroll.scroll_vertical) + (WHEEL_STEP if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -WHEEL_STEP) * mb.factor)
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			press(mb.position)
		else:
			release()
	elif event is InputEventMouseMotion and _down:
		if move((event as InputEventMouseMotion).position):
			get_viewport().set_input_as_handled()  # the drag owns the finger; buttons see no motion


func press(at: Vector2) -> void:
	_down = _scroll.get_global_rect().has_point(at)
	_dragging = false
	_vel = 0.0
	_start = at
	_press_at = at
	_start_scroll = float(_scroll.scroll_vertical)
	_pos = _start_scroll
	_last_y = at.y
	_last_t = Time.get_ticks_msec()


## Returns true when the motion is part of a drag.
func move(at: Vector2) -> bool:
	if not _down:
		return false
	var dy := at.y - _start.y
	if not _dragging:
		if absf(dy) < DEADZONE:
			return false
		_dragging = true
		_start.y += DEADZONE * signf(dy)  # no jump when the drag takes over
		_cancel_press(_scroll, _press_at)
		dy = at.y - _start.y
	var now := Time.get_ticks_msec()
	var dt := maxf(float(now - _last_t) / 1000.0, 0.001)
	_vel = lerpf(_vel, -(at.y - _last_y) / dt, 0.6)
	_last_y = at.y
	_last_t = now
	_set_pos(_start_scroll - dy)
	return true


func release() -> void:
	if not _down:
		return
	_down = false
	if not _dragging or Time.get_ticks_msec() - _last_t > 90:  # finger stopped before lifting: no glide
		_vel = 0.0


## The press that started the drag sits on a button: cancel it. Disabling a button drops the press
## it holds (mouse or touch), and enabling it again at once leaves no trace on screen, so the release
## does not count as a tap. Buttons that were already disabled are left alone.
static func _cancel_press(node: Node, at: Vector2) -> void:
	for ch in node.get_children():
		if ch is CanvasItem and not (ch as CanvasItem).is_visible_in_tree():
			continue
		_cancel_press(ch, at)
		if ch is BaseButton and not (ch as BaseButton).disabled and (ch as Control).get_global_rect().has_point(at):
			(ch as BaseButton).disabled = true
			(ch as BaseButton).disabled = false


func _set_pos(v: float) -> void:
	var bar := _scroll.get_v_scroll_bar()
	var top := maxf(0.0, bar.max_value - bar.page) if bar != null else v
	_pos = clampf(v, 0.0, top)
	_scroll.scroll_vertical = int(round(_pos))


func _process(delta: float) -> void:
	if _down:
		return
	if absf(_vel) < MIN_FLING:
		_vel = 0.0
		return
	var before := _pos
	_set_pos(_pos + _vel * delta)
	_vel *= exp(-FRICTION * delta)
	if is_equal_approx(before, _pos):  # hit the top or the bottom
		_vel = 0.0

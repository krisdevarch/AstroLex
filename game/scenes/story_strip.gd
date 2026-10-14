extends Control
## The crew's radio chatter, played on the game screen itself between levels (WP-3.O), instead of
## a separate comms screen. Lines rise one at a time from just above Earth's rim, in bubbles drawn
## like Babel's (navy fill, a pill outline in the speaker's colour) with a small avatar disc; older
## lines drift up and fade. Babel's own lines go to his bubble at the top of the screen
## (`babel_line`). A tap finishes the line being typed, or moves on; Skip ends the chatter.
## The field ticks it (so pause freezes it) and starts Babel's throw when `finished` fires.
## Covers only the play field, so the HUD buttons under it still work.

const Ui := preload("res://scenes/ui.gd")

signal finished
## A line of Babel's: the field shows it in Babel's own bubble.
signal babel_line(text: String)

const SPEAKER_COLORS := {
	"rhee": Color("F8BC04"), "ade": Color("88FFEE"), "kit": Color("FF88CC"),
	"vanta": Color("C9374C"), "tomas": Color("FF6B35"), "babel": Color("7070FF"),
}
const BUBBLE_FILL := Color(0.15, 0.15, 0.3, 0.94)  # Babel's bubble fill
const TEXT_CREAM := Color("efe8d6")
const INSET := 60.0
const PAD := 26.0
const AVATAR_D := 76.0
const NAME_FS := 34
const TEXT_FS := 40
const GAP := 22.0
const BOTTOM_PAD := 80.0  # clear of the launcher ring on Earth's rim
const KEEP := 3  # bubbles on screen at once
const TYPE_CPS := 38.0
const IN_SEC := 0.3
const OUT_SEC := 0.35

## [{who, text}]
var messages: Array = []
var reduced_motion: bool = false
var read_sec: float = 1.6
var cps: float = 22.0
## Optional Sfx node: a soft blip per line.
var sfx: Node

var _i: int = -1
var _line_t: float = 0.0
var _bubbles: Array = []  # [Panel, Label, target_y, age]
var _done: bool = false
var _out_t: float = -1.0
var _skip: Button


static func color_for(who: String) -> Color:
	return SPEAKER_COLORS.get(who, Ui.INK)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_skip = Button.new()
	_skip.name = "SkipButton"
	_skip.text = "Skip  ›"
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.size = Vector2(200, 72)
	_skip.position = Vector2(size.x - INSET - 200.0, 20.0)
	_skip.add_theme_font_size_override("font_size", 34)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		_skip.add_theme_stylebox_override(st, Ui.box(Color(0.13, 0.15, 0.25, 0.86), 36))
	_skip.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		_skip.add_theme_color_override(c, TEXT_CREAM)
	_skip.pressed.connect(skip)
	add_child(_skip)
	if messages.is_empty():
		_finish.call_deferred()
		return
	if reduced_motion:
		for i in messages.size():
			_show(i)
		_snap()
	else:
		_show(0)


## Lines shown so far.
func shown_count() -> int:
	return _i + 1


func is_done() -> bool:
	return _done


## A tap: finish typing the newest line, else the next line, else the end.
func advance() -> void:
	if _done:
		return
	var b: Array = _bubbles.back() if not _bubbles.is_empty() else []
	if not b.is_empty() and (b[1] as Label).visible_ratio < 1.0:
		(b[1] as Label).visible_ratio = 1.0
		_line_t = maxf(_line_t, float((b[1] as Label).text.length()) / TYPE_CPS)
		return
	if _i < messages.size() - 1:
		_show(_i + 1)
	else:
		_finish()


func skip() -> void:
	_finish()


func _process(delta: float) -> void:
	if _out_t >= 0.0:
		tick(delta)  # the fade-out runs on its own; the field ticks the rest


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
		accept_event()


func _line_secs(i: int) -> float:
	var text := str((messages[i] as Dictionary).get("text", ""))
	return read_sec + float(text.length()) / maxf(1.0, cps)


func _show(i: int) -> void:
	_i = i
	_line_t = 0.0
	var m: Dictionary = messages[i]
	var who := str(m.get("who", ""))
	var text := str(m.get("text", ""))
	if sfx != null:
		sfx.call("story_line")
	if who == "babel":
		babel_line.emit(text)
		return
	var w := size.x - 2.0 * INSET
	var text_w := w - 2.0 * PAD - AVATAR_D - 20.0
	var font := ThemeDB.fallback_font
	var th := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, text_w, TEXT_FS).y
	var h := maxf(AVATAR_D + 2.0 * PAD - 8.0, PAD + 44.0 + th + PAD)
	var col := color_for(who)
	var p := Panel.new()
	p.name = "StoryBubble"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", Ui.box(BUBBLE_FILL, 40, col, 5))
	p.size = Vector2(w, h)
	p.pivot_offset = Vector2(0, h)
	p.position = Vector2(INSET, size.y - BOTTOM_PAD - h + (0.0 if reduced_motion else 60.0))
	var av := Avatar.new()
	av.name = "Avatar"
	av.colour = col
	av.initial = who.substr(0, 1).to_upper()
	av.size = Vector2(AVATAR_D, AVATAR_D)
	av.position = Vector2(PAD - 6.0, PAD - 6.0)
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(av)
	var n := Ui.label(who.capitalize(), NAME_FS, col, HORIZONTAL_ALIGNMENT_LEFT)
	n.name = "Speaker"
	n.add_theme_constant_override("outline_size", 0)
	n.position = Vector2(PAD + AVATAR_D + 14.0, PAD - 8.0)
	n.size = Vector2(text_w, 44)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(n)
	var t := Ui.label(text, TEXT_FS, TEXT_CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	t.name = "Text"
	t.add_theme_constant_override("outline_size", 0)
	t.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.position = Vector2(PAD + AVATAR_D + 14.0, PAD + 36.0)
	t.size = Vector2(text_w, th + 8.0)
	t.visible_ratio = 1.0 if reduced_motion else 0.0
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(t)
	p.modulate.a = 1.0 if reduced_motion else 0.0
	add_child(p)
	# Everything already up moves up to make room; the oldest beyond KEEP fade out.
	for b in _bubbles:
		b[2] = float(b[2]) - h - GAP
	_bubbles.append([p, t, size.y - BOTTOM_PAD - h, 0.0])
	move_child(_skip, -1)


func _snap() -> void:
	for b in _bubbles:
		(b[0] as Panel).position.y = float(b[2])
		(b[0] as Panel).modulate.a = 1.0 if float(b[2]) >= 0.0 else 0.0


## Advances typing, the rise of each bubble, the reading timer and the fade-out.
func tick(delta: float) -> void:
	if _out_t >= 0.0:
		_out_t += delta
		modulate.a = clampf(1.0 - _out_t / OUT_SEC, 0.0, 1.0)
		if _out_t >= OUT_SEC:
			queue_free()
		return
	if _done:
		return
	_line_t += delta
	var n := _bubbles.size()
	for k in n:
		var b: Array = _bubbles[k]
		var p: Panel = b[0]
		b[3] = float(b[3]) + delta
		if reduced_motion:
			continue
		p.position.y = lerpf(p.position.y, float(b[2]), 1.0 - exp(-12.0 * delta))
		var fade_old := 1.0 if k >= n - KEEP else 0.0
		var target_a := minf(fade_old, clampf(float(b[3]) / IN_SEC, 0.0, 1.0))
		if p.position.y < 0.0:
			target_a = 0.0
		p.modulate.a = move_toward(p.modulate.a, target_a, delta / IN_SEC)
		var lab: Label = b[1]
		if lab.visible_ratio < 1.0:
			var chars := lab.text.length()
			lab.visible_ratio = clampf(float(b[3]) * TYPE_CPS / maxf(1.0, float(chars)), 0.0, 1.0)
	if _i >= 0 and _line_t >= _line_secs(_i):
		if _i < messages.size() - 1:
			_show(_i + 1)
		else:
			_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	name = "StoryStripFading"  # so the flow (and tests) see the chatter as over while it fades
	_skip.name = "SkipButtonFading"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip.disabled = true
	_skip.visible = false
	finished.emit()
	if reduced_motion or not is_inside_tree():
		queue_free()
	else:
		_out_t = 0.0


## The speaker's disc: their colour with their initial, until the crew have portraits.
class Avatar extends Control:
	var colour: Color = Color.WHITE
	var initial: String = ""

	func _draw() -> void:
		var c := size * 0.5
		var r := size.x * 0.5
		draw_circle(c, r, Color(0.06, 0.08, 0.16))
		draw_circle(c, r - 5.0, colour.darkened(0.15))
		draw_arc(c, r - 2.0, 0.0, TAU, 40, colour, 4.0, true)
		var font := ThemeDB.fallback_font
		var fs := int(r * 1.05)
		var tw := font.get_string_size(initial, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(font, Vector2(c.x - tw.x * 0.5, c.y + fs * 0.36), initial, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.06, 0.08, 0.16))

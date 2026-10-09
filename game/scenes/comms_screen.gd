extends Control
## Radio chatter between levels: speech bubbles appear one at a time (tap or timer).

const Ui := preload("res://scenes/ui.gd")

signal finished

const SPEAKER_COLORS := {
	"rhee": Color("F8BC04"), "ade": Color("88FFEE"), "kit": Color("FF88CC"),
	"vanta": Color("C9374C"), "tomas": Color("FF6B35"), "babel": Color("7070FF"),
}
const BUBBLE_SEC := 1.2

## [{who, text}]
var messages: Array = []
var reduced_motion: bool = false

var _box: VBoxContainer
var _shown: int = 0
var _t: float = 0.0
var _done: bool = false
var _continue: Button


static func color_for(who: String) -> Color:
	return SPEAKER_COLORS.get(who, Ui.INK)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if messages.is_empty():
		_finish.call_deferred()
		return
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_box = VBoxContainer.new()
	_box.name = "Bubbles"
	_box.add_theme_constant_override("separation", 26)
	_box.custom_minimum_size = Vector2(920, 0)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(_box)
	for m: Dictionary in messages:
		var b := _bubble(str(m.get("who", "")), str(m.get("text", "")))
		b.visible = false
		_box.add_child(b)
	_continue = Ui.button("Continue", 52, Vector2(480, 120))
	_continue.name = "ContinueButton"
	_continue.visible = false
	_continue.pressed.connect(_finish)
	_box.add_child(_continue)
	var skip := Ui.button("Skip", 40, Vector2(220, 90))
	skip.name = "SkipButton"
	skip.anchor_left = 1.0
	skip.anchor_right = 1.0
	skip.offset_left = -260.0
	skip.offset_right = -40.0
	skip.offset_top = 50.0
	skip.offset_bottom = 140.0
	skip.pressed.connect(_finish)
	add_child(skip)
	if reduced_motion:
		_reveal(messages.size())
	else:
		_reveal(1)


func _bubble(who: String, text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Bubble"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := Ui.box(Color(0.06, 0.08, 0.16, 0.95), 28, color_for(who), 3)
	sb.set_content_margin_all(26)
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var n := Ui.label(who.capitalize(), 40, color_for(who), HORIZONTAL_ALIGNMENT_LEFT)
	n.name = "Speaker"
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(n)
	var t := Ui.label(text, 44, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	t.name = "Text"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(840, 0)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	return p


func shown_count() -> int:
	return _shown


func _reveal(n: int) -> void:
	_shown = clampi(n, 0, messages.size())
	_t = 0.0
	for i in messages.size():
		_box.get_child(i).visible = i < _shown
	_continue.visible = _shown >= messages.size()


## Next bubble, or finish when all are visible.
func advance() -> void:
	if _done or _box == null:
		return
	if _shown < messages.size():
		_reveal(_shown + 1)
	else:
		_finish()


func _process(delta: float) -> void:
	if _done or _box == null or _shown >= messages.size():
		return
	_t += delta
	if _t >= BUBBLE_SEC:
		_reveal(_shown + 1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()

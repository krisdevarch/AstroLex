extends Control
## First-play coach (WP-3.Q): a soft pulsing ring that points at a screen position, with a short
## caption pill beside it. Lives on the field's HUD layer and ignores the mouse. The field decides
## what to point at and when; this node only draws. Reduced motion: no pulse, a static ring.

const CREAM := Color("efe8d6")
const TEAL := Color("3cbfd2")
const PILL_FILL := Color(0.09, 0.12, 0.2, 0.95)
const PILL_EDGE := Color("2f3b58")
const EDGE_PAD := 24.0

var reduced_motion: bool = false
var ring_visible: bool = false
var target: Vector2 = Vector2.ZERO
var ring_px: float = 130.0
var ring_width: float = 8.0
var pulse_sec: float = 1.2
var pulse_amount: float = 0.14
var gap_px: float = 26.0
var _age: float = 0.0
var _pill: PanelContainer
var _label: Label


func setup(tun: Dictionary, reduced: bool, view: Vector2) -> void:
	reduced_motion = reduced
	ring_px = float(tun["coach.ringPx"])
	ring_width = float(tun["coach.ringWidthPx"])
	pulse_sec = float(tun["coach.pulseSec"])
	pulse_amount = float(tun["coach.pulseAmount"])
	gap_px = float(tun["coach.captionGapPx"])
	name = "Coach"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = view
	visible = false
	_pill = PanelContainer.new()
	_pill.name = "CoachPill"
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = PILL_FILL
	box.border_color = PILL_EDGE
	box.set_border_width_all(3)
	box.set_corner_radius_all(36)
	box.content_margin_left = 34.0
	box.content_margin_right = 34.0
	box.content_margin_top = 14.0
	box.content_margin_bottom = 14.0
	_pill.add_theme_stylebox_override("panel", box)
	_label = Label.new()
	_label.name = "CoachText"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", int(tun["coach.captionPx"]))
	_label.add_theme_color_override("font_color", CREAM)
	_pill.add_child(_label)
	add_child(_pill)


## Points the ring at `at` (screen px) with `text` beside it; `ring` false shows the caption alone,
## centred on `at`. Cheap to call every frame to follow a moving target.
func show_at(at: Vector2, text: String, ring: bool = true) -> void:
	target = at
	ring_visible = ring
	_label.text = text
	visible = true
	var s := _pill.get_combined_minimum_size()
	_pill.size = s
	var gap := ring_px + gap_px if ring else 0.0
	var y := at.y - gap - s.y if ring else at.y - s.y * 0.5
	if ring and y < EDGE_PAD + 120.0:
		y = at.y + gap  # no room above: below the ring
	var x := clampf(at.x - s.x * 0.5, EDGE_PAD, maxf(size.x - s.x - EDGE_PAD, EDGE_PAD))
	_pill.position = Vector2(x, clampf(y, EDGE_PAD, maxf(size.y - s.y - EDGE_PAD, EDGE_PAD)))
	queue_redraw()


func clear() -> void:
	visible = false
	ring_visible = false


func caption() -> String:
	return _label.text if visible else ""


## 1.0 when static; swings by pulse_amount when animated.
func pulse_scale() -> float:
	if reduced_motion or pulse_sec <= 0.0:
		return 1.0
	return 1.0 + pulse_amount * sin(_age / pulse_sec * TAU)


func _process(delta: float) -> void:
	if not visible or not ring_visible:
		return
	if not reduced_motion:
		_age += delta
	queue_redraw()


func _draw() -> void:
	if not visible or not ring_visible:
		return
	var r := ring_px * pulse_scale()
	var glow := 0.5 if reduced_motion else 0.35 + 0.25 * (0.5 + 0.5 * sin(_age / maxf(pulse_sec, 0.01) * TAU))
	for i in 4:
		var k := float(i)
		draw_arc(target, r + k * 7.0, 0.0, TAU, 64, Color(TEAL, glow * (1.0 - k * 0.22) * 0.5), ring_width + k * 8.0, true)
	draw_arc(target, r, 0.0, TAU, 64, CREAM, ring_width, true)

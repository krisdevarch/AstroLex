extends Node2D
## Babel on the field (WP-3.P): flies in from off-screen top right, perches, says a line in a speech
## bubble beside him, recoils and flashes at each shot, then flies back out. Always: hover bob,
## breathing, a slight tilt and a cape sway (shader). Reduced motion: no flight, bob or sway; he
## fades in and out. The view sits at the origin of its canvas layer, so its local space is screen space.

const SWAY_SHADER: Shader = preload("res://shaders/babel_sway.gdshader")
const TEX: Texture2D = preload("res://art/babel/babel.png")
const MUZZLE_UV := Vector2(0.93, 0.32)  # the gun's muzzle as a share of the image
const BUBBLE_FILL := Color(0.15, 0.15, 0.3, 0.94)
const PERIWINKLE := Color("7579f0")
const CREAM := Color(0.96, 0.93, 0.85)
const BUBBLE_FONT := 40
const BUBBLE_MAX_W := 600.0
const BUBBLE_PAD := 30.0
const BUBBLE_GAP := 18.0
const ENTER_OVERSHOOT := 0.9
const LEAN_RAD := 0.32
const RECOIL_SEC := 0.2
const FLASH_SEC := 0.1
const PUFF_EVERY := 0.035
const PUFF_LIFE := 0.55

var cps: float = 38.0  # bubble typing speed, characters per second (the caller sets field.gd's TYPE_CPS)
var reduced_motion: bool = false
var state: String = "off"  # "off", "enter", "perch", "exit"

var _view := Vector2(1080, 1920)
var _perch := Vector2.ZERO
var _off := Vector2.ZERO
var _enter_sec := 0.7
var _exit_sec := 0.6
var _bob_px := 10.0
var _recoil_px := 26.0
var _k := 1.0  # sprite scale
var _t := 0.0  # state time
var _clock := 0.0
var _recoil := Vector2.ZERO
var _recoil_t := 0.0
var _flash_t := 0.0
var _puff_acc := 0.0
var _puffs: Array = []  # [position, age]
var _typed_t := 0.0
var _talking := false

var _rig: Node2D
var _body: Node2D
var _sprite: Sprite2D
var _flash: Node2D
var _puff_node: Node2D
var _bubble: Panel
var _bubble_label: Label
var _tail: Polygon2D


func setup(view_size: Vector2, tun: Dictionary, p_reduced: bool) -> void:
	_view = view_size
	reduced_motion = p_reduced
	var h := float(tun["babel.heightShare"]) * view_size.x
	_k = h / float(TEX.get_height())
	_perch = Vector2(float(tun["babel.perchX"]) * view_size.x, float(tun["babel.perchY"]) * view_size.x)
	var w := TEX.get_width() * _k
	_off = Vector2(view_size.x + w * 0.8, -h * 0.8)
	_enter_sec = maxf(0.01, float(tun["babel.enterSec"]))
	_exit_sec = maxf(0.01, float(tun["babel.exitSec"]))
	_bob_px = float(tun["babel.bobPx"])
	_recoil_px = float(tun["babel.recoilPx"])

	_puff_node = Puffs.new()
	_puff_node.name = "JetPuffs"
	add_child(_puff_node)
	_rig = Node2D.new()
	_rig.name = "Rig"
	add_child(_rig)
	_body = Node2D.new()
	_body.name = "Body"
	_rig.add_child(_body)
	_sprite = Sprite2D.new()
	_sprite.name = "BabelSprite"
	_sprite.texture = TEX
	_sprite.scale = Vector2(_k, _k)
	if not reduced_motion:
		var mat := ShaderMaterial.new()
		mat.shader = SWAY_SHADER
		mat.set_shader_parameter("amp", float(tun["babel.swayAmp"]))
		_sprite.material = mat
	_body.add_child(_sprite)
	_flash = Flash.new()
	_flash.name = "MuzzleFlash"
	_flash.position = Vector2((MUZZLE_UV.x - 0.5) * TEX.get_width(), (MUZZLE_UV.y - 0.5) * TEX.get_height())
	_flash.visible = false
	_sprite.add_child(_flash)
	_build_bubble()
	visible = false


func _build_bubble() -> void:
	_bubble = Panel.new()
	_bubble.name = "Bubble"
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_theme_stylebox_override("panel", _box(BUBBLE_FILL, 34, PERIWINKLE, 6))
	_bubble.visible = false
	add_child(_bubble)
	_bubble_label = Label.new()
	_bubble_label.name = "BubbleText"
	_bubble_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble_label.add_theme_font_size_override("font_size", BUBBLE_FONT)
	_bubble_label.add_theme_color_override("font_color", CREAM)
	_bubble_label.add_theme_constant_override("outline_size", 0)
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_bubble_label.position = Vector2(BUBBLE_PAD, BUBBLE_PAD * 0.6)
	_bubble.add_child(_bubble_label)
	_tail = Polygon2D.new()
	_tail.name = "BubbleTail"
	_tail.color = PERIWINKLE
	_bubble.add_child(_tail)


static func _box(bg: Color, radius: int, border: Color, border_w: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(border_w)
	return s


## Screen position of the gun's muzzle right now (follows flight, bob, tilt and recoil).
func muzzle_position() -> Vector2:
	return _sprite.global_transform * _flash.position


func perch_position() -> Vector2:
	return _perch


## Where Babel's centre is now.
func body_position() -> Vector2:
	return _rig.position


func fly_in() -> void:
	state = "enter"
	_t = 0.0
	visible = true
	_apply_pose()


func fly_out() -> void:
	if state == "off" or state == "exit":
		return
	state = "exit"
	_t = 0.0
	_talking = false
	_bubble.visible = false


## Stops everything at once: Babel is gone and the bubble closed.
func hide_now() -> void:
	state = "off"
	visible = false
	_talking = false
	_bubble.visible = false
	_flash.visible = false
	_flash_t = 0.0
	_recoil_t = 0.0
	_recoil = Vector2.ZERO
	_puff_acc = 0.0
	_puffs.clear()
	_puff_node.queue_redraw()


func is_talking() -> bool:
	return _talking


func quote_text() -> String:
	return _bubble_label.text


## Opens the bubble to Babel's left and types the line in.
func say(text: String) -> void:
	var font := _bubble_label.get_theme_font("font")
	var w := minf(BUBBLE_MAX_W, _perch.x - TEX.get_width() * _k * 0.5 - BUBBLE_GAP - 40.0)
	var tw := w - 2.0 * BUBBLE_PAD
	# Width first, then the text: an autowrapped label sized after its text grows to one word per
	# line, and the line then sat far below the bubble.
	_bubble_label.custom_minimum_size = Vector2(tw, 0.0)
	_bubble_label.size = Vector2(tw, 0.0)
	_bubble_label.text = text
	var sz := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, tw, BUBBLE_FONT, -1, TextServer.BREAK_WORD_BOUND | TextServer.BREAK_MANDATORY)
	var h := sz.y + BUBBLE_PAD * 1.2
	_bubble_label.size = Vector2(tw, sz.y)
	_bubble.size = Vector2(w, h)
	var right := _perch.x - TEX.get_width() * _k * 0.5 - BUBBLE_GAP
	var cy := _perch.y - TEX.get_height() * _k * 0.12
	_bubble.position = Vector2(right - w, cy - h * 0.5)
	# The tail points right, at Babel.
	var m := h * 0.5
	_tail.polygon = PackedVector2Array([Vector2(w - 8, m - 20), Vector2(w + BUBBLE_GAP + 12, m + 8), Vector2(w - 8, m + 24)])
	_bubble_label.visible_characters = 0
	_typed_t = 0.0
	_talking = true
	_bubble.modulate.a = 0.0
	_bubble.visible = true


## Seconds the bubble needs to type the whole line.
func typing_sec(text: String) -> float:
	return float(text.length()) / maxf(cps, 1.0)


func close_bubble() -> void:
	_talking = false
	_bubble.visible = false


## One shot at `target` (screen px): a kick away from it and a short muzzle flash.
func shoot(target: Vector2) -> void:
	var dir := (target - muzzle_position()).normalized()
	if not reduced_motion:
		_recoil = -dir * _recoil_px
		_recoil_t = RECOIL_SEC
	_flash_t = FLASH_SEC
	_flash.visible = true
	_flash.set("u", 0.0)
	_flash.queue_redraw()


func tick(delta: float) -> void:
	if state == "off":
		return
	_clock += delta
	_t += delta
	if state == "enter" and _t >= _enter_sec:
		state = "perch"
	elif state == "exit" and _t >= _exit_sec:
		hide_now()
		return
	if _talking:
		_typed_t += delta
		_bubble_label.visible_characters = int(_typed_t * cps) + 1
		_bubble.modulate.a = clampf(_typed_t / 0.12, 0.0, 1.0)
	if _recoil_t > 0.0:
		_recoil_t = maxf(0.0, _recoil_t - delta)
	if _flash_t > 0.0:
		_flash_t = maxf(0.0, _flash_t - delta)
		_flash.set("u", 1.0 - _flash_t / FLASH_SEC)
		_flash.queue_redraw()
		if _flash_t <= 0.0:
			_flash.visible = false
	_apply_pose()
	_tick_puffs(delta)


func _apply_pose() -> void:
	var u := 1.0
	var flying := false
	var pos := _perch
	var lean := 0.0
	var alpha := 1.0
	if state == "enter":
		u = clampf(_t / _enter_sec, 0.0, 1.0)
		if reduced_motion:
			alpha = u
		else:
			var w := u - 1.0
			var e := 1.0 + (ENTER_OVERSHOOT + 1.0) * w * w * w + ENTER_OVERSHOOT * w * w  # back ease-out
			pos = _off.lerp(_perch, e)
			lean = LEAN_RAD * (1.0 - u)
			flying = u < 1.0
	elif state == "exit":
		u = clampf(_t / _exit_sec, 0.0, 1.0)
		if reduced_motion:
			alpha = 1.0 - u
		else:
			pos = _perch.lerp(_off, u * u)
			lean = LEAN_RAD * u
			flying = true
	_rig.position = pos
	modulate.a = alpha
	var bob := Vector2.ZERO
	var breathe := 1.0
	var tilt := 0.0
	if not reduced_motion:
		bob = Vector2(0.0, sin(_clock * 1.9) * _bob_px)
		breathe = 1.0 + 0.018 * sin(_clock * 1.3)
		tilt = 0.035 * sin(_clock * 0.9 + 1.0)
	var kick := _recoil * pow(_recoil_t / RECOIL_SEC, 2.0) if _recoil_t > 0.0 else Vector2.ZERO
	_body.position = bob + kick
	_body.rotation = tilt - lean + (kick.y * 0.0006 if kick != Vector2.ZERO else 0.0)
	_body.scale = Vector2(1.0 / breathe, breathe)
	_puff_emit = flying and not reduced_motion


var _puff_emit := false


func _tick_puffs(delta: float) -> void:
	for p in _puffs:
		p[1] += delta
	while not _puffs.is_empty() and float(_puffs[0][1]) > PUFF_LIFE:
		_puffs.pop_front()
	if _puff_emit:
		_puff_acc += delta
		while _puff_acc >= PUFF_EVERY:
			_puff_acc -= PUFF_EVERY
			# From his back (left side, below the middle of the sprite).
			var back := _sprite.global_transform * Vector2(-0.32 * TEX.get_width(), 0.18 * TEX.get_height())
			_puffs.append([back + Vector2(randf_range(-6, 6), randf_range(-6, 6)), 0.0])
	_puff_node.set("puffs", _puffs)
	_puff_node.queue_redraw()


class Flash extends Node2D:
	var u: float = 0.0

	func _draw() -> void:
		var r := 46.0 * (0.5 + u * 0.8)
		var a := 1.0 - u
		draw_circle(Vector2.ZERO, r * 1.6, Color(0.44, 0.47, 0.94, 0.28 * a))
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.85, 0.35, 0.85 * a))
		draw_circle(Vector2.ZERO, r * 0.5, Color(1.0, 1.0, 0.9, a))


class Puffs extends Node2D:
	var puffs: Array = []

	func _draw() -> void:
		for p in puffs:
			var k: float = float(p[1]) / 0.55
			draw_circle(p[0], 8.0 + 20.0 * k, Color(0.7, 0.75, 1.0, 0.45 * (1.0 - k)))

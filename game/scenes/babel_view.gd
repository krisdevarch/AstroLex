extends Node2D
## Babel on the field (WP-F.18): he lives in a round porthole in the top-left corner, clipped to his
## head and gun (he faces right, the gun in his right hand), with a gentle bob and breathing. His
## line sits in a speech bubble to the right of the porthole, typing in; every shot recoils (the
## porthole gives a little) and flashes at the muzzle. At the start of a level he pops in; there is
## no flight. Reduced motion: no bob, breathing or recoil; he fades in and out. The view sits at
## the origin of its canvas layer, so its local space is screen space.

const MASK_SHADER: Shader = preload("res://shaders/babel_porthole.gdshader")
const TEX: Texture2D = preload("res://art/babel/babel.png")
## The part of the picture the porthole shows: his head and the gun, a square so the circle fits.
const CROP := Rect2(12.0, 0.0, 450.0, 450.0)
const MUZZLE_PX := Vector2(430.0, 175.0)  # the gun's muzzle in the picture
const BUBBLE_FILL := Color(0.15, 0.15, 0.3, 0.94)
const PERIWINKLE := Color("7579f0")
const CREAM := Color(0.96, 0.93, 0.85)
const BUBBLE_FONT := 40
const BUBBLE_MAX_W := 700.0
const BUBBLE_PAD := 30.0
const BUBBLE_GAP := 30.0  # between the ring and the bubble (the tail spans it)
const BUBBLE_TOP_MIN := 150.0  # keeps the bubble under the top HUD pills
const POP_FROM := 0.4
const POP_OVERSHOOT := 0.9
const RECOIL_SEC := 0.2
const FLASH_SEC := 0.1
const NAME_FONT := 30

var cps: float = 38.0  # bubble typing speed, characters per second (the caller sets field.gd's TYPE_CPS)
var reduced_motion: bool = false
var state: String = "off"  # "off", "enter", "perch", "exit"

var _view := Vector2(1080, 1920)
var _corner := Vector2.ZERO  # the porthole's centre
var _radius := 108.0
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
var _typed_t := 0.0
var _talking := false
var _hold := 0.0  # seconds the bubble stays after it has typed the line; 0 keeps it open

var _rig: Node2D
var _sprite: Sprite2D
var _flash: Node2D
var _bubble: Panel
var _bubble_label: Label
var _tail: Polygon2D


func setup(view_size: Vector2, tun: Dictionary, p_reduced: bool) -> void:
	_view = view_size
	reduced_motion = p_reduced
	_corner = Vector2(float(tun["babel.cornerX"]) * view_size.x, float(tun["babel.cornerY"]) * view_size.y)
	_radius = float(tun["babel.cornerSize"]) * view_size.x * 0.5
	_k = _radius * 2.0 / CROP.size.x
	_enter_sec = maxf(0.01, float(tun["babel.enterSec"]))
	_exit_sec = maxf(0.01, float(tun["babel.exitSec"]))
	_bob_px = float(tun["babel.bobPx"])
	_recoil_px = float(tun["babel.recoilPx"])

	_rig = Node2D.new()
	_rig.name = "Rig"
	_rig.position = _corner
	add_child(_rig)
	var disc := Disc.new()
	disc.name = "Disc"
	disc.radius = _radius
	_rig.add_child(disc)
	_sprite = Sprite2D.new()
	_sprite.name = "BabelSprite"
	_sprite.texture = TEX
	_sprite.region_enabled = true
	_sprite.region_rect = CROP
	_sprite.scale = Vector2(_k, _k)
	var mat := ShaderMaterial.new()
	mat.shader = MASK_SHADER
	mat.set_shader_parameter("radius", _radius / _k)
	_sprite.material = mat
	_rig.add_child(_sprite)
	_flash = Flash.new()
	_flash.name = "MuzzleFlash"
	_flash.position = MUZZLE_PX - CROP.position - CROP.size * 0.5
	_flash.visible = false
	_sprite.add_child(_flash)
	var ring := Ring.new()
	ring.name = "Ring"
	ring.radius = _radius
	_rig.add_child(ring)
	var pill := Panel.new()
	pill.name = "NamePill"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_theme_stylebox_override("panel", _box(Color(0.1, 0.1, 0.26, 0.96), 24, PERIWINKLE, 4))
	pill.size = Vector2(150.0, 48.0)
	pill.position = Vector2(-75.0, _radius - 14.0)
	_rig.add_child(pill)
	var nm := Label.new()
	nm.name = "NameText"
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm.text = "Babel"
	nm.add_theme_font_size_override("font_size", NAME_FONT)
	nm.add_theme_color_override("font_color", CREAM)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.size = pill.size
	pill.add_child(nm)
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


## Screen position of the gun's muzzle right now (follows bob, breathing and recoil).
func muzzle_position() -> Vector2:
	return _sprite.global_transform * _flash.position


## The porthole's centre and radius at rest.
func corner_position() -> Vector2:
	return _corner


func corner_radius() -> float:
	return _radius


## Where Babel's porthole is now.
func body_position() -> Vector2:
	return _rig.position


## Pops the porthole in (reduced motion: fades in).
func fly_in() -> void:
	state = "enter"
	_t = 0.0
	visible = true
	_apply_pose()


## Pops the porthole out (reduced motion: fades out); used when the level is over.
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


func is_talking() -> bool:
	return _talking


func quote_text() -> String:
	return _bubble_label.text


func bubble_rect() -> Rect2:
	return Rect2(_bubble.position, _bubble.size)


func bubble_visible() -> bool:
	return _bubble.visible


## Opens the bubble to the right of the porthole, its tail pointing at him, and types the line in.
## `hold` > 0 closes it that many seconds after the line has been typed.
func say(text: String, hold: float = 0.0) -> void:
	var font := _bubble_label.get_theme_font("font")
	var left := _corner.x + _radius + BUBBLE_GAP
	var w := minf(BUBBLE_MAX_W, _view.x - left - 40.0)
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
	var top := maxf(BUBBLE_TOP_MIN, _corner.y - h * 0.5)
	_bubble.position = Vector2(left, top)
	# The tail points left at the porthole.
	var ty := clampf(_corner.y - top, 34.0, maxf(34.0, h - 34.0))
	_tail.polygon = PackedVector2Array([Vector2(8, ty - 22), Vector2(-BUBBLE_GAP + 6.0, ty), Vector2(8, ty + 22)])
	_bubble_label.visible_characters = 0
	_typed_t = 0.0
	_hold = hold
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
		var typed := int(_typed_t * cps) + 1
		_bubble_label.visible_characters = typed
		_bubble.modulate.a = clampf(_typed_t / 0.12, 0.0, 1.0)
		if _hold > 0.0 and typed >= _bubble_label.text.length() and _typed_t - typing_sec(_bubble_label.text) >= _hold:
			close_bubble()
	if _recoil_t > 0.0:
		_recoil_t = maxf(0.0, _recoil_t - delta)
	if _flash_t > 0.0:
		_flash_t = maxf(0.0, _flash_t - delta)
		_flash.set("u", 1.0 - _flash_t / FLASH_SEC)
		_flash.queue_redraw()
		if _flash_t <= 0.0:
			_flash.visible = false
	_apply_pose()


func _apply_pose() -> void:
	var pop := 1.0
	var alpha := 1.0
	if state == "enter":
		var u := clampf(_t / _enter_sec, 0.0, 1.0)
		if reduced_motion:
			alpha = u
		else:
			var w := u - 1.0
			var e := 1.0 + (POP_OVERSHOOT + 1.0) * w * w * w + POP_OVERSHOOT * w * w  # back ease-out
			pop = lerpf(POP_FROM, 1.0, e)
			alpha = clampf(u * 3.0, 0.0, 1.0)
	elif state == "exit":
		var u := clampf(_t / _exit_sec, 0.0, 1.0)
		if reduced_motion:
			alpha = 1.0 - u
		else:
			pop = lerpf(1.0, POP_FROM, u * u)
			alpha = 1.0 - u
	modulate.a = alpha
	var bob := Vector2.ZERO
	var breathe := 1.0
	if not reduced_motion:
		bob = Vector2(0.0, sin(_clock * 1.9) * _bob_px * 0.5)
		breathe = 1.0 + 0.018 * sin(_clock * 1.3)
	# The recoil kicks the whole porthole (the picture is clipped to it, so it cannot move alone).
	var kick := _recoil * pow(_recoil_t / RECOIL_SEC, 2.0) if _recoil_t > 0.0 else Vector2.ZERO
	_rig.position = _corner + bob + kick * 0.5
	_rig.scale = Vector2.ONE * pop
	_sprite.scale = Vector2(_k, _k) * breathe


class Disc extends Node2D:
	var radius: float = 100.0

	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius * 1.18, Color(0.46, 0.47, 0.94, 0.14))
		draw_circle(Vector2.ZERO, radius, Color(0.07, 0.07, 0.2))
		draw_circle(Vector2(-radius * 0.2, -radius * 0.25), radius * 0.7, Color(0.16, 0.15, 0.42, 0.7))


class Ring extends Node2D:
	var radius: float = 100.0

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius - 5.0, 0.0, TAU, 72, Color("7579f0"), 10.0, true)
		draw_arc(Vector2.ZERO, radius + 9.0, 0.0, TAU, 72, Color(0.46, 0.47, 0.94, 0.45), 3.0, true)


class Flash extends Node2D:
	var u: float = 0.0

	func _draw() -> void:
		var r := 46.0 * (0.5 + u * 0.8)
		var a := 1.0 - u
		draw_circle(Vector2.ZERO, r * 1.6, Color(0.44, 0.47, 0.94, 0.28 * a))
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.85, 0.35, 0.85 * a))
		draw_circle(Vector2.ZERO, r * 0.5, Color(1.0, 1.0, 0.9, a))

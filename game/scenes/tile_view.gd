extends Node2D
## One 2.5D letter tile (plan 8.2), in one of the two glass looks (O-22): "glass" (a clear rounded
## square that tilts) or "bubble" (a clear ball that wobbles). A glyph that always faces the player
## and a faint drop shadow. Plane depth is scale only. The opaque looks (flat, tilt, bevel) were
## dropped on 9 Oct 2026: the owner found them too much like every other word game.

const TileTextures := preload("res://scenes/tile_textures.gd")
const GameFont := preload("res://scenes/game_font.gd")
const GLASS_SHADER: Shader = preload("res://shaders/glass.gdshader")
## The ambient CanvasModulate dims anything it tints; glass is off the lamp, so undo it.
const GLASS_GAIN := Vector3(1.55, 1.52, 1.28)
const GLASS_ACCENT := Color(0.35, 0.85, 1.0)
const LOOKS: Array[String] = ["glass", "bubble"]
const DEFAULT_LOOK := "bubble"
## Babel's hazards (WP-F.1): forgeries shimmer periwinkle, trap letters wear a faint periwinkle ring,
## and while the colour channel is jammed decoys pulse the Catcher's cyan and needed letters periwinkle.
const HAZARD_PERIWINKLE := Color("7579f0")
const SHIMMER_ARC := 1.1  # radians of the sweeping glint
const SHIMMER_RIM_ALPHA := 0.16  # the faint rim a forgery always has
const TRAP_RING_ALPHA := 0.32
const JAM_PULSE_HZ := 1.6

@onready var shadow: Sprite2D = $Shadow
@onready var body: Sprite2D = $Body
@onready var glyph: Label = $Glyph

var ch: String = ""
var plane: int = 0
var is_back: bool = false
var is_item: bool = false
var item: String = ""
var treatment: String = DEFAULT_LOOK
var reduced_motion: bool = false
var size_px: float = 100.0
var anim: String = ""  # "", "fly", "dissolve" or "scatter"
var current_tilt: Vector2 = Vector2.ZERO
## "", "counterfeit" or "trap" (the rules' Tile.kind) and the jam colour: 0 off, 1 cyan (a decoy), 2 periwinkle (needed).
var kind: String = ""
var jam_colour: int = 0
var _ring: HazardRing

var _tun: Dictionary = {}
var _phase: float = 0.0
var _mat: ShaderMaterial
var _flash_t: float = 0.0
var _flash_dur: float = 0.4
var _glow: HintGlow
var _glow_t: float = 0.0
var _glow_dur: float = 1.0
var _anim_t: float = 0.0
var _anim_dur: float = 1.0
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _to_scale: float = 1.0
var _body_scale: Vector2 = Vector2.ONE
## Motion feel: the last placement, the smoothed screen velocity and the bounce squash.
var _last_pos: Vector2 = Vector2.INF
var _last_time: float = 0.0
var _vel_px: Vector2 = Vector2.ZERO
var _squash_t: float = 0.0
var _squash_axis: Vector2 = Vector2.ZERO
const SQUASH_DUR := 0.28  # seconds a bounce squash takes to spring back
const GROW_FROM := 0.35  # a letter made mid-play starts at this share of its size
const GROW_OVERSHOOT := 1.0
## Grow-in for letters made mid-play (WP-3.P): node scale and alpha only.
var _grow_t: float = 0.0
var _grow_dur: float = 0.0
var _grow_alpha: float = 1.0  # the alpha it grows to


func setup(p_ch: String, p_size_px: float, plane_scale: float, p_plane: int, p_treatment: String, p_reduced: bool, tun: Dictionary, p_phase: float) -> void:
	ch = p_ch
	size_px = p_size_px
	plane = p_plane
	treatment = p_treatment if LOOKS.has(p_treatment) else DEFAULT_LOOK
	reduced_motion = p_reduced
	_tun = tun
	_phase = p_phase
	var k := size_px / float(TileTextures.SIZE)
	if treatment == "bubble":
		k *= float(tun["glass.bubbleScale"])  # bigger ball, same letter size
	body.scale = Vector2(k, k)
	_body_scale = body.scale
	_mat = ShaderMaterial.new()
	_mat.shader = GLASS_SHADER
	var round_shape := treatment == "bubble"
	body.texture = TileTextures.glass_mask(TileTextures.HALF if round_shape else TileTextures.GLASS_CORNER)
	_mat.set_shader_parameter("corner", TileTextures.HALF if round_shape else TileTextures.GLASS_CORNER)
	_mat.set_shader_parameter("lens_width", TileTextures.HALF * 0.75 if round_shape else 26.0)
	_mat.set_shader_parameter("bubble", round_shape)
	_mat.set_shader_parameter("unlit_gain", GLASS_GAIN)
	_mat.set_shader_parameter("accent", GLASS_ACCENT)
	_mat.set_shader_parameter("blur", float(_tun["glass.blur"]))
	_mat.set_shader_parameter("refract_px", float(_tun["glass.refractPx"]))
	_mat.set_shader_parameter("frost", float(_tun["glass.frost"]))
	_mat.set_shader_parameter("specular", float(_tun["glass.specular"]))
	_mat.set_shader_parameter("edge_tint", float(_tun["glass.edgeTint"]))
	_mat.set_shader_parameter("chroma", float(_tun["glass.chroma"]))
	_mat.set_shader_parameter("grain", float(_tun["glass.grain"]))
	_mat.set_shader_parameter("sky_tex", TileTextures.sky())
	_mat.set_shader_parameter("stars_tex", TileTextures.stars())
	_mat.set_shader_parameter("milk", float(_tun["glass.milk"]))
	_mat.set_shader_parameter("live", float(_tun.get("glass.live", 0)) > 0.5)
	_mat.set_shader_parameter("magnify", float(_tun.get("glass.magnify", 0.0)))
	_mat.set_shader_parameter("rim_bend", float(_tun.get("glass.rimBend", 0.0)))
	_mat.set_shader_parameter("dark", float(_tun.get("glass.dark", 0.0)))
	_mat.set_shader_parameter("film", float(_tun.get("glass.film", 0.1)))
	_mat.set_shader_parameter("gloss", float(_tun.get("glass.gloss", 0.0)))
	shadow.modulate.a = 0.45  # clear glass casts a faint shadow
	_mat.set_shader_parameter("max_tilt_deg", maxf(1.0, float(_tun["tile.maxTiltDeg"])))
	body.light_mask = 2
	body.material = _mat
	shadow.texture = TileTextures.shadow(_shadow_corner())
	shadow.scale = body.scale
	shadow.position = Vector2(0.4, 1.0) * float(_tun["tile.shadowOffset"]) * plane_scale
	shadow.light_mask = 2
	glyph.light_mask = 2
	glyph.text = ch.to_upper()
	glyph.size = Vector2(size_px, size_px)
	glyph.position = -glyph.size * 0.5
	glyph.pivot_offset = glyph.size * 0.5
	glyph.add_theme_font_size_override("font_size", int(size_px * float(tun.get("tile.glyphScale", 0.68))))
	# White glyph with a thin dark ink halo; modulate undoes the ambient tint (glyph is unlit).
	glyph.add_theme_color_override("font_color", Color.WHITE)
	var hc: bool = GameFont.high_contrast
	glyph.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.12, 1.0 if hc else 0.6))
	var halo := float(tun.get("tile.glyphOutline" if hc else "tile.glyphOutlineNormal", 0.1 if hc else 0.035))
	glyph.add_theme_constant_override("outline_size", maxi(2, int(size_px * halo)))
	glyph.modulate = Color(GLASS_GAIN.x, GLASS_GAIN.y, GLASS_GAIN.z, 1.0)


## Marks the tile as a hazard: a counterfeit shimmers, a trap letter wears a ring.
func set_kind(k: String) -> void:
	kind = k
	_refresh_ring()


## Colour jam: decoy true pulses cyan, false pulses periwinkle; `on` false clears it.
func set_jam(on: bool, decoy: bool) -> void:
	var c := 0 if not on else (1 if decoy else 2)
	if c == jam_colour:
		return
	jam_colour = c
	_refresh_ring()


func _refresh_ring() -> void:
	if is_item or (kind == "" and jam_colour == 0):
		if _ring != null:
			_ring.queue_free()
			_ring = null
		return
	if _ring == null:
		_ring = HazardRing.new()
		_ring.name = "HazardRing"
		add_child(_ring)
		move_child(_ring, glyph.get_index())  # over the bubble, under the letter
	_ring.radius = size_px * 0.5 * (float(_tun.get("glass.bubbleScale", 1.0)) if treatment == "bubble" else 1.0) * 0.97
	_ring.width = maxf(3.0, size_px * 0.045)
	_ring.kind = kind
	_ring.jam = jam_colour
	_ring.queue_redraw()


## The shimmer's sweep position (0..1) at a time; one pass every hazard.shimmerSec.
func shimmer_at(time: float) -> float:
	return fposmod(time / maxf(0.1, float(_tun.get("hazard.shimmerSec", 2.0))) + _phase / TAU, 1.0)


func _tick_ring(time: float) -> void:
	if _ring == null:
		return
	_ring.sweep = 0.25 if reduced_motion else shimmer_at(time)
	_ring.pulse = 0.5 if reduced_motion else 0.5 + 0.5 * sin(time * TAU * JAM_PULSE_HZ + _phase)
	_ring.queue_redraw()


class HazardRing extends Node2D:
	var radius: float = 60.0
	var width: float = 5.0
	var kind: String = ""
	var jam: int = 0
	var sweep: float = 0.0
	var pulse: float = 0.5

	func _draw() -> void:
		if jam != 0:
			var c := Color("59d9ff") if jam == 1 else Color("7579f0")
			c.a = 0.45 + 0.5 * pulse
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, c, width * 1.6, true)
			return
		if kind == "trap":
			var tc := Color("7579f0")
			tc.a = TRAP_RING_ALPHA
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, tc, width * 0.8, true)
		elif kind == "counterfeit":
			var rim := Color("7579f0")
			rim.a = SHIMMER_RIM_ALPHA
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, rim, width * 0.6, true)
			var centre := sweep * TAU
			for i in 6:  # a glint that fades off at both ends
				var u := float(i) / 5.0
				var a := lerpf(0.9, 0.15, absf(u * 2.0 - 1.0))
				var gc := Color("b9bcff")
				gc.a = a
				draw_arc(Vector2.ZERO, radius, centre - SHIMMER_ARC * 0.5 + u * SHIMMER_ARC - 0.1, centre - SHIMMER_ARC * 0.5 + u * SHIMMER_ARC + 0.1, 8, gc, width * 1.3, true)


func _shadow_corner() -> float:
	if treatment == "bubble":
		return TileTextures.HALF - 8.0  # the shadow is inset by 8 px, so this makes it a circle
	return TileTextures.GLASS_CORNER


## Background items: every sticker cut from the owner's sheet (docs/design/space-items-sheet.jpg).
## They ride the back plane, drifting behind the letters.
const ITEMS := ["teacup", "bread", "spoon", "key", "desk_lamp", "door", "envelope", "chair", "tv", "satellite", "solar_panel", "gears", "cable_tangle", "helmet", "power_cable", "battery", "wrench", "gear_tag", "backpack", "glove", "camera", "thermos", "asteroid_purple", "asteroid_teal", "asteroid_brown", "asteroid_small", "comet_small", "comet_mid", "comet_big", "rocket", "sputnik"]
const ITEM_ART := "res://art/space/%s.png"
const ITEM_FILL := 0.95  # the item's longest side as a share of the bubble's diameter
const ITEM_TUMBLE := 0.25  # radians per second, alternating direction
const ITEM_FLASH := Color(1.0, 0.35, 0.3)


## Shows this tile as a sticker item: no bubble, no letter, no shadow, lightly tinted toward the night.
## It tumbles slowly unless reduced motion is on.
func set_item(art: String) -> void:
	is_item = true
	item = art
	glyph.visible = false
	shadow.visible = false
	body.material = null
	body.texture = load(ITEM_ART % art)
	var k := size_px * float(_tun.get("glass.bubbleScale", 1.0)) * ITEM_FILL / maxf(body.texture.get_width(), body.texture.get_height())
	body.scale = Vector2(k, k)
	_body_scale = body.scale
	body.rotation = (fposmod(_phase, TAU) - PI) * 0.2
	current_tilt = Vector2.ZERO
	_mat.set_shader_parameter("tilt_deg", Vector2.ZERO)
	# Unlit like the glass, so the ambient tint does not dim it.
	body.self_modulate = Color(GLASS_GAIN.x, GLASS_GAIN.y, GLASS_GAIN.z, 1.0) * Color(0.82, 0.86, 0.95)


## Mid plane (2.5D): a letter one layer back, smaller (plane.midScale, applied by the caller) and a
## little dimmer and bluer, so it reads as further away when it drifts behind a front letter.
func set_depth(dim: float) -> void:
	var k := 1.0 - clampf(dim, 0.0, 1.0)
	body.self_modulate = Color(k, k * 1.02, minf(1.0, k * 1.12), 1.0)
	glyph.self_modulate = Color(k, k * 1.02, minf(1.0, k * 1.12), 1.0)


## Back plane: one of the owner's sticker items drifting slowly behind the letters (owner, 13 Oct
## 2026: "keep the decoys in the background moving"). It cannot be tapped.
func set_back(alpha: float, art: String) -> void:
	set_item(art)
	is_back = true
	modulate = Color(1.0, 1.0, 1.0, alpha)


## Places the tile and tilts it toward the lamp, plus a slow sway. nx is the tile's x in 0..1.
func place(screen_pos: Vector2, time: float, nx: float) -> void:
	if anim != "":
		return
	_track_motion(screen_pos, time)
	position = screen_pos
	_tick_ring(time)
	var tilt := Vector2.ZERO
	if is_item:
		if not reduced_motion:
			body.rotation = (fposmod(_phase, TAU) - PI) * 0.2 + time * ITEM_TUMBLE * (1.0 if int(_phase * 10.0) % 2 == 0 else -1.0)
		return
	if treatment == "bubble":
		# A sphere looks the same from any angle, so no tilt: the bubble wobbles instead, and
		# breathes with a very small pulse (owner, 13 Oct 2026: "extremely subtle").
		if not reduced_motion:
			var wob := 0.03 * sin(time * 2.3 + _phase * 2.0)
			var pulse := 1.0 + float(_tun.get("tile.pulse", 0.0)) * sin(time * TAU * float(_tun.get("tile.pulseHz", 0.5)) + _phase)
			body.scale = _body_scale * pulse * Vector2(1.0 + wob, 1.0 - wob) * _squash()
			glyph.rotation = _lean()
			_mat.set_shader_parameter("bubble_time", time + _phase)
		current_tilt = Vector2.ZERO
		_mat.set_shader_parameter("tilt_deg", Vector2.ZERO)
		return
	if not reduced_motion and not is_back:
		var maxd: float = _tun["tile.maxTiltDeg"]
		var sway_deg: float = _tun["tile.swayDeg"]
		var w := TAU * float(_tun["tile.swaySpeed"])
		tilt.y = clampf(clampf((nx - 0.5) * 2.0, -1.0, 1.0) * maxd * 0.6 + sway_deg * sin(time * w + _phase), -maxd, maxd)
		tilt.x = clampf(sway_deg * cos(time * w * 0.8 + _phase * 1.3) - maxd * 0.15, -maxd, maxd)
	current_tilt = tilt
	_mat.set_shader_parameter("tilt_deg", tilt)


## Watches the tile's screen motion: a sharp turn in x or y is a bounce (off a wall or another
## letter), which squashes the bubble along that axis for a moment.
func _track_motion(p: Vector2, time: float) -> void:
	var dt := time - _last_time
	if _last_pos != Vector2.INF and dt > 0.0001 and dt < 0.25:
		var v := (p - _last_pos) / dt
		var min_px := size_px * 0.3  # ignore tiny nudges from crowding
		if absf(_vel_px.x) > min_px and absf(v.x) > min_px and signf(v.x) != signf(_vel_px.x):
			_bounce(Vector2.RIGHT)
		elif absf(_vel_px.y) > min_px and absf(v.y) > min_px and signf(v.y) != signf(_vel_px.y):
			_bounce(Vector2.DOWN)
		_vel_px = _vel_px.lerp(v, clampf(dt * 10.0, 0.0, 1.0))
	if dt > 0.0:
		_squash_t = maxf(0.0, _squash_t - dt)
	_last_pos = p
	_last_time = time


func _bounce(axis: Vector2) -> void:
	_squash_axis = axis
	_squash_t = SQUASH_DUR


## Scale factor for the bounce: flattened along the bounce axis, then a springy overshoot back.
func _squash() -> Vector2:
	if _squash_t <= 0.0:
		return Vector2.ONE
	var u := 1.0 - _squash_t / SQUASH_DUR
	var a := float(_tun.get("tile.bounceSquash", 0.0)) * sin(u * PI * 1.5) * (1.0 - u)
	return Vector2.ONE - _squash_axis * a + Vector2(_squash_axis.y, _squash_axis.x) * a * 0.6


## The letter leans into its motion, as if the bubble were being towed.
func _lean() -> float:
	var k := clampf(_vel_px.x / maxf(1.0, size_px * 2.5), -1.0, 1.0)
	return deg_to_rad(float(_tun.get("tile.leanDeg", 0.0))) * k


## A letter made mid-play grows from about a third of its size with a small back-ease and fades in
## (reduced motion: fade only). place(), fly, dissolve, hint glow and taps are untouched.
func grow_in(dur: float) -> void:
	if dur <= 0.0:
		return
	_grow_dur = dur
	_grow_t = dur
	_grow_alpha = modulate.a
	_apply_grow(0.0)


## A fly, dissolve or scatter takes over from a grow-in: start it from the full size and alpha.
func _cancel_grow() -> void:
	if _grow_t > 0.0:
		_grow_t = 0.0
		scale = Vector2.ONE
		modulate.a = _grow_alpha


func is_growing() -> bool:
	return _grow_t > 0.0


func _apply_grow(u: float) -> void:
	modulate.a = _grow_alpha * clampf(u * 1.5, 0.0, 1.0)
	if reduced_motion:
		return
	var w := u - 1.0
	var e := 1.0 + (GROW_OVERSHOOT + 1.0) * w * w * w + GROW_OVERSHOOT * w * w
	scale = Vector2.ONE * lerpf(GROW_FROM, 1.0, e)


func flash(dur: float) -> void:
	_flash_dur = maxf(0.01, dur)
	_flash_t = _flash_dur


## Amber hint glow for dur seconds (pulses unless reduced motion).
func glow(dur: float) -> void:
	_glow_dur = maxf(0.01, dur)
	_glow_t = _glow_dur
	if _glow == null:
		_glow = HintGlow.new()
		_glow.name = "HintGlow"
		_glow.z_index = -1
		add_child(_glow)
		move_child(_glow, 0)
	_glow.radius = size_px * 0.5 * (float(_tun.get("glass.bubbleScale", 1.0)) if treatment == "bubble" else 1.0) * 1.15
	_glow.alpha = 1.0
	_glow.queue_redraw()


func clear_glow() -> void:
	_glow_t = 0.0
	if _glow != null:
		_glow.queue_free()
		_glow = null


func glow_left() -> float:
	return _glow_t


class HintGlow extends Node2D:
	var radius: float = 60.0
	var alpha: float = 1.0

	func _draw() -> void:
		var amber := Color("F8BC04")
		for i in 6:
			draw_circle(Vector2.ZERO, radius * (1.0 + 0.09 * float(5 - i)), Color(amber.r, amber.g, amber.b, 0.16 * alpha))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(amber.r, amber.g, amber.b, alpha), 6.0, true)


func fly_to(target: Vector2, target_size_px: float, dur: float) -> void:
	_cancel_grow()
	anim = "fly"
	_from = position
	_to = target
	_to_scale = target_size_px / size_px
	_anim_dur = maxf(0.01, dur)
	_anim_t = 0.0
	z_index = 20
	shadow.visible = false


func dissolve(dur: float) -> void:
	_cancel_grow()
	anim = "dissolve"
	_anim_dur = maxf(0.01, dur)
	_anim_t = 0.0
	z_index = 5


## The level is over: the tile drifts out of the field along `push` (pixels) and fades.
func scatter(push: Vector2, dur: float) -> void:
	_cancel_grow()
	anim = "scatter"
	_from = position
	_to = position + push
	_to_scale = modulate.a  # the alpha it fades from (back items are already faint)
	_anim_dur = maxf(0.01, dur)
	_anim_t = 0.0
	clear_glow()


## Advances flash and animation; true when a fly, dissolve or scatter has finished.
func tick(delta: float) -> bool:
	if _glow_t > 0.0:
		_glow_t = maxf(0.0, _glow_t - delta)
		var k := _glow_t / _glow_dur
		var pulse := 1.0 if reduced_motion else 0.75 + 0.25 * sin(_glow_t * 14.0)
		_glow.alpha = clampf(k * 3.0, 0.0, 1.0) * pulse
		_glow.queue_redraw()
		if _glow_t <= 0.0:
			_glow.queue_free()
			_glow = null
	if _flash_t > 0.0:
		_flash_t = maxf(0.0, _flash_t - delta)
		_mat.set_shader_parameter("flash", _flash_t / _flash_dur)
		if is_item:
			var fc := Color.WHITE.lerp(ITEM_FLASH, _flash_t / _flash_dur)
			modulate = Color(fc.r, fc.g, fc.b, modulate.a)
	if _grow_t > 0.0:
		if anim != "":
			_grow_t = 0.0  # a fly, dissolve or scatter takes over
		else:
			_grow_t = maxf(0.0, _grow_t - delta)
			_apply_grow(1.0 - _grow_t / _grow_dur)
			if _grow_t <= 0.0:
				scale = Vector2.ONE
				modulate.a = _grow_alpha
	if anim == "":
		return false
	_anim_t += delta
	var u := clampf(_anim_t / _anim_dur, 0.0, 1.0)
	if anim == "fly":
		var e := u * u * (3.0 - 2.0 * u)
		position = _from.lerp(_to, e)
		scale = Vector2.ONE * lerpf(1.0, _to_scale, e)
		_mat.set_shader_parameter("tilt_deg", current_tilt * (1.0 - e))
	elif anim == "scatter":
		var e := u * u  # eases in: the letters let go, then speed away
		position = _from.lerp(_to, e)
		modulate.a = _to_scale * (1.0 - u)
		scale = Vector2.ONE * (1.0 - 0.35 * u)
	else:
		modulate.a = 1.0 - u
		scale = Vector2.ONE * (1.0 + 0.25 * u)
	return u >= 1.0

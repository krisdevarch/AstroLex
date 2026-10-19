extends RefCounted
## Procedural art for the in-round HUD: the veil over Earth's night side, the porthole portrait
## frame, vector icons and the coral clock fill. Drawn in _draw; every size is a pixel at 1080 wide.

const PANEL_H := 600.0  # height of the night panel control
const CREST := 40.0  # local y of the highest point (so it sits PANEL_H - CREST above the bottom)
const EDGE_DROP := 100.0  # how far the curve falls from the crest to either screen edge (as the painted Earth)
const VEIL_MAX := 0.45  # how dark Earth is veiled before any word is restored
const VEIL_GAP := 26.0  # the veil starts this far under the rim
const VEIL_FADE := 70.0
const ART_D := 356.0  # the portrait art's own size; the field scales it to fit its column
const CORAL := Color("FF6B35")
const CORAL_LIGHT := Color("ff9a6e")
const CRIMSON := Color("ff3b5c")
const CRIMSON_LIGHT := Color("ff7a90")
const RIM_R := 178.0
const DISC_R := 138.0
const CLIP_SHADER := "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tc.a *= smoothstep(0.5, 0.49, length(UV - vec2(0.5)));\n\tCOLOR = c;\n}\n"


## A coral (or crimson) rounded bar fill: a 9-slice texture so the ends stay round at any length.
static func bar_fill_box(c1: Color, c2: Color, h: int = 28) -> StyleBoxTexture:
	var w := maxi(64, h * 2 + 8)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var r := float(h) * 0.5
	for y in h:
		for x in w:
			var cx := clampf(x + 0.5, r, float(w) - r)
			var d := Vector2(x + 0.5 - cx, y + 0.5 - r).length()
			var col := c1.lerp(c2, float(x) / float(w - 1))
			col.a = clampf(r + 0.5 - d, 0.0, 1.0)
			img.set_pixel(x, y, col)
	var sb := StyleBoxTexture.new()
	sb.texture = ImageTexture.create_from_image(img)
	sb.texture_margin_left = r
	sb.texture_margin_right = r
	return sb


static func clip_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = CLIP_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


class NightPanel extends Control:
	## Earth's night side is painted in the backdrop (owner, mock v3). This panel only veils it:
	## the veil lifts as words are restored, so the city lights come up with the colour story.
	var lit: float = 0.0:
		set(v):
			lit = v
			queue_redraw()

	## Local y of the planet's curved top edge at x (width w): a symmetric arc, highest at the middle.
	static func edge_y(x: float, w: float) -> float:
		var u := (x - w * 0.5) / (w * 0.5)
		return CREST + EDGE_DROP * u * u

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var a := lerpf(VEIL_MAX, 0.0, clampf(lit, 0.0, 1.0))
		if a <= 0.001:
			return
		var veil := Color("060b22")
		# The veil starts a little under the rim and fades in, so the painted rim glow stays clear.
		# One polygon for the fade band and one for the solid part: strips left seams on the web build.
		var top := PackedVector2Array()
		var mid := PackedVector2Array()
		var n := 48
		for i in n + 1:
			var x := w * float(i) / float(n)
			var y := NightPanel.edge_y(x, w) + VEIL_GAP
			top.append(Vector2(x, y))
			mid.append(Vector2(x, y + VEIL_FADE))
		var band := PackedVector2Array(top)
		var cols := PackedColorArray()
		for i in top.size():
			cols.append(Color(veil, 0.0))
		for i in range(mid.size() - 1, -1, -1):
			band.append(mid[i])
			cols.append(Color(veil, a))
		draw_polygon(band, cols)
		var solid := PackedVector2Array(mid)
		solid.append(Vector2(w, h))
		solid.append(Vector2(0, h))
		draw_colored_polygon(solid, Color(veil, a))


class PortraitArt extends Control:
	var colour: Color = Color(0.55, 0.9, 1.0)
	## Seconds of idle animation (the field advances it); the orange arcs drift round the ring.
	var t: float = 0.0
	var calm: bool = false

	## The console porthole (owner's target mock, 19 Oct 2026): a dark metal ring with a neon ring
	## in the suit colour, two orange arcs that drift slowly round it, and a deep blue window.
	func _draw() -> void:
		var c := size * 0.5
		var glow := 0.75 if calm else 0.75 + 0.25 * sin(t * 1.6)
		for i in 9:
			draw_circle(c, RIM_R + 26.0 - float(i) * 3.0, Color(colour.r, colour.g, colour.b, 0.06 * glow))
		draw_circle(c, RIM_R + 2.0, Color("0d1428"))
		draw_circle(c, RIM_R - 4.0, Color("2b3550"))
		draw_arc(c, RIM_R - 10.0, PI * 1.05, PI * 1.95, 48, Color(1, 1, 1, 0.14), 10.0, true)
		draw_arc(c, RIM_R - 10.0, PI * 0.05, PI * 0.95, 48, Color(0, 0, 0, 0.22), 10.0, true)
		# Neon ring with a soft halo, then the drifting orange arcs.
		draw_arc(c, RIM_R - 22.0, 0.0, TAU, 96, Color(colour.r, colour.g, colour.b, 0.28 * glow), 16.0, true)
		draw_arc(c, RIM_R - 22.0, 0.0, TAU, 96, colour.lightened(0.25), 5.0, true)
		var spin := 0.0 if calm else t * 0.35
		for k in 2:
			var a0 := spin + PI * float(k) + PI * 0.72
			draw_arc(c, RIM_R - 22.0, a0, a0 + 0.95, 24, Color(1.0, 0.55, 0.22, 0.35), 18.0, true)
			draw_arc(c, RIM_R - 22.0, a0, a0 + 0.95, 24, Color("ff9a4a"), 7.0, true)
		draw_circle(c, DISC_R + 6.0, Color("0b1224"))
		draw_circle(c, DISC_R, Color("1d3a74"))
		for i in 6:
			draw_circle(c + Vector2(0, -30), 130.0 - float(i) * 18.0, Color(0.6, 0.8, 1.0, 0.05))
		# A glass glint across the window.
		draw_arc(c, DISC_R - 14.0, PI * 1.15, PI * 1.45, 16, Color(1, 1, 1, 0.22), 8.0, true)


## The tail under Babel's speech bubble (owner's target mock): a short curl down and to the left.
class BubbleTail extends Control:
	var colour: Color = Color(0.56, 0.61, 0.95)
	var fill: Color = Color(0.08, 0.12, 0.29)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var tri := PackedVector2Array([Vector2(w * 0.25, 0), Vector2(0, h), Vector2(w, 0)])
		draw_colored_polygon(tri, fill)
		draw_polyline(PackedVector2Array([Vector2(w * 0.25, 2), Vector2(0, h), Vector2(w, 2)]), colour, 5.0, true)


## The console tray behind the porthole and the slots (owner's target mock, 19 Oct 2026): a dark
## metal body with a lighter rim and a neon edge, a slot screen with a cyan glow, a cable from the
## porthole, and a row of small lights that blink now and then. Positions are set by the field.
class Console extends Control:
	var body: Rect2 = Rect2()  # the tray body, local px
	var screen: Rect2 = Rect2()  # the slot screen
	var porthole: Vector2 = Vector2.ZERO  # centre of the porthole socket
	var porthole_r: float = 130.0
	var accent: Color = Color("4fe3ff")
	var t: float = 0.0
	var calm: bool = false

	func _draw() -> void:
		var glow := 0.8 if calm else 0.8 + 0.2 * sin(t * 1.3)
		# Soft shadow, outer rim, body.
		_round(body.grow(10.0).grow_individual(0, 0, 0, 6), 60.0, Color(0.0, 0.01, 0.06, 0.35))
		_round(body, 56.0, Color("3a4766"))
		_round(body.grow(-6.0), 50.0, Color("17213d"))
		_round(Rect2(body.position + Vector2(6, 6), Vector2(body.size.x - 12, body.size.y * 0.45)), 50.0, Color(1, 1, 1, 0.035))
		# Neon edge just inside the rim.
		_outline(body.grow(-14.0), 44.0, Color(accent.r, accent.g, accent.b, 0.22 * glow), 10.0)
		_outline(body.grow(-14.0), 44.0, Color(accent.r, accent.g, accent.b, 0.75), 3.0)
		# Porthole socket: a dark collar the portrait sits in.
		draw_circle(porthole, porthole_r + 18.0, Color("3a4766"))
		draw_circle(porthole, porthole_r + 12.0, Color("111a33"))
		# The cable from the socket down under the tray.
		var c0 := porthole + Vector2(-porthole_r * 0.62, porthole_r * 0.78)
		var pts := PackedVector2Array()
		for i in 13:
			var u := float(i) / 12.0
			pts.append(c0.lerp(Vector2(c0.x + 40.0, body.end.y + 36.0), u) + Vector2(-30.0 * sin(u * PI), 0))
		draw_polyline(pts, Color("0b1122"), 16.0, true)
		draw_polyline(pts, Color("44527a"), 9.0, true)
		# Slot screen: deep navy with a cyan glow round it.
		for i in 4:
			_outline(screen.grow(4.0 + float(i) * 4.0), 30.0 + float(i) * 4.0, Color(accent.r, accent.g, accent.b, (0.12 - float(i) * 0.025) * glow), 4.0)
		_round(screen, 28.0, Color("081028"))
		_outline(screen, 28.0, Color(accent.r, accent.g, accent.b, 0.85), 3.0)
		# Small lights between the porthole and the screen: each blinks on its own beat.
		var lx := screen.position.x - 34.0
		for i in 4:
			var ly := screen.position.y + 36.0 + float(i) * 34.0
			var on := 1.0 if calm else 0.35 + 0.65 * clampf(sin(t * (1.1 + float(i) * 0.37) + float(i) * 1.9) * 2.0, 0.0, 1.0)
			var col := Color("ff9a4a") if i % 2 == 0 else accent
			draw_circle(Vector2(lx, ly), 9.0, Color(col.r, col.g, col.b, 0.18 * on))
			draw_circle(Vector2(lx, ly), 5.0, Color(col.r, col.g, col.b, 0.35 + 0.65 * on))

	func _round(r: Rect2, rad: float, col: Color) -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		sb.set_corner_radius_all(int(minf(rad, minf(r.size.x, r.size.y) * 0.5)))
		sb.anti_aliasing = true
		draw_style_box(sb, r)

	func _outline(r: Rect2, rad: float, col: Color, w: float) -> void:
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.border_color = col
		sb.set_border_width_all(int(maxf(1.0, w)))
		sb.set_corner_radius_all(int(minf(rad, minf(r.size.x, r.size.y) * 0.5)))
		sb.anti_aliasing = true
		draw_style_box(sb, r)


## The art of a round console button (pause, sound, settings): a dark disc, a metal rim and a
## neon ring whose bright arc drifts slowly round. The button itself is invisible over it.
class RingArt extends Control:
	var ring: Color = Color("4fe3ff")
	var t: float = 0.0
	var calm: bool = false

	func _draw() -> void:
		var c := size * 0.5
		var r := size.x * 0.5
		for i in 6:
			draw_circle(c, r + 2.0 - float(i) * 2.0, Color(ring.r, ring.g, ring.b, 0.05))
		draw_circle(c, r - 4.0, Color("3a4766"))
		draw_circle(c, r - 9.0, Color("142047"))
		draw_circle(c, r - 22.0, Color("1a2a5a"))
		draw_arc(c, r - 15.0, 0.0, TAU, 64, Color(ring.r, ring.g, ring.b, 0.25), 12.0, true)
		draw_arc(c, r - 15.0, 0.0, TAU, 64, Color(ring.r, ring.g, ring.b, 0.75), 4.0, true)
		var a0 := -PI * 0.5 + (0.0 if calm else t * 0.8)
		draw_arc(c, r - 15.0, a0, a0 + PI * 1.1, 40, Color(ring.r, ring.g, ring.b, 0.45), 16.0, true)
		draw_arc(c, r - 15.0, a0, a0 + PI * 1.1, 40, ring.lightened(0.35), 6.0, true)
		draw_arc(c, r - 22.0, PI * 1.1, PI * 1.6, 16, Color(1, 1, 1, 0.12), 5.0, true)


## The clock's liquid (owner's target mock): coral fill with a wobbling wave front and a few
## bubbles rising through it. Child of the TimeBar; reads the bar's value.
class Liquid extends Control:
	var c1: Color = Color("ff5e3a")
	var c2: Color = Color("ff9a6e")
	var t: float = 0.0
	var calm: bool = false

	func _draw() -> void:
		var bar := get_parent() as ProgressBar
		if bar == null:
			return
		var share := clampf(bar.value / maxf(0.01, bar.max_value), 0.0, 1.0)
		var pad := 8.0
		var h := size.y - pad * 2.0
		var full := size.x - pad * 2.0
		var w := full * share
		if w < 2.0:
			return
		var r := h * 0.5
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var steps := 40
		# Left cap (round), straight top and bottom, and a wavy front at the right end.
		for i in range(steps + 1):
			var a := PI * 0.5 + PI * float(i) / float(steps)
			pts.append(Vector2(pad + r, pad + r) + Vector2.from_angle(a) * r)
		var front := pad + maxf(r, w)
		for i in range(steps + 1):
			var u := float(i) / float(steps)
			var y := pad + u * h
			var wave := 0.0 if calm else 6.0 * sin(u * TAU * 1.5 + t * 5.0)
			if i == 0:
				pts.append(Vector2(front - 6.0 + wave, y))
			pts.append(Vector2(front + wave - 6.0 * (1.0 - sin(u * PI)), y))
		pts.reverse()
		for p in pts:
			cols.append(c1.lerp(c2, clampf((p.x - pad) / maxf(1.0, full), 0.0, 1.0)))
		draw_polygon(pts, cols)
		# Highlight band along the top.
		draw_line(Vector2(pad + r, pad + h * 0.24), Vector2(maxf(pad + r, front - 14.0), pad + h * 0.24), Color(1, 1, 1, 0.28), h * 0.16, true)
		if calm:
			return
		for i in 6:
			var x := pad + r + fposmod(float(i) * 97.0 + t * (22.0 + float(i) * 5.0), maxf(1.0, w - r))
			var y := pad + h * (0.3 + 0.5 * fposmod(float(i) * 0.37 + t * 0.4, 1.0))
			draw_circle(Vector2(x, pad + h - (y - pad)), 3.0 + float(i % 3), Color(1, 1, 1, 0.22))


class Icon extends Control:
	var kind: String = "pause":
		set(v):
			kind = v
			queue_redraw()
	var colour: Color = Color(0.93, 0.95, 1.0):
		set(v):
			colour = v
			queue_redraw()
	## Hint bulb only: how bright its halo is (0..1); the field pulses it.
	var glow: float = 0.5:
		set(v):
			glow = v
			queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var col := colour
		match kind:
			"pause":
				draw_rect(Rect2(c.x - 19, c.y - 24, 12, 48), col)
				draw_rect(Rect2(c.x + 7, c.y - 24, 12, 48), col)
			"play":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-14, -26), c + Vector2(-14, 26), c + Vector2(24, 0)]), col)
			"hint":
				# The target mock's bulb: a warm halo, a yellow-orange glass with a white glint and
				# a glowing filament, on a grey screw base. glow (0..1) pulses the halo.
				var b := c + Vector2(0, -12)
				for i in 7:
					draw_circle(b, 52.0 - float(i) * 5.0, Color(1.0, 0.78, 0.3, (0.05 + 0.05 * glow)))
				var ink := Color("5a3410")
				draw_circle(b, 31.0, ink)
				draw_circle(b, 27.0, Color("ffb52e"))
				draw_circle(b + Vector2(-2, -3), 21.0, Color("ffd45c"))
				draw_circle(b + Vector2(-3, -5), 12.0, Color(1.0, 0.95, 0.7, 0.5 + 0.4 * glow))
				draw_polyline(PackedVector2Array([b + Vector2(-8, 10), b + Vector2(-4, 2), b + Vector2(0, 8), b + Vector2(4, 2), b + Vector2(8, 10)]), Color("fff2c0"), 3.0, true)
				draw_arc(b, 19.0, deg_to_rad(200), deg_to_rad(250), 12, Color.WHITE, 5.0, true)
				draw_colored_polygon(PackedVector2Array([b + Vector2(-17, 20), b + Vector2(17, 20), b + Vector2(13, 30), b + Vector2(-13, 30)]), ink)
				draw_rect(Rect2(b.x - 13.0, b.y + 29.0, 26.0, 22.0), ink)
				draw_rect(Rect2(b.x - 10.0, b.y + 31.0, 20.0, 6.0), Color("d3d7de"))
				draw_rect(Rect2(b.x - 10.0, b.y + 40.0, 20.0, 6.0), Color("a3a9b2"))
				draw_rect(Rect2(b.x - 5.0, b.y + 50.0, 10.0, 5.0), ink)
			"sound", "muted":
				draw_rect(Rect2(c.x - 28, c.y - 9, 13, 18), col)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-16, -9), c + Vector2(-2, -21), c + Vector2(-2, 21), c + Vector2(-16, 9)]), col)
				if kind == "sound":
					draw_arc(c + Vector2(-2, 0), 14.0, deg_to_rad(-50), deg_to_rad(50), 12, col, 4.0, true)
					draw_arc(c + Vector2(-2, 0), 25.0, deg_to_rad(-50), deg_to_rad(50), 14, col, 4.0, true)
				else:
					draw_line(c + Vector2(8, -11), c + Vector2(28, 11), col, 5.0)
					draw_line(c + Vector2(8, 11), c + Vector2(28, -11), col, 5.0)
			"settings":
				draw_arc(c, 18.0, 0.0, TAU, 32, col, 5.0, true)
				draw_arc(c, 7.0, 0.0, TAU, 20, col, 4.0, true)
				for i in 8:
					var d := Vector2.from_angle(TAU * float(i) / 8.0)
					draw_line(c + d * 20.0, c + d * 29.0, col, 8.0)

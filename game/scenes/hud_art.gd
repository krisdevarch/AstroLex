extends RefCounted
## Procedural art for the in-round HUD: the veil over Earth's night side, the porthole portrait
## frame, vector icons and the coral clock fill. Drawn in _draw; every size is a pixel at 1080 wide.

const PANEL_H := 600.0  # height of the night panel control
const CREST := 40.0  # local y of the highest point (so it sits PANEL_H - CREST above the bottom)
const EDGE_DROP := 100.0  # how far the curve falls from the crest to either screen edge (as the painted Earth)
const VEIL_MAX := 0.45  # how dark Earth is veiled before any word is restored
const VEIL_GAP := 26.0  # the veil starts this far under the rim
const VEIL_FADE := 70.0
const ART_SCALE := 0.5  # the console, button and bulb textures are rendered at 2x (scripts/art/make_hud.sh); drawn at this scale
const ART_D := 356.0  # the portrait art's own size; the field scales it to fit its column
const CORAL := Color("ff6468")  # the mock's clock liquid: coral at the left end, peach at the front
const CORAL_LIGHT := Color("feab7b")
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


## The console tray (owner, 19 Oct 2026: "make it pixel perfect"): the mock's own art, cut out
## and upscaled by scripts/art/cut_hud.py (porthole frame, slot screen, cables and the clock bar's
## frame), with its little lights blinking on their own beats and a faint scan sweeping the screen.
class Console extends Control:
	## The lights painted on the tray, in mock px: [x, y, colour, radius].
	const LIGHTS := [
		[161.8, 776.7, Color("ff9a4a"), 4.5], [85.0, 907.5, Color("5ff2ff"), 6.0],
		[183.1, 921.6, Color("5ff2ff"), 5.5], [438.3, 919.5, Color("5ff2ff"), 5.5],
		[187.5, 922.8, Color("ff9a4a"), 2.2], [410.5, 922.5, Color("ff9a4a"), 2.2],
		[417.5, 922.5, Color("ff9a4a"), 2.2], [152.5, 898.5, Color("ff9a4a"), 2.4],
		[157.5, 898.5, Color("ff9a4a"), 2.4], [162.5, 898.5, Color("ff9a4a"), 2.4],
	]
	const SCAN_EVERY := 5.0
	var tex: Texture2D
	var k: float = 1080.0 / 572.0  # mock px -> game px
	var origin: Vector2 = Vector2(0, 742)  # mock px of the texture's top-left corner
	var screen: Rect2 = Rect2()  # the slot screen, local px
	var t: float = 0.0
	var calm: bool = false

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	func _draw() -> void:
		if tex != null:
			draw_texture_rect(tex, Rect2(Vector2.ZERO, tex.get_size() * ART_SCALE), false)
		for i in LIGHTS.size():
			var l: Array = LIGHTS[i]
			var on := 0.6 if calm else clampf(0.5 + 0.9 * sin(t * (0.9 + 0.23 * float(i)) + float(i) * 2.1), 0.0, 1.0)
			var p := (Vector2(l[0], l[1]) - origin) * k
			var c: Color = l[2]
			draw_circle(p, float(l[3]) * k * 2.2, Color(c.r, c.g, c.b, 0.16 * on))
			draw_circle(p, float(l[3]) * k * 1.3, Color(c.r, c.g, c.b, 0.22 * on))
		# Now and then a soft band of light sweeps down the slot screen.
		if calm or screen.size.y <= 0.0:
			return
		var u := fposmod(t, SCAN_EVERY) / 1.6
		if u < 1.0:
			var band := 26.0
			var y := screen.position.y - band + (screen.size.y + band * 2.0) * u
			for j in 6:
				var yy := y + float(j) * band / 6.0
				if yy > screen.position.y + 6.0 and yy < screen.end.y - 6.0:
					var a := 0.05 * sin(PI * float(j) / 5.0)
					draw_line(Vector2(screen.position.x + 10.0, yy), Vector2(screen.end.x - 10.0, yy), Color(0.6, 0.95, 1.0, a), band / 6.0 + 1.0)


## The glass over the porthole's screen, drawn on top of the Catcher: fine scan lines, a slow
## bright scan and a glint, all kept inside the round window.
class PortholeGlass extends Control:
	var t: float = 0.0
	var calm: bool = false

	func _draw() -> void:
		var c := size * 0.5
		var r := size.x * 0.5
		var y := -r + 3.0
		while y < r:
			var half := sqrt(maxf(0.0, r * r - y * y))
			draw_line(c + Vector2(-half, y), c + Vector2(half, y), Color(0.55, 0.95, 1.0, 0.05), 1.5)
			y += 6.0
		if not calm:
			var sy := -r + fposmod(t * 34.0, r * 2.6)
			if sy < r:
				var half := sqrt(maxf(0.0, r * r - sy * sy))
				draw_line(c + Vector2(-half, sy), c + Vector2(half, sy), Color(0.6, 1.0, 1.0, 0.12), 8.0)
		draw_arc(c, r - 12.0, PI * 1.12, PI * 1.42, 16, Color(1, 1, 1, 0.16), 6.0, true)


## A round console button's face: the mock's ring (icon painted out) with a bright glint that
## travels round its neon ring. The button itself is invisible over it.
class RingArt extends Control:
	var tex: Texture2D
	var tex_pos: Vector2 = Vector2.ZERO  # where the texture's corner sits, local px
	var ring: Color = Color("4fe3ff")
	var ring_r: float = 48.0  # the neon ring's radius, local px
	var t: float = 0.0
	var calm: bool = false

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	func _draw() -> void:
		if tex != null:
			draw_texture_rect(tex, Rect2(tex_pos, tex.get_size() * ART_SCALE), false)
		var c := size * 0.5
		var glow := 0.5 if calm else 0.5 + 0.5 * sin(t * 1.7)
		draw_arc(c, ring_r, 0.0, TAU, 64, Color(ring.r, ring.g, ring.b, 0.1 * glow), 10.0, true)
		if calm:
			return
		var a0 := -PI * 0.5 + t * 1.1
		for i in 5:
			var f := float(i) / 5.0
			draw_arc(c, ring_r, a0 - f * 0.5, a0 - f * 0.5 + 0.12, 6, Color(1, 1, 1, 0.5 * (1.0 - f)), 4.0, true)


## The clock's liquid, as in the owner's mock: coral to peach, a long rolling wave on top with a
## pale crest, a straight front with a soft corner, and bubbles drifting up (a few hop out of it).
## Child of the TimeBar, which sits exactly over the bar's channel; reads the bar's value.
class Liquid extends Control:
	var c1: Color = Color("ff6468")
	var c2: Color = Color("feab7b")
	var t: float = 0.0
	var calm: bool = false
	var pad: float = 4.5  # the channel's dark lining

	func _surface(x: float, h: float, ph: float) -> float:
		var base := 0.34 * h
		return pad + base + 0.24 * h * sin(x / 48.0 + ph)

	func _draw() -> void:
		var bar := get_parent() as ProgressBar
		if bar == null:
			return
		var share := clampf(bar.value / maxf(0.01, bar.max_value), 0.0, 1.0)
		var h := size.y - pad * 2.0
		var full := size.x - pad * 2.0
		var r := h * 0.5
		var front := pad + maxf(r * 1.2, full * share)
		if share <= 0.0:
			return
		var ph := 0.0 if calm else t * 1.3
		var corner := 7.0
		# Top edge left to right (the wave, held inside the round left cap), then the bottom back.
		var crest := PackedVector2Array()
		var steps := maxi(2, int((front - corner - pad) / 6.0))
		for i in steps + 1:
			var x := lerpf(pad, front - corner, float(i) / float(steps))
			var dx := pad + r - x
			var cap := sqrt(maxf(0.0, r * r - dx * dx)) if x < pad + r else r
			crest.append(Vector2(x, clampf(_surface(x, h, ph), pad + r - cap, pad + r + cap * 0.6)))
		var poly := PackedVector2Array(crest)
		poly.append(Vector2(front, crest[crest.size() - 1].y + corner))
		poly.append(Vector2(front, pad + h))
		for i in steps:  # stops short of the left tip, which the top edge already holds
			var x := lerpf(front - corner, pad, float(i) / float(steps))
			var dx := pad + r - x
			var cap := sqrt(maxf(0.0, r * r - dx * dx)) if x < pad + r else r
			poly.append(Vector2(x, pad + r + cap))
		var cols := PackedColorArray()
		for p in poly:
			cols.append(c1.lerp(c2, clampf((p.x - pad) / maxf(1.0, full * 0.8), 0.0, 1.0)))
		draw_polygon(poly, cols)
		# The pale crest just under the surface.
		var line := PackedVector2Array()
		for p in crest:
			line.append(p + Vector2(0, 3.0))
		if line.size() > 1:
			draw_polyline(line, Color(1.0, 0.9, 0.82, 0.75), 4.0, true)
		# Bubbles drift up through the liquid; a couple float just above it.
		for i in 7:
			var bx := pad + r * 0.6 + fposmod(float(i) * 113.0 + (0.0 if calm else t * (9.0 + float(i) * 3.0)), maxf(1.0, front - pad - r))
			var rise := 0.5 if calm else fposmod(float(i) * 0.31 + t * (0.18 + 0.04 * float(i)), 1.0)
			var sy := _surface(bx, h, ph)
			var by := lerpf(pad + h - 6.0, sy + 6.0, rise)
			draw_circle(Vector2(bx, by), 2.5 + float(i % 3) * 1.5, Color(1.0, 0.86, 0.84, 0.7))
		for i in 2:
			var dx := pad + front * (0.25 + 0.45 * float(i))
			var hop := 0.0 if calm else maxf(0.0, sin(t * 1.4 + float(i) * 2.0))
			draw_circle(Vector2(dx, _surface(dx, h, ph) - 5.0 - 10.0 * hop), 3.5, Color(1.0, 0.8, 0.8, 0.65 * (0.4 + 0.6 * hop)))


## The wires on the slot screen (owner's mock): a glowing amber link between neighbouring letters
## of the active word and a cyan wire from each letter down to the slot under it. Links light up as
## letters are caught; a spark runs along the lit ones and the wires flicker.
class SlotWires extends Control:
	var top_row: Control
	var bottom_row: Control
	var t: float = 0.0
	var calm: bool = false

	func _filled(p: Control) -> bool:
		return bool(p.get_meta("was_filled", false))

	func _draw() -> void:
		if top_row == null or bottom_row == null:
			return
		var tops := top_row.get_children()
		var bots := bottom_row.get_children()
		for i in tops.size():
			var a := tops[i] as Control
			var ar := Rect2(a.position, a.size)
			# Cyan wire down to the slot below, when one sits under this letter.
			for bn in bots:
				var b := bn as Control
				var bc := b.position.x + b.size.x * 0.5
				if absf(bc - ar.get_center().x) < ar.size.x * 0.35:
					var lit := _filled(a)
					var y0 := ar.end.y + 2.0
					var y1 := b.position.y - 2.0
					var fl := 1.0 if calm else 0.75 + 0.25 * sin(t * 13.0 + float(i) * 1.7)
					var al := (0.95 if lit else 0.35) * fl
					var x := ar.get_center().x
					draw_line(Vector2(x, y0), Vector2(x, y1), Color(0.35, 0.9, 1.0, 0.3 * al), 12.0)
					var zig := PackedVector2Array()
					for j in 7:
						var u := float(j) / 6.0
						var jit := 0.0 if calm or j == 0 or j == 6 else 1.6 * sin(t * 21.0 + float(j) * 2.3 + float(i))
						zig.append(Vector2(x + jit, lerpf(y0, y1, u)))
					draw_polyline(zig, Color(0.82, 1.0, 1.0, al), 4.0, true)
					break
			if i + 1 >= tops.size():
				continue
			var nb := tops[i + 1] as Control
			var x0 := ar.end.x - 2.0
			var x1 := nb.position.x + 2.0
			if x1 <= x0:
				continue
			var y := ar.get_center().y
			var both := _filled(a) and _filled(nb)
			var g := 1.0 if both else 0.3
			draw_line(Vector2(x0, y), Vector2(x1, y), Color(1.0, 0.72, 0.25, 0.3 * g), 14.0)
			draw_line(Vector2(x0, y), Vector2(x1, y), Color(1.0, 0.93, 0.6, 0.85 * g), 6.0)
			if both and not calm:
				var sx := lerpf(x0, x1, fposmod(t * 1.2 + float(i) * 0.37, 1.0))
				draw_circle(Vector2(sx, y), 5.0, Color(1, 1, 0.9, 0.9))


## A console button's icon. Pause, sound, settings and the hint bulb are the mock's own art
## (`art`, by kind); the states the mock does not show (play, muted) are drawn in its style: a
## pale glyph with a dark ink outline.
class Icon extends Control:
	const INK := Color("0a1430")
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
	## kind -> Texture2D from the mock (the whole button for pause/sound/settings, the bulb for hint).
	var art: Dictionary = {}
	var art_pos: Vector2 = Vector2.ZERO  # where a button texture's corner sits, local px
	var clip_r: float = 43.0  # a button's icon disc, local px
	var halo: Vector2 = Vector2.ZERO  # hint: the bulb glass centre, local px
	var halo_r: float = 47.0

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	func _draw() -> void:
		var c := size * 0.5
		match kind:
			"hint":
				for i in 7:
					draw_circle(halo, halo_r * (2.0 - float(i) * 0.14), Color(1.0, 0.72, 0.25, 0.035 + 0.045 * glow))
				if art.has("hint"):
					draw_texture_rect(art["hint"], Rect2(Vector2.ZERO, size), false)
				draw_circle(halo + Vector2(-halo_r * 0.15, -halo_r * 0.2), halo_r * 0.5, Color(1.0, 0.96, 0.75, 0.25 * glow))
			"pause", "sound", "settings":
				_disc(art.get(kind), c)
			"muted":
				# The mock's speaker without its waves, and a cross.
				_disc(art.get("sound"), c, 0.12)
				var x0 := c + Vector2(clip_r * 0.28, 0)
				for d in [Vector2(1, 1), Vector2(1, -1)]:
					draw_line(x0 - d * 11.0, x0 + d * 11.0, INK, 11.0, true)
				for d in [Vector2(1, 1), Vector2(1, -1)]:
					draw_line(x0 - d * 11.0, x0 + d * 11.0, Color("e6eef6"), 5.5, true)
			"play":
				var tri := PackedVector2Array([c + Vector2(-13, -22), c + Vector2(-13, 22), c + Vector2(23, 0)])
				var ink := PackedVector2Array([c + Vector2(-18, -30), c + Vector2(-18, 30), c + Vector2(31, 0)])
				draw_colored_polygon(ink, INK)
				draw_colored_polygon(tri, colour)

	## Draws a button texture's icon disc (radius clip_r); `cut` (share of the radius) clips it at
	## that far right of centre, so the muted speaker loses its waves.
	func _disc(tex: Variant, c: Vector2, cut: float = 1.0) -> void:
		if not tex is Texture2D:
			return
		var ts := (tex as Texture2D).get_size() * ART_SCALE
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for i in 48:
			var p := c + Vector2.from_angle(TAU * float(i) / 48.0) * clip_r
			p.x = minf(p.x, c.x + clip_r * cut)
			pts.append(p)
			uvs.append((p - art_pos) / ts)
		draw_colored_polygon(pts, Color.WHITE, uvs, tex)

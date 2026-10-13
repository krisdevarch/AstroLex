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
const DISC_R := 148.0
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
		var x := 0.0
		while x < w:
			var x2 := minf(x + 12.0, w)
			# The veil starts a little under the rim and fades in, so the painted rim glow stays clear.
			var y1 := NightPanel.edge_y(x, w) + VEIL_GAP
			var y2 := NightPanel.edge_y(x2, w) + VEIL_GAP
			var pts := PackedVector2Array([Vector2(x, y1), Vector2(x2 + 0.5, y2), Vector2(x2 + 0.5, y2 + VEIL_FADE), Vector2(x, y1 + VEIL_FADE)])
			draw_polygon(pts, PackedColorArray([Color(veil, 0.0), Color(veil, 0.0), Color(veil, a), Color(veil, a)]))
			draw_rect(Rect2(x, y1 + VEIL_FADE, x2 + 0.5 - x, h - y1 - VEIL_FADE), Color(veil, a))
			x = x2


class PortraitArt extends Control:
	var colour: Color = Color(0.55, 0.9, 1.0)

	## A porthole as in the owner's mock: a glow in the suit colour, a thick metal ring with bolts,
	## a thin coloured inner ring and a pale sky behind the Catcher.
	func _draw() -> void:
		var c := size * 0.5
		for i in 8:
			draw_circle(c, RIM_R + 26.0 - float(i) * 3.5, Color(colour.r, colour.g, colour.b, 0.08))
		draw_circle(c, RIM_R + 2.0, Color("0b1433"))
		var segs := 64
		for i in segs:
			var a0 := TAU * float(i) / float(segs)
			var a1 := TAU * float(i + 1) / float(segs) + 0.02
			var shade := 0.6 + 0.3 * cos(a0 + 0.8 + PI)
			draw_arc(c, RIM_R - 9.0, a0, a1, 4, Color(shade, shade + 0.03, shade + 0.08), 20.0)
		draw_arc(c, RIM_R + 1.0, 0.0, TAU, 96, Color("0b1433"), 3.0, true)
		for i in 8:
			var p := c + Vector2.from_angle(TAU * float(i) / 8.0 + PI / 8.0) * (RIM_R - 9.0)
			draw_circle(p, 6.0, Color(0.32, 0.36, 0.45))
			draw_circle(p + Vector2(-1.2, -1.2), 3.6, Color(0.88, 0.9, 0.95))
		draw_arc(c, DISC_R + 1.0, 0.0, TAU, 96, colour, 6.0, true)
		draw_circle(c, DISC_R - 2.0, Color("bfe4ff"))
		for i in 6:
			draw_circle(c + Vector2(0, 40), 120.0 - float(i) * 16.0, Color(1, 1, 1, 0.06))


## The little triangle on top of Babel's bubble, pointing up.
class BubbleTail extends Control:
	var colour: Color = Color(0.56, 0.61, 0.95)
	var fill: Color = Color(0.08, 0.12, 0.29)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var tri := PackedVector2Array([Vector2(0, h), Vector2(w * 0.62, 0), Vector2(w, h)])
		draw_colored_polygon(tri, fill)
		draw_polyline(PackedVector2Array([Vector2(0, h - 3), Vector2(w * 0.62, 0), Vector2(w, h - 3)]), colour, 4.0, true)


class Icon extends Control:
	var kind: String = "pause":
		set(v):
			kind = v
			queue_redraw()
	var colour: Color = Color(0.93, 0.95, 1.0):
		set(v):
			colour = v
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
				var b := c + Vector2(0, -10)
				draw_arc(b, 20.0, deg_to_rad(120), deg_to_rad(420), 40, col, 5.0, true)
				draw_line(b + Vector2(-10, 17), b + Vector2(-10, 28), col, 5.0)
				draw_line(b + Vector2(10, 17), b + Vector2(10, 28), col, 5.0)
				draw_line(b + Vector2(-10, 34), b + Vector2(10, 34), col, 5.0)
				draw_line(b + Vector2(-5, 41), b + Vector2(5, 41), col, 5.0)
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

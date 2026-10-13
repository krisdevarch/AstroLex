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

	## A porthole as in the owner's mock v3: a soft glow and a bright ring in the suit colour, a
	## brushed metal rim with eight bolts, and a deep blue window behind the Catcher.
	func _draw() -> void:
		var c := size * 0.5
		for i in 10:
			draw_circle(c, RIM_R + 30.0 - float(i) * 3.0, Color(colour.r, colour.g, colour.b, 0.07))
		draw_circle(c, RIM_R + 4.0, colour)
		draw_circle(c, RIM_R - 4.0, Color("1b2333"))
		# Metal rim: a grey band, lighter on top, with a thin dark inner lip.
		draw_circle(c, RIM_R - 7.0, Color("8d97a6"))
		draw_arc(c, RIM_R - 18.0, PI * 1.1, PI * 1.9, 48, Color(1, 1, 1, 0.22), 14.0, true)
		draw_arc(c, RIM_R - 18.0, PI * 0.1, PI * 0.9, 48, Color(0, 0, 0, 0.16), 14.0, true)
		for i in 8:
			var d := Vector2.from_angle(TAU * float(i) / 8.0 - PI * 0.5)
			var bolt := c + d * (RIM_R - 18.0)
			draw_circle(bolt, 8.5, Color("3b4352"))
			draw_circle(bolt, 6.0, Color("a9b2bf"))
		draw_circle(c, DISC_R + 6.0, Color("39414f"))
		draw_circle(c, DISC_R, Color("2a4a86"))
		for i in 6:
			draw_circle(c + Vector2(0, -30), 130.0 - float(i) * 18.0, Color(0.6, 0.8, 1.0, 0.05))


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
				# The owner's tray mock: a warm glow on the orange button, a yellow bulb with a dark
				# ink outline and a white glint, on a grey screw base.
				var b := c + Vector2(0, -11)
				for i in 5:
					draw_circle(c + Vector2(0, -8), 44.0 - float(i) * 6.0, Color(1.0, 0.84, 0.3, 0.13))
				var ink := Color("4a2c0c")
				draw_circle(b, 25.0, ink)
				draw_circle(b, 20.5, Color("ffd23f"))
				draw_circle(b + Vector2(-3, -3), 13.0, Color("ffe682"))
				draw_arc(b, 13.5, deg_to_rad(195), deg_to_rad(255), 12, Color.WHITE, 4.5, true)
				draw_rect(Rect2(b.x - 13.0, b.y + 18.0, 26.0, 21.0), ink)
				draw_rect(Rect2(b.x - 9.5, b.y + 21.0, 19.0, 6.0), Color("c9cdd3"))
				draw_rect(Rect2(b.x - 9.5, b.y + 30.0, 19.0, 5.0), Color("a3a9b2"))
				draw_rect(Rect2(b.x - 5.0, b.y + 39.0, 10.0, 5.0), ink)
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

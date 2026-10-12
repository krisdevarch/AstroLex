extends RefCounted
## Procedural art for the in-round HUD (no image assets): Earth's night side, the porthole portrait
## frame, vector icons and the coral clock fill. Drawn in _draw; every size is a pixel at 1080 wide.

const PANEL_H := 560.0  # height of the night panel control
const CREST := 40.0  # local y of the highest point (so it sits PANEL_H - CREST above the bottom)
const EDGE_LEFT := 90.0
const EDGE_RIGHT := 130.0
const ATMOS := Color("8fe3ff")
const CORAL := Color("FF6B35")
const CORAL_LIGHT := Color("ff9a6e")
const CRIMSON := Color("ff3b5c")
const CRIMSON_LIGHT := Color("ff7a90")
const RIM_R := 178.0
const DISC_R := 160.0
const CLIP_SHADER := "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tc.a *= smoothstep(0.5, 0.49, length(UV - vec2(0.5)));\n\tCOLOR = c;\n}\n"


## A coral (or crimson) rounded bar fill: a 9-slice texture so the ends stay round at any length.
static func bar_fill_box(c1: Color, c2: Color) -> StyleBoxTexture:
	var w := 64
	var h := 28
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
	## Local y of the planet's curved top edge at x (width w): rises to a crest at the middle, eases down to the right.
	static func edge_y(x: float, w: float) -> float:
		var cx := w * 0.5
		if x <= cx:
			return lerpf(EDGE_LEFT, CREST, sin(x / cx * PI * 0.5))
		var u := (x - cx) / (w - cx)
		return lerpf(CREST, EDGE_RIGHT, 1.0 - cos(u * PI * 0.5))

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var top_c := Color("0f2f5c")
		var bot_c := Color("050b1e")
		var x := 0.0
		while x < w:
			var x2 := minf(x + 12.0, w)
			var y1 := NightPanel.edge_y(x, w)
			var y2 := NightPanel.edge_y(x2, w)
			var pts := PackedVector2Array([Vector2(x, y1), Vector2(x2 + 0.5, y2), Vector2(x2 + 0.5, h), Vector2(x, h)])
			var cols := PackedColorArray([_grad(y1, h, top_c, bot_c), _grad(y2, h, top_c, bot_c), bot_c, bot_c])
			draw_polygon(pts, cols)
			x = x2
		var line := PackedVector2Array()
		var lx := 0.0
		while lx <= w + 0.1:
			line.append(Vector2(lx, NightPanel.edge_y(lx, w)))
			lx += 8.0
		draw_polyline(line, Color(ATMOS.r, ATMOS.g, ATMOS.b, 0.07), 22.0, true)
		draw_polyline(line, Color(ATMOS.r, ATMOS.g, ATMOS.b, 0.16), 11.0, true)
		draw_polyline(line, ATMOS, 3.0, true)
		# City lights: coral dots just under the curve on the right half.
		for i in 11:
			var cxp := w * (0.56 + 0.040 * float(i)) + float((i * 7) % 5) * 3.0
			var cyp := NightPanel.edge_y(cxp, w) + 16.0 + float((i * 37) % 53)
			var rad := 2.5 + float(i % 3)
			draw_circle(Vector2(cxp, cyp), rad * 3.0, Color(CORAL.r, CORAL.g, CORAL.b, 0.14))
			draw_circle(Vector2(cxp, cyp), rad, CORAL)

	static func _grad(y: float, h: float, a: Color, b: Color) -> Color:
		return a.lerp(b, clampf((y - CREST) / (h - CREST), 0.0, 1.0))


class PortraitArt extends Control:
	var colour: Color = Color(0.55, 0.9, 1.0)

	func _draw() -> void:
		var c := size * 0.5
		for i in 6:
			draw_circle(c, RIM_R + 24.0 - float(i) * 4.0, Color(colour.r, colour.g, colour.b, 0.07))
		# Metal rim: a light grey ring, brighter at the upper left.
		var segs := 48
		for i in segs:
			var a0 := TAU * float(i) / float(segs)
			var a1 := TAU * float(i + 1) / float(segs) + 0.02
			var shade := 0.62 + 0.30 * cos(a0 + 0.8 + PI)
			draw_arc(c, RIM_R - 5.0, a0, a1, 4, Color(shade, shade + 0.02, shade + 0.06), 10.0)
		draw_arc(c, RIM_R - 14.0, 0.0, TAU, 96, colour, 8.0, true)
		draw_circle(c, DISC_R, Color("0a1030"))
		# Suit-colour glow low in the sky.
		for i in 7:
			draw_circle(c + Vector2(0, 28), 128.0 - float(i) * 16.0, Color(colour.r, colour.g, colour.b, 0.07))
		var stars := [Vector2(-92, -84), Vector2(-40, -118), Vector2(30, -96), Vector2(88, -60), Vector2(112, -10), Vector2(-120, -20), Vector2(60, -128), Vector2(-70, -40), Vector2(8, -60), Vector2(126, 40)]
		for i in stars.size():
			var s: Vector2 = stars[i]
			draw_circle(c + s, 1.6 + float(i % 3) * 0.5, Color(1, 1, 1, 0.5 + 0.1 * float(i % 4)))
		# Earth's dark curve at the bottom of the porthole.
		var top := PackedVector2Array()
		var bottom := PackedVector2Array()
		var ex := 0.0
		var ey := DISC_R + 70.0
		var er := 190.0
		var n := 24
		for i in n + 1:
			var dx := -DISC_R * 0.99 + 2.0 * DISC_R * 0.99 * float(i) / float(n)
			var y_d := sqrt(maxf(DISC_R * DISC_R - dx * dx, 0.0))
			var y_e := ey - sqrt(maxf(er * er - (dx - ex) * (dx - ex), 0.0))
			top.append(c + Vector2(dx, minf(y_e, y_d)))
			bottom.append(c + Vector2(dx, y_d))
		for i in n:
			if bottom[i].y - top[i].y < 0.5 and bottom[i + 1].y - top[i + 1].y < 0.5:
				continue
			draw_colored_polygon(PackedVector2Array([top[i], top[i + 1], bottom[i + 1] + Vector2(0, 0.5), bottom[i] + Vector2(0, 0.5)]), Color("060b22"))
		draw_polyline(top, Color(ATMOS.r, ATMOS.g, ATMOS.b, 0.55), 2.0, true)


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

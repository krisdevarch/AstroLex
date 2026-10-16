extends Control
## Crew portraits (WP-F.3): a round vector face per speaker, drawn inside a disc ring in the
## speaker's colour. Placeholder art, simple but distinct: Rhee (glasses, grey bun), Ade (big grin,
## cap), Kit (freckles, spiky hair), VANTA (visor, sharp jaw), Tomas (small boy, big eyes) and
## Babel (his sprite, cropped to the helmet). Unknown speakers get a plain face.

const BABEL_TEX := "res://art/babel/babel.png"
const BABEL_CROP := Rect2(80, 8, 260, 260)  # the helmet, in babel.png px
const INK := Color("1b2333")
const SKIN := Color("f2c6a0")
const WHOS := ["rhee", "ade", "kit", "vanta", "tomas", "babel"]

var who: String = ""
var colour: Color = Color.WHITE


func _draw() -> void:
	var c := size * 0.5
	var r := size.x * 0.5
	draw_circle(c, r, Color(0.06, 0.08, 0.16))
	var ri := r - 5.0
	draw_circle(c, ri, colour.darkened(0.45))
	if who == "babel":
		_babel(c, ri)
	else:
		call("_face_" + who if who in WHOS else "_face_plain", c, ri)
	draw_arc(c, r - 2.0, 0.0, TAU, 40, colour, 4.0, true)


func _eyes(c: Vector2, r: float, dx: float, y: float, er: float) -> void:
	for s in [-1.0, 1.0]:
		draw_circle(c + Vector2(dx * s * r, y * r), er * r, Color.WHITE if er > 0.13 else INK)
		if er > 0.13:
			draw_circle(c + Vector2(dx * s * r, y * r + er * r * 0.1), er * r * 0.62, INK)
			draw_circle(c + Vector2(dx * s * r - er * r * 0.2, y * r - er * r * 0.2), er * r * 0.2, Color.WHITE)


func _head(c: Vector2, r: float, skin: Color = SKIN) -> void:
	draw_circle(c + Vector2(0, r * 0.08), r * 0.62, skin)


func _face_plain(c: Vector2, r: float) -> void:
	_head(c, r)
	_eyes(c, r, 0.22, 0.0, 0.07)


func _face_rhee(c: Vector2, r: float) -> void:
	draw_circle(c + Vector2(0, -r * 0.72), r * 0.2, Color("b8bcc6"))  # bun
	_head(c, r, Color("e8bb94"))
	draw_arc(c + Vector2(0, r * 0.02), r * 0.64, PI * 1.05, PI * 1.95, 20, Color("b8bcc6"), r * 0.16, true)  # grey hair
	for s in [-1.0, 1.0]:  # round glasses
		draw_arc(c + Vector2(s * r * 0.24, r * 0.06), r * 0.17, 0.0, TAU, 20, Color("5a4630"), 3.0, true)
	draw_line(c + Vector2(-r * 0.07, r * 0.06), c + Vector2(r * 0.07, r * 0.06), Color("5a4630"), 3.0)
	_eyes(c, r, 0.24, 0.06, 0.05)
	draw_arc(c + Vector2(0, r * 0.28), r * 0.14, 0.2, PI - 0.2, 10, Color("9c4a3c"), 3.0, true)


func _face_ade(c: Vector2, r: float) -> void:
	_head(c, r, Color("b9855a"))
	_eyes(c, r, 0.22, -0.02, 0.06)
	draw_colored_polygon(_arc_pts(c + Vector2(0, r * 0.2), r * 0.3, 0.0, PI), Color.WHITE)  # big grin
	draw_arc(c + Vector2(0, r * 0.2), r * 0.3, 0.0, PI, 14, INK, 3.0, true)
	draw_arc(c + Vector2(0, -r * 0.1), r * 0.62, PI * 1.02, PI * 1.98, 20, Color("2f8f84"), r * 0.3, true)  # cap
	draw_rect(Rect2(c + Vector2(-r * 0.2, -r * 0.2), Vector2(r * 0.7, r * 0.1)), Color("2f8f84"))  # brim


func _face_kit(c: Vector2, r: float) -> void:
	for i in 7:  # spiky hair
		var a := PI * (1.1 + 0.13 * float(i))
		draw_colored_polygon(PackedVector2Array([c + Vector2.from_angle(a - 0.16) * r * 0.55, c + Vector2.from_angle(a) * r * 0.9, c + Vector2.from_angle(a + 0.16) * r * 0.55]), Color("8c4a2b"))
	_head(c, r, Color("f4cfae"))
	_eyes(c, r, 0.22, 0.0, 0.06)
	for s in [-1.0, 1.0]:  # freckles
		for k in 3:
			draw_circle(c + Vector2(s * r * (0.3 + 0.08 * float(k % 2)), r * (0.14 + 0.07 * float(k))), r * 0.025, Color("b8704a"))
	draw_arc(c + Vector2(0, r * 0.22), r * 0.14, 0.2, PI - 0.2, 10, Color("9c4a3c"), 3.0, true)


func _face_vanta(c: Vector2, r: float) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.6, -r * 0.4), c + Vector2(r * 0.6, -r * 0.4), c + Vector2(r * 0.46, r * 0.35), c + Vector2(0, r * 0.7), c + Vector2(-r * 0.46, r * 0.35)]), Color("c9a58a"))  # sharp jaw
	draw_rect(Rect2(c + Vector2(-r * 0.62, -r * 0.3), Vector2(r * 1.24, r * 0.3)), Color("1b1020"))  # visor
	draw_rect(Rect2(c + Vector2(-r * 0.5, -r * 0.22), Vector2(r * 1.0, r * 0.1)), Color("ff4a5e"))  # its glow
	draw_line(c + Vector2(-r * 0.15, r * 0.3), c + Vector2(r * 0.15, r * 0.3), Color("5a2a2a"), 3.0)


func _face_tomas(c: Vector2, r: float) -> void:
	draw_circle(c + Vector2(0, r * 0.1), r * 0.55, Color("f6d2b0"))  # a smaller head
	draw_arc(c + Vector2(0, r * 0.02), r * 0.56, PI * 1.05, PI * 1.95, 20, Color("3a2a22"), r * 0.18, true)
	_eyes(c, r, 0.2, 0.08, 0.17)  # big eyes
	draw_arc(c + Vector2(0, r * 0.38), r * 0.09, 0.2, PI - 0.2, 8, Color("9c4a3c"), 3.0, true)


func _babel(c: Vector2, ri: float) -> void:
	var tex: Texture2D = load(BABEL_TEX)
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in 40:
		var a := TAU * float(i) / 40.0
		pts.append(c + Vector2.from_angle(a) * ri)
		uvs.append((BABEL_CROP.get_center() + Vector2.from_angle(a) * BABEL_CROP.size * 0.5) / tex.get_size())
	draw_colored_polygon(pts, Color.WHITE, uvs, tex)


func _arc_pts(c: Vector2, rad: float, a0: float, a1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 13:
		pts.append(c + Vector2.from_angle(lerpf(a0, a1, float(i) / 12.0)) * rad)
	return pts

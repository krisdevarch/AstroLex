extends Control
## Crew portraits (WP-F.3, art WP-F.13a): each speaker is an illustrated bust (res://art/crew/<who>.png,
## vector sticker art in the style of the Catcher art, rendered from scripts/art/crew/*.svg) clipped to
## a disc inside a ring in the speaker's colour. Babel uses his sprite, cropped to the helmet. The
## Catcher's suits (WP-F.27) use their portrait busts. Unknown speakers get a plain face.

const BABEL_TEX := "res://art/babel/babel.png"
const BABEL_CROP := Rect2(80, 8, 260, 260)  # the helmet, in babel.png px
const CREW_TEX := "res://art/crew/%s.png"
const CREW := ["rhee", "ade", "kit", "vanta", "tomas"]
const SUIT_TEX := "res://brand/characters/%s.png"
const SUITS := ["wren", "juno", "ash", "pip"]
const CREW_FRAME := 0.92  # the bust PNGs are framed for a centred circle crop of this share
const INK := Color("1b2333")
const SKIN := Color("f2c6a0")

var who: String = ""
var colour: Color = Color.WHITE


static func crew_texture(name: String) -> Texture2D:
	return load(CREW_TEX % name) as Texture2D if name in CREW else null


func _draw() -> void:
	var c := size * 0.5
	var r := size.x * 0.5
	draw_circle(c, r, Color(0.06, 0.08, 0.16))
	var ri := r - 5.0
	draw_circle(c, ri, colour.darkened(0.45))
	if who == "babel":
		_disc_texture(c, ri, load(BABEL_TEX), BABEL_CROP)
	elif who in SUITS:
		var st := load(SUIT_TEX % who) as Texture2D
		_disc_texture(c, ri, st, Rect2(Vector2.ZERO, st.get_size()))
	elif who in CREW:
		var tex := crew_texture(who)
		_disc_texture(c, ri, tex, Rect2(tex.get_size() * (1.0 - CREW_FRAME) * 0.5, tex.get_size() * CREW_FRAME))
	else:
		_face_plain(c, ri)
	draw_arc(c, r - 2.0, 0.0, TAU, 40, colour, 4.0, true)


func _face_plain(c: Vector2, r: float) -> void:
	draw_circle(c + Vector2(0, r * 0.08), r * 0.62, SKIN)
	for s in [-1.0, 1.0]:
		draw_circle(c + Vector2(0.22 * s * r, 0.0), 0.07 * r, INK)


## Draws `crop` (a rect in texture px) as a disc of radius ri centred on c.
func _disc_texture(c: Vector2, ri: float, tex: Texture2D, crop: Rect2) -> void:
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in 40:
		var a := TAU * float(i) / 40.0
		pts.append(c + Vector2.from_angle(a) * ri)
		uvs.append((crop.get_center() + Vector2.from_angle(a) * crop.size * 0.5) / tex.get_size())
	draw_colored_polygon(pts, Color.WHITE, uvs, tex)

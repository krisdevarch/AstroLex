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

const HudArt := preload("res://scenes/hud_art.gd")

static var _clip: ShaderMaterial

var who: String = "":
	set(v):
		who = v
		_rebuild()
var colour: Color = Color.WHITE:
	set(v):
		colour = v
		queue_redraw()

var _bust: TextureRect
var _ring: Control


static func crew_texture(name: String) -> Texture2D:
	return load(CREW_TEX % name) as Texture2D if name in CREW else null


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rebuild()


func _ready() -> void:
	_rebuild()


## The bust is a clipped TextureRect (draw_colored_polygon with a texture does not show on web).
func _rebuild() -> void:
	if _bust == null:
		_bust = TextureRect.new()
		_bust.name = "Bust"
		_bust.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_bust.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_bust.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_bust.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _clip == null:
			_clip = HudArt.clip_material()
		_bust.material = _clip
		add_child(_bust)
		_ring = Control.new()
		_ring.name = "Ring"
		_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ring.draw.connect(_draw_ring)
		add_child(_ring)
	var ri := size.x * 0.5 - 5.0
	var c := size * 0.5
	_bust.position = c - Vector2(ri, ri)
	_bust.size = Vector2(ri, ri) * 2.0
	_bust.texture = _bust_texture()
	_bust.visible = _bust.texture != null
	_ring.position = Vector2.ZERO
	_ring.size = size
	queue_redraw()
	_ring.queue_redraw()


func _bust_texture() -> Texture2D:
	if who == "babel":
		return _region(load(BABEL_TEX) as Texture2D, BABEL_CROP)
	if who in SUITS:
		return load(SUIT_TEX % who) as Texture2D
	if who in CREW:
		var tex := crew_texture(who)
		return _region(tex, Rect2(tex.get_size() * (1.0 - CREW_FRAME) * 0.5, tex.get_size() * CREW_FRAME))
	return null


func _region(tex: Texture2D, r: Rect2) -> Texture2D:
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = r
	return at


func _draw() -> void:
	var c := size * 0.5
	var r := size.x * 0.5
	draw_circle(c, r, Color(0.06, 0.08, 0.16))
	var ri := r - 5.0
	draw_circle(c, ri, colour.darkened(0.45))
	if _bust == null or not _bust.visible:
		_face_plain(c, ri)


func _draw_ring() -> void:
	var r := size.x * 0.5
	_ring.draw_arc(_ring.size * 0.5, r - 2.0, 0.0, TAU, 40, colour, 4.0, true)


func _face_plain(c: Vector2, r: float) -> void:
	draw_circle(c + Vector2(0, r * 0.08), r * 0.62, SKIN)
	for s in [-1.0, 1.0]:
		draw_circle(c + Vector2(0.22 * s * r, 0.0), 0.07 * r, INK)

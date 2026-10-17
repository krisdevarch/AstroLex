extends RefCounted
## The Daily Signal share image (WP-F.6): a 1080x1080 navy card with the day's words in bubbles
## (dim when missed), the stars, the date and the time left. Drawn from Control nodes in a SubViewport;
## no art assets.

const Ui := preload("res://scenes/ui.gd")

const SIZE := 1080


## A SubViewport holding the card. Add it to the tree, wait two frames, then read png().
static func build(date: String, words: Array, words_done: int, stars: int, time_left: float) -> SubViewport:
	var vp := SubViewport.new()
	vp.name = "DailyImage"
	vp.size = Vector2i(SIZE, SIZE)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Ui.NAVY_DEEP
	bg.size = Vector2(SIZE, SIZE)
	vp.add_child(bg)
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", Ui.box(Color(Ui.NAVY, 1.0), 56, Ui.TEAL, 6))
	frame.position = Vector2(40, 40)
	frame.size = Vector2(SIZE - 80, SIZE - 80)
	vp.add_child(frame)
	_text(vp, "ASTROLEX", 110, Ui.CREAM, 80.0)
	_text(vp, "DAILY SIGNAL  ·  %s" % date, 48, Ui.TEAL, 205.0)
	for i in words.size():
		var done := i < words_done
		var pill := Panel.new()
		pill.add_theme_stylebox_override("panel", Ui.box(Color("15214d") if done else Color(0.08, 0.1, 0.18), 60, Ui.TEAL if done else Ui.SLATE, 5))
		pill.size = Vector2(560, 120)
		pill.position = Vector2((SIZE - 560) * 0.5, 300.0 + i * 140.0)
		vp.add_child(pill)
		var l := Ui.text(str(words[i]).to_upper(), 72, Ui.CREAM if done else Color(Ui.MUTED, 0.5))
		l.size = pill.size
		l.position = Vector2.ZERO
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pill.add_child(l)
	for i in 3:
		var s := Ui.StarIcon.new()
		s.filled = i < stars
		s.size = Vector2(110, 110)
		s.position = Vector2(SIZE * 0.5 + (i - 1) * 135.0 - 55.0, 870.0)
		vp.add_child(s)
	_text(vp, "%d s left" % int(ceil(maxf(time_left, 0.0))), 48, Ui.MUTED, 990.0)
	return vp


static func _text(vp: Node, t: String, size: int, col: Color, y: float) -> void:
	var l := Ui.text(t, size, col)
	l.position = Vector2(0, y)
	l.size = Vector2(SIZE, size * 1.3)
	vp.add_child(l)


## The rendered card as PNG bytes; empty when the renderer gives no image (headless).
static func png(vp: SubViewport) -> PackedByteArray:
	var tex := vp.get_texture()
	if tex == null:
		return PackedByteArray()
	var img := tex.get_image()
	if img == null or img.is_empty():
		return PackedByteArray()
	return img.save_png_to_buffer()

extends RefCounted
## Small UI helpers: placeholder styling built from StyleBoxFlat (no art assets yet).

const INK := Color(0.93, 0.95, 1.0)
const DIM := Color(0.6, 0.66, 0.8)
const ACCENT := Color(0.45, 0.8, 1.0)
const PANEL := Color(0.09, 0.12, 0.24, 0.92)


static func box(bg: Color, radius: int = 18, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(border_w)
	return s


static func label(text: String, size: int, color: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", maxi(2, size / 10))
	return l


static func button(text: String, size: int = 44, min_size: Vector2 = Vector2(420, 110), toggle: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = toggle
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_pressed_color", Color(0.04, 0.07, 0.16))
	b.add_theme_color_override("font_hover_pressed_color", Color(0.04, 0.07, 0.16))
	b.add_theme_stylebox_override("normal", box(PANEL, 20, Color(0.35, 0.45, 0.7), 3))
	b.add_theme_stylebox_override("hover", box(Color(0.13, 0.17, 0.32), 20, ACCENT, 3))
	b.add_theme_stylebox_override("pressed", box(ACCENT, 20, Color.WHITE, 3))
	b.add_theme_stylebox_override("hover_pressed", box(ACCENT, 20, Color.WHITE, 3))
	b.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), 20, Color.WHITE, 2))
	return b

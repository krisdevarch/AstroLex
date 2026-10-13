extends RefCounted
## The game's font (owner, 13 Oct 2026: "for the whole game use Libre Caslon Condensed"), set as the
## engine's fallback font at startup so every label, button and tile letter uses it. Set at runtime,
## not as the project's custom font: a fresh import loads that setting before the font is imported
## and logs a parse error.

const FONT := "res://fonts/ui_font.tres"


static func apply() -> void:
	var f := load(FONT) as Font
	if f == null:
		return
	if ThemeDB.fallback_font != f:
		ThemeDB.fallback_font = f
	var t := ThemeDB.get_default_theme()
	if t != null and t.default_font != f:
		t.default_font = f

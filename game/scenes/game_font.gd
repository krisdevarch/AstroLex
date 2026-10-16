extends RefCounted
## The game's font: Fredoka, a rounded sans matching the owner's mock v3 (owner, 13 Oct 2026), set as the
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


## Text size (Comfort setting, WP-F.9): Ui helpers multiply every font size by this. 1.2 when "Large".
const LARGE_SCALE := 1.2
static var ui_scale: float = 1.0
## High contrast letters (Comfort setting): tile glyphs get the thick ink halo (tile.glyphOutline).
static var high_contrast: bool = false


static func scaled(size: int) -> int:
	return roundi(float(size) * ui_scale)

extends Node2D
## Walking skeleton: proves the project imports, runs and exports on every platform in CI.
## WP-3.2 replaces it with the 2.5D field (plan §8.2).

const WORD := "ASTROLEX"
const TILE_SIZE := 104.0
const TILE_GAP := 18.0

func _ready() -> void:
	var view := get_viewport_rect().size
	var total := WORD.length() * TILE_SIZE + (WORD.length() - 1) * TILE_GAP
	var x0 := (view.x - total) / 2.0
	for i in WORD.length():
		var tile := _make_tile(WORD[i])
		var lift := 12.0 if i % 2 == 0 else -12.0
		tile.position = Vector2(x0 + i * (TILE_SIZE + TILE_GAP), view.y * 0.42 + lift)
		tile.rotation = deg_to_rad(float(i % 3 - 1) * 4.0)
		add_child(tile)

	var build := Label.new()
	build.name = "BuildLabel"
	build.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0")
	build.add_theme_font_size_override("font_size", 28)
	build.modulate = Color(1, 1, 1, 0.5)
	build.position = Vector2(view.x / 2.0 - 60.0, view.y - 120.0)
	add_child(build)
	# The web smoke test in CI waits for this line to prove the scene ran in a browser.
	print("AstroLex ready: %d tiles" % WORD.length())


func _make_tile(letter: String) -> Panel:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.96, 0.93)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 10
	style.shadow_offset = Vector2(6, 10)
	var tile := Panel.new()
	tile.name = "Tile_%s" % letter
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.pivot_offset = tile.size / 2.0
	tile.add_theme_stylebox_override("panel", style)

	var glyph := Label.new()
	glyph.text = letter
	glyph.size = tile.size
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_font_size_override("font_size", 64)
	glyph.add_theme_color_override("font_color", Color(0.05, 0.07, 0.16))
	tile.add_child(glyph)
	return tile

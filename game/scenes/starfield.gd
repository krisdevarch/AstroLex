extends Node2D
## Static procedural star backdrop (placeholder for the sector art).

const TileTextures := preload("res://scenes/tile_textures.gd")

var view_size: Vector2 = Vector2(1080, 1920)


## One full-screen sprite with the pre-baked placeholder sky, drawn behind the stars.
func _ready() -> void:
	var sky := Sprite2D.new()
	sky.name = "Sky"
	sky.texture = TileTextures.sky()
	sky.centered = false
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sky.scale = view_size / Vector2(sky.texture.get_size())
	sky.show_behind_parent = true
	add_child(sky)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	for i in 110:
		var p := Vector2(rng.randf() * view_size.x, rng.randf() * view_size.y)
		var b := rng.randf_range(0.25, 0.9)
		draw_circle(p, rng.randf_range(1.2, 3.2), Color(0.7 * b, 0.8 * b, b, 1.0))

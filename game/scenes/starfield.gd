extends Node2D
## Static procedural star backdrop (placeholder for the sector art).

const TileTextures := preload("res://scenes/tile_textures.gd")

var view_size: Vector2 = Vector2(1080, 1920)


## Two full-screen sprites: the pre-baked placeholder sky and the baked stars over it. The glass
## tiles sample the same two textures.
func _ready() -> void:
	var sky := Sprite2D.new()
	sky.name = "Sky"
	sky.texture = TileTextures.sky()
	sky.centered = false
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sky.scale = view_size / Vector2(sky.texture.get_size())
	sky.show_behind_parent = true
	add_child(sky)
	var stars := Sprite2D.new()
	stars.name = "Stars"
	stars.texture = TileTextures.stars()
	stars.centered = false
	stars.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	stars.scale = view_size / Vector2(stars.texture.get_size())
	add_child(stars)

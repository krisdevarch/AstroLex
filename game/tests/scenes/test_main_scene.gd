extends "res://tests/test_case.gd"


func test_main_scene_shows_the_title_tiles_and_build_label() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)  # runs _ready
	var tiles := main.get_children().filter(func(n: Node) -> bool: return n.name.begins_with("Tile_"))
	assert_eq(tiles.size(), 8, "one tile per letter of ASTROLEX")
	var label := main.get_node_or_null("BuildLabel") as Label
	assert_true(label != null, "build label exists")
	if label:
		assert_true(label.text.begins_with("v"), "build label shows the version")
	main.free()

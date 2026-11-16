extends "res://tests/test_case.gd"

const CrewArt := preload("res://scenes/crew_art.gd")

const IMPORTS := [
	"res://art/babel/babel.png.import",
	"res://art/crew/ade.png.import",
	"res://art/crew/rhee.png.import",
	"res://brand/characters/wren.png.import",
	"res://brand/characters/juno.png.import",
]


func _art(who: String, before_size: bool) -> Control:
	var a: Control = CrewArt.new()
	a.who = who
	if before_size:
		a.size = Vector2(110, 110)
	return a


func test_busts_are_clipped_mipmapped_texture_rects() -> void:
	for who in ["ade", "babel", "wren"]:
		var a := _art(who, true)
		var root := Node.new()
		(Engine.get_main_loop() as SceneTree).root.add_child(root)
		root.add_child(a)
		var t := a.get_node_or_null("Bust") as TextureRect
		assert_true(t != null and t.visible, who + " has a visible bust")
		if t:
			assert_true(t.texture != null, who + " texture")
			assert_true(t.material is ShaderMaterial, who + " clip material")
			assert_eq(t.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, who + " filter")
			assert_true(t.size.x > 90.0, who + " bust sized to disc")
		root.free()


func test_who_set_after_add_child_and_unknown_speaker() -> void:
	var a: Control = CrewArt.new()
	var root := Node.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(root)
	root.add_child(a)
	a.size = Vector2(130, 130)
	a.who = "ade"
	var t := a.get_node("Bust") as TextureRect
	assert_true(t.visible and t.texture != null)
	assert_true(t.size.x > 100.0)
	a.who = "nobody"
	assert_false(t.visible, "unknown speaker shows the plain face")
	root.free()


func test_imports_have_mipmaps_and_lossless() -> void:
	for p in IMPORTS:
		var f := FileAccess.open(p, FileAccess.READ)
		assert_true(f != null, p)
		if f:
			var txt := f.get_as_text()
			assert_true(txt.contains("mipmaps/generate=true"), p + " mipmaps")
			assert_true(txt.contains("compress/mode=0"), p + " lossless")

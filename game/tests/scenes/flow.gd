extends RefCounted
## Helpers for tests that drive main.gd through its screens. Not a test file.

const Save := preload("res://services/save.gd")


static func press(main: Node, node_name: String) -> bool:
	var b := main.find_child(node_name, true, false) as Button
	if b:
		b.pressed.emit()
	return b != null


static func has(main: Node, node_name: String) -> bool:
	return main.find_child(node_name, true, false) != null


## A main with a returning player (profile saved) and the given save, added to the tree.
static func returning(tree: SceneTree, save: RefCounted = null) -> Node:
	var s: RefCounted = save if save != null else Save.fake()
	if not s.has_profile():
		s.set_profile("wren", "they", "normal")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = s
	tree.root.add_child(main)
	return main


## Start -> map -> level `id` -> past the comms. Returns the field (or null).
static func to_field(main: Node, id: String = "1-01") -> Node:
	press(main, "StartButton")
	press(main, "Level_%s" % id)
	if has(main, "CommsScreen"):
		press(main, "SkipButton")
	return main.find_child("Field", true, false)

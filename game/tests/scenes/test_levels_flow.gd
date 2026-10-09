extends "res://tests/test_case.gd"

const FieldScene: PackedScene = preload("res://scenes/field.tscn")
const GameData := preload("res://rules/game_data.gd")


func _level(i: int) -> Dictionary:
	return GameData.load_content()["levels"]["act1_low_orbit"][i]


func _press(main: Node, node_name: String) -> void:
	var b := main.find_child(node_name, true, false) as Button
	assert_true(b != null, node_name + " exists")
	if b:
		b.pressed.emit()


func _to_field(main: Node) -> Node:
	_press(main, "StartButton")
	if main.find_child("CommsScreen", true, false) != null:
		_press(main, "SkipButton")
	return main.find_child("Field", true, false)


func test_start_shows_comms_then_level_1_01() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	_press(main, "StartButton")
	assert_true(main.find_child("CommsScreen", true, false) != null, "comms before level")
	_press(main, "SkipButton")
	var f := main.find_child("Field", true, false)
	assert_true(f != null, "field after skip")
	if f:
		assert_eq(f.game_round.level_id, "1-01", "level 1-01")
		assert_eq(main.level_index, 0, "index 0")
		var lab := f.find_child("LevelLabel", true, false) as Label
		assert_true(lab != null and lab.text.begins_with("1-01"), "HUD shows the level id")
	main.free()


func test_win_advances_and_loss_keeps_the_index() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	var f := _to_field(main)
	f.autoplay = true
	f.skip_intro()
	var steps := 0
	while not f.finished and steps < 300 * 60:
		f.advance(1.0 / 60.0)
		steps += 1
	assert_eq(f.game_round.state, "won", "bot wins 1-01")
	assert_eq(main.level_index, 1, "win moves to the next level")
	# commsAfter (if any), then the End screen offers Next level.
	if main.find_child("CommsScreen", true, false) != null:
		_press(main, "SkipButton")
	var again := main.find_child("PlayAgainButton", true, false) as Button
	assert_true(again != null and again.text == "Next level", "Next level offered")
	main.call("_on_level_finished", {"won": false}, _level(1))
	assert_eq(main.level_index, 1, "loss keeps the index")
	again = main.find_child("PlayAgainButton", true, false) as Button
	assert_true(again != null and again.text == "Retry", "Retry offered")
	main.free()


func test_last_level_won_completes_the_act() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	var n: int = main.levels.size()
	main.level_index = n - 1
	main.call("_on_level_finished", {"won": true}, _level(n - 1))
	if main.find_child("CommsScreen", true, false) != null:
		_press(main, "SkipButton")
	var t := main.find_child("EndTitle", true, false) as Label
	assert_true(t != null and t.text == "Act I complete", "act complete title")
	var again := main.find_child("PlayAgainButton", true, false) as Button
	assert_true(again != null and again.text == "Play again from 1-01", "restart button")
	main.free()


func test_comms_screen_skip_and_colours() -> void:
	var c: Control = load("res://scenes/comms_screen.gd").new()
	c.messages = [{"who": "rhee", "text": "Hello."}, {"who": "babel", "text": "No."}, {"who": "kit", "text": "Hi."}]
	var done := [0]
	c.finished.connect(func() -> void: done[0] += 1)
	tree.root.add_child(c)
	var names: Array = []
	for n in c.find_children("Speaker", "Label", true, false):
		names.append(n)
	assert_eq(names.size(), 3, "three speaker labels")
	assert_eq((names[0] as Label).get_theme_color("font_color"), Color("F8BC04"), "rhee colour")
	assert_eq((names[1] as Label).get_theme_color("font_color"), Color("7070FF"), "babel colour")
	assert_eq((names[2] as Label).get_theme_color("font_color"), Color("FF88CC"), "kit colour")
	assert_eq(c.shown_count(), 1, "one bubble at first")
	c.advance()
	c.advance()
	assert_eq(c.shown_count(), 3, "all shown after taps")
	(c.find_child("SkipButton", true, false) as Button).pressed.emit()
	(c.find_child("SkipButton", true, false) as Button).pressed.emit()
	assert_eq(done[0], 1, "finished emitted once")
	c.free()


func test_comms_reduced_motion_shows_all() -> void:
	var c: Control = load("res://scenes/comms_screen.gd").new()
	c.messages = [{"who": "ade", "text": "a"}, {"who": "vanta", "text": "b"}]
	c.reduced_motion = true
	tree.root.add_child(c)
	assert_eq(c.shown_count(), 2, "all at once")
	c.free()


func test_begin_level_uses_the_level_words_in_order() -> void:
	var lv := _level(0)
	var f: Node2D = FieldScene.instantiate()
	tree.root.add_child(f)
	f.begin_level("drift", lv)
	var words: Array = lv["words"]
	assert_eq(Array(f.game_round.words), words, "words in level order")
	assert_eq(f.game_round.level_id, "1-01", "level id")
	assert_eq(f.game_round.seed_value, int(lv["seed"]), "level seed")
	f.free()

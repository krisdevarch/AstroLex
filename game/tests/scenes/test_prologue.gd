extends "res://tests/test_case.gd"

const Flow := preload("res://tests/scenes/flow.gd")
const Save := preload("res://services/save.gd")
const Prologue := preload("res://scenes/prologue.gd")


## A new player up to the end of the difficulty pick.
func _new_player() -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = Save.fake()
	tree.root.add_child(main)
	Flow.press(main, "StartButton")
	Flow.press(main, "Character_wren")
	Flow.press(main, "ConfirmButton")
	Flow.press(main, "Difficulty_normal")
	Flow.press(main, "ConfirmButton")
	return main


func _play_through_stills(p: Node, upto: int) -> void:
	while p.index < upto:
		p.advance(p.current_seconds())


func test_new_player_sees_the_prologue_once_then_the_map() -> void:
	var main := _new_player()
	assert_true(Flow.has(main, "Prologue"), "prologue after the difficulty pick")
	assert_false(Flow.has(main, "LevelMap"), "not the map yet")
	var p: Node = main.find_child("Prologue", true, false)
	assert_false((main.find_child("PrologueSkip", true, false) as Control).visible, "no skip on the first still")
	_play_through_stills(p, 6)
	assert_true((main.find_child("PrologueSkip", true, false) as Control).visible, "skip from the second still on")
	assert_true(p.tile_waiting(), "the w tile on the last still")
	p.advance(2.0)
	p.tap()
	assert_true(p.sfx.played.has("fire"), "tether sound on the tap")
	p.advance(20.0)
	assert_true(Flow.has(main, "LevelMap"), "the map after the prologue")
	assert_true(main.save.flag("prologue_seen"), "remembered")
	main.free()
	# A returning player with the flag never sees it, even when picking a difficulty again.
	var s: RefCounted = Save.fake()
	s.set_profile("wren", "they", "normal")
	s.set_flag("prologue_seen")
	var again: Node = Flow.returning(tree, s)
	main = again
	main._prologue_then_map()
	assert_false(Flow.has(main, "Prologue"), "not shown twice")
	assert_true(Flow.has(main, "LevelMap"))
	main.free()


func test_skip_ends_the_prologue_and_saves_the_flag() -> void:
	var main := _new_player()
	var p: Node = main.find_child("Prologue", true, false)
	p.advance(p.current_seconds())
	assert_eq(p.index, 1)
	Flow.press(main, "PrologueSkip")
	assert_true(Flow.has(main, "LevelMap"), "map after skip")
	assert_true(main.save.flag("prologue_seen"))
	main.free()


func test_flag_persists_in_the_save_file() -> void:
	var path := "user://test_prologue_save.json"
	var s: RefCounted = Save.real(path)
	assert_false(s.flag("prologue_seen"))
	s.set_flag("prologue_seen")
	var back: RefCounted = Save.real(path)
	assert_true(back.flag("prologue_seen"), "flag reloaded")
	assert_false(back.flag("flashback_seen"))
	back.reset()
	assert_true(back.flag("prologue_seen"), "progress reset keeps it")
	DirAccess.remove_absolute(path)


func test_tapping_the_water_tile_ends_the_prologue() -> void:
	var p: Control = Prologue.new()
	p.stills = [Prologue.load_stills("prologue")[6]]
	tree.root.add_child(p)
	var finished: Array = []
	p.finished.connect(func(sk: bool) -> void: finished.append(sk))
	p.tap()
	assert_false(p.caught(), "nothing to catch before the tile drifts in")
	p.advance(1.5)
	p.tap()
	assert_true(p.caught(), "tapped")
	p.advance(0.3)
	assert_true(p.shown_letters() >= 1)
	p.advance(1.0)
	var sat: float = p.saturation()
	assert_true(sat > 0.0 and sat < 1.0, "colour is coming back")
	p.advance(10.0)
	assert_eq(p.shown_letters(), 5, "WATER spelled out")
	assert_eq(p.saturation(), 1.0)
	assert_eq(finished, [false], "finished, not skipped")
	p.free()


func test_flashback_plays_before_3_06_once_and_skips() -> void:
	var s: RefCounted = Save.fake()
	s.set_profile("wren", "they", "normal")
	s.set_flag("prologue_seen")
	var main: Node = Flow.returning(tree, s)
	main.act = "act3_tower"
	main.levels = main.dictionary.levels("act3_tower")
	main.level_index = 5
	assert_eq(str(main.levels[5]["id"]), "3-06")
	main._begin_level_with_comms()
	assert_true(Flow.has(main, "Prologue"), "flashback first")
	var p: Node = main.find_child("Prologue", true, false)
	assert_false(p.with_water, "no water ending")
	var total := 0.0
	for st: Dictionary in p.stills:
		total += float(st["seconds"])
	assert_true(total < 30.0 and p.stills.size() == 5, "five stills, under 30 s")
	assert_true(main._field() == null, "level not started yet")
	p.advance(p.current_seconds())
	Flow.press(main, "PrologueSkip")
	assert_true(s.flag("flashback_seen"))
	assert_true(main._field() != null, "level starts after it")
	main._begin_level_with_comms()
	assert_false(Flow.has(main, "Prologue"), "not twice")
	main.free()


func test_reduced_motion_has_no_drift() -> void:
	var calm: Control = Prologue.new()
	calm.reduced_motion = true
	tree.root.add_child(calm)
	calm.advance(3.0)
	assert_eq(calm.drift_scale(), 1.0, "no Ken Burns")
	calm.free()
	var moving: Control = Prologue.new()
	tree.root.add_child(moving)
	moving.advance(3.0)
	assert_true(moving.drift_scale() > 1.0, "drift with motion on")
	moving.free()

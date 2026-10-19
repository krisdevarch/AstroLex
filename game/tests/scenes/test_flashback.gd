extends "res://tests/test_case.gd"

const Flow := preload("res://tests/scenes/flow.gd")
const Save := preload("res://services/save.gd")
const Flashback := preload("res://scenes/flashback.gd")


func test_new_player_goes_straight_to_the_map() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = Save.fake()
	tree.root.add_child(main)
	Flow.press(main, "StartButton")
	Flow.press(main, "Character_wren")
	(main.find_child("NameInput", true, false) as LineEdit).text_changed.emit("Kit")
	Flow.press(main, "ConfirmButton")
	Flow.press(main, "Difficulty_normal")
	Flow.press(main, "ConfirmButton")
	assert_true(Flow.has(main, "LevelMap"), "the map right after the difficulty pick")
	assert_false(Flow.has(main, "AnimaticLayer"), "no Prologue")
	main.free()


func test_settings_has_no_prologue_replay() -> void:
	var s: RefCounted = Save.fake()
	s.set_profile("wren", "they", "normal", "Kit")
	var main: Node = Flow.returning(tree, s)
	main._show_settings(main._show_map)
	assert_true(Flow.has(main, "SettingsScreen"))
	assert_false(Flow.has(main, "PrologueButton"))
	main.free()


func test_flag_persists_in_the_save_file() -> void:
	var path := "user://test_flashback_save.json"
	var s: RefCounted = Save.real(path)
	assert_false(s.flag("flashback_seen"))
	s.set_flag("flashback_seen")
	var back: RefCounted = Save.real(path)
	assert_true(back.flag("flashback_seen"), "flag reloaded")
	back.reset()
	assert_true(back.flag("flashback_seen"), "progress reset keeps it")
	DirAccess.remove_absolute(path)


func test_flashback_plays_before_3_06_once_and_skips() -> void:
	var s: RefCounted = Save.fake()
	s.set_profile("wren", "they", "normal", "Kit")
	var main: Node = Flow.returning(tree, s)
	main.act = "act3_tower"
	main.levels = main.dictionary.levels("act3_tower")
	main.level_index = 5
	assert_eq(str(main.levels[5]["id"]), "3-06")
	main._begin_level_with_comms()
	assert_true(Flow.has(main, "Flashback"), "flashback first")
	var p: Node = main.find_child("Flashback", true, false)
	var total := 0.0
	for st: Dictionary in p.stills:
		total += float(st["seconds"])
	assert_true(total < 30.0 and p.stills.size() == 5, "five stills, under 30 s")
	assert_true(main._field() == null, "level not started yet")
	assert_false((main.find_child("FlashbackSkip", true, false) as Control).visible, "no skip on the first still")
	p.advance(p.current_seconds())
	Flow.press(main, "FlashbackSkip")
	assert_true(s.flag("flashback_seen"))
	assert_true(main._field() != null, "level starts after it")
	main._begin_level_with_comms()
	assert_false(Flow.has(main, "Flashback"), "not twice")
	main.free()


func test_flashback_ends_on_its_own() -> void:
	var p: Control = Flashback.new()
	tree.root.add_child(p)
	var finished: Array = []
	p.finished.connect(func(sk: bool) -> void: finished.append(sk))
	for i in 5:
		p.advance(p.current_seconds())
	assert_eq(finished, [false], "finished, not skipped")
	p.free()


func test_reduced_motion_has_no_drift() -> void:
	var calm: Control = Flashback.new()
	calm.reduced_motion = true
	tree.root.add_child(calm)
	calm.advance(3.0)
	assert_eq(calm.drift_scale(), 1.0, "no Ken Burns")
	calm.free()
	var moving: Control = Flashback.new()
	tree.root.add_child(moving)
	moving.advance(3.0)
	assert_true(moving.drift_scale() > 1.0, "drift with motion on")
	moving.free()

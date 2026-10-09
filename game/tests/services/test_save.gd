extends "res://tests/test_case.gd"

const Save := preload("res://services/save.gd")
const A := "act1_low_orbit"


func _paths() -> Array:
	return ["user://test_save_a.json", "user://test_save_a.json.tmp"]


func _clean() -> void:
	for p in _paths():
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _each(check: Callable) -> void:
	_clean()
	check.call(Save.fake())
	check.call(Save.real("user://test_save_a.json"))
	_clean()


func test_record_moves_next_on_and_loss_counts_a_play_only() -> void:
	_each(func(s: RefCounted) -> void:
		assert_eq(s.next_level(A), 0)
		s.record_level(A, "1-01", 0, false, 50)
		assert_eq(s.next_level(A), 0, "loss does not advance")
		var l: Dictionary = s.data()["progress"][A]["levels"]["1-01"]
		assert_eq(int(l["plays"]), 1)
		assert_eq(int(l["best_score"]), 0, "loss records no score")
		assert_true(not l["won"]["burst"], "not won")
		s.record_level(A, "1-01", 0, true, 300)
		assert_eq(s.next_level(A), 1)
		s.record_level(A, "1-01", 0, true, 200)
		assert_eq(s.next_level(A), 1, "replaying an earlier level never moves next back")
		l = s.data()["progress"][A]["levels"]["1-01"]
		assert_eq(int(l["best_score"]), 300, "best score keeps the max")
		assert_true(l["won"]["burst"], "won")
		assert_eq(int(l["plays"]), 3))


func test_act_complete_and_restart_keeps_scores() -> void:
	_each(func(s: RefCounted) -> void:
		s.record_level(A, "1-01", 0, true, 10)
		s.record_level(A, "1-02", 1, true, 20)
		assert_true(not s.act_complete(A, 3))
		assert_true(s.act_complete(A, 2))
		s.restart_act(A)
		assert_eq(s.next_level(A), 0)
		assert_true(not s.act_complete(A, 2))
		assert_eq(int(s.data()["progress"][A]["levels"]["1-02"]["best_score"]), 20)
		assert_true(s.data()["progress"][A]["levels"]["1-01"]["won"]["burst"]))


func test_reset_keeps_player_id() -> void:
	_each(func(s: RefCounted) -> void:
		var id: String = s.player_id()
		assert_eq(id.length(), 16)
		s.record_level(A, "1-01", 0, true, 10)
		s.reset()
		assert_eq(s.next_level(A), 0)
		assert_true((s.data()["progress"] as Dictionary).is_empty())
		assert_eq(s.player_id(), id))


func test_round_trip_survives_a_new_instance() -> void:
	_clean()
	var s: RefCounted = Save.real("user://test_save_a.json")
	s.record_level(A, "1-01", 0, true, 77)
	var again: RefCounted = Save.real("user://test_save_a.json")
	assert_eq(again.next_level(A), 1)
	assert_eq(again.player_id(), s.player_id())
	assert_eq(int(again.data()["progress"][A]["levels"]["1-01"]["best_score"]), 77)
	_clean()


func _write_raw(text: String) -> void:
	var f := FileAccess.open("user://test_save_a.json", FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_corrupt_or_unknown_files_start_fresh() -> void:
	for raw in ["{not json", "[1,2]", "", "{\"version\": 99, \"player_id\": \"x\", \"progress\": {}}", "{\"progress\": {}}", "{\"version\": 1, \"player_id\": \"abc\", \"progress\": 5}"]:
		_write_raw(raw)
		var s: RefCounted = Save.real("user://test_save_a.json")
		assert_eq(s.next_level(A), 0, "fresh for: %s" % raw)
		assert_eq(s.player_id().length(), 16, "new id for: %s" % raw)
	_clean()
	assert_eq(Save.real("user://test_save_a.json").next_level(A), 0, "missing file is fresh")
	_clean()


func test_version_1_file_loads() -> void:
	_write_raw("{\"version\": 1, \"player_id\": \"abc\", \"updated_at\": 1, \"progress\": {\"%s\": {\"next\": 4, \"levels\": {}}}}" % A)
	var s: RefCounted = Save.real("user://test_save_a.json")
	assert_eq(s.next_level(A), 4)
	assert_eq(s.player_id(), "abc")
	_clean()


func test_main_continues_from_the_saved_level() -> void:
	var s: RefCounted = Save.fake()
	for i in 4:
		s.record_level(A, "1-0%d" % (i + 1), i, true, 10)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = s
	tree.root.add_child(main)
	var start := main.find_child("StartButton", true, false) as Button
	assert_eq(start.text, "Continue  1-05")
	start.pressed.emit()
	var skip := main.find_child("SkipButton", true, false) as Button
	if skip:
		skip.pressed.emit()
	assert_eq(main.level_index, 4)
	var field := main.find_child("Field", true, false)
	assert_true(field != null, "field is up")
	main.free()


func test_main_offers_replay_after_act_one_and_settings_resets() -> void:
	var s: RefCounted = Save.fake()
	for i in 12:
		s.record_level(A, "1-%02d" % (i + 1), i, true, 10 + i)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = s
	tree.root.add_child(main)
	var start := main.find_child("StartButton", true, false) as Button
	assert_eq(start.text, "Play Act I again")
	main._show_settings()
	var reset := main.find_child("ResetButton", true, false) as Button
	assert_true(reset != null, "reset button")
	reset.pressed.emit()
	assert_true((main.find_child("ResetConfirm", true, false) as Control).visible, "confirm row")
	(main.find_child("ResetNo", true, false) as Button).pressed.emit()
	assert_eq(s.next_level(A), 12, "No keeps progress")
	reset.pressed.emit()
	(main.find_child("ResetYes", true, false) as Button).pressed.emit()
	assert_eq(s.next_level(A), 0, "Yes resets")
	main.free()
	var fresh: Node = load("res://scenes/main.tscn").instantiate()
	fresh.save = Save.fake()
	tree.root.add_child(fresh)
	assert_eq((fresh.find_child("StartButton", true, false) as Button).text, "Start")
	fresh.free()


func test_malformed_acts_and_levels_are_repaired() -> void:
	_write_raw("{\"version\": 1, \"player_id\": \"abc\", \"progress\": {\"%s\": \"garbage\", \"x\": {\"next\": 2, \"levels\": {\"1-01\": {\"best_score\": 5}, \"1-02\": 7}}}}" % A)
	var s: RefCounted = Save.real("user://test_save_a.json")
	assert_eq(s.next_level(A), 0)
	assert_eq(s.next_level("x"), 2)
	s.record_level("x", "1-01", 0, true, 9)
	s.record_level("x", "1-02", 1, false, 9)
	assert_eq(int(s.data()["progress"]["x"]["levels"]["1-01"]["best_score"]), 9)
	assert_eq(int(s.data()["progress"]["x"]["levels"]["1-02"]["plays"]), 1)
	_clean()


func test_stale_tmp_is_used_when_main_file_is_bad_and_removed_after_write() -> void:
	_clean()
	_write_raw("{broken")
	var f := FileAccess.open("user://test_save_a.json.tmp", FileAccess.WRITE)
	f.store_string("{\"version\": 1, \"player_id\": \"tmpid\", \"progress\": {\"%s\": {\"next\": 3, \"levels\": {}}}}" % A)
	f.close()
	var s: RefCounted = Save.real("user://test_save_a.json")
	assert_eq(s.next_level(A), 3)
	s.record_level(A, "1-04", 3, true, 1)
	assert_true(not FileAccess.file_exists("user://test_save_a.json.tmp"), "tmp removed")
	assert_eq(Save.real("user://test_save_a.json").next_level(A), 4)
	_clean()


func test_reset_in_settings_makes_start_begin_at_1_01() -> void:
	var s: RefCounted = Save.fake()
	for i in 4:
		s.record_level(A, "1-0%d" % (i + 1), i, true, 10)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = s
	tree.root.add_child(main)
	assert_eq(main.level_index, 4)
	main._show_settings()
	main.find_child("ResetButton", true, false).pressed.emit()
	main.find_child("ResetYes", true, false).pressed.emit()
	main.find_child("BackButton", true, false).pressed.emit()
	var start := main.find_child("StartButton", true, false) as Button
	assert_eq(start.text, "Start")
	start.pressed.emit()
	var skip := main.find_child("SkipButton", true, false) as Button
	if skip:
		skip.pressed.emit()
	assert_eq(main.level_index, 0)
	main.free()

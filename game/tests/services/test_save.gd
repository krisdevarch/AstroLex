extends "res://tests/test_case.gd"

const Save := preload("res://services/save.gd")
const Flow := preload("res://tests/scenes/flow.gd")
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
		assert_false(l["won"], "not won")
		s.record_level(A, "1-01", 0, true, 300, 2)
		assert_eq(s.next_level(A), 1)
		s.record_level(A, "1-01", 0, true, 200, 1)
		assert_eq(s.next_level(A), 1, "replaying an earlier level never moves next back")
		l = s.data()["progress"][A]["levels"]["1-01"]
		assert_eq(int(l["best_score"]), 300, "best score keeps the max")
		assert_true(l["won"], "won")
		assert_eq(int(l["best_stars"]), 2, "best stars keeps the max")
		assert_eq(int(l["plays"]), 3))


func test_act_complete_and_next_act_unlocks() -> void:
	_each(func(s: RefCounted) -> void:
		s.act_sizes = {A: 2, "act2_nebula": 3}
		assert_false(s.unlocked("act2_nebula", 0), "act 2 locked at first")
		s.record_level(A, "1-01", 0, true, 10, 3)
		assert_true(not s.act_complete(A, 2))
		assert_true(s.unlocked(A, 1), "1-02 open after 1-01")
		assert_false(s.unlocked(A, 2), "out of range")
		s.record_level(A, "1-02", 1, true, 20, 1)
		assert_true(s.act_complete(A, 2))
		assert_true(s.unlocked("act2_nebula", 0), "act 2 opens when act 1 is done")
		assert_false(s.unlocked("act2_nebula", 1), "but only its first level")
		assert_eq(s.stars(A, "1-01"), 3)
		assert_eq(s.total_stars(), 4))


func test_reset_keeps_player_id() -> void:
	_each(func(s: RefCounted) -> void:
		var id: String = s.player_id()
		assert_eq(id.length(), 16)
		s.set_profile("ash", "she", "hard")
		s.record_level(A, "1-01", 0, true, 10)
		s.reset()
		assert_true(s.has_profile(), "reset keeps the profile")
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


func test_main_continues_to_the_map_with_unlocked_levels() -> void:
	var s: RefCounted = Save.fake()
	for i in 4:
		s.record_level(A, "1-0%d" % (i + 1), i, true, 10)
	var main: Node = Flow.returning(tree, s)
	var start := main.find_child("StartButton", true, false) as Button
	assert_eq(start.text, "Continue")
	start.pressed.emit()
	assert_false((main.find_child("Level_1-05", true, false) as Button).disabled, "1-05 open")
	assert_true((main.find_child("Level_1-06", true, false) as Button).disabled, "1-06 locked")
	Flow.press(main, "Level_1-05")
	if Flow.has(main, "CommsScreen"):
		Flow.press(main, "SkipButton")
	assert_eq(main.level_index, 4)
	assert_true(Flow.has(main, "Field"), "field is up")
	main.free()


func test_settings_resets_progress_and_keeps_the_profile() -> void:
	var s: RefCounted = Save.fake()
	for i in 12:
		s.record_level(A, "1-%02d" % (i + 1), i, true, 10 + i)
	var main: Node = Flow.returning(tree, s)
	main._show_settings(main._show_start)
	var reset := main.find_child("ResetButton", true, false) as Button
	assert_true(reset != null, "reset button")
	reset.pressed.emit()
	assert_true((main.find_child("ResetConfirm", true, false) as Control).visible, "confirm row")
	(main.find_child("ResetNo", true, false) as Button).pressed.emit()
	assert_eq(s.next_level(A), 12, "No keeps progress")
	reset.pressed.emit()
	(main.find_child("ResetYes", true, false) as Button).pressed.emit()
	assert_eq(s.next_level(A), 0, "Yes resets")
	assert_true(Flow.has(main, "ChangeCharacterButton") and Flow.has(main, "ChangeDifficultyButton"), "change entries")
	main.free()


func test_reset_then_the_map_shows_only_1_01_open() -> void:
	var s: RefCounted = Save.fake()
	for i in 4:
		s.record_level(A, "1-0%d" % (i + 1), i, true, 10)
	var main: Node = Flow.returning(tree, s)
	main._show_settings(main._show_map)
	Flow.press(main, "ResetButton")
	Flow.press(main, "ResetYes")
	Flow.press(main, "BackButton")
	assert_true(Flow.has(main, "LevelMap"), "back goes to the map")
	assert_false((main.find_child("Level_1-01", true, false) as Button).disabled, "1-01 open")
	assert_true((main.find_child("Level_1-02", true, false) as Button).disabled, "1-02 locked")
	main.free()


func test_v1_save_migrates_to_v2() -> void:
	_write_raw("{\"version\": 1, \"player_id\": \"abc\", \"progress\": {\"%s\": {\"next\": 2, \"levels\": {\"1-01\": {\"best_score\": 90, \"won\": {\"drift\": true, \"pressure\": false}, \"plays\": 3}, \"1-02\": {\"best_score\": 0, \"won\": {\"drift\": false}, \"plays\": 1}}}}}" % A)
	var s: RefCounted = Save.real("user://test_save_a.json")
	assert_eq(int(s.data()["version"]), 2)
	assert_false(s.has_profile(), "v1 has no profile")
	assert_eq(s.next_level(A), 2)
	assert_eq(s.stars(A, "1-01"), 1, "a v1 win is one star")
	assert_eq(s.stars(A, "1-02"), 0)
	assert_eq(int(s.data()["progress"][A]["levels"]["1-01"]["best_score"]), 90)
	assert_true(s.data()["progress"][A]["levels"]["1-01"]["won"] == true)
	s.set_profile("pip", "he", "easy")
	var again: RefCounted = Save.real("user://test_save_a.json")
	assert_true(again.has_profile())
	assert_eq(again.profile()["character"], "pip")
	assert_eq(again.profile()["difficulty"], "easy")
	_clean()


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

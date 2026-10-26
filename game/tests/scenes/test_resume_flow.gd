extends "res://tests/test_case.gd"
## WP-F.20: the level being played is remembered; Continue and the recovery boot drop back into it.

const Flow := preload("res://tests/scenes/flow.gd")
const Save := preload("res://services/save.gd")

const A := "act1_low_orbit"


func _returning(s: RefCounted, recover: String = "") -> Node:
	if not s.has_profile():
		s.set_profile("wren", "they", "normal", "ADA")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = s
	main.daily_today = "2026-10-16"
	main.recover_override = recover
	tree.root.add_child(main)
	return main


func test_starting_a_level_sets_resume_and_finishing_clears_it() -> void:
	var s: RefCounted = Save.fake()
	var main := _returning(s)
	assert_true(s.resume().is_empty(), "nothing at the start screen")
	Flow.to_field(main, "1-01")
	assert_eq(s.resume(), {"act": A, "index": 0, "level_id": "1-01"})
	main._on_level_finished({"won": true, "stars": 2, "score": 80, "time_left": 10.0, "words_done": 4, "words_total": 4})
	assert_true(s.resume().is_empty(), "the level ended")
	main.free()


func test_quit_to_map_clears_resume() -> void:
	var s: RefCounted = Save.fake()
	var main := _returning(s)
	var f := Flow.to_field(main, "1-01")
	main._show_pause(f)
	Flow.press(main, "QuitButton")
	assert_true(Flow.has(main, "LevelMap"))
	assert_true(s.resume().is_empty(), "quit forgets the level")
	main.free()


func test_continue_with_resume_starts_that_level() -> void:
	var s: RefCounted = Save.fake()
	s.record_level(A, "1-01", 0, true, 50, 1)
	s.set_resume(A, 1, "1-02")
	var main := _returning(s)
	Flow.press(main, "StartButton")
	assert_true(Flow.has(main, "Field"), "straight into the field")
	assert_false(Flow.has(main, "LevelMap"), "not the map")
	assert_eq(main.telemetry._round["level"], "1-02")
	assert_eq(main.level_index, 1)
	main.free()


func test_continue_without_resume_opens_the_map() -> void:
	var main := _returning(Save.fake())
	Flow.press(main, "StartButton")
	assert_true(Flow.has(main, "LevelMap"))
	main.free()


func test_recovery_boot_skips_the_start_screen() -> void:
	var s: RefCounted = Save.fake()
	s.record_level(A, "1-01", 0, true, 50, 1)
	s.set_resume(A, 1, "1-02")
	var main := _returning(s, "1")
	assert_false(Flow.has(main, "StartScreen"), "no start screen")
	assert_true(Flow.has(main, "Field"))
	assert_eq(main.telemetry._round["level"], "1-02")
	assert_false(Flow.has(main, "StoryStrip"), "no chatter before the level")
	main.free()


func test_recovery_flag_without_resume_shows_the_start_screen() -> void:
	var main := _returning(Save.fake(), "1")
	assert_true(Flow.has(main, "StartScreen"))
	main.free()


func test_daily_does_not_set_resume() -> void:
	var s: RefCounted = Save.fake()
	var main := _returning(s)
	Flow.press(main, "DailyButton")
	assert_true(Flow.has(main, "Field"))
	assert_true(s.resume().is_empty(), "daily is not remembered")
	main.free()


func test_settings_from_pause_reports_the_current_level() -> void:
	var main := _returning(Save.fake())
	var f := Flow.to_field(main, "1-01")
	main._show_field_settings(f)
	assert_true(Flow.has(main, "ReportButton") and Flow.has(main, "CopyReportButton"))
	main.telemetry = load("res://services/telemetry.gd").fake()
	Flow.press(main, "ReportButton")
	var urls: Array = main.telemetry.opened_urls
	assert_eq(urls.size(), 1, "one issue opened")
	assert_true(str(urls[0]).contains("1-01") and str(urls[0]).contains("labels=bug"), "level in the report")
	Flow.press(main, "CopyReportButton")
	assert_true(main.telemetry.clipboard_text.contains("1-01"), "copied report names the level")
	main.free()

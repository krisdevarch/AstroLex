extends "res://tests/test_case.gd"

const Flow := preload("res://tests/scenes/flow.gd")
const Save := preload("res://services/save.gd")
const Daily := preload("res://rules/daily.gd")
const DailyRecord := preload("res://services/daily_record.gd")

const TODAY := "2026-10-16"


func _main(s: RefCounted = null) -> Node:
	var m := Flow.returning(tree, s)
	m.daily_today = TODAY
	return m


func _win(main: Node, stars: int = 3, left: float = 21.0) -> void:
	main._on_level_finished({"won": true, "stars": stars, "score": 80, "time_left": left, "words_done": 4, "words_total": 4})


func test_title_button_plays_the_days_level() -> void:
	var s: RefCounted = Save.fake()
	s.set_profile("wren", "they", "normal", "ADA")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = s
	main.daily_today = TODAY
	tree.root.add_child(main)
	assert_eq((main.find_child("DailyButton", true, false) as Button).text, "Daily Signal")
	Flow.press(main, "DailyButton")
	var f := main.find_child("Field", true, false)
	assert_true(f != null, "the field is up")
	assert_eq(f.game_round.level_id, "daily-%s" % TODAY)
	assert_eq(Array(f.game_round.words), Daily.words_for(TODAY, main.dictionary.content()))
	assert_eq(main.telemetry._round["act"], "daily", "telemetry act")
	assert_eq(main.telemetry._round["level"], "daily-%s" % TODAY, "telemetry level")
	main.free()


func test_new_player_picks_a_catcher_first() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = Save.fake()
	main.daily_today = TODAY
	tree.root.add_child(main)
	Flow.press(main, "DailyButton")
	assert_true(Flow.has(main, "CharacterSelect"), "character first")
	Flow.press(main, "Character_ash")
	(main.find_child("NameInput", true, false) as LineEdit).text_changed.emit("Ada")
	Flow.press(main, "ConfirmButton")
	Flow.press(main, "ConfirmButton")  # difficulty
	assert_true(Flow.has(main, "Field"), "then the daily level")
	assert_eq(main.daily_date, TODAY)
	main.free()


func test_map_has_a_signal_button() -> void:
	var main := _main()
	Flow.press(main, "StartButton")
	assert_true(Flow.has(main, "DailyButton"), "round button on the top bar")
	Flow.press(main, "DailyButton")
	assert_true(Flow.has(main, "Field"), "plays the daily")
	main.free()


func test_result_card_save_streak_and_replay() -> void:
	var s: RefCounted = Save.fake()
	var main := _main(s)
	Flow.press(main, "DailyButton")
	var f := main.find_child("Field", true, false)
	_win(main, 2, 21.0)
	assert_true(Flow.has(main, "ShareButton"), "Share on the card")
	assert_true(Flow.has(main, "BackButton"), "Back on the card")
	assert_true(Flow.has(main, "DailyLine"), "Babel's line")
	assert_false(Flow.has(main, "NextButton"), "no Next")
	var card: Control = f.card()
	assert_true(card.share_text().contains("★★☆"), "stars in the share text")
	assert_true(card.share_text().contains("🟦🟦🟦🟦"), "all four restored")
	assert_eq(card.on_share(), "copied", "no share sheet here: copied")
	assert_eq(DailyRecord.result(s, TODAY)["stars"], 2)
	assert_eq(DailyRecord.streak(s, TODAY), 1)
	assert_eq(s.total_stars(), 0, "daily stars are not map stars")
	Flow.press(main, "BackButton")
	assert_true(Flow.has(main, "StartScreen"), "Back goes to the title")
	assert_eq((main.find_child("DailyButton", true, false) as Button).text, "Daily Signal · done")
	assert_true(Flow.has(main, "DailyStreak"), "the streak line")
	# Replay the same day: allowed, streak unchanged.
	Flow.press(main, "DailyButton")
	_win(main, 3, 30.0)
	assert_eq(DailyRecord.streak(s, TODAY), 1, "a replay does not change the streak")
	assert_eq(DailyRecord.result(s, TODAY)["stars"], 3, "the better run is kept")
	# Tomorrow extends it.
	main.daily_today = Daily.shift(TODAY, 1)
	Flow.press(main, "BackButton")
	Flow.press(main, "DailyButton")
	_win(main, 1, 5.0)
	assert_eq(DailyRecord.streak(s, main.daily_today), 2, "the next day makes two")
	main.free()


func test_daily_leaves_the_map_progress_alone() -> void:
	var s: RefCounted = Save.fake()
	var main := _main(s)
	Flow.press(main, "DailyButton")
	_win(main)
	assert_eq(s.next_level("act1_low_orbit"), 0)
	assert_eq(s.next_level("act2_nebula"), 0)
	Flow.press(main, "BackButton")
	Flow.press(main, "StartButton")
	assert_eq(main.daily_date, "", "the map is not a daily run")
	main.free()

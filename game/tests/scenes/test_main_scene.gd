extends "res://tests/test_case.gd"

const Flow := preload("res://tests/scenes/flow.gd")


func test_start_screen_shows_title_and_start() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)  # runs _ready
	var title := main.find_child("Title", true, false) as Label
	assert_true(title != null and title.text == "ASTROLEX", "title reads ASTROLEX")
	assert_true(main.find_child("DriftButton", true, false) == null, "no mode choice")
	assert_true(main.find_child("StartButton", true, false) != null, "Start button")
	assert_true(main.find_child("SettingsButton", true, false) != null, "Settings button")
	main.free()


func test_start_leads_to_the_field_and_shows_the_time_bar() -> void:
	var main: Node = Flow.returning(tree)
	var field := Flow.to_field(main)
	assert_true(field != null, "field is up after Start")
	if field:
		var bar := field.find_child("TimeBar", true, false) as Control
		assert_true(bar != null and bar.visible, "time bar")
		assert_eq(field.game_round.mode, "burst", "burst mode")
	main.free()


func test_level_card_shows_the_stars_and_the_numbers() -> void:
	var card: Control = load("res://scenes/level_card.gd").new()
	card.summary = {"won": true, "score": 812, "words_done": 4, "words_total": 4, "time_left": 8.2, "stars": 2}
	tree.root.add_child(card)
	assert_eq((card.find_child("EndTitle", true, false) as Label).text, "Sector cleared")
	assert_eq((card.find_child("ScoreStat", true, false) as Label).text, "Score 812   ·   9 s left")
	assert_eq(card.stars_earned(), 2, "two stars earned")
	assert_eq(card.stars_shown(), 0, "the stars are still to fly in")
	for _i in 120:
		card.tick(1.0 / 30.0)
	assert_eq(card.stars_shown(), 2, "both stars landed")
	assert_true(card.find_child("Star_1", true, false).get("filled") and not card.find_child("Star_2", true, false).get("filled"), "the third socket stays empty")
	assert_true(card.find_child("NextButton", true, false) != null, "next after a win")
	assert_true(card.find_child("RetryButton", true, false) != null and card.find_child("MapButton", true, false) != null, "retry and map")
	card.free()

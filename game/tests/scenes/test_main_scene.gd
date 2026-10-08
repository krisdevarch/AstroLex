extends "res://tests/test_case.gd"


func test_start_screen_shows_title_and_both_modes() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)  # runs _ready
	var title := main.find_child("Title", true, false) as Label
	assert_true(title != null and title.text == "ASTROLEX", "title reads ASTROLEX")
	var drift := main.find_child("DriftButton", true, false) as Button
	var pressure := main.find_child("PressureButton", true, false) as Button
	assert_true(drift != null and drift.text == "Drift", "Drift choice")
	assert_true(pressure != null and pressure.text == "Pressure", "Pressure choice")
	assert_true(main.find_child("StartButton", true, false) != null, "Start button")
	assert_true(main.find_child("SettingsButton", true, false) != null, "Settings button")
	main.free()


func test_start_leads_to_the_field_and_pressure_shows_the_oxygen_bar() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(main)
	(main.find_child("PressureButton", true, false) as Button).button_pressed = true
	(main.find_child("PressureButton", true, false) as Button).pressed.emit()
	(main.find_child("StartButton", true, false) as Button).pressed.emit()
	var field := main.find_child("Field", true, false)
	assert_true(field != null, "field is up after Start")
	if field:
		var bar := field.find_child("OxygenBar", true, false) as Control
		assert_true(bar != null and bar.visible, "oxygen bar in Pressure")
		assert_eq(field.game_round.mode, "pressure", "mode carried over")
	main.free()


func test_end_screen_lists_the_numbers() -> void:
	var end: Control = load("res://scenes/end_screen.gd").new()
	end.summary = {"won": true, "mode": "drift", "score": 812, "words_done": 4, "words_total": 4, "secs": 75.0, "catches": 20, "wrong": 1, "babel": "you are not that"}
	tree.root.add_child(end)
	assert_eq((end.find_child("EndTitle", true, false) as Label).text, "Sector cleared")
	assert_eq((end.find_child("ScoreStat", true, false) as Label).text, "Score  812")
	assert_eq((end.find_child("WordsStat", true, false) as Label).text, "Words  4/4")
	assert_eq((end.find_child("TimeStat", true, false) as Label).text, "Time  1:15")
	assert_true(end.find_child("PlayAgainButton", true, false) != null, "play again")
	assert_true(end.find_child("ModeSwitchButton", true, false) != null, "mode switch")
	end.free()

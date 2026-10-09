extends "res://tests/test_case.gd"

const Flow := preload("res://tests/scenes/flow.gd")
const Save := preload("res://services/save.gd")
const GameData := preload("res://rules/game_data.gd")


func _level(act: String, i: int) -> Dictionary:
	return GameData.load_content()["levels"][act][i]


func _won_through(s: RefCounted, act: String, n: int) -> void:
	var lv: Array = GameData.load_content()["levels"][act]
	for i in n:
		s.record_level(act, str(lv[i]["id"]), i, true, 10, 2)


func test_new_player_reaches_the_map_with_a_profile_saved() -> void:
	var s: RefCounted = Save.fake()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = s
	tree.root.add_child(main)
	assert_eq((main.find_child("StartButton", true, false) as Button).text, "New game")
	Flow.press(main, "StartButton")
	assert_true(Flow.has(main, "CharacterSelect"), "character select first")
	for id in ["wren", "juno", "ash", "pip"]:
		assert_true(Flow.has(main, "Swatch_%s" % id) and Flow.has(main, "Character_%s" % id), "card %s" % id)
	Flow.press(main, "Character_ash")
	Flow.press(main, "Pronoun_she")
	Flow.press(main, "ConfirmButton")
	assert_true(Flow.has(main, "DifficultySelect"), "difficulty next")
	Flow.press(main, "Difficulty_hard")
	Flow.press(main, "ConfirmButton")
	assert_true(Flow.has(main, "LevelMap"), "map after the two choices")
	assert_true(s.has_profile(), "profile saved")
	assert_eq(s.profile(), {"character": "ash", "pronouns": "she", "difficulty": "hard"})
	assert_eq(main._mods().size(), 2, "difficulty and character mods")
	main.free()


func test_map_shows_four_acts_locks_and_stars() -> void:
	var s: RefCounted = Save.fake()
	s.set_profile("wren", "they", "normal")
	s.record_level("act1_low_orbit", "1-01", 0, true, 50, 3)
	var main: Node = Flow.returning(tree, s)
	Flow.press(main, "StartButton")
	for a in ["act1_low_orbit", "act2_nebula", "act3_tower", "act4_core"]:
		assert_true(Flow.has(main, "ActTitle_%s" % a), a)
	assert_eq((main.find_child("ActTitle_act2_nebula", true, false) as Label).text, "Act II · The Nebula")
	assert_eq((main.find_child("ActTitle_act4_core", true, false) as Label).text, "Act IV · Babel Core")
	assert_true((main.find_child("Level_1-01", true, false) as Button).text.contains("***"), "3 stars shown")
	assert_false((main.find_child("Level_1-02", true, false) as Button).disabled, "1-02 open")
	assert_true((main.find_child("Level_1-03", true, false) as Button).disabled, "1-03 locked")
	assert_true((main.find_child("Level_2-01", true, false) as Button).disabled, "act 2 locked")
	assert_eq((main.find_child("StarsTotal", true, false) as Label).text, "Stars  3")
	assert_true(main.find_child("MapScroll", true, false) is ScrollContainer, "scrollable")
	Flow.press(main, "CharacterButton")
	assert_true(Flow.has(main, "CharacterSelect"), "change character from the map")
	Flow.press(main, "BackButton")
	assert_true(Flow.has(main, "LevelMap"), "back returns to the map")
	Flow.press(main, "DifficultyButton")
	assert_true(Flow.has(main, "DifficultySelect"))
	Flow.press(main, "ConfirmButton")
	assert_true(Flow.has(main, "LevelMap"))
	Flow.press(main, "BackButton")
	assert_true(Flow.has(main, "StartScreen"), "back to start")
	main.free()


func test_last_level_of_an_act_unlocks_the_next_act() -> void:
	var s: RefCounted = Save.fake()
	_won_through(s, "act1_low_orbit", 11)
	var main: Node = Flow.returning(tree, s)
	Flow.to_field(main, "1-12")
	main.call("_on_level_finished", {"won": true, "stars": 2, "score": 99}, _level("act1_low_orbit", 11))
	if Flow.has(main, "CommsScreen"):
		Flow.press(main, "SkipButton")
	assert_true(Flow.has(main, "NextButton"), "end screen")
	assert_true(s.unlocked("act2_nebula", 0), "act 2 open")
	Flow.press(main, "NextButton")
	assert_true(Flow.has(main, "ActComplete"), "act complete screen")
	Flow.press(main, "NextActButton")
	if Flow.has(main, "CommsScreen"):
		Flow.press(main, "SkipButton")
	var f := main.find_child("Field", true, false)
	assert_true(f != null and f.game_round.level_id == "2-01", "act 2 starts at 2-01")
	main.free()


func test_winning_4_12_shows_beta_complete() -> void:
	var s: RefCounted = Save.fake()
	for a in ["act1_low_orbit", "act2_nebula", "act3_tower"]:
		_won_through(s, a, 12)
	_won_through(s, "act4_core", 11)
	var main: Node = Flow.returning(tree, s)
	Flow.to_field(main, "4-12")
	main.call("_on_level_finished", {"won": true, "stars": 3, "score": 99}, _level("act4_core", 11))
	if Flow.has(main, "CommsScreen"):
		Flow.press(main, "SkipButton")
	assert_true(Flow.has(main, "BetaComplete"), "beta complete screen")
	assert_eq((main.find_child("BetaMessage", true, false) as Label).text, "You restored every word in the beta. Story, art and music are on the way.")
	assert_eq((main.find_child("TotalStars", true, false) as Label).text, "Total stars  %d" % s.total_stars())
	Flow.press(main, "MapButton")
	assert_true(Flow.has(main, "LevelMap"), "back to map")
	main.free()


func test_pause_menu_resume_restart_and_quit() -> void:
	var main: Node = Flow.returning(tree)
	var f := Flow.to_field(main)
	main._show_pause(f)
	assert_true(Flow.has(main, "PauseMenu"), "pause overlay")
	Flow.press(main, "ResumeButton")
	assert_true(main.pause_menu == null, "resume closes the menu")
	assert_true(main.find_child("Field", true, false) == f, "same field")
	main._show_pause(f)
	Flow.press(main, "RestartButton")
	assert_true(main.pause_menu == null, "restart closes the menu")
	var f2 := main.find_child("Field", true, false)
	assert_true(f2 != null, "restart builds a field")
	main._show_pause(f2)
	Flow.press(main, "QuitButton")
	assert_true(Flow.has(main, "LevelMap"), "quit goes to the map")
	main.free()


func test_field_gets_character_colour_and_content_when_supported() -> void:
	var s: RefCounted = Save.fake()
	s.set_profile("juno", "he", "easy")
	var main: Node = Flow.returning(tree, s)
	var f := Flow.to_field(main)
	if "tether_colour" in f:
		assert_eq(f.tether_colour, Color("#f2b544"), "juno colour")
	if "content_override" in f:
		assert_false(f.content_override.is_empty(), "content override passed")
	main.free()

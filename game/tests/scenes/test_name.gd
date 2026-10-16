extends "res://tests/test_case.gd"

const Flow := preload("res://tests/scenes/flow.gd")
const Save := preload("res://services/save.gd")
const GameData := preload("res://rules/game_data.gd")
const PlayerName := preload("res://rules/player_name.gd")
const RoundScript := preload("res://rules/round.gd")
const Ending := preload("res://scenes/ending.gd")
const Main := preload("res://scenes/main.gd")


func _bad_name() -> String:
	var bl: Array = GameData.load_content()["blocklist"]
	return str(bl.filter(func(w: String) -> bool: return w.length() >= 3 and w.length() <= 8)[0])


func test_clean_strips_to_upper_az_and_cuts_at_eight() -> void:
	assert_eq(PlayerName.clean("a-d4 a!"), "ADA")
	assert_eq(PlayerName.clean("abcdefghijk"), "ABCDEFGH")
	assert_eq(PlayerName.clean("1234"), "")


func test_validation_needs_three_letters_and_an_unblocked_name() -> void:
	var bl: Array = GameData.load_content()["blocklist"]
	assert_false(bl.is_empty(), "blocklist exported")
	assert_false(PlayerName.long_enough("AB"))
	assert_true(PlayerName.long_enough("ABC"))
	assert_true(PlayerName.blocked(_bad_name().to_upper(), bl), "a blocklisted name is blocked")
	assert_false(PlayerName.blocked("ADA", bl))


func test_character_screen_gates_suit_up_on_the_name() -> void:
	var s: RefCounted = Save.fake()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = s
	tree.root.add_child(main)
	Flow.press(main, "StartButton")
	var ok := main.find_child("ConfirmButton", true, false) as Button
	var input := main.find_child("NameInput", true, false) as LineEdit
	assert_true(ok.disabled, "disabled with no name")
	assert_eq(input.placeholder_text, "Your name")
	input.text_changed.emit("a1b")
	assert_eq(input.text, "AB", "non-letters stripped, upper-case")
	assert_true(ok.disabled, "two letters is not enough")
	input.text_changed.emit(_bad_name())
	assert_true(ok.disabled, "blocked")
	assert_eq((main.find_child("NameWarning", true, false) as Label).text, "Pick another name")
	input.text_changed.emit("Ada")
	assert_false(ok.disabled)
	main.free()


func test_save_stores_and_migrates_the_name() -> void:
	var s: RefCounted = Save.fake()
	s.set_profile("ash", "she", "hard", "ADA")
	assert_eq(s.player_name(), "ADA")
	var old: Dictionary = Save._migrate({"version": 2, "player_id": "abc", "progress": {}, "profile": {"character": "pip", "pronouns": "he", "difficulty": "easy"}})
	assert_eq(int(old["version"]), 3)
	assert_eq(old["profile"], {"character": "pip", "pronouns": "he", "difficulty": "easy", "name": ""})


func test_old_save_without_a_name_is_asked_on_the_map() -> void:
	var s: RefCounted = Save.fake()
	s.set_profile("wren", "they", "normal", "")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = s
	tree.root.add_child(main)
	Flow.press(main, "StartButton")
	assert_true(Flow.has(main, "CharacterSelect"), "asked for the name")
	assert_false(Flow.has(main, "BackButton"), "no way round it")
	(main.find_child("NameInput", true, false) as LineEdit).text_changed.emit("Bob")
	Flow.press(main, "ConfirmButton")
	assert_eq(s.player_name(), "BOB")
	assert_true(Flow.has(main, "LevelMap"))
	main.free()


func test_4_12_words_are_listen_then_the_name() -> void:
	var lv: Dictionary = GameData.load_content()["levels"]["act4_core"][11]
	assert_eq(lv["id"], "4-12")
	assert_eq(lv["words"], ["listen", "name"], "the file keeps listen and a placeholder")
	var f: Dictionary = Main.finale_level(lv, "Ada")
	assert_eq(f["words"], ["listen", "ada"])
	assert_eq(lv["words"], ["listen", "name"], "the original is untouched")
	var s: RefCounted = Save.fake()
	s.set_profile("wren", "they", "normal", "MARLO")
	for a in ["act1_low_orbit", "act2_nebula", "act3_tower"]:
		for i in 12:
			s.record_level(a, "x%d" % i, i, true, 1, 1)
	for i in 11:
		s.record_level("act4_core", "y%d" % i, i, true, 1, 1)
	var main: Node = Flow.returning(tree, s)
	var field := Flow.to_field(main, "4-12")
	assert_eq(field.game_round.words, PackedStringArray(["listen", "marlo"]))
	assert_true(field.game_round.finale)
	field.settings.hint = "none"
	assert_true(field._name_row("preview"), "the name is the preview row first")
	assert_false(field._name_row("active"))
	main.free()


func test_finale_babel_lines() -> void:
	var content := GameData.load_content()
	var lv: Dictionary = Main.finale_level(content["levels"]["act4_core"][11], "Ada")
	var r = RoundScript.create_level(GameData.load_tunables(), content, "act4_core", lv)
	assert_eq(r.words, PackedStringArray(["listen", "ada"]))
	r.restored_words = PackedStringArray(["listen"])
	assert_eq(r._finale_line("listen"), "SILENT. No. LISTEN.")
	r.restored_words = PackedStringArray(["listen", "ada"])
	assert_eq(r._finale_line("ada"), "ADA. I hear you.")


func test_ending_names_the_catcher_in_tomas_text() -> void:
	var e: Control = Ending.new()
	e.player_name = "ADA"
	e.total_stars = 40
	tree.root.add_child(e)
	assert_eq(e.cards.size(), 3)
	assert_true(str(e.cards[0]["text"]).contains("Listen"), "Rhee first")
	var text := e.find_child("EndingText", true, false) as Label
	e.advance()
	assert_true(text.text.contains("Thank you, Ada."), "Tomas names the Catcher")
	e.advance()
	assert_eq(text.text, "Every word is home.")
	e.advance()
	assert_true(e.credits_shown)
	assert_eq((e.find_child("TotalStars", true, false) as Label).text, "Total stars  40")
	assert_true(e.find_child("CreditsText", true, false) != null)
	var got := [false]
	e.back_to_map.connect(func() -> void: got[0] = true)
	(e.find_child("MapButton", true, false) as Button).pressed.emit()
	assert_true(got[0])
	e.free()


func test_ending_reduced_motion_has_no_sweep() -> void:
	var e: Control = Ending.new()
	e.reduced_motion = true
	tree.root.add_child(e)
	assert_eq((e.find_child("Band_1", true, false) as Control).position.x, 0.0)
	e.free()

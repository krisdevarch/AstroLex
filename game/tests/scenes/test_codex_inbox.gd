extends "res://tests/test_case.gd"

const Flow := preload("res://tests/scenes/flow.gd")
const Save := preload("res://services/save.gd")
const GameData := preload("res://rules/game_data.gd")
const StoryData := preload("res://rules/story_data.gd")

const ACTS := ["act1_low_orbit", "act2_nebula", "act3_tower", "act4_core"]


func _win(s: RefCounted, act: String, n: int) -> void:
	var lv: Array = GameData.load_content()["levels"][act]
	for i in n:
		s.record_level(act, str(lv[i]["id"]), i, true, 10, 2)


func _save() -> RefCounted:
	var s: RefCounted = Save.fake()
	s.set_profile("wren", "they", "normal")
	return s


func _text_of(main: Node, msg: String) -> RichTextLabel:
	var row := main.find_child(msg, true, false)
	return row.find_child("Text", true, false) as RichTextLabel if row else null


func test_codex_shows_notes_only_for_won_levels_and_counts_them() -> void:
	var s := _save()
	_win(s, ACTS[0], 3)
	var main: Node = Flow.returning(tree, s)
	Flow.press(main, "StartButton")
	Flow.press(main, "CodexButton")
	assert_true(Flow.has(main, "CodexScreen"), "codex opens")
	assert_eq((main.find_child("CodexCounter", true, false) as Label).text, "3 / 48 words filed")
	for id in ["1-01", "1-02", "1-03"]:
		assert_true(Flow.has(main, "Note_%s" % id), "note %s" % id)
	assert_true(Flow.has(main, "Locked_1-04") and not Flow.has(main, "Note_1-04"), "1-04 locked")
	var w := main.find_child("Locked_1-04", true, false).find_child("Word", true, false) as Label
	assert_eq(w.text, "???")
	var won_w := main.find_child("Note_1-01", true, false).find_child("Word", true, false) as Label
	assert_eq(won_w.text, "MILK")
	Flow.press(main, "BackButton")
	assert_true(Flow.has(main, "LevelMap"), "back returns to the map")
	main.free()


func test_codex_is_reachable_from_settings() -> void:
	var main: Node = Flow.returning(tree, _save())
	Flow.press(main, "StartButton")
	Flow.press(main, "SettingsButton")
	assert_true(Flow.has(main, "SettingsScreen"), "settings")
	Flow.press(main, "CodexButton")
	assert_true(Flow.has(main, "CodexScreen"), "codex from settings")
	assert_eq((main.find_child("CodexCounter", true, false) as Label).text, "0 / 48 words filed")
	Flow.press(main, "BackButton")
	assert_true(Flow.has(main, "SettingsScreen"), "back to settings")
	main.free()


func test_inbox_shows_blanks_then_fills_when_the_act_is_complete() -> void:
	var s := _save()
	var main: Node = Flow.returning(tree, s)
	Flow.press(main, "StartButton")
	Flow.press(main, "InboxButton")
	assert_true(Flow.has(main, "InboxScreen"), "inbox opens")
	assert_true(Flow.has(main, "Typing"), "typing mark before the first win")
	assert_eq(_text_of(main, "Message_1").text, "___. I can say ___.")
	main.free()
	_win(s, ACTS[0], 12)
	main = Flow.returning(tree, s)
	Flow.press(main, "StartButton")
	Flow.press(main, "InboxButton")
	assert_false(Flow.has(main, "Typing"), "no typing mark after a win")
	var t := _text_of(main, "Message_1")
	assert_eq(t.get_parsed_text(), "Water. I can say water.")
	assert_true(t.text.contains("[color="), "filled words highlighted")
	assert_eq(_text_of(main, "Message_2").get_parsed_text(), "I ___ you. I am not ___.")
	main.free()


func test_name_substitution_in_act_four() -> void:
	var msg: Dictionary = StoryData.tomas()[4]
	assert_true(StoryData.filled_bbcode(msg, "", "#ff7f6e").contains("Thank[/color] you, [color=#ff7f6e]Catcher"), "default name")
	assert_true(StoryData.filled_bbcode(msg, "Sam", "#ff7f6e").contains("[color=#ff7f6e]Sam[/color]"), "saved name")
	var s := _save()
	for a in ACTS:
		_win(s, a, 12)
	s.profile()["name"] = "Sam"
	var main: Node = Flow.returning(tree, s)
	Flow.press(main, "StartButton")
	Flow.press(main, "InboxButton")
	assert_eq(_text_of(main, "Message_4").get_parsed_text(), "I can say all of it now. I love you, Gran. Thank you, Sam. Come and see the water with us.")
	main.free()


func test_unread_badge_clears_when_the_inbox_is_opened() -> void:
	var s := _save()
	_win(s, ACTS[0], 12)
	var main: Node = Flow.returning(tree, s)
	Flow.press(main, "StartButton")
	assert_true(Flow.has(main, "InboxBadge"), "badge for the unread message")
	Flow.press(main, "InboxButton")
	assert_eq(s.inbox_read(), 1, "read count stored")
	Flow.press(main, "BackButton")
	assert_true(Flow.has(main, "LevelMap"), "back to the map")
	assert_false(Flow.has(main, "InboxBadge"), "badge cleared")
	main.free()


func test_act_complete_offers_the_new_message() -> void:
	var s := _save()
	_win(s, ACTS[0], 12)
	var main: Node = Flow.returning(tree, s)
	main.act = ACTS[0]
	main._show_complete(false)
	assert_true(Flow.has(main, "NewMessage"), "new message line")
	Flow.press(main, "InboxButton")
	assert_true(Flow.has(main, "InboxScreen"), "opens the inbox")
	assert_eq(s.inbox_read(), 1)
	main.free()

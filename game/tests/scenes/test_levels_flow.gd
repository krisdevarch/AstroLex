extends "res://tests/test_case.gd"

const FieldScene: PackedScene = preload("res://scenes/field.tscn")
const GameData := preload("res://rules/game_data.gd")
const Flow := preload("res://tests/scenes/flow.gd")


func _level(i: int) -> Dictionary:
	return GameData.load_content()["levels"]["act1_low_orbit"][i]


func _press(main: Node, node_name: String) -> void:
	var b := main.find_child(node_name, true, false) as Button
	assert_true(b != null, node_name + " exists")
	if b:
		b.pressed.emit()


func test_map_leads_through_comms_to_level_1_01() -> void:
	var main: Node = Flow.returning(tree)
	Flow.press(main, "StartButton")
	assert_true(Flow.has(main, "LevelMap"), "map after Continue")
	Flow.press(main, "Level_1-01")
	assert_true(Flow.has(main, "StoryStrip"), "comms before level")
	Flow.press(main, "SkipButton")
	var f := main.find_child("Field", true, false)
	assert_true(f != null, "field after skip")
	if f:
		assert_eq(f.game_round.level_id, "1-01", "level 1-01")
		assert_eq(main.level_index, 0, "index 0")
		var lab := f.find_child("LevelLabel", true, false) as Label
		assert_true(lab != null and lab.text != "" and not lab.text.begins_with("1-01"), "HUD shows the level name (the counter chip gives the number)")
	main.free()


func test_win_offers_next_and_next_plays_the_following_level() -> void:
	var main: Node = Flow.returning(tree)
	var f := Flow.to_field(main)
	f.autoplay = true
	f.skip_intro()
	var steps := 0
	while not f.finished and steps < 300 * 60:
		f.advance(1.0 / 60.0)
		steps += 1
	assert_eq(f.game_round.state, "won", "bot wins 1-01")
	assert_true(main.save.next_level(main.act) >= 1, "win saved")
	if Flow.has(main, "StoryStrip"):
		Flow.press(main, "SkipButton")
	assert_true(Flow.has(main, "NextButton"), "Next offered after a win")
	assert_true(Flow.has(main, "RetryButton") and Flow.has(main, "MapButton"), "Retry and Map")
	assert_false(Flow.has(main, "ModeSwitchButton"), "no mode switch")
	Flow.press(main, "NextButton")
	if Flow.has(main, "StoryStrip"):
		Flow.press(main, "SkipButton")
	var f2 := main.find_child("Field", true, false)
	assert_true(f2 != null and f2.game_round.level_id == "1-02", "next level is 1-02")
	main.free()


func test_loss_offers_retry_but_no_next_and_keeps_the_level() -> void:
	var main: Node = Flow.returning(tree)
	Flow.to_field(main)
	main.call("_on_level_finished", {"won": false}, _level(0))
	assert_false(Flow.has(main, "NextButton"), "no Next after a loss")
	assert_eq(main.save.next_level(main.act), 0, "loss does not unlock")
	Flow.press(main, "RetryButton")
	var f := main.find_child("Field", true, false)
	assert_true(f != null and f.game_round.level_id == "1-01", "retry replays 1-01")
	main.free()


func test_story_strip_taps_skip_and_colours() -> void:
	var c: Control = load("res://scenes/story_strip.gd").new()
	c.messages = [{"who": "rhee", "text": "Hello."}, {"who": "babel", "text": "No."}, {"who": "kit", "text": "Hi."}]
	c.size = Vector2(1080, 1000)
	var done := [0]
	var babel: Array = []
	c.finished.connect(func() -> void: done[0] += 1)
	c.babel_line.connect(func(t: String) -> void: babel.append(t))
	tree.root.add_child(c)
	assert_eq(c.shown_count(), 1, "one line at first")
	c.advance()  # finishes typing the first line
	c.advance()  # Babel's line goes to his own bubble
	assert_eq(babel, ["No."], "Babel speaks in his bubble, not the crew's")
	c.advance()
	assert_eq(c.shown_count(), 3, "all shown after taps")
	var names: Array = c.find_children("Speaker", "Label", true, false)
	assert_eq(names.size(), 2, "two crew bubbles")
	assert_eq((names[0] as Label).get_theme_color("font_color"), Color("F8BC04"), "rhee colour")
	assert_eq((names[1] as Label).get_theme_color("font_color"), Color("FF88CC"), "kit colour")
	(c.find_child("SkipButton", true, false) as Button).pressed.emit()
	assert_eq(done[0], 1, "finished once")
	c.skip()
	assert_eq(done[0], 1, "finished emitted once")
	c.free()


func test_story_strip_reads_on_by_itself_and_reduced_motion_shows_all() -> void:
	var c: Control = load("res://scenes/story_strip.gd").new()
	c.messages = [{"who": "ade", "text": "a"}, {"who": "vanta", "text": "b"}]
	c.size = Vector2(1080, 1000)
	tree.root.add_child(c)
	for _i in 200:
		c.tick(1.0 / 30.0)
	assert_true(c.is_done(), "the lines move on at reading pace and end")
	c.free()
	var r: Control = load("res://scenes/story_strip.gd").new()
	r.messages = [{"who": "ade", "text": "a"}, {"who": "vanta", "text": "b"}]
	r.size = Vector2(1080, 1000)
	r.reduced_motion = true
	tree.root.add_child(r)
	assert_eq(r.shown_count(), 2, "all at once")
	r.free()


func test_begin_level_uses_the_level_words_in_order() -> void:
	var lv := _level(0)
	var f: Node2D = FieldScene.instantiate()
	tree.root.add_child(f)
	f.begin_level(lv)
	var words: Array = lv["words"]
	assert_eq(Array(f.game_round.words), words, "words in level order")
	assert_eq(f.game_round.level_id, "1-01", "level id")
	assert_eq(f.game_round.seed_value, int(lv["seed"]), "level seed")
	f.free()


func test_act_one_burst_is_sixty_seconds_and_the_bar_fits_it() -> void:
	var lv := _level(0)
	var secs := float((lv["tuning"] as Dictionary)["burst.seconds"])
	assert_true(secs >= 30.0, "burst comes from the level tuning (WP-F.9 curve)")
	var f: Node2D = FieldScene.instantiate()
	f.print_ready = false
	tree.root.add_child(f)
	f.begin_level(lv)
	f.skip_intro()
	f.advance(1.0 / 60.0)
	assert_eq(f.game_round.burst_seconds, secs)
	var bar := f.find_child("TimeBar", true, false) as ProgressBar
	assert_eq(bar.max_value, secs, "time bar spans the whole burst")
	assert_true(bar.value > secs - 1.0, "bar starts full")
	f.free()

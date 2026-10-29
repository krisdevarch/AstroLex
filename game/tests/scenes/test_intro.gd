extends "res://tests/test_case.gd"
## The intro screen (WP-F.29): shows once per launch before the title, a tap or the timer ends it.

const Flow := preload("res://tests/scenes/flow.gd")
const Save := preload("res://services/save.gd")


func _main_with_intro() -> Node:
	var s: RefCounted = Save.fake()
	s.set_profile("wren", "normal", "ADA")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = s
	main.show_intro = true
	main.intro_fade_sec = 0.0
	tree.root.add_child(main)
	return main


func _tap(node: Control) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	node._gui_input(ev)


func test_intro_is_off_in_headless_runs() -> void:
	var main: Node = Flow.returning(tree)
	assert_false(main.show_intro, "tests start on the title")
	assert_true(Flow.has(main, "StartScreen"))
	assert_false(Flow.has(main, "IntroScreen"))
	main.free()


func test_intro_shows_the_logo_and_the_four_catchers() -> void:
	var main := _main_with_intro()
	assert_true(Flow.has(main, "IntroScreen"), "intro first")
	assert_false(Flow.has(main, "StartScreen"), "title waits")
	assert_true(Flow.has(main, "IntroLogo"), "logo")
	assert_true(Flow.has(main, "TapToStart"), "prompt")
	for id in ["wren", "juno", "ash", "pip"]:
		var b := main.find_child("IntroBubble_%s" % id, true, false)
		assert_true(main.find_child("IntroBust_%s" % id, true, false) != null and main.find_child("IntroBust_%s" % id, true, false).find_child("Bust", true, false) != null, "bubble %s with a bust" % id)
		assert_true(b != null and b.find_child("Glass", true, false) != null, "bubble %s with glass" % id)
	assert_true(main.find_child("Wordmark", true, false) is Label, "wordmark text")
	assert_eq((main.find_child("TapToStart", true, false) as Button).text, "Tap to start", "standard button")
	main.free()


func test_tap_goes_to_the_title_once_per_launch() -> void:
	var main := _main_with_intro()
	_tap(main.find_child("IntroScreen", true, false))
	assert_true(Flow.has(main, "StartScreen"), "title after the tap")
	Flow.press(main, "StartButton")
	assert_true(Flow.has(main, "LevelMap"))
	Flow.press(main, "BackButton")
	assert_true(Flow.has(main, "StartScreen"), "Back from the map returns to the title")
	assert_false(Flow.has(main, "IntroScreen"), "no second intro")
	main.free()


func test_touch_and_double_tap_emit_finished_once() -> void:
	var intro: Control = load("res://scenes/intro_screen.gd").new()
	intro.fade_sec = 0.0
	tree.root.add_child(intro)
	var count := [0]
	intro.finished.connect(func() -> void: count[0] += 1)
	var ev := InputEventScreenTouch.new()
	ev.pressed = true
	intro._gui_input(ev)
	_tap(intro)
	assert_eq(count[0], 1, "finished once")
	intro.free()


func test_timer_ends_the_intro_even_with_reduced_motion() -> void:
	var intro: Control = load("res://scenes/intro_screen.gd").new()
	intro.settings.reduced_motion = true
	intro.fade_sec = 0.0
	tree.root.add_child(intro)
	var count := [0]
	intro.finished.connect(func() -> void: count[0] += 1)
	intro._process(intro.hold_sec - 0.5)
	assert_eq(count[0], 0, "still waiting")
	intro._process(1.0)
	assert_eq(count[0], 1, "timer finished it")
	assert_eq((intro.find_child("IntroBubble_juno", true, false) as Node2D).scale, Vector2.ONE, "reduced motion: at rest")
	intro.free()

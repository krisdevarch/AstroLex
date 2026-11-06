extends "res://tests/test_case.gd"
## The intro (WP-F.29, one screen since WP-F.31): the title opens with only "Tap to start"; a tap or the
## timer fades the menu in on the same screen, with no second screen and no dip to black.

const Flow := preload("res://tests/scenes/flow.gd")
const Save := preload("res://services/save.gd")
const StartScreen := preload("res://scenes/start_screen.gd")


func _main_with_intro() -> Node:
	var s: RefCounted = Save.fake()
	s.set_profile("wren", "normal", "ADA")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.save = s
	main.show_intro = true
	main.intro_reveal_sec = 0.0
	tree.root.add_child(main)
	return main


func _tap(node: Control) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	node._gui_input(ev)


func _menu_shown(main: Node) -> bool:
	return (main.find_child("Buttons", true, false) as Control).visible


func test_intro_is_off_in_headless_runs() -> void:
	var main: Node = Flow.returning(tree)
	assert_false(main.show_intro, "tests start on the title")
	assert_true(Flow.has(main, "StartScreen"))
	assert_false(Flow.has(main, "TapToStart"), "no intro button")
	assert_true(_menu_shown(main), "menu at once")
	main.free()


func test_intro_is_the_title_with_only_tap_to_start() -> void:
	var main := _main_with_intro()
	assert_true(Flow.has(main, "StartScreen"), "one screen from the start")
	assert_false(Flow.has(main, "IntroScreen"), "no separate intro screen")
	assert_true(Flow.has(main, "CrewLogo"), "logo")
	assert_eq((main.find_child("TapToStart", true, false) as Button).text, "Tap to start", "standard button")
	assert_false(_menu_shown(main), "menu waits")
	for id in ["wren", "juno", "ash", "pip"]:
		var b := main.find_child("CrewBubble_%s" % id, true, false)
		assert_true(main.find_child("CrewBust_%s" % id, true, false) != null and main.find_child("CrewBust_%s" % id, true, false).find_child("Bust", true, false) != null, "bubble %s with a bust" % id)
		assert_true(b != null and b.find_child("Glass", true, false) != null, "bubble %s with glass" % id)
	main.free()


func test_tap_reveals_the_menu_on_the_same_screen_once_per_launch() -> void:
	var main := _main_with_intro()
	var screen: Node = main.find_child("StartScreen", true, false)
	_tap(screen)
	await tree.process_frame
	assert_true(main.find_child("StartScreen", true, false) == screen, "same screen, not rebuilt")
	assert_true(_menu_shown(main), "menu after the tap")
	assert_false(Flow.has(main, "TapToStart"), "Tap to start gone")
	Flow.press(main, "StartButton")
	assert_true(Flow.has(main, "LevelMap"))
	Flow.press(main, "BackButton")
	assert_true(Flow.has(main, "StartScreen"), "Back from the map returns to the title")
	assert_false(Flow.has(main, "TapToStart"), "no second intro")
	assert_true(_menu_shown(main))
	main.free()


func test_touch_and_double_tap_reveal_once() -> void:
	var s: Control = StartScreen.new()
	s.intro = true
	s.reveal_sec = 0.0
	tree.root.add_child(s)
	var count := [0]
	s.revealed.connect(func() -> void: count[0] += 1)
	var ev := InputEventScreenTouch.new()
	ev.pressed = true
	s._gui_input(ev)
	_tap(s)
	assert_eq(count[0], 1, "revealed once")
	assert_false(s.waiting())
	s.free()


func test_reveal_cross_fades_without_a_black_dip() -> void:
	var s: Control = StartScreen.new()
	s.intro = true
	tree.root.add_child(s)
	s.reveal()
	assert_true(s.find_child("Buttons", true, false).visible, "menu fading in")
	assert_eq((s.find_child("StartButton", true, false) as Button).mouse_filter, Control.MOUSE_FILTER_IGNORE, "no clicks while it fades")
	assert_true(s.find_child("IntroFade", true, false) == null, "no fade-to-black layer")
	await tree.create_timer(s.reveal_sec + 0.3).timeout
	assert_eq((s.find_child("Buttons", true, false) as Control).modulate.a, 1.0, "menu fully in")
	assert_eq((s.find_child("StartButton", true, false) as Button).mouse_filter, Control.MOUSE_FILTER_STOP, "clickable once in")
	s.free()


func test_timer_reveals_the_menu_even_with_reduced_motion() -> void:
	var s: Control = StartScreen.new()
	s.intro = true
	s.settings.reduced_motion = true
	tree.root.add_child(s)
	s._process(s.hold_sec - 0.5)
	assert_true(s.waiting(), "still waiting")
	s._process(1.0)
	assert_false(s.waiting(), "timer revealed it")
	assert_eq((s.find_child("Buttons", true, false) as Control).modulate.a, 1.0, "reduced motion: no fade")
	assert_eq((s.find_child("CrewBubble_juno", true, false) as Node2D).scale, Vector2.ONE, "reduced motion: at rest")
	s.free()


func test_still_capture_is_still_available() -> void:
	var intro: Control = load("res://scenes/intro_screen.gd").new()
	intro.still = true
	intro.pop = false
	tree.root.add_child(intro)
	assert_false((intro.find_child("TapToStart", true, false) as Button).visible, "art only")
	intro.free()

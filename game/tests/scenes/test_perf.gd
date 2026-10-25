extends "res://tests/test_case.gd"
## WP-F.15: frame cap by screen, pause when the player leaves, bounded frame telemetry.

const Flow := preload("res://tests/scenes/flow.gd")
const Telemetry := preload("res://services/telemetry.gd")
const GameData := preload("res://rules/game_data.gd")


func test_frame_cap_follows_the_screen() -> void:
	var t := GameData.load_tunables()
	var play := int(t["perf.playFps"])
	var menu := int(t["perf.menuFps"])
	var main: Node = Flow.returning(tree)
	Flow.press(main, "StartButton")
	assert_eq(Engine.max_fps, menu, "menu rate on the map")
	var f := Flow.to_field(main)
	assert_eq(Engine.max_fps, play, "play rate on the field")
	main._show_pause(f)
	assert_eq(Engine.max_fps, menu, "menu rate while paused")
	Flow.press(main, "ResumeButton")
	assert_eq(Engine.max_fps, play, "play rate after resume")
	main.free()
	Engine.max_fps = 0


func test_leaving_the_app_pauses_a_round_in_play() -> void:
	var main: Node = Flow.returning(tree)
	var f := Flow.to_field(main)
	f.skip_intro()
	f.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(Flow.has(main, "PauseMenu"), "focus out opens the pause menu")
	main.free()
	Engine.max_fps = 0


func test_a_very_late_frame_pauses_a_round_in_play() -> void:
	var main: Node = Flow.returning(tree)
	var f := Flow.to_field(main)
	f.skip_intro()
	f._process(3.0)
	assert_true(Flow.has(main, "PauseMenu"), "a tab that slept opens the pause menu")
	main.free()
	Engine.max_fps = 0


func test_a_late_frame_while_babel_throws_does_not_pause() -> void:
	var main: Node = Flow.returning(tree)
	var f := Flow.to_field(main)
	assert_true(f.intro_active(), "Babel is throwing")
	f._process(3.0)  # a slow first frame on a slow phone, not a hidden tab
	assert_false(Flow.has(main, "PauseMenu"), "no pause during the throw")
	main.free()
	Engine.max_fps = 0


func test_leaving_with_the_card_up_does_not_pause() -> void:
	var main: Node = Flow.returning(tree)
	var f := Flow.to_field(main)
	f.autoplay = true
	f.skip_intro()
	var steps := 0
	while not f.finished and steps < 300 * 60:
		f.advance(1.0 / 60.0)
		steps += 1
	assert_true(f.card() != null, "the card is up")
	f.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(Flow.has(main, "PauseMenu"), "no pause over the card")
	main.free()
	Engine.max_fps = 0


func test_telemetry_keeps_the_last_3600_frames() -> void:
	var t: RefCounted = Telemetry.fake()
	for i in 5000:
		t.sample_frame(0.016)
	assert_true(t.frames_ms.size() <= Telemetry.FRAME_CAP, "capped (%d)" % t.frames_ms.size())
	assert_true(t.frames_ms.size() > Telemetry.FRAME_CAP - Telemetry.FRAME_DROP, "still a long window")

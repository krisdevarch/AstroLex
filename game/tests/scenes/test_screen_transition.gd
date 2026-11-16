extends "res://tests/test_case.gd"
## WP-F.33: screen-to-screen hand-overs. The swap itself stays instant (game logic and every flow test
## see the new screen at once); a still of the old screen animates over it. Headless runs get no still.

const Flow := preload("res://tests/scenes/flow.gd")
const ScreenTransition := preload("res://scenes/screen_transition.gd")
const Announcer := preload("res://services/announcer.gd")


func _still() -> Texture2D:
	return ImageTexture.create_from_image(Image.create(8, 8, false, Image.FORMAT_RGBA8))


func _setup() -> Array:
	var t: ScreenTransition = ScreenTransition.new()
	tree.root.add_child(t)
	var c := Control.new()
	c.size = Vector2(1080, 1920)
	tree.root.add_child(c)
	return [t, c]


func test_headless_capture_is_null_and_nothing_plays() -> void:
	var tc := _setup()
	var t: ScreenTransition = tc[0]
	assert_true(t.capture() == null, "no still without a renderer")
	assert_eq(t.play(null, tc[1], ScreenTransition.FORWARD), 0.0, "nothing plays")
	assert_false(t.busy())
	t.free()
	tc[1].free()


func test_forward_lays_a_tap_blocking_still_and_settles_the_new_screen() -> void:
	var tc := _setup()
	var t: ScreenTransition = tc[0]
	var c: Control = tc[1]
	var sec := t.play(_still(), c, ScreenTransition.FORWARD)
	assert_true(sec > 0.3 and sec < 0.7, "a menu change lasts about 0.4 s, got %s" % sec)
	assert_true(t.busy(), "the still is up")
	var shot := t.get_node("OutgoingStill") as TextureRect
	assert_eq(shot.mouse_filter, Control.MOUSE_FILTER_STOP, "taps cannot reach the new screen mid-change")
	assert_eq(c.modulate.a, 0.0, "the new screen starts clear")
	assert_true(c.position.y > 0.0, "and a little low (it rises in)")
	t.finish()
	assert_false(t.busy(), "finish removes the still")
	assert_eq(c.modulate.a, 1.0)
	assert_eq(c.position, Vector2.ZERO, "back at rest")
	assert_eq(c.scale, Vector2.ONE)
	t.free()
	c.free()


func test_back_settles_from_slightly_large() -> void:
	var tc := _setup()
	var t: ScreenTransition = tc[0]
	var c: Control = tc[1]
	t.play(_still(), c, ScreenTransition.BACK)
	assert_true(c.scale.x > 1.0, "back: the screen comes from slightly in front")
	assert_eq(c.position, Vector2.ZERO, "and does not rise")
	t.finish()
	assert_eq(c.scale, Vector2.ONE)
	t.free()
	c.free()


func test_reduced_motion_is_a_short_plain_cross_fade() -> void:
	var tc := _setup()
	var t: ScreenTransition = tc[0]
	var c: Control = tc[1]
	t.reduced_motion = true
	for kind in [ScreenTransition.FORWARD, ScreenTransition.BACK, ScreenTransition.PLAY, ScreenTransition.FADE]:
		var sec := t.play(_still(), c, kind)
		assert_eq(sec, t.num("calmSec", 0.2), "calm length for kind %d" % kind)
		assert_eq(c.position, Vector2.ZERO, "nothing moves (kind %d)" % kind)
		assert_eq(c.scale, Vector2.ONE, "nothing scales (kind %d)" % kind)
		assert_eq((t.get_node("OutgoingStill") as Control).scale, Vector2.ONE)
		t.finish()
	t.free()
	c.free()


func test_a_new_change_ends_the_one_in_progress() -> void:
	var tc := _setup()
	var t: ScreenTransition = tc[0]
	var a: Control = tc[1]
	t.play(_still(), a, ScreenTransition.FORWARD)
	var b := Control.new()
	tree.root.add_child(b)
	t.play(_still(), b, ScreenTransition.BACK)
	assert_eq(a.modulate.a, 1.0, "the first screen was put at rest")
	assert_eq(a.position, Vector2.ZERO)
	assert_eq(t.get_children().size(), 1, "one still at a time")
	t.finish()
	t.free()
	a.free()
	b.free()


func test_tunables_exist() -> void:
	var t: ScreenTransition = ScreenTransition.new()
	t._ready()
	for k in ["outSec", "inSec", "inDelaySec", "playSec", "calmSec", "zoom", "playZoom", "rise", "overlaySec"]:
		assert_true(t._tun.has("transition." + k), "transition.%s tunable" % k)
	t.free()


func test_main_picks_the_kind_and_resets_it() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.announcer = Announcer.fake()
	var s: RefCounted = load("res://services/save.gd").fake()
	s.set_profile("wren", "normal", "ADA")
	main.save = s
	tree.root.add_child(main)
	assert_true(main.transition != null, "main owns one transition layer")
	Flow.press(main, "SettingsButton")
	assert_true(Flow.has(main, "SettingsScreen"), "settings open at once")
	assert_eq(main.announcer.last(), "Settings", "a screen reader hears the screen's name")
	main._back(main._show_start)
	assert_true(Flow.has(main, "StartScreen"), "back to the title")
	assert_eq(main._next_kind, ScreenTransition.FORWARD, "the kind resets after each change")
	main._into_play(func() -> void: pass)
	assert_eq(main._next_kind, ScreenTransition.PLAY, "from a menu, the next change dives into play")
	main.free()


func test_announcer_labels() -> void:
	var b := Button.new()
	b.text = "Done"
	assert_eq(Announcer.label_of(b), "Done")
	var icon := Button.new()
	icon.tooltip_text = "Settings"
	assert_eq(Announcer.label_of(icon), "Settings", "icon buttons speak their tooltip")
	var tog := Button.new()
	tog.text = "Bubble"
	tog.toggle_mode = true
	tog.button_pressed = true
	assert_eq(Announcer.label_of(tog), "Bubble, on")
	var a: RefCounted = Announcer.fake()
	a.say("Level map")
	a.say("Level map")
	assert_eq(a.spoken.size(), 1, "repeats are skipped")
	for n in [b, icon, tog]:
		n.free()

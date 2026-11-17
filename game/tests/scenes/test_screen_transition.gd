extends "res://tests/test_case.gd"
## WP-F.33: screen-to-screen hand-overs. The swap itself stays instant (game logic and every flow test
## see the new screen at once); a still of the old screen animates over it. Headless runs get no still.

const Flow := preload("res://tests/scenes/flow.gd")
const ScreenTransition := preload("res://scenes/screen_transition.gd")
const Announcer := preload("res://services/announcer.gd")


## A transition allowed to play headless, a leaving screen (with its own sky layer) and a new screen.
func _setup() -> Array:
	var t: ScreenTransition = ScreenTransition.new()
	t.allow_headless = true
	tree.root.add_child(t)
	var old := Control.new()
	old.size = Vector2(1080, 1920)
	var sky := CanvasLayer.new()
	sky.layer = -3
	var sky_art := ColorRect.new()
	sky.add_child(sky_art)
	old.add_child(sky)
	tree.root.add_child(old)
	var c := Control.new()
	c.size = Vector2(1080, 1920)
	tree.root.add_child(c)
	return [t, old, c, sky, sky_art]


func test_headless_plays_nothing_by_default() -> void:
	var t: ScreenTransition = ScreenTransition.new()
	tree.root.add_child(t)
	assert_false(t.can_play(ScreenTransition.FORWARD), "no renderer, no change")
	var c := Control.new()
	tree.root.add_child(c)
	assert_eq(t.play(c, ScreenTransition.FORWARD), 0.0, "nothing plays without a leaving screen")
	assert_false(t.busy())
	t.free()
	c.free()


func test_forward_keeps_the_old_screen_live_above_and_blocks_taps() -> void:
	var tc := _setup()
	var t: ScreenTransition = tc[0]
	var old: Control = tc[1]
	var c: Control = tc[2]
	var sky: CanvasLayer = tc[3]
	t.take_outgoing(old)
	assert_eq(old.process_mode, Node.PROCESS_MODE_DISABLED, "the leaving screen stops processing")
	assert_true(str(old.name).ends_with("_Leaving"), "renamed so find_child finds the new screen")
	assert_eq(sky.layer, ScreenTransition.OUT_LAYER - 3, "its own layers move above the new screen")
	var sec := t.play(c, ScreenTransition.FORWARD)
	assert_true(sec > 0.25 and sec < 0.6, "a menu change lasts about a third of a second, got %s" % sec)
	assert_true(t.busy())
	var b := t.get_node("TapBlocker") as Control
	assert_eq(b.mouse_filter, Control.MOUSE_FILTER_STOP, "taps cannot reach either screen mid-change")
	assert_eq(c.modulate.a, 0.0, "the new screen starts clear")
	assert_true(c.position.y > 0.0, "and a little low (it rises in)")
	t.finish()
	assert_false(t.busy(), "finish ends it")
	assert_true(old.is_queued_for_deletion(), "the old screen is freed")
	assert_eq(c.modulate.a, 1.0)
	assert_eq(c.position, Vector2.ZERO, "back at rest")
	t.free()
	c.free()


func test_old_screen_fades_and_zooms_about_the_centre() -> void:
	var tc := _setup()
	var t: ScreenTransition = tc[0]
	var old: Control = tc[1]
	var sky: CanvasLayer = tc[3]
	var art: ColorRect = tc[4]
	t.take_outgoing(old)
	t.play(tc[2], ScreenTransition.PLAY)
	t._view = Vector2(1080, 1920)
	t._out_alpha(0.5)
	assert_eq(old.modulate.a, 0.5, "root fades")
	assert_eq(art.modulate.a, 0.5, "its layers' art fades too")
	t._out_zoom(1.1)
	assert_eq(sky.scale, Vector2(1.1, 1.1))
	assert_true(sky.offset.distance_to(Vector2(-54, -96)) < 0.01, "scaled about the centre, got %s" % sky.offset)
	t.finish()
	t.free()
	tc[2].free()


func test_back_settles_from_slightly_large() -> void:
	var tc := _setup()
	var t: ScreenTransition = tc[0]
	var c: Control = tc[2]
	t.take_outgoing(tc[1])
	t.play(c, ScreenTransition.BACK)
	assert_true(c.scale.x > 1.0, "back: the screen comes from slightly in front")
	assert_eq(c.position, Vector2.ZERO, "and does not rise")
	t.finish()
	assert_eq(c.scale, Vector2.ONE)
	t.free()
	c.free()


func test_reduced_motion_is_a_short_plain_cross_fade() -> void:
	var t: ScreenTransition = ScreenTransition.new()
	t.allow_headless = true
	t.reduced_motion = true
	tree.root.add_child(t)
	var c := Control.new()
	tree.root.add_child(c)
	for kind in [ScreenTransition.FORWARD, ScreenTransition.BACK, ScreenTransition.PLAY, ScreenTransition.FADE]:
		var old := Control.new()
		tree.root.add_child(old)
		t.take_outgoing(old)
		var sec := t.play(c, kind)
		assert_eq(sec, t.num("calmSec", 0.15), "calm length for kind %d" % kind)
		assert_eq(c.position, Vector2.ZERO, "nothing moves (kind %d)" % kind)
		assert_eq(c.scale, Vector2.ONE, "nothing scales (kind %d)" % kind)
		t.finish()
	t.free()
	c.free()


func test_a_new_change_ends_the_one_in_progress() -> void:
	var tc := _setup()
	var t: ScreenTransition = tc[0]
	var old: Control = tc[1]
	var a: Control = tc[2]
	t.take_outgoing(old)
	t.play(a, ScreenTransition.FORWARD)
	t.take_outgoing(a)
	assert_true(old.is_queued_for_deletion(), "the first leaving screen is gone")
	var b := Control.new()
	tree.root.add_child(b)
	t.play(b, ScreenTransition.BACK)
	assert_eq(a.modulate.a, 1.0, "the screen now leaving started from rest")
	assert_eq(t.find_children("*", "CanvasLayer", false, false).size(), 1, "one leaving layer at a time")
	t.finish()
	t.free()
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

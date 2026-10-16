extends "res://tests/test_case.gd"

const FieldScene: PackedScene = preload("res://scenes/field.tscn")


func _make(reduced: bool = false) -> Node2D:
	var f: Node2D = FieldScene.instantiate()
	f.settings.reduced_motion = reduced
	tree.root.add_child(f)
	f.begin(1, 12345)
	return f


func _max_gap(f: Node2D) -> float:
	var worst := 0.0
	for t in f.game_round.tiles:
		var v: Node2D = f._views[t.id]
		worst = maxf(worst, v.position.distance_to(f.to_screen(t.pos)))
	return worst


func _run_intro(f: Node2D) -> void:
	for _i in 60 * 30:
		if not f.intro_active():
			return
		f.advance(1.0 / 60.0)


func _make_level(reduced: bool = false) -> Node2D:
	var f: Node2D = FieldScene.instantiate()
	f.settings.reduced_motion = reduced
	tree.root.add_child(f)
	var level: Dictionary = {}
	for l in f.GameData.load_content()["levels"]["act1_low_orbit"]:
		if bool(l.get("babel", false)):
			level = l
			break
	f.begin_level(level)
	return f


func test_sim_waits_and_tiles_are_away_from_place_during_intro() -> void:
	var f := _make()
	assert_true(f.intro_active(), "intro runs after begin")
	var before: float = f.game_round.stats["secs"]
	for _i in 60 * 20:
		f.advance(1.0 / 60.0)
		if f._intro_t > f._intro_throw_at + 0.1:
			break
	assert_eq(float(f.game_round.stats["secs"]), before, "no sim time during the intro")
	assert_true(_max_gap(f) > 5.0, "tiles are not at their rule positions")
	f.free()


func test_tiles_land_within_a_pixel_after_the_intro() -> void:
	var f := _make()
	_run_intro(f)
	assert_false(f.intro_active(), "intro ended")
	f.advance(1.0 / 60.0)
	assert_true(f.game_round.stats["secs"] > 0.0, "play started")
	assert_true(_max_gap(f) < 1.0, "every view at to_screen(pos)")
	f.free()


func test_tap_skips_the_intro() -> void:
	var f := _make()
	f.advance(1.0 / 60.0)
	assert_eq(f.tap(Vector2(540, 900)), -1, "the skipping tap fires nothing")
	assert_false(f.intro_active(), "intro skipped")
	assert_true(_max_gap(f) < 1.0, "tiles snapped into place")
	f.free()


func test_reduced_motion_has_no_travel() -> void:
	var f := _make(true)
	for _i in 10:
		f.advance(1.0 / 60.0)
		assert_true(_max_gap(f) < 1.0, "tiles never travel")
	var t = f.game_round.tiles[0]
	assert_true((f._views[t.id] as Node2D).modulate.a < 1.0, "tiles are still fading in")
	f.free()


func test_autoplay_waits_for_the_throw_and_babel_leaves() -> void:
	var f := _make()
	f.autoplay = true
	for _i in 30:
		f.advance(1.0 / 60.0)
	assert_eq(int(f.game_round.stats["catches"]), 0, "autoplay fires nothing during the throw")
	assert_true(f._babel != null and f._babel.visible, "Babel shown during the throw")
	_run_intro(f)
	for _i in 60:
		f.advance(1.0 / 60.0)
	assert_false(f._babel.visible, "Babel gone once the throw is over")
	f.free()


func test_babel_flies_in_from_the_left_at_mid_screen_and_leaves() -> void:
	var f := _make_level()
	var b: Node2D = f._babel
	var p0: Vector2 = b.body_position()
	assert_true(p0.x < 0.0, "starts off-screen left")
	assert_true(absf(p0.y - f.view_size.y * 0.5) < f.view_size.y * 0.2, "at mid-screen height")
	assert_true(b.perch_position().x < f.view_size.x * 0.5, "perches on the left")
	for _i in 6:
		f.advance(1.0 / 60.0)
	assert_true(b.body_position().distance_to(b.perch_position()) > 100.0, "still in flight")
	var enter: float = float(f._tun["babel.enterSec"])
	for _i in int(enter * 60.0) + 4:
		f.advance(1.0 / 60.0)
	assert_eq(b.state, "perch", "landed")
	assert_true(b.body_position().distance_to(b.perch_position()) < 1.0, "at the perch")
	var left_seen := false
	for _i in 60 * 30:
		if not f.intro_active() and not b.visible:
			break
		f.advance(1.0 / 60.0)
		if b.state == "exit":
			left_seen = true
	assert_true(left_seen, "flew out")
	assert_false(b.visible, "gone at the end")
	f.free()


func test_babel_says_the_level_quote() -> void:
	var f := _make_level()
	var quote: String = f._intro_quote
	assert_true(quote != "", "the level has a babelIntro")
	var b: Node2D = f._babel
	assert_eq(b.quote_text(), quote, "bubble holds the quote")
	for _i in 6:
		f.advance(1.0 / 60.0)
	var label: Label = b.get_node("Bubble/BubbleText")
	assert_true(label.visible_characters < quote.length(), "typed in, not all at once")
	for _i in 60 * 4:
		f.advance(1.0 / 60.0)
		if label.visible_characters >= quote.length():
			break
	assert_true(label.visible_characters >= quote.length(), "typed in full")
	var bubble: Control = b.get_node("Bubble")
	assert_true(bubble.position.y + bubble.size.y < b.perch_position().y, "bubble sits above Babel")
	assert_true(bubble.position.x + bubble.size.x <= f.view_size.x, "bubble stays on screen")
	assert_true(label.position.y + label.size.y <= bubble.size.y + 1.0, "the line stays inside the bubble")
	assert_true(bubble.position.y > 140.0, "the bubble sits below the top chips")
	# The endless rounds have no quote.
	var g := _make()
	assert_false(g._babel.is_talking(), "begin() rounds do not talk")
	g.free()
	f.free()


func test_letters_leave_from_the_muzzle() -> void:
	var f := _make()
	var b: Node2D = f._babel
	var checked := 0
	for _i in 60 * 30:
		if not f.intro_active():
			break
		f.advance(1.0 / 60.0)
		for id in f._intro_origin.keys():
			var v: Node2D = f._views[id]
			if f._intro_t - (f._intro_throw_at + float(f._intro_order[id]) * float(f._tun["babel.throwStagger"])) < 0.03 and checked < 3:
				var real: Vector2 = f.to_screen(f.game_round.find_tile(id).pos)
				var origin: Vector2 = f._intro_origin[id]
				assert_true(v.position.distance_to(origin) < 0.3 * origin.distance_to(real), "a fresh letter is still near the muzzle")
				assert_true(origin.distance_to(b.muzzle_position()) < 60.0, "the origin is the muzzle")
				assert_true(origin.x > b.perch_position().x, "the muzzle is on his right, the side he faces")
				checked += 1
	assert_true(checked > 0, "launches observed")
	f.free()


func test_a_long_first_frame_does_not_skip_the_throw() -> void:
	var f := _make()
	f.advance(0.25)
	assert_true(f.intro_active(), "intro still running")
	assert_true(f._intro_t <= 0.1 + 0.0001, "the step is clamped")
	for t in f.game_round.tiles:
		assert_false((f._views[t.id] as Node2D).visible, "no letter has landed")
	f.free()


func test_new_letters_grow_in() -> void:
	var f := _make()
	_run_intro(f)
	f.advance(1.0 / 60.0)
	var before: Array = f._views.keys()
	f.game_round._spawn("e", true, 0)
	f.advance(1.0 / 60.0)
	var fresh: Node2D = null
	for id in f._views.keys():
		if not before.has(id):
			fresh = f._views[id]
	assert_true(fresh != null, "a new view appeared")
	assert_true(fresh.scale.x < 0.6, "starts small")
	assert_true(fresh.modulate.a < 0.5, "starts faint")
	for _i in 30:
		f.advance(1.0 / 60.0)
	assert_true(absf(fresh.scale.x - 1.0) < 0.001, "full size after the grow")
	assert_true(fresh.modulate.a > 0.99, "fully visible after the grow")
	f.free()


func test_letters_ease_into_their_drift_after_the_throw() -> void:
	var f := _make()
	_run_intro(f)
	assert_false(f.intro_active(), "intro ended")
	var t: Object = f.game_round.tiles[0]
	var p0: Vector2 = t.pos
	for _i in 6:
		f.advance(1.0 / 60.0)
	var early: float = t.pos.distance_to(p0)
	assert_true(f.game_round.drift_scale < 0.2, "barely drifting just after the throw")
	for _i in 60:
		f.advance(1.0 / 60.0)
	assert_eq(f.game_round.drift_scale, 1.0, "full drift once settled")
	assert_true(early < t.base_speed * 0.1 * 0.5, "the first frames move only a little")
	f.free()

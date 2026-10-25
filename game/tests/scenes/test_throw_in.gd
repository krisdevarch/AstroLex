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


func test_autoplay_waits_for_the_throw_and_babel_stays() -> void:
	var f := _make()
	f.autoplay = true
	for _i in 30:
		f.advance(1.0 / 60.0)
	assert_eq(int(f.game_round.stats["catches"]), 0, "autoplay fires nothing during the throw")
	assert_true(f._babel != null and f._babel.visible, "Babel shown during the throw")
	_run_intro(f)
	for _i in 60:
		f.advance(1.0 / 60.0)
	assert_true(f._babel.visible, "Babel stays in his corner once the throw is over")
	f.free()


func test_babel_pops_in_at_the_corner_and_stays_through_play() -> void:
	var f := _make_level()
	var b: Node2D = f._babel
	var c: Vector2 = b.corner_position()
	assert_true(absf(c.x - f.view_size.x * float(f._tun["babel.cornerX"])) < 0.5, "corner x from the tunable")
	assert_true(absf(c.y - f.view_size.y * float(f._tun["babel.cornerY"])) < 0.5, "corner y from the tunable")
	assert_true(c.x < f.view_size.x * 0.5 and c.y < f.view_size.y * 0.25, "top-left corner")
	var enter: float = float(f._tun["babel.enterSec"])
	for _i in int(enter * 60.0) + 4:
		f.advance(1.0 / 60.0)
	assert_eq(b.state, "perch", "popped in")
	assert_true(b.body_position().distance_to(c) <= float(f._tun["babel.bobPx"]), "at the corner, only bobbing")
	for _i in 60 * 30:
		if not f.intro_active():
			break
		f.advance(1.0 / 60.0)
	for _i in 60 * 6:
		f.advance(1.0 / 60.0)
		assert_true(b.visible and b.state == "perch", "Babel stays visible through play")
		assert_true(b.body_position().distance_to(c) <= float(f._tun["babel.bobPx"]), "never leaves the corner")
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
	assert_true(bubble.position.x > b.corner_position().x + b.corner_radius(), "bubble sits to the right of the porthole")
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
				assert_true(origin.distance_to(b.corner_position()) < b.corner_radius(), "the muzzle is inside the porthole")
				assert_true(origin.x > b.corner_position().x, "the muzzle is on his right, the side he faces")
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


func test_new_letters_are_shot_from_the_muzzle() -> void:
	var f := _make()
	_run_intro(f)
	f.advance(1.0 / 60.0)
	var b: Node2D = f._babel
	var before: Array = f._views.keys()
	f.game_round._spawn("e", true, 0)
	f.advance(1.0 / 60.0)
	var fresh: Node2D = null
	var fid := -1
	for id in f._views.keys():
		if not before.has(id):
			fresh = f._views[id]
			fid = id
	assert_true(fresh != null, "a new view appeared")
	var real: Vector2 = f.to_screen(f.game_round.find_tile(fid).pos)
	assert_true(fresh.position.distance_to(b.muzzle_position()) < 0.35 * b.muzzle_position().distance_to(real) + 30.0, "starts at the muzzle")
	assert_true(fresh.scale.x < 0.6, "starts small")
	assert_true(fresh.modulate.a < 0.5, "starts faint")
	var flew := false
	for _i in 60:
		f.advance(1.0 / 60.0)
		flew = flew or fresh.position.distance_to(real) > 20.0
	assert_true(flew, "it travelled")
	assert_true(fresh.position.distance_to(f.to_screen(f.game_round.find_tile(fid).pos)) < 1.0, "ends at the tile's position")
	assert_true(absf(fresh.scale.x - 1.0) < 0.001, "full size after the flight")
	assert_true(fresh.modulate.a > 0.99, "fully visible after the flight")
	f.free()


func test_reduced_motion_new_letters_fade_in_place_and_babel_does_not_recoil() -> void:
	var f := _make(true)
	_run_intro(f)
	f.advance(1.0 / 60.0)
	var b: Node2D = f._babel
	var before: Array = f._views.keys()
	var rest: Vector2 = b.body_position()
	f.game_round._spawn("e", true, 0)
	f.advance(1.0 / 60.0)
	var fresh: Node2D = null
	var fid := -1
	for id in f._views.keys():
		if not before.has(id):
			fresh = f._views[id]
			fid = id
	assert_true(fresh != null, "a new view appeared")
	assert_true(fresh.position.distance_to(f.to_screen(f.game_round.find_tile(fid).pos)) < 1.0, "fades in at its place")
	assert_true(fresh.modulate.a < 1.0, "still fading in")
	assert_eq(b.body_position(), rest, "no recoil, no bob")
	f.free()


func test_babel_view_clips_to_the_porthole_and_recoils() -> void:
	var f := _make()
	var b: Node2D = f._babel
	for _i in 60:
		f.advance(1.0 / 60.0)
	var rest: Vector2 = b.body_position()
	b.shoot(Vector2(900, 900))
	b.tick(0.03)
	assert_true(b.body_position().distance_to(rest) > 1.0, "the porthole kicks on a shot")
	assert_true(b.muzzle_position().distance_to(b.body_position()) < b.corner_radius(), "muzzle inside the porthole")
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

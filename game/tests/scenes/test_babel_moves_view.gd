extends "res://tests/test_case.gd"
## WP-F.19 view half: Babel's tell, gust streaks, shield ring and scramble flight.

const FieldScene: PackedScene = preload("res://scenes/field.tscn")


func _field(reduced: bool = false) -> Node2D:
	var f: Node2D = FieldScene.instantiate()
	f.settings.reduced_motion = reduced
	f.intro_enabled = false
	tree.root.add_child(f)
	f.begin(1, 777)
	return f


func _run(f: Node2D, sec: float) -> void:
	for _i in int(sec * 60.0):
		f.advance(1.0 / 60.0)


func _tell(f: Node2D, move: String, sec: float = 1.0) -> void:
	f._on_babel_move_event({"type": "babel_tell", "move": move, "sec": sec})


## A letter on the playable planes (the back plane is decorative stars).
func _front(f: Node2D) -> Object:
	for t in f.game_round.tiles:
		if t.plane < 2:
			return t
	return f.game_round.tiles[0]


## Nodes in a subtree that are not already queued for deletion.
func _live_count(n: Node) -> int:
	if n.is_queued_for_deletion():
		return 0
	var c := 1
	for k in n.get_children():
		c += _live_count(k)
	return c


func test_tell_shows_the_pictogram_and_ends_after_sec() -> void:
	for move in ["volley", "gust", "shield", "scramble"]:
		var f := _field()
		_tell(f, move, 0.5)
		assert_true(f._babel.tell_active(), move + " tell starts")
		assert_eq(f._babel.tell_move(), move)
		assert_true(f._babel.get_node("Rig/Tell").visible, "pictogram drawn")
		assert_true(f.sfx.played.has("babel_tell"), "tell sound")
		_run(f, 0.3)
		assert_true(f._babel.tell_active(), "still going")
		_run(f, 0.4)
		assert_false(f._babel.tell_active(), "over after sec")
		assert_false(f._babel.get_node("Rig/Tell").visible, "hidden")
		f.free()


func test_tell_reduced_motion_keeps_pictogram_without_pulse() -> void:
	var f := _field(true)
	_tell(f, "gust", 0.5)
	assert_true(f._babel.get_node("Rig/Tell").visible)
	assert_true(f._babel.get_node("Rig/Tell").calm, "no pulse")
	f.free()


func test_shield_ring_appears_flashes_on_bounce_and_ends() -> void:
	var f := _field()
	var t = _front(f)
	var v: Node2D = f._views[t.id]
	f._on_babel_move_event({"type": "babel_move", "move": "shield", "tile_id": t.id, "sec": 0.5})
	assert_true(v.shield_on(), "ring on")
	assert_true(f.sfx.played.has("move_shield"))
	f._on_babel_move_event({"type": "shield_bounce", "tile_id": t.id})
	assert_true(v.shield_flashing(), "flashes")
	assert_true(f.sfx.played.has("shield_bounce"))
	_run(f, 0.6)
	assert_false(v.shield_flashing())
	assert_false(v.shield_on(), "ring gone after sec")
	f.free()


func test_shield_follows_the_rules_shield_t_when_present() -> void:
	var f := _field()
	var t = _front(f)
	var v: Node2D = f._views[t.id]
	v.sync_shield(2.0)
	assert_true(v.shield_on())
	v.tick(2.5)
	assert_false(v.shield_on())
	f.free()


func test_scramble_view_flies_and_ends_at_the_new_place() -> void:
	var f := _field()
	var t = _front(f)
	var v: Node2D = f._views[t.id]
	var from: Vector2 = t.pos + Vector2(200.0, 150.0)
	f._on_babel_move_event({"type": "babel_move", "move": "scramble", "sec": 0.6, "moves": [{"tile_id": t.id, "from": from, "to": t.pos}]})
	assert_true(v.is_scrambling())
	v.place(f.to_screen(t.pos), f._time, t.pos.x)
	assert_true(v.position.distance_to(f.to_screen(from)) < 1.0, "starts at from")
	_run(f, 0.7)
	assert_false(v.is_scrambling())
	assert_true(v.position.distance_to(f.to_screen(t.pos)) < 1.0, "ends at to")
	f.free()


func test_scramble_reduced_motion_fades_at_the_new_place() -> void:
	var f := _field(true)
	var t = _front(f)
	var v: Node2D = f._views[t.id]
	var base := v.modulate.a
	f._on_babel_move_event({"type": "babel_move", "move": "scramble", "sec": 0.6, "moves": [{"tile_id": t.id, "from": t.pos + Vector2(200, 0), "to": t.pos}]})
	v.tick(0.3)
	v.place(f.to_screen(t.pos), f._time, t.pos.x)
	assert_true(v.position.distance_to(f.to_screen(t.pos)) < 1.0, "no travel")
	assert_true(v.modulate.a < base * 0.2, "faded out midway")
	v.tick(0.4)
	assert_true(absf(v.modulate.a - base) < 0.01, "back in")
	f.free()


func test_gust_streaks_are_capped_and_freed_after_sec() -> void:
	var f := _field()
	f._on_babel_move_event({"type": "babel_move", "move": "gust", "dir": Vector2(0.8, -0.6), "sec": 0.5})
	assert_true(f._gust_fx != null)
	assert_true(f._gust_fx.streak_count() > 0 and f._gust_fx.streak_count() <= 12, "capped")
	_run(f, 0.7)
	assert_true(f._gust_fx == null, "freed")
	f.free()


func test_gust_has_no_streaks_under_reduced_motion() -> void:
	var f := _field(true)
	f._on_babel_move_event({"type": "babel_move", "move": "gust", "dir": Vector2.RIGHT, "sec": 0.5})
	assert_true(f._gust_fx == null)
	f.free()


func test_several_moves_leave_no_extra_nodes() -> void:
	var f := _field()
	var t = _front(f)
	_tell(f, "volley", 0.1)  # builds Babel's view so it is in the baseline
	_run(f, 0.3)
	var before := _live_count(f)
	for _i in 4:
		for move in ["volley", "gust", "shield", "scramble"]:
			_tell(f, move, 0.2)
			f._on_babel_move_event({"type": "babel_move", "move": move, "dir": Vector2.LEFT, "tile_id": t.id, "sec": 0.2, "moves": [{"tile_id": t.id, "from": t.pos, "to": t.pos}]})
			f._on_babel_move_event({"type": "shield_bounce", "tile_id": t.id})
			_run(f, 0.7)
	assert_true(f._gust_fx == null)
	assert_false(f._views[t.id].shield_on())
	var after := _live_count(f)
	assert_true(after <= before + 12, "no node leak: %d -> %d" % [before, after])
	f.free()

extends "res://tests/test_case.gd"
## WP-F.21 view half: hop tell, arc lift, landing squash and ripple, miss flinch, tether warmth.

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


func _tile(f: Node2D) -> Object:
	for t in f.game_round.tiles:
		if t.plane < 2:
			return t
	return f.game_round.tiles[0]


func _ev(f: Node2D, e: Dictionary) -> void:
	f.game_round._emit(e)
	f.advance(1.0 / 60.0)


func test_tell_flight_land_cycle() -> void:
	var f := _field()
	var t := _tile(f)
	var v = f._views[t.id]
	_ev(f, {"type": "hop_tell", "tile_id": t.id, "to": 0})
	assert_true(v.is_telling(), "tell starts")
	assert_true(v.has_node("HopTellRing"), "gold ring")
	_run(f, 0.1)
	assert_true(v._wind_scale().y < 1.0, "wind-up squash")
	_run(f, 0.4)
	assert_false(v.is_telling(), "tell ends")
	assert_true(v._tell_ring == null, "ring gone")
	_ev(f, {"type": "hop", "tile_id": t.id, "from": t.pos, "to": t.pos, "sec": 0.45})
	_run(f, 0.2)
	assert_true(v.is_hopping())
	assert_true(v.hop_lift() > 10.0, "lifted mid-flight")
	assert_true(v.z_index >= 20, "drawn above the others")
	_ev(f, {"type": "hop_land", "tile_id": t.id})
	assert_false(v.is_hopping())
	assert_eq(v.hop_lift(), 0.0)
	assert_true(v.squash_active(), "landing squash")
	assert_eq(f._ripples.size(), 1, "ripple")
	_run(f, 0.5)
	assert_false(v.squash_active(), "squash clears")
	assert_eq(f._ripples.size(), 0, "ripple clears")
	assert_true(v.z_index < 20, "z restored")


func test_miss_flinches_nearest() -> void:
	var f := _field()
	var t := _tile(f)
	var v = f._views[t.id]
	f._tether_end = v.position
	_ev(f, {"type": "escape", "tile_id": t.id})
	var n := 0
	for id in f._views:
		if f._views[id].squash_active():
			n += 1
	assert_eq(n, 1, "exactly one flinch")
	assert_true(v.squash_active(), "the nearest one")
	_run(f, 0.5)
	assert_false(v.squash_active())


func test_reduced_motion_skips_lift_flinch_ring() -> void:
	var f := _field(true)
	var t := _tile(f)
	var v = f._views[t.id]
	_ev(f, {"type": "hop", "tile_id": t.id, "from": t.pos, "to": t.pos, "sec": 0.45})
	_run(f, 0.2)
	assert_eq(v.hop_lift(), 0.0, "no lift")
	assert_true(v.is_scrambling(), "fades instead")
	_ev(f, {"type": "hop_land", "tile_id": t.id})
	assert_eq(f._ripples.size(), 0, "no ring")
	f._tether_end = v.position
	_ev(f, {"type": "escape", "tile_id": t.id})
	assert_false(v.squash_active(), "no flinch")


func test_tether_warms_with_combo() -> void:
	var f := _field()
	f.game_round.combo = 1.0
	assert_eq(f.warm_tether_colour(), f.tether_colour)
	f.game_round.combo = f._n("combo.max")
	var c: Color = f.warm_tether_colour()
	assert_true(c.r > f.tether_colour.r and c.b < f.tether_colour.b, "toward coral")

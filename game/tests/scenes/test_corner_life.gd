extends "res://tests/test_case.gd"
## WP-F.18 view half: drones enter from the side they spawned on, letters breathe and stretch.

const FieldScene: PackedScene = preload("res://scenes/field.tscn")
const ThiefView := preload("res://scenes/thief_view.gd")


func _field(reduced: bool) -> Node2D:
	var f: Node2D = FieldScene.instantiate()
	f.settings.reduced_motion = reduced
	f.intro_enabled = false
	tree.root.add_child(f)
	f.begin(1, 777)
	return f


func _thief(side: int, reduced: bool = false) -> Node2D:
	var v: Node2D = ThiefView.new()
	v.setup(50.0, reduced, 0.0)
	v.set_entry(side)
	tree.root.add_child(v)
	v.place(Vector2(100.0, 400.0))
	return v


func test_thief_view_enters_from_the_left_for_the_left_edge() -> void:
	var v := _thief(-1)
	v.tick(0.02)
	assert_true(v.position.x < 100.0 - 100.0, "starts well left of its place")
	assert_true(absf(v.position.y - 400.0) < 10.0, "at its own height")
	for _i in 60:
		v.tick(1.0 / 60.0)
	assert_true(absf(v.position.x - 100.0) < 1.0, "slid in to its place")
	v.free()


func test_thief_view_enters_from_the_right_and_the_top() -> void:
	var r := _thief(1)
	r.tick(0.02)
	assert_true(r.position.x > 100.0 + 100.0, "starts right of its place")
	r.free()
	var t := _thief(0)
	t.tick(0.02)
	assert_true(absf(t.position.x - 100.0) < 1.0 and t.position.y < 400.0 - 100.0, "the top entry still drops in")
	t.free()


func test_thief_view_reduced_motion_fades_in_place() -> void:
	var v := _thief(-1, true)
	v.tick(0.02)
	assert_true(absf(v.position.x - 100.0) < 1.0 and absf(v.position.y - 400.0) < 1.0, "no travel")
	assert_true(v.modulate.a < 1.0, "fading in")
	v.free()


func test_letters_breathe_and_never_leave_their_rule_position() -> void:
	var f := _field(false)
	var t = f.game_round.tiles[0]
	var v: Node2D = f._views[t.id]
	var seen := {}
	for i in 120:
		f.advance(1.0 / 30.0)
		seen[snappedf(v.life_scale(f._time).x, 0.0001)] = true
		assert_true(v.position.distance_to(f.to_screen(t.pos)) < 1.0, "the view stays on the rule position")
	assert_true(seen.size() > 10, "the scale pulses")
	var amp := float(f._tun["tile.breathe"])
	for k in seen.keys():
		assert_true(absf(float(k) - 1.0) <= amp * 1.5 + 0.0001 + float(f._tun["tile.stretch"]) * 1.5, "the pulse stays small")
	f.free()


func test_breathing_and_stretch_are_off_under_reduced_motion() -> void:
	var f := _field(true)
	var t = f.game_round.tiles[0]
	var v: Node2D = f._views[t.id]
	for i in 60:
		f.advance(1.0 / 30.0)
		assert_eq(v.life_scale(f._time), Vector2.ONE, "no breathing or stretch")
	f.free()


func test_a_fast_letter_stretches_along_its_motion() -> void:
	var f := _field(false)
	var t = f.game_round.tiles[0]
	var v: Node2D = f._views[t.id]
	# Drive the view directly: 2000 px/s to the right.
	var x := 200.0
	var time := 100.0
	for i in 30:
		x += 2000.0 / 60.0
		time += 1.0 / 60.0
		v.place(Vector2(x, 900.0), time, 0.5)
	var s: Vector2 = v.life_scale(time)
	assert_true(s.x > s.y, "longer along the direction of travel")
	assert_true(s.x > 1.0 + float(f._tun["tile.breathe"]) * 1.01 or s.x - s.y > 0.02, "visible stretch")
	f.free()

extends "res://tests/test_case.gd"

const FieldScene: PackedScene = preload("res://scenes/field.tscn")


func _make(reduced: bool = false) -> Node2D:
	var f: Node2D = FieldScene.instantiate()
	f.settings.reduced_motion = reduced
	tree.root.add_child(f)
	f.begin("drift", 1, 12345)
	return f


func _max_gap(f: Node2D) -> float:
	var worst := 0.0
	for t in f.game_round.tiles:
		var v: Node2D = f._views[t.id]
		worst = maxf(worst, v.position.distance_to(f.to_screen(t.pos)))
	return worst


func _run_intro(f: Node2D) -> void:
	var secs: float = float(f._tun["babel.throwSec"]) + float(f._tun["babel.throwStagger"]) * float(f.game_round.tiles.size()) + 0.5
	for _i in int(secs * 60.0):
		f.advance(1.0 / 60.0)


func test_sim_waits_and_tiles_are_away_from_place_during_intro() -> void:
	var f := _make()
	assert_true(f.intro_active(), "intro runs after begin")
	var before: float = f.game_round.stats["secs"]
	for _i in 12:
		f.advance(1.0 / 60.0)
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

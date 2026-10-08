extends "res://tests/test_case.gd"

const FieldScene: PackedScene = preload("res://scenes/field.tscn")


func _make_field(autoplay: bool, mode: String = "drift") -> Node2D:
	var f: Node2D = FieldScene.instantiate()
	f.autoplay = autoplay
	tree.root.add_child(f)
	f.begin(mode, 1, 12345)
	return f


func test_autoplay_wins_a_drift_round_and_the_hud_score_matches() -> void:
	var f := _make_field(true)
	var steps := 0
	while f.game_round.state == "play" and steps < 300 * 60:
		f.advance(1.0 / 60.0)
		steps += 1
	assert_eq(f.game_round.state, "won", "round won within 300 s")
	for _i in 120:
		f.advance(1.0 / 60.0)
	var score_label := f.find_child("ScoreLabel", true, false) as Label
	assert_eq(score_label.text, "%d" % int(round(f.game_round.score)), "HUD score matches the round")
	assert_true(f.game_round.score > 0.0, "score is positive")
	assert_true(f.finished, "round_finished was emitted")
	f.free()


func test_tap_on_a_tile_fires_and_a_far_tap_does_not() -> void:
	var f := _make_field(false)
	var target = null
	for t in f.game_round.tiles:
		if t.plane < 2 and t.alive:
			target = t
			break
	assert_true(target != null, "a catchable tile exists")
	# Far from every tile: off the left edge of the screen.
	assert_eq(f.tap(Vector2(-900, -900)), -1, "far tap misses")
	assert_true(f.game_round.shot.is_empty(), "a miss fires nothing")
	var id: int = f.tap(f.to_screen(target.pos))
	assert_eq(id, target.id, "tap on the tile picks it")
	assert_eq(int(f.game_round.shot["tile_id"]), target.id, "the shot targets it")
	f.free()


func test_back_plane_tiles_cannot_be_tapped() -> void:
	var f := _make_field(false)
	var back = null
	for t in f.game_round.tiles:
		if t.plane == 2:
			back = t
			break
	assert_true(back != null, "back tiles exist")
	var p: Vector2 = f.to_screen(back.pos)
	var id: int = f.tap(p)
	assert_true(id != back.id, "back tile is decorative")
	f.free()

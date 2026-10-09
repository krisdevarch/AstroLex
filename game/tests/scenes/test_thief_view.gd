extends "res://tests/test_case.gd"

const FieldScene: PackedScene = preload("res://scenes/field.tscn")
const GameData := preload("res://rules/game_data.gd")


func _level(i: int) -> Dictionary:
	return GameData.load_content()["levels"]["act1_low_orbit"][i]


func _field(level_i: int, autoplay: bool, intro: bool = false) -> Node2D:
	var f: Node2D = FieldScene.instantiate()
	f.autoplay = autoplay
	f.intro_enabled = intro
	tree.root.add_child(f)
	f.begin_level(_level(level_i))
	return f


func _until_thief(f: Node2D) -> void:
	var n := 0
	while f.game_round.thieves.is_empty() and f.game_round.state == "play" and n < 60 * 60:
		f.advance(1.0 / 60.0)
		n += 1


func test_thief_view_appears_and_is_freed_on_down() -> void:
	var f := _field(11, false)
	_until_thief(f)
	assert_true(not f.game_round.thieves.is_empty(), "a thief spawned")
	assert_eq(f.thief_view_count(), 1, "one drone view")
	var th = f.game_round.thieves[0]
	assert_eq(f.tap(f.to_screen(th.pos)), th.id, "tap on the drone picks it")
	assert_eq(str(f.game_round.shot["kind"]), "thief", "the shot targets a thief")
	var n := 0
	while f.thief_view_count() > 0 and n < 600:
		f.advance(1.0 / 60.0)
		n += 1
	assert_eq(f.thief_view_count(), 0, "view freed once the drone is gone")
	f.free()


func test_clock_follows_time_and_does_not_drain_in_the_intro() -> void:
	var f := _field(0, false, true)
	assert_true(f.intro_active(), "intro plays")
	var t0: float = f.game_round.time_left
	for _i in 30:
		f.advance(1.0 / 60.0)
	assert_eq(f.game_round.time_left, t0, "no drain in the intro")
	f.skip_intro()
	for _i in 120:
		f.advance(1.0 / 60.0)
	var lab := f.find_child("ClockLabel", true, false) as Label
	assert_eq(lab.text, "%d" % int(ceil(f.game_round.time_left)), "readout follows the clock")
	assert_true(f.game_round.time_left < t0, "clock runs after the intro")
	f.free()


func test_pause_stops_time_and_taps() -> void:
	var f := _field(0, false)
	f.set_paused(true)
	var t0: float = f.game_round.time_left
	for _i in 60:
		f.advance(1.0 / 60.0)
	assert_eq(f.game_round.time_left, t0, "paused clock holds")
	var target = null
	for t in f.game_round.tiles:
		if t.plane < 2:
			target = t
			break
	assert_eq(f.tap(f.to_screen(target.pos)), -1, "taps ignored while paused")
	f.set_paused(false)
	f.advance(0.5)
	assert_true(f.game_round.time_left < t0, "resumes")
	f.free()


func test_autoplay_wins_level_1_12_with_thieves() -> void:
	var f := _field(11, true)
	var steps := 0
	while f.game_round.state == "play" and steps < 120 * 60:
		f.advance(1.0 / 60.0)
		steps += 1
	assert_eq(f.game_round.state, "won", "1-12 won by autoplay")
	assert_true(int(f.summary()["thieves_down"]) >= 0, "summary has thieves_down")
	f.free()

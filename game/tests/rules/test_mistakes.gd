extends "res://tests/test_case.gd"
## WP-F.23: tapping every letter cannot win. burst.maxWrong wrong catches lose the round.

const Round := preload("res://rules/round.gd")
const Bot := preload("res://tests/rules/bot.gd")
const GameData := preload("res://rules/game_data.gd")

const DT := 1.0 / 60.0

var _tun: Dictionary = GameData.load_tunables()
var _content: Dictionary = GameData.load_content()


func _make(seed_value: int, tuning := {}, act := "act1_low_orbit") -> Round:
	var t := {"burst.seconds": 120.0}
	t.merge(tuning, true)
	return Round.create_level(_tun, _content, act, {"id": "m", "seed": seed_value, "words": ["moon", "star", "orbit", "dust"], "tuning": t})


## The tap-everything player: fires at every catchable letter on the field, nearest first, whatever it is.
static func _tap_all(r: Round, max_secs: float) -> void:
	while r.state == "play" and float(r.stats["secs"]) < max_secs:
		if r.shot.is_empty():
			var origin := r.origin()
			var best := -1
			var best_d := INF
			for t in r.tiles:
				if t.plane < 2 and t.alive and t.carried_by < 0 and t.landing <= 0.0 and t.shield_t <= 0.0:
					var d: float = origin.distance_to(t.pos)
					if d < best_d:
						best_d = d
						best = t.id
			if best >= 0:
				r.fire(best)
		r.step(DT)


func _of_type(evs: Array, kind: String) -> Array:
	return evs.filter(func(e): return e["type"] == kind)


func test_tapping_every_letter_loses_every_act1_level() -> void:
	var n := 0
	for lv: Dictionary in _content["levels"]["act1_low_orbit"]:
		var r := Round.create_level(_tun, _content, "act1_low_orbit", lv)
		_tap_all(r, 200.0)
		n += 1
		assert_eq(r.state, "lost", "level %s: tapping everything must not win" % str(lv.get("id", "")))
		assert_eq(r.end_reason, "mistakes", "level %s lost on mistakes, not on the clock" % str(lv.get("id", "")))
	assert_true(n >= 12, "every Act I level checked: %d" % n)


func test_tapping_every_letter_loses_on_every_difficulty() -> void:
	for mod: Dictionary in _content.get("difficulty", {}).get("levels", []):
		var r := Round.create_level(_tun, _content, "act1_low_orbit", {"id": "d", "seed": 7, "words": ["moon", "star", "orbit", "dust"], "tuning": {"burst.seconds": 120.0}}, [mod.get("mod", {})])
		_tap_all(r, 200.0)
		assert_eq(r.state, "lost", "difficulty %s" % str(mod.get("id", "")))


func test_careful_bot_still_wins() -> void:
	for sd in 6:
		var r := _make(sd + 1)
		Bot.play(r, DT, 200.0)
		assert_eq(r.state, "won", "seed %d" % (sd + 1))
		assert_eq(r.end_reason, "", "no end reason on a win")


func test_mistakes_left_counts_down_and_the_last_one_ends_the_round() -> void:
	var r := _make(3, {"burst.maxWrong": 2})
	assert_eq(r.mistakes_left(), 2, "two allowed")
	var wrong_ids: Array[int] = []
	for t in r.tiles:
		if t.plane < 2 and t.decoy and t.kind == "":
			wrong_ids.append(t.id)
	assert_true(wrong_ids.size() >= 2, "two decoys to tap")
	r.fire(wrong_ids[0])
	while not r.shot.is_empty():
		r.step(DT)
	var ev := r.drain_events()
	var w := _of_type(ev, "wrong")
	assert_eq(w.size(), 1, "one wrong catch")
	assert_eq(int(w[0]["left"]), 1, "the event says one left")
	assert_eq(r.mistakes_left(), 1)
	assert_eq(r.state, "play", "still playing after one")
	r.fire(wrong_ids[1])
	while not r.shot.is_empty() and r.state == "play":
		r.step(DT)
	ev = r.drain_events()
	assert_eq(r.state, "lost", "the second wrong catch loses")
	assert_eq(r.end_reason, "mistakes")
	var end := _of_type(ev, "round_end")
	assert_eq(end.size(), 1)
	assert_eq(str(end[0]["reason"]), "mistakes")
	assert_eq(bool(end[0]["won"]), false)


func test_zero_max_wrong_means_no_limit() -> void:
	var r := _make(3, {"burst.maxWrong": 0, "burst.seconds": 60.0})
	assert_eq(r.mistakes_left(), -1, "no limit")
	_tap_all(r, 200.0)
	assert_true(r.state != "play", "the round still ends")
	assert_true(r.end_reason != "mistakes", "never on mistakes without a cap")


func test_time_out_reason_is_time() -> void:
	var r := _make(3, {"burst.seconds": 1.0})
	r.step(2.0)
	assert_eq(r.state, "lost")
	assert_eq(r.end_reason, "time")

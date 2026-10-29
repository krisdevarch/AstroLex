extends "res://tests/test_case.gd"
## WP-F.25: a caught letter is replaced on its own spot, so the field stays as full as it started.

const Round := preload("res://rules/round.gd")
const GameData := preload("res://rules/game_data.gd")

const DT := 1.0 / 60.0

var _tun: Dictionary = GameData.load_tunables()
var _content: Dictionary = GameData.load_content()


func _make(seed_value: int, tuning := {}) -> Round:
	var t := {"burst.seconds": 500.0, "hop.every": 0, "babel.moveEvery": 0, "thief.interval": 0}
	t.merge(tuning, true)
	return Round.create_level(_tun, _content, "act1_low_orbit", {"id": "m", "seed": seed_value, "words": ["moon", "star", "orbit", "dust"], "tuning": t})


func _catchable(r: Round) -> int:
	var n := 0
	for t in r.tiles:
		if t.plane < 2 and t.alive:
			n += 1
	return n


## A real letter the active word still needs, with its tile sitting still enough to be caught.
func _needed_tile(r: Round) -> Object:
	for s in r.active:
		if not s["filled"]:
			for t in r.tiles:
				if t.plane < 2 and t.alive and not t.decoy and t.ch == s["ch"] and t.carried_by < 0:
					return t
	return null


func _catch(r: Round, t: Object) -> void:
	var before := int(r.stats["catches"])
	assert_true(r.fire(t.id), "fire")
	for _i in 120:
		r.step(DT)
		if int(r.stats["catches"]) > before:
			return
	assert_true(false, "the catch never landed")


func test_a_right_catch_is_replaced_on_its_own_spot() -> void:
	for sd in 6:
		var r := _make(sd + 1)
		var n := _catchable(r)
		var t := _needed_tile(r)
		var spot: int = t.anchor
		_catch(r, t)
		assert_true(r._owner[spot] < 0 or _catchable(r) == n, "seed %d: the spot is empty right after the catch" % (sd + 1))
		for _i in int(float(_tun["spawner.refillDelay"]) / DT) + 3:
			r.step(DT)
		assert_eq(_catchable(r), n, "seed %d: as many letters as before the catch" % (sd + 1))
		assert_true(r._owner[spot] >= 0, "seed %d: the caught letter's spot holds a letter again" % (sd + 1))
		var repl: Object = r.find_tile(r._owner[spot])
		assert_true(repl != null and repl.id != t.id, "seed %d: a new tile" % (sd + 1))


func test_the_field_stays_full_over_several_catches() -> void:
	var r := _make(3)
	var n := _catchable(r)
	for _k in r.active.size() - 1:  # one short of finishing the word
		var t := _needed_tile(r)
		_catch(r, t)
		for _i in 60:
			r.step(DT)
		assert_eq(_catchable(r), n, "still %d letters on the field" % n)
	assert_eq(r.state, "play")


func test_without_refill_the_field_thins_out() -> void:
	var r := _make(3, {"spawner.refill": 0})
	var n := _catchable(r)
	_catch(r, _needed_tile(r))
	for _i in 60:
		r.step(DT)
	assert_eq(_catchable(r), n - 1, "one letter fewer")


func test_more_letters_than_before() -> void:
	# moon + star: 8 letters, decoys 1.0x = 8, so 16 letters on a grid of 19.
	var r := _make(1)
	assert_true(_catchable(r) >= 16, "at least 16 letters: %d" % _catchable(r))
	assert_true(float(_tun["spawner.decoyRatio"]) >= 1.0, "a decoy per real letter")

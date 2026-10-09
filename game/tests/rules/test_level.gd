extends "res://tests/test_case.gd"

const Round := preload("res://rules/round.gd")
const Bot := preload("res://tests/rules/bot.gd")
const GameData := preload("res://rules/game_data.gd")

var _tun: Dictionary = GameData.load_tunables()
var _content: Dictionary = GameData.load_content()


func _level(extra := {}) -> Dictionary:
	var lv := {"id": "t-01", "seed": 42, "babel": true, "words": ["moon", "star", "orbit", "dust"], "tuning": {}}
	lv.merge(extra, true)
	return lv


func _make(lv: Dictionary) -> Round:
	return Round.create_level(_tun, _content, "act1_low_orbit", lv)


func test_words_in_given_order() -> void:
	var r := _make(_level())
	assert_eq(Array(r.words), ["moon", "star", "orbit", "dust"], "words")
	assert_eq(r.level_id, "t-01", "id")
	assert_eq(r.round_no, 1, "round_no")
	assert_eq(r.seed_value, 42, "seed")
	var order := PackedStringArray()
	for e in Bot.play(r, 1.0 / 60.0, 600.0):
		if e["type"] == "restore":
			order.append(e["word"])
	assert_eq(Array(order), ["moon", "star", "orbit", "dust"], "restore order")


func _spawn_stats(r: Round, events: Array[Dictionary]) -> Dictionary:
	var decoys := 0
	for e in events:
		if e["type"] == "spawn" and e["decoy"] and e["plane"] < 2:
			decoys += 1
	return {"decoys": decoys}


func test_tuning_overrides() -> void:
	var base := _make(_level())
	var tuned := _make(_level({"tuning": {"spawner.decoys": 7, "drift.speed": 0.3}}))
	assert_eq(_spawn_stats(base, base.drain_events())["decoys"], int(_tun["spawner.decoys"]), "base decoys")
	assert_eq(_spawn_stats(tuned, tuned.drain_events())["decoys"], 7, "tuned decoys")
	assert_eq(float(_tun["drift.speed"]), 0.1, "base tunables untouched")
	var max_base := 0.0
	var max_tuned := 0.0
	for t in base.tiles:
		max_base = maxf(max_base, t.vel.length())
	for t in tuned.tiles:
		max_tuned = maxf(max_tuned, t.vel.length())
	assert_true(max_tuned > max_base * 2.0, "tuned tiles faster")


func test_deterministic() -> void:
	var a := Bot.play(_make(_level()), 1.0 / 60.0, 600.0)
	var b := Bot.play(_make(_level()), 1.0 / 60.0, 600.0)
	assert_true(a.size() > 10, "has events")
	assert_true(a == b, "identical event streams")


func test_babel_off() -> void:
	var on := Bot.play(_make(_level()), 1.0 / 60.0, 600.0)
	var off := Bot.play(_make(_level({"babel": false})), 1.0 / 60.0, 600.0)
	var n_on := 0
	var n_off := 0
	var restores := 0
	for e in on:
		if e["type"] == "babel":
			n_on += 1
	for e in off:
		if e["type"] == "babel":
			n_off += 1
		if e["type"] == "restore":
			restores += 1
	assert_true(n_on > 0, "babel speaks when on")
	assert_eq(n_off, 0, "no babel when off")
	assert_eq(restores, 4, "words still restored")


func test_winnable_in_a_burst() -> void:
	for sd in [1, 2, 3, 4, 5]:
		var r := _make(_level({"seed": sd}))
		Bot.play(r, 1.0 / 60.0, 60.0)
		assert_eq(r.state, "won", "won seed %d" % sd)
		assert_eq(r.restored_words.size(), 4, "all words")


func test_bot_wins_with_thieves_within_a_burst() -> void:
	for sd in [1, 2, 3, 4, 5]:
		var r := _make(_level({"seed": sd, "tuning": {"thief.interval": 4.0}}))
		var ev := Bot.play(r, 1.0 / 60.0, 60.0)
		assert_eq(r.state, "won", "won seed %d" % sd)
		assert_true(float(r.stats["secs"]) < 30.0, "within 30 s")
		assert_true(r.stars() >= 1)

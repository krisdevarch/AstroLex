extends "res://tests/test_case.gd"
## WP-F.19: Babel's telegraphed moves (volley, gust, shield, scramble).

const Round := preload("res://rules/round.gd")
const Bot := preload("res://tests/rules/bot.gd")
const GameData := preload("res://rules/game_data.gd")

const DT := 1.0 / 60.0
const ACTS := ["act1_low_orbit", "act2_nebula", "act3_tower", "act4_core"]

var _tun: Dictionary = GameData.load_tunables()
var _content: Dictionary = GameData.load_content()


func _make(seed_value: int, act := "act1_low_orbit", id := "x", tuning := {}) -> Round:
	var t := {"burst.seconds": 300.0, "thief.interval": 0}
	t.merge(tuning, true)
	var key: String = act
	if not _content.get("acts", {}).has(key) and not ACTS.has(key):
		key = "act1_low_orbit"
	return Round.create_level(_tun, _content, key, {"id": id, "seed": seed_value, "words": ["moon", "star", "orbit", "dust"], "tuning": t})


## Runs without shooting, collecting every event until secs.
func _idle(r: Round, secs: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append_array(r.drain_events())
	while r.state == "play" and float(r.stats["secs"]) < secs:
		r.step(DT)
		out.append_array(r.drain_events())
	return out


func _of(ev: Array[Dictionary], type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in ev:
		if e["type"] == type:
			out.append(e)
	return out


func _kinds(ev: Array[Dictionary]) -> Dictionary:
	var k := {}
	for e in _of(ev, "babel_move"):
		k[e["move"]] = true
	return k


func _act_key(n: int) -> String:
	for a: String in ACTS:
		if a.begins_with("act%d" % n):
			return a
	return ACTS[0]


func test_act_gating() -> void:
	var from_act := {"gust": 2, "shield": 3, "scramble": 4}
	for n in [2, 3, 4]:
		var seen := {}
		for sd in 10:
			var r := _make(sd + 1, _act_key(n), "%d-09" % n, {"babel.moveEvery": 3.0, "babel.moveFirstAt": 2.0, "thief.interval": 0})
			seen.merge(_kinds(_idle(r, 60.0)))
		for m: String in from_act:
			if int(from_act[m]) <= n:
				assert_true(seen.has(m), "act %d has %s" % [n, m])
			else:
				assert_false(seen.has(m), "act %d has no %s" % [n, m])
		assert_true(seen.has("volley"), "act %d has volley" % n)


func test_act_one_early_levels_have_none_and_late_levels_volley_only() -> void:
	for sd in 5:
		var early := _make(sd + 1, "act1_low_orbit", "1-04", {"babel.moveEvery": 3.0, "babel.moveFirstAt": 2.0})
		var ev := _idle(early, 40.0)
		assert_eq(_of(ev, "babel_tell").size() + _of(ev, "babel_move").size(), 0, "no moves on 1-04")
		var late := _make(sd + 1, "act1_low_orbit", "1-05", {"babel.moveEvery": 3.0, "babel.moveFirstAt": 2.0})
		var k := _kinds(_idle(late, 40.0))
		assert_eq(k.keys(), ["volley"], "only volley on 1-05")


func test_move_every_zero_is_off() -> void:
	var r := _make(3, "act4_core", "4-02", {"babel.moveEvery": 0.0})
	var ev := _idle(r, 60.0)
	assert_eq(_of(ev, "babel_tell").size(), 0, "no tell")
	assert_eq(_of(ev, "babel_move").size(), 0, "no move")


func test_tell_precedes_move_by_tell_sec() -> void:
	var r := _make(5, "act4_core", "4-02", {"babel.moveEvery": 6.0, "babel.moveFirstAt": 5.0})
	var tell_at := -1.0
	var checked := 0
	while r.state == "play" and float(r.stats["secs"]) < 40.0:
		r.step(DT)
		var secs := float(r.stats["secs"])
		for e in r.drain_events():
			if e["type"] == "babel_tell":
				tell_at = secs
				assert_eq(float(e["sec"]), _tun["babel.tellSec"], "tell carries tellSec")
			elif e["type"] == "babel_move":
				assert_true(tell_at >= 0.0, "a tell came first")
				assert_true(absf((secs - tell_at) - float(_tun["babel.tellSec"])) < 2.0 * DT, "gap %f" % (secs - tell_at))
				checked += 1
				tell_at = -1.0
	assert_true(checked >= 5, "several moves checked")


func test_determinism_per_seed() -> void:
	var a := _idle(_make(9, "act4_core", "4-02", {"babel.moveEvery": 4.0, "babel.moveFirstAt": 3.0}), 50.0)
	var b := _idle(_make(9, "act4_core", "4-02", {"babel.moveEvery": 4.0, "babel.moveFirstAt": 3.0}), 50.0)
	assert_eq(var_to_str(a), var_to_str(b), "same seed, same events")


func test_no_repeat_when_alternatives_exist() -> void:
	for sd in 8:
		var r := _make(sd + 1, "act4_core", "4-02", {"babel.moveEvery": 2.0, "babel.moveFirstAt": 2.0, "ramp.decoyMax": 40})
		var last := ""
		for e in _of(_idle(r, 80.0), "babel_move"):
			assert_true(e["move"] != last, "no repeat seed %d: %s" % [sd, last])
			last = e["move"]


func test_volley_adds_decoys_through_the_spawn_path_and_respects_the_cap() -> void:
	var r := _make(2, "act2_nebula", "2-02", {"babel.moveEvery": 2.0, "babel.moveFirstAt": 2.0, "babel.gustFromAct": 9, "babel.shieldFromAct": 9, "babel.scrambleFromAct": 9, "ramp.decoyMax": 20, "babel.volleyLifeSec": 1000.0})
	var max_decoys := 20
	var volleys := 0
	while r.state == "play" and float(r.stats["secs"]) < 60.0:
		r.step(DT)
		var ev := r.drain_events()
		for m in _of(ev, "babel_move"):
			volleys += 1
			var spawned := {}
			for s in _of(ev, "spawn"):
				spawned[s["tile_id"]] = s
			for id in m["tile_ids"]:
				assert_true(spawned.has(id), "volley tile has a spawn event")
				assert_true(spawned[id]["decoy"], "volley tile is a decoy")
				assert_true(r.find_tile(id).landing > 0.0, "volley tile lands first")
		var n := 0
		for t in r.tiles:
			if t.plane < 2 and t.decoy:
				n += 1
		assert_true(n <= max_decoys, "cap held (%d)" % n)
	assert_true(volleys >= 2, "volleys happened")
	var total := 0
	for t in r.tiles:
		if t.plane < 2 and t.decoy:
			total += 1
	assert_eq(total, max_decoys, "volleys fill the field up to the cap and no further")


func test_gust_never_down_and_letters_stay_in_the_field() -> void:
	var tun := {"babel.moveEvery": 2.0, "babel.moveFirstAt": 2.0, "babel.shieldFromAct": 9, "babel.scrambleFromAct": 9, "babel.gustPush": 1.2}
	var gusts := 0
	for sd in 6:
		var r := _make(sd + 1, "act2_nebula", "2-02", tun)
		while r.state == "play" and float(r.stats["secs"]) < 40.0:
			r.step(DT)
			for e in r.drain_events():
				if e["type"] == "babel_move" and e["move"] == "gust":
					gusts += 1
					var d: Vector2 = e["dir"]
					assert_true(absf(d.length() - 1.0) < 1e-4, "unit")
					assert_true(d.y <= 0.2 + 1e-6, "never down")
					assert_eq(float(e["sec"]), _tun["babel.gustSec"], "sec")
			for t in r.tiles:
				if t.plane < 2:
					assert_true(t.pos.x >= t.radius - 1e-6 and t.pos.x <= 1.0 - t.radius + 1e-6, "x in field")
					assert_true(t.pos.y >= float(_tun["field.topMargin"]) + t.radius - 1e-6 and t.pos.y <= float(_tun["field.height"]) - t.radius + 1e-6, "y in field")
	assert_true(gusts >= 3, "gusts happened")


func test_gust_pushes_letters() -> void:
	var r := _make(4, "act2_nebula", "2-02", {"babel.moveEvery": 100.0, "drift.speed": 0.0001, "drift.speedVariation": 0.0, "drift.orbitShare": 0, "drift.dartShare": 0, "drift.shyRadius": 0, "drift.rippleRadius": 0})
	r._gust_dir = Vector2(1, 0)
	r._gust_t = float(_tun["babel.gustSec"])
	var t = r.tiles[r.tiles.size() - 1]
	t.pos = Vector2(0.2, 0.8)
	t.vel = Vector2.ZERO
	t.base_speed = 0.0
	var x0: float = t.pos.x
	r.step(0.5)
	assert_true(t.pos.x > x0 + 0.02, "pushed along the gust")


func _shield_round(seed_value: int) -> Round:
	return _make(seed_value, "act3_tower", "3-02", {"babel.moveEvery": 100.0, "thief.interval": 0})


func test_shield_bounce_costs_nothing_and_expires() -> void:
	var r := _shield_round(6)
	var tgt = r._shield_target()
	assert_true(tgt != null, "a target exists")
	assert_eq(tgt.ch, r.active[0]["ch"], "the next open slot's letter")
	tgt.shield_t = float(_tun["babel.shieldSec"])
	tgt.landing = 0.0
	tgt.vel = Vector2.ZERO
	tgt.base_speed = 0.0
	r.drain_events()
	var time_before := r.time_left
	var secs_before := float(r.stats["secs"])
	var combo_before := r.combo
	assert_true(r.fire(tgt.id), "fire accepted")
	var bounced := false
	for _i in 120:
		r.step(DT)
		for e in r.drain_events():
			if e["type"] == "shield_bounce":
				bounced = true
				assert_eq(int(e["tile_id"]), tgt.id, "bounced tile")
			assert_true(e["type"] != "catch" and e["type"] != "wrong" and e["type"] != "escape", "no catch, wrong or escape")
	assert_true(bounced, "bounce event")
	assert_true(tgt.alive and r.find_tile(tgt.id) != null, "letter stays")
	assert_eq(int(r.stats["wrong"]), 0, "no wrong")
	assert_eq(int(r.stats["escapes"]), 0, "no escape counted")
	assert_eq(r.combo, combo_before, "combo unchanged")
	assert_true(absf((time_before - r.time_left) - (float(r.stats["secs"]) - secs_before)) < 1e-3, "only the clock ran")
	# Expires after shieldSec; then a shot catches it.
	while tgt.shield_t > 0.0:
		r.step(DT)
	assert_true(r.stats["secs"] > float(_tun["babel.shieldSec"]), "after shieldSec")
	r.drain_events()
	tgt.pos = Vector2(0.5, 0.8)
	r.fire(tgt.id)
	for _i in 120:
		r.step(DT)
	assert_true(r.find_tile(tgt.id) == null or int(r.stats["catches"]) > 0, "caught after expiry")


func test_shield_in_flight_bounces_on_resolution() -> void:
	var r := _shield_round(7)
	var tgt = r._shield_target()
	tgt.vel = Vector2.ZERO
	tgt.base_speed = 0.0
	tgt.landing = 0.0
	r.drain_events()
	assert_true(r.fire(tgt.id), "fired")
	tgt.shield_t = 4.0  # shield lands while the shot flies
	var bounced := false
	for _i in 90:
		r.step(DT)
		for e in r.drain_events():
			bounced = bounced or e["type"] == "shield_bounce"
	assert_true(bounced, "bounced")
	assert_eq(int(r.stats["catches"]), 0, "no catch")


func test_drones_skip_shielded_letters() -> void:
	var r := _make(8, "act3_tower", "3-02", {"babel.moveEvery": 100.0, "thief.interval": 100.0, "thief.firstAt": 1.0, "thief.max": 1})
	for t in r.tiles:
		if t.plane < 2 and not t.decoy:
			t.shield_t = 1000.0
	for _i in 60 * 10:
		r.step(DT)
	for th in r.thieves:
		assert_true(th.carrying_id < 0 and th.target_id < 0, "no grab or target on shielded letters")
	assert_eq(int(r.stats["stolen"]), 0, "nothing stolen")


func test_shield_move_targets_a_needed_letter() -> void:
	var seen := 0
	for sd in 10:
		var r := _make(sd + 1, "act3_tower", "3-02", {"babel.moveEvery": 2.0, "babel.moveFirstAt": 2.0, "babel.scrambleFromAct": 9, "babel.gustFromAct": 9})
		for e in _of(_idle(r, 30.0), "babel_move"):
			if e["move"] == "shield":
				seen += 1
				assert_eq(float(e["sec"]), _tun["babel.shieldSec"], "sec")
	assert_true(seen >= 5, "shields happened")


func test_scramble_moves_letters_inside_the_field_and_blocks_catches() -> void:
	var r := _make(3, "act4_core", "4-02", {"babel.moveEvery": 100.0})
	r.drain_events()
	var before := {}
	for t in r.tiles:
		before[t.id] = t.pos
	r._do_move("scramble")
	var ev := r.drain_events()
	var mv := _of(ev, "babel_move")
	assert_eq(mv.size(), 1, "one event")
	assert_eq(float(mv[0]["sec"]), _tun["babel.scrambleSec"], "sec")
	var moved := 0
	for m: Dictionary in mv[0]["moves"]:
		var t = r.find_tile(int(m["tile_id"]))
		assert_true(m["from"] == before[t.id], "from is the old spot")
		assert_true(m["to"] == t.pos, "to is the new spot")
		if t.pos != before[t.id]:
			moved += 1
		assert_true(t.pos.x >= t.radius - 1e-6 and t.pos.x <= 1.0 - t.radius + 1e-6, "x in field")
		assert_true(t.pos.y >= float(_tun["field.topMargin"]) + t.radius - 1e-6 and t.pos.y <= float(_tun["field.height"]) - t.radius + 1e-6, "y in field")
		assert_true(t.landing > 0.0, "uncatchable")
		assert_false(r.fire(t.id), "fire refused meanwhile")
	assert_true(moved >= mv[0]["moves"].size() - 1, "letters moved")
	# Spawn clearance: catchable tiles on one plane do not overlap.
	for a in r.tiles:
		for b in r.tiles:
			if a.id < b.id and a.plane == b.plane and a.plane < 2:
				assert_true(a.pos.distance_to(b.pos) >= a.radius + b.radius - 1e-3, "no overlap")
	for _i in int(ceil(float(_tun["babel.scrambleSec"]) / DT)) + 2:
		r.step(DT)
	for m: Dictionary in mv[0]["moves"]:
		var t2 = r.find_tile(int(m["tile_id"]))
		if t2 != null:
			assert_true(t2.landing <= 0.0, "catchable again")


func test_moves_never_fire_after_the_round_ends() -> void:
	var r := _make(3, "act4_core", "4-02", {"babel.moveEvery": 2.0, "babel.moveFirstAt": 2.0})
	r._end(false)
	r.drain_events()
	r.step(30.0)
	assert_eq(r.drain_events().size(), 0, "silent after the end")


func test_bot_wins_with_all_moves_on() -> void:
	for n in [1, 2, 3, 4]:
		for sd in 4:
			var r := _make(sd + 30, _act_key(n), "%d-09" % n, {"burst.seconds": 70.0})
			Bot.play(r, DT, 140.0)
			assert_eq(r.state, "won", "act %d seed %d" % [n, sd + 30])


func test_volley_decoys_dissolve_after_their_life() -> void:
	var r := _make(2, "act2_nebula", "2-02", {"babel.moveEvery": 100.0, "babel.moveFirstAt": 2.0, "babel.gustFromAct": 9, "babel.shieldFromAct": 9, "babel.scrambleFromAct": 9, "ramp.decoyMax": 20})
	var ev := _idle(r, 4.0)
	var moves := _of(ev, "babel_move")
	assert_true(not moves.is_empty() and moves[0]["move"] == "volley", "a volley happened")
	var ids: Array = moves[0]["tile_ids"]
	assert_true(not ids.is_empty(), "the volley fired decoys")
	var gone := _of(_idle(r, 4.0 + float(_tun["babel.volleyLifeSec"]) + 0.5), "dissolve")
	var dissolved := {}
	for d in gone:
		dissolved[int(d["tile_id"])] = true
	for id in ids:
		assert_true(r.find_tile(int(id)) == null and dissolved.has(int(id)), "volley decoy %d dissolved" % int(id))


func test_scramble_leaves_the_letter_under_fire_in_place() -> void:
	var r := _make(4, "act4_core", "4-05", {"babel.moveEvery": 1000.0})
	_idle(r, 0.5)
	var target = null
	for t in r.tiles:
		if t.plane < 2 and t.carried_by < 0 and t.landing <= 0.0:
			target = t
			break
	assert_true(target != null and r.fire(target.id), "fired")
	var before: Vector2 = target.pos
	r._scramble()
	assert_eq(target.pos, before, "the shot's letter is not scrambled")

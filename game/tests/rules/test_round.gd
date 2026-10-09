extends "res://tests/test_case.gd"

const Round := preload("res://rules/round.gd")
const Bot := preload("res://tests/rules/bot.gd")
const GameData := preload("res://rules/game_data.gd")
const LetterPool := preload("res://rules/letter_pool.gd")

var _tun: Dictionary = GameData.load_tunables()
var _content: Dictionary = GameData.load_content()


func _make(seed_value := 1, round_no := 1, act := "act1_low_orbit", mods: Array = []) -> Round:
	return Round.create(_tun, _content, act, seed_value, round_no, mods)


## Lands a shot on the tile deterministically: it stops drifting, then the shot resolves.
func _catch(r: Round, tile: RefCounted) -> void:
	tile.vel = Vector2.ZERO
	assert_true(r.fire(tile.id), "fire")
	r.step(0.5)


func _first_real(r: Round, ch: String) -> RefCounted:
	for t in r.tiles:
		if t.ch == ch and not t.decoy and t.plane < 2:
			return t
	return null


func _types(events: Array[Dictionary]) -> PackedStringArray:
	var out := PackedStringArray()
	for e in events:
		out.append(e["type"])
	return out


func _of_type(events: Array[Dictionary], type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in events:
		if e["type"] == type:
			out.append(e)
	return out


func _letters(slots: Array[Dictionary]) -> String:
	var s := ""
	for x in slots:
		s += x["ch"]
	return s


## A letter in the preview word that is not in the active word, or "" if none.
func _preview_only_letter(r: Round) -> String:
	for s in r.preview:
		if not _letters(r.active).contains(s["ch"]):
			return s["ch"]
	return ""


func test_create_picks_distinct_words_and_slots() -> void:
	var r := _make(3)
	assert_eq(r.words.size(), 4)
	var seen := {}
	for w in r.words:
		seen[w] = true
		assert_true(w in _content["acts"]["act1_low_orbit"]["words"])
	assert_eq(seen.size(), 4)
	assert_eq(_letters(r.active), r.words[0])
	assert_eq(_letters(r.preview), r.words[1])
	assert_eq(r.state, "play")
	assert_eq(r.combo, 1.0)
	assert_eq(r.time_left, 30.0)
	assert_eq(r.mode, "burst")


func test_spawns_exactly_the_needed_letters_plus_decoys_and_back_tiles() -> void:
	var r := _make(4)
	var need := LetterPool.count(r.words[0] + r.words[1])
	var real := {}
	var decoys := 0
	var back := 0
	for t in r.tiles:
		if t.plane == 2:
			back += 1
		elif t.decoy:
			decoys += 1
		else:
			real[t.ch] = int(real.get(t.ch, 0)) + 1
	assert_eq(real, need)
	assert_eq(decoys, 4)
	assert_eq(back, 6)
	assert_eq(_of_type(r.drain_events(), "spawn").size(), r.tiles.size())


func test_decoys_never_use_a_letter_of_the_active_or_preview_word() -> void:
	for seed_value in 100:
		var r := _make(seed_value, 1 + seed_value % 5, ["act1_low_orbit", "act2_nebula", "act3_tower", "act4_core"][seed_value % 4])
		_assert_no_word_letter_decoys(r)
		# and after every catch while the bot plays a while
		for _i in 400:
			if r.shot.is_empty():
				var id := Bot.target(r)
				if id >= 0:
					r.fire(id)
			r.step(0.0166667)
			if r.state != "play":
				break
			_assert_no_word_letter_decoys(r)


func _assert_no_word_letter_decoys(r: Round) -> void:
	var word_letters: String = _letters(r.active) + _letters(r.preview)
	for t in r.tiles:
		if t.plane < 2 and t.decoy:
			assert_false(word_letters.contains(t.ch), "decoy %s while %s" % [t.ch, word_letters])


func test_back_tiles_are_decorative_and_not_catchable() -> void:
	var r := _make(2)
	var found := 0
	for t in r.tiles:
		if t.plane == 2:
			found += 1
			assert_false(r.fire(t.id))
			assert_true(absf(t.radius - 0.12 * 0.45 / 2.0) < 1e-6)
	assert_eq(found, 6)
	assert_false(r.fire(99999))
	assert_true(r.shot.is_empty())


func test_tiles_stay_inside_the_bounds_while_drifting() -> void:
	var r := _make(9)
	for _i in 600:
		r.step(0.0166667)
		for t in r.tiles:
			assert_true(t.pos.x >= t.radius - 1e-6 and t.pos.x <= 1.0 - t.radius + 1e-6, "x")
			assert_true(t.pos.y >= 0.32 + t.radius - 1e-6 and t.pos.y <= 1.6 - t.radius + 1e-6, "y")
	assert_true(float(r.stats["secs"]) > 9.9)


func test_drift_speed_is_within_the_variation_band_and_ramps() -> void:
	for round_no in [1, 4]:
		var r := _make(5, round_no)
		var base: float = 0.1 * (1.0 + 0.08 * (round_no - 1))
		for t in r.tiles:
			if t.plane >= 2:
				continue
			var s: float = t.vel.length()
			assert_true(s >= base * 0.65 - 1e-6 and s <= base * 1.35 + 1e-6, "speed %f base %f" % [s, base])


func test_ramp_numbers() -> void:
	var r1 := _make(1, 1).ramp()
	assert_eq(r1["decoys"], 4)
	assert_true(absf(r1["drift"] - 1.0) < 1e-9)
	var r3 := _make(1, 3).ramp()
	assert_eq(r3["decoys"], 6)
	assert_true(absf(r3["drift"] - 1.16) < 1e-9, "drift")
	assert_eq(_make(1, 20).ramp()["decoys"], 8)
	var decoys := 0
	for t in _make(1, 20).tiles:
		if t.plane < 2 and t.decoy:
			decoys += 1
	assert_eq(decoys, 8)


func test_catch_active_slot() -> void:
	var r := _make(7)
	r.drain_events()
	var ch: String = r.words[0][0]
	var tile := _first_real(r, ch)
	_catch(r, tile)
	var ev := r.drain_events()
	assert_eq(_types(ev).slice(0, 2), PackedStringArray(["fire", "catch"]))
	var c := _of_type(ev, "catch")[0]
	assert_eq(c["where"], "active")
	assert_eq(c["tile_id"], tile.id)
	assert_true(r.active[c["slot"]]["filled"])
	assert_false(r.tiles.has(tile))
	assert_eq(r.stats["catches"], 1)
	assert_true(absf(r.combo - 1.1) < 1e-9)


func test_catch_preview_slot_then_carry_over() -> void:
	var r := _make(12)
	var ch := _preview_only_letter(r)
	for seed_value in range(13, 60):
		if ch != "":
			break
		r = _make(seed_value)
		ch = _preview_only_letter(r)
	assert_true(ch != "", "found a round with a preview-only letter")
	var tile := _first_real(r, ch)
	r.drain_events()
	_catch(r, tile)
	var c := _of_type(r.drain_events(), "catch")[0]
	assert_eq(c["where"], "preview")
	var next_word: String = r.words[1]
	var filled_slot: int = c["slot"]
	assert_true(r.preview[filled_slot]["filled"])
	# finish the active word with the bot's help; the preview slot must still be filled
	while r.word_index == 0 and r.state == "play":
		var id := Bot.target(r)
		_catch(r, r.find_tile(id))
	assert_eq(r.word_index, 1)
	assert_eq(_letters(r.active), next_word)
	assert_true(r.active[filled_slot]["filled"], "preview catch carried into the active word")


func test_wrong_catch_unneeded_resets_combo_and_flips_velocity() -> void:
	var r := _make(21)
	_catch(r, _first_real(r, r.words[0][0]))
	assert_true(r.combo > 1.0)
	var letters: String = _letters(r.active) + _letters(r.preview)
	var decoy: RefCounted = null
	for t in r.tiles:
		if t.plane < 2 and t.decoy:
			decoy = t
			break
	assert_false(letters.contains(decoy.ch))
	r.drain_events()
	decoy.vel = Vector2(0.05, -0.02)
	var before: Vector2 = decoy.vel
	r.fire(decoy.id)
	r.step(0.5)
	var ev := r.drain_events()
	var w := _of_type(ev, "wrong")[0]
	assert_eq(w["kind"], "unneeded")
	assert_eq(r.combo, 1.0)
	assert_eq(r.stats["wrong"], 1)
	assert_true(r.tiles.has(decoy), "wrong tile stays alive")
	assert_true(decoy.alive)
	assert_true(decoy.vel.dot(before) < 0.0, "velocity flipped")
	assert_true(absf(r.time_left - (30.0 - 1.0 - float(r.stats["secs"]))) < 0.01, "wrong costs 1 s: %f" % r.time_left)


func test_wrong_catch_surplus_when_letter_is_in_word_but_no_open_slot() -> void:
	var r := _make(8)
	var ch: String = r.words[0][0]
	if _letters(r.active).count(ch) + _letters(r.preview).count(ch) != 1:
		ch = ""
		for s in r.active:
			if (_letters(r.active) + _letters(r.preview)).count(s["ch"]) == 1:
				ch = s["ch"]
				break
	assert_true(ch != "")
	_catch(r, _first_real(r, ch))
	var extra = r._spawn(ch, true, 0)
	r.drain_events()
	_catch(r, extra)
	var w := _of_type(r.drain_events(), "wrong")
	assert_eq(w.size(), 1)
	assert_eq(w[0]["kind"], "surplus")


func test_surplus_real_copy_and_word_letter_decoy_dissolve_after_next_catch() -> void:
	var r: Round = null
	var first := ""
	var other := ""
	for seed_value in range(15, 80):
		r = _make(seed_value)
		first = r.words[0][0]
		other = ""
		for s in r.active:
			if s["ch"] != first and not _letters(r.preview).contains(s["ch"]) and not _letters(r.active).substr(1).contains(first):
				other = s["ch"]
				break
		if other != "" and _letters(r.active).count(first) == 1 and not _letters(r.preview).contains(first):
			break
	assert_true(other != "", "found a suitable round")
	var real_extra = r._spawn(other, false, 0)
	var decoy_extra = r._spawn(first, true, 1)
	r.drain_events()
	_catch(r, _first_real(r, first))
	var dissolved := _of_type(r.drain_events(), "dissolve")
	var ids := []
	for d in dissolved:
		ids.append(d["tile_id"])
	assert_true(ids.has(real_extra.id), "extra real copy dissolved")
	assert_true(ids.has(decoy_extra.id), "decoy of a word letter dissolved (letter first is now filled)")
	assert_false(r.tiles.has(real_extra))
	# decoy count is topped back up
	var decoys := 0
	for t in r.tiles:
		if t.plane < 2 and t.decoy:
			decoys += 1
	assert_eq(decoys, 4)


func test_real_copies_dissolve_before_decoys_of_the_same_letter() -> void:
	var r := _make(31)
	var ch: String = r.words[0][0]
	# one unfilled slot for ch; add a decoy and a second real copy: the second real copy goes first
	var real2 = r._spawn(ch, false, 0)
	var decoy2 = r._spawn(ch, true, 0)
	r.drain_events()
	r._refill()
	var ids := []
	for d in _of_type(r.drain_events(), "dissolve"):
		ids.append(d["tile_id"])
	var need: int = _letters(r.active).count(ch) + _letters(r.preview).count(ch)
	assert_true(ids.has(real2.id), "second real copy dissolves")
	assert_true(ids.has(decoy2.id), "decoy of a word letter dissolves")
	assert_true(need >= 1)
	assert_eq(_first_real(r, ch) != null, true, "needed copy stays")


func test_escape_when_the_tile_moves_more_than_tolerance() -> void:
	var r := _make(2)
	var tile := _first_real(r, r.words[0][0])
	tile.vel = Vector2.ZERO
	r.fire(tile.id)
	tile.pos += Vector2(0.2, 0.0)
	r.step(0.5)
	var ev := r.drain_events()
	assert_eq(_of_type(ev, "escape").size(), 1)
	assert_eq(_of_type(ev, "catch").size(), 0)
	assert_eq(r.stats["escapes"], 1)
	assert_true(r.tiles.has(tile))
	assert_true(r.shot.is_empty())
	# The forgiving tolerance (0.06 * 1.6) applies to everything: 0.07 is a hit.
	var q := _make(2)
	var t2 := _first_real(q, q.words[0][0])
	t2.vel = Vector2.ZERO
	q.fire(t2.id)
	t2.pos += Vector2(0.07, 0.0)
	q.step(0.5)
	assert_eq(_of_type(q.drain_events(), "escape").size(), 0)


func test_travel_time_scales_with_distance() -> void:
	var r := _make(2)
	var tile := _first_real(r, r.words[0][0])
	r.fire(tile.id)
	var d: float = r.origin().distance_to(tile.pos)
	assert_true(absf(r.shot["dur"] - 0.2 * (0.7 + 0.3 * d / 1.6)) < 1e-9)
	assert_eq(r.origin(), Vector2(0.5, 1.6))


func test_one_shot_in_flight_and_one_queued() -> void:
	var r := _make(6)
	var a := _first_real(r, r.words[0][0])
	var b: RefCounted = null
	for t in r.tiles:
		if t != a and t.plane < 2:
			b = t
			break
	a.vel = Vector2.ZERO
	b.vel = Vector2.ZERO
	r.drain_events()
	assert_true(r.fire(a.id))
	assert_false(r.fire(a.id), "same tile while in flight")
	assert_true(r.fire(b.id))
	assert_false(r.fire(b.id), "already queued")
	assert_eq(_types(r.drain_events()), PackedStringArray(["fire", "queue"]))
	r.step(0.25)
	var ev := r.drain_events()
	assert_eq(ev[ev.size() - 1]["type"], "fire", "queued shot starts when the first lands")
	assert_eq(ev[ev.size() - 1]["tile_id"], b.id)
	assert_eq(r.queued_id, -1)


func test_clock_runs_out_and_loses() -> void:
	var r := _make(3)
	r.step(10.0)
	assert_true(absf(r.time_left - 20.0) < 0.05, "drain 1/s: %f" % r.time_left)
	r.step(200.0)
	assert_eq(r.state, "lost")
	assert_eq(r.time_left, 0.0)
	var ev := r.drain_events()
	assert_eq(ev[ev.size() - 1], {"type": "round_end", "won": false})
	assert_eq(_of_type(ev, "round_end").size(), 1)
	assert_true(float(r.stats["secs"]) > 29.9 and float(r.stats["secs"]) < 30.1)
	assert_eq(r.stats["min_time"], 0.0)
	assert_eq(r.stars(), 0)
	assert_false(r.fire(r.tiles[0].id), "no shots after the round")
	r.step(1.0)
	assert_true(r.drain_events().is_empty())


func test_wrong_catch_costs_time_and_can_end_the_round() -> void:
	var r := _make(21)
	var decoy: RefCounted = null
	for t in r.tiles:
		if t.plane < 2 and t.decoy:
			decoy = t
			break
	decoy.vel = Vector2.ZERO
	var before := r.time_left
	r.fire(decoy.id)
	r.step(0.4)
	assert_true(absf((before - r.time_left) - (1.0 + 0.4)) < 0.05, "cost 1 plus clock: %f" % (before - r.time_left))
	var tc := _of_type(r.drain_events(), "time_cost")
	assert_eq(tc.size(), 1)
	assert_eq(tc[0]["reason"], "wrong")
	assert_eq(tc[0]["amount"], 1.0)
	r.time_left = 0.9
	decoy.vel = Vector2.ZERO
	r.fire(decoy.id)
	r.step(0.4)
	assert_eq(r.state, "lost")
	var ev := r.drain_events()
	assert_eq(_types(ev).slice(_types(ev).size() - 3), PackedStringArray(["wrong", "time_cost", "round_end"]))


func test_stars_thresholds() -> void:
	var r := _make(1)
	assert_eq(r.stars(), 0, "not won")
	r.state = "won"
	for pair in [[30.0, 3], [10.0, 3], [9.9, 2], [5.0, 2], [4.9, 1], [0.1, 1]]:
		r.time_left = pair[0]
		assert_eq(r.stars(), pair[1], str(pair[0]))


func test_mods_apply_set_then_mul_then_add_in_order() -> void:
	var mods := [
		{"set": {"burst.seconds": 20}, "mul": {"burst.seconds": 2.0}, "add": {"burst.seconds": 5}},
		{"mul": {"burst.seconds": 0.5}},
	]
	var r := _make(1, 1, "act1_low_orbit", mods)
	assert_eq(r.time_left, 22.5, "((20*2)+5)*0.5")
	assert_eq(float(_tun["burst.seconds"]), 30.0, "base untouched")
	var d := _make(1, 1, "act1_low_orbit", [{"add": {"spawner.decoys": -10}}])
	var n := 0
	for t in d.tiles:
		if t.plane < 2 and t.decoy:
			n += 1
	assert_eq(n, 0, "decoys clamp to 0")
	var lv := Round.create_level(_tun, _content, "act1_low_orbit", {"id": "x", "seed": 1, "words": ["moon", "star"], "tuning": {"burst.seconds": 10}}, [{"mul": {"burst.seconds": 3}}])
	assert_eq(lv.time_left, 30.0, "level tuning first, then mod")


func test_thieves_off_when_interval_is_zero() -> void:
	var r := _make(5)
	for _i in 25:
		r.step(1.0)
		assert_true(r.thieves.is_empty())
	assert_eq(_of_type(r.drain_events(), "thief_spawn").size(), 0)


func _thief_round(seed_value := 5, extra := {}) -> Round:
	var tuning := {"thief.firstAt": 1.0, "thief.interval": 100.0, "thief.max": 1}
	tuning.merge(extra, true)
	return Round.create_level(_tun, _content, "act1_low_orbit", {"id": "th", "seed": seed_value, "words": ["moon", "star", "orbit", "dust"], "tuning": tuning})


func test_thief_steals_when_nobody_shoots_and_round_stays_winnable() -> void:
	for sd in [5, 6, 7]:
		var r := _thief_round(sd)
		var evs: Array[Dictionary] = []
		while r.state == "play" and _of_type(evs, "stolen").is_empty() and float(r.stats["secs"]) < 25.0:
			r.step(1.0 / 60.0)
			evs.append_array(r.drain_events())
		assert_eq(_of_type(evs, "thief_spawn").size(), 1, "spawned")
		assert_eq(_of_type(evs, "thief_grab").size(), 1, "grab")
		var st := _of_type(evs, "stolen")
		assert_eq(st.size(), 1, "stolen")
		assert_eq(r.thieves.size(), 0)
		assert_eq(r.find_tile(st[0]["tile_id"]), null, "tile gone")
		var costs := _of_type(evs, "time_cost")
		assert_eq(costs[costs.size() - 1]["reason"], "stolen")
		assert_eq(costs[costs.size() - 1]["amount"], 2.0)
		assert_eq(r.stats["stolen"], 1)
		var secs := float(r.stats["secs"])
		assert_true(absf(r.time_left - (30.0 - secs - 2.0)) < 0.05, "time cost applied")
		var ch: String = st[0]["ch"]
		var rest := Bot.play(r, 1.0 / 60.0, 60.0)
		evs.append_array(rest)
		assert_eq(r.state, "won", "still winnable seed %d" % sd)
		var respawned := false
		for e in rest:
			if e["type"] == "spawn" and e["ch"] == ch and not e["decoy"]:
				respawned = true
		assert_true(respawned, "letter respawned")


func test_shooting_a_carrying_thief_frees_the_letter() -> void:
	var r := _thief_round(5)
	var th = null
	while r.state == "play" and float(r.stats["secs"]) < 25.0:
		r.step(1.0 / 60.0)
		if not r.thieves.is_empty() and r.thieves[0].carrying_id >= 0:
			th = r.thieves[0]
			break
	assert_true(th != null, "a thief grabbed")
	r.drain_events()
	var tile_id: int = th.carrying_id
	var tile := r.find_tile(tile_id)
	assert_true(tile.carried_by == th.id)
	assert_false(r.fire(tile_id), "carried tile not catchable")
	assert_true(r.fire(th.id), "thief shootable")
	r.step(0.5)
	var ev := r.drain_events()
	var down := _of_type(ev, "thief_down")
	assert_eq(down.size(), 1)
	assert_eq(down[0]["tile_id"], tile_id)
	assert_eq(_of_type(ev, "wrong").size(), 0, "not a wrong catch")
	assert_eq(r.stats["thieves_down"], 1)
	assert_eq(r.stats["wrong"], 0)
	assert_true(r.thieves.is_empty())
	assert_true(tile.alive and tile.carried_by < 0)
	tile.vel = Vector2.ZERO
	assert_true(r.fire(tile_id), "catchable again")


func test_thieves_are_deterministic() -> void:
	var a := Bot.play(_thief_round(9, {"thief.interval": 3.0, "thief.max": 2}), 1.0 / 60.0, 60.0)
	var b := Bot.play(_thief_round(9, {"thief.interval": 3.0, "thief.max": 2}), 1.0 / 60.0, 60.0)
	assert_true(_of_type(a, "thief_spawn").size() > 0)
	assert_eq(a, b)


func test_restore_score_and_events() -> void:
	var r := _make(40)
	r.drain_events()
	var w: String = r.words[0]
	while r.word_index == 0 and r.state == "play":
		_catch(r, r.find_tile(Bot.target(r)))
	var n := w.length()
	var combo := minf(2.0, 1.0 + 0.1 * n)
	var expected := 10.0 * n * (1.0 + 0.1 * (n - 3)) * combo
	var ev := r.drain_events()
	var rs := _of_type(ev, "restore")
	assert_eq(rs.size(), 1)
	assert_eq(rs[0]["word"], w)
	assert_true(absf(rs[0]["score"] - expected) < 1e-6, "%f vs %f" % [rs[0]["score"], expected])
	assert_true(absf(r.score - expected) < 1e-6)
	var types := _types(ev)
	assert_true(types.find("restore") < types.find("babel") or types.find("babel") == -1, "restore before babel")
	assert_eq(r.restored_words, PackedStringArray([w]))
	assert_eq(_letters(r.active), r.words[1])


func test_win_pays_the_time_bonus() -> void:
	var r := _make(50)
	r.step(5.0)
	var ev := Bot.play(r, 0.0166667, 60.0)
	assert_eq(r.state, "won")
	var sum := 0.0
	for e in _of_type(ev, "restore"):
		sum += e["score"]
	assert_true(absf(r.score - (sum + 5.0 * r.time_left)) < 1e-6, "bonus: %f vs %f + 5*%f" % [r.score, sum, r.time_left])
	assert_true(r.time_left > 0.0 and r.time_left < 30.0)
	assert_true(float(r.stats["min_time"]) < 30.0)
	assert_true(r.stars() >= 1)
	assert_eq(_of_type(ev, "round_end")[0]["won"], true)


func test_babel_lines_follow_restore_and_never_repeat() -> void:
	var r := _make(60)
	var ev := Bot.play(r, 0.0166667, 600.0)
	assert_eq(r.state, "won")
	var seen := {}
	for e in _of_type(ev, "babel"):
		assert_false(seen.has(e["text"]))
		seen[e["text"]] = true
	assert_eq(_of_type(ev, "restore").size(), 4)
	assert_eq(_of_type(ev, "round_end").size(), 1)
	assert_eq(ev[ev.size() - 1]["type"], "round_end")


func test_same_seed_same_event_stream() -> void:
	var a := Bot.play(_make(77), 0.0166667, 600.0)
	var b := Bot.play(_make(77), 0.0166667, 600.0)
	assert_true(a.size() > 20)
	assert_eq(a, b)
	var c := Bot.play(_make(78), 0.0166667, 600.0)
	assert_true(c != Bot.play(_make(77), 0.0166667, 600.0))


func _run_schedule(seed_value: int, dt: float) -> Dictionary:
	var r := _make(seed_value)
	var events: Array[Dictionary] = []
	var steps_per_half := int(round(0.5 / dt))
	for k in 12:
		for tile in r.tiles:
			if tile.alive and not tile.decoy and tile.plane < 2:
				r.fire(tile.id)
				break
		for _i in steps_per_half:
			r.step(dt)
		events.append_array(r.drain_events())
	return {"r": r, "events": events}


func test_step_size_does_not_change_the_outcome_of_the_sim() -> void:
	var ref := _run_schedule(5, 1.0 / 120.0)
	assert_true(ref["events"].size() > 3, "schedule produces events")
	for dt in [1.0 / 30.0, 1.0 / 60.0]:
		var o := _run_schedule(5, dt)
		assert_eq(o["events"], ref["events"], "events dt %f" % dt)
		var a: Round = o["r"]
		var b: Round = ref["r"]
		assert_eq(a.tiles.size(), b.tiles.size())
		for i in a.tiles.size():
			assert_true(a.tiles[i].pos.distance_to(b.tiles[i].pos) < 1e-4, "tile %d dt %f" % [i, dt])


func test_babel_calls_do_not_shift_tile_spawns() -> void:
	var wa := _make(31)
	var wb := _make(31)
	# Heavy Babel use on one round must leave the spawn stream untouched.
	for _i in 25:
		wa._babel_rng.randi()
	for i in wa.tiles.size():
		assert_eq(wa.tiles[i].pos, wb.tiles[i].pos)
	assert_eq(wa._rng.randi(), wb._rng.randi())


func test_thousand_seeded_rounds_are_solvable_in_drift() -> void:
	var acts: Array = _content["acts"].keys()
	assert_eq(acts.size(), 4)
	var worst := 0.0
	var wins := 0
	for i in 1000:
		var r := _make(1000 + i, 1 + i % 3, acts[i % 4])
		var ev := Bot.play(r, 0.0166667, 600.0)
		if r.state != "won":
			failures.append("seed %d act %s not won (state %s, word %d, secs %f)" % [1000 + i, acts[i % 4], r.state, r.word_index, r.stats["secs"]])
			continue
		wins += 1
		worst = maxf(worst, float(r.stats["secs"]))
		assert_eq(r.restored_words, r.words)
		# babel lines only from restored letters, none repeated
		var pool := {}
		var shown := {}
		for e in ev:
			if e["type"] == "restore":
				var cnt := LetterPool.count(e["word"])
				for c: String in cnt:
					pool[c] = int(pool.get(c, 0)) + int(cnt[c])
			elif e["type"] == "babel":
				assert_true(LetterPool.fits(e["text"], pool), "babel '%s' outside pool" % e["text"])
				assert_false(shown.has(e["text"]), "babel repeat")
				shown[e["text"]] = true
	assert_eq(wins, 1000)
	assert_true(worst < 30.0)


func test_back_tiles_drift_slower_than_catchable_tiles() -> void:
	var r := _make(77)
	var back := 0.0
	var front := 0.0
	var nb := 0
	var nf := 0
	for t in r.tiles:
		if t.plane >= 2:
			back += t.vel.length()
			nb += 1
		else:
			front += t.vel.length()
			nf += 1
	assert_true(nb > 0 and nf > 0, "both kinds exist")
	assert_true(back / nb < front / nf * 0.6, "back mean speed well below catchable mean")
	var cap: float = float(_tun["drift.speed"]) * float(r.ramp()["drift"]) * (1.0 + float(_tun["drift.speedVariation"])) * float(_tun["plane.backSpeedMul"])
	for t in r.tiles:
		if t.plane >= 2:
			assert_true(t.vel.length() <= cap + 0.0001, "back speed capped by backSpeedMul")


func test_thief_cannot_grab_tile_under_an_inflight_shot() -> void:
	var r := _thief_round(5)
	var th = null
	while r.state == "play" and float(r.stats["secs"]) < 25.0:
		r.step(1.0 / 60.0)
		if not r.thieves.is_empty() and r.thieves[0].target_id >= 0:
			th = r.thieves[0]
			break
	assert_true(th != null, "a thief is chasing")
	r.drain_events()
	var tile_id: int = th.target_id
	assert_true(r.fire(tile_id), "chased tile shootable")
	r.step(1.0 / 60.0)
	assert_true(th.target_id != tile_id, "thief dropped the shot tile")
	while not r.shot.is_empty() and r.state == "play":
		r.step(1.0 / 60.0)
	for g in _of_type(r.drain_events(), "thief_grab"):
		assert_true(g["tile_id"] != tile_id, "no grab of the shot tile")


func test_thief_schedule_advances_when_spawn_skipped_at_max() -> void:
	var r := _thief_round(5, {"thief.interval": 5.0, "thief.firstAt": 1.0, "thief.max": 1})
	while r.state == "play" and float(r.stats["secs"]) < 6.05:
		r.step(1.0 / 60.0)
	assert_eq(r.thieves.size(), 1, "still one thief at the skipped attempt")
	r.thieves.clear()
	r.drain_events()
	while r.state == "play" and float(r.stats["secs"]) < 9.0:
		r.step(1.0 / 60.0)
	assert_eq(_of_type(r.drain_events(), "thief_spawn").size(), 0, "no replacement before next interval")

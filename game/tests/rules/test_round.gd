extends "res://tests/test_case.gd"

const Round := preload("res://rules/round.gd")
const Bot := preload("res://tests/rules/bot.gd")
const GameData := preload("res://rules/game_data.gd")
const LetterPool := preload("res://rules/letter_pool.gd")

var _tun: Dictionary = GameData.load_tunables()
var _content: Dictionary = GameData.load_content()


func _make(seed_value := 1, mode := "drift", round_no := 1, act := "act1_low_orbit") -> Round:
	return Round.create(_tun, _content, act, mode, seed_value, round_no)


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
	assert_eq(r.oxygen, 100.0)


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
		var r := _make(seed_value, "drift", 1 + seed_value % 5, ["act1_low_orbit", "act2_nebula", "act3_tower", "act4_core"][seed_value % 4])
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
			assert_true(absf(t.radius - 0.12 * 0.65 / 2.0) < 1e-6)
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
		var r := _make(5, "drift", round_no)
		var base: float = 0.1 * (1.0 + 0.08 * (round_no - 1))
		for t in r.tiles:
			var s: float = t.vel.length()
			assert_true(s >= base * 0.65 - 1e-6 and s <= base * 1.35 + 1e-6, "speed %f base %f" % [s, base])


func test_ramp_numbers() -> void:
	var r1 := _make(1, "drift", 1).ramp()
	assert_eq(r1["decoys"], 4)
	assert_true(absf(r1["drift"] - 1.0) < 1e-9 and absf(r1["drain"] - 1.0) < 1e-9)
	var r3 := _make(1, "drift", 3).ramp()
	assert_eq(r3["decoys"], 6)
	assert_true(absf(r3["drift"] - 1.16) < 1e-9, "drift")
	assert_true(absf(r3["drain"] - 1.2) < 1e-9, "drain")
	assert_eq(_make(1, "drift", 20).ramp()["decoys"], 8)
	var decoys := 0
	for t in _make(1, "drift", 20).tiles:
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
	assert_eq(r.oxygen, 100.0, "no oxygen cost in Drift")


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
	# Pressure has the tighter tolerance: 0.07 is within 0.06 * 1.6 but not within 0.06
	for pair in [["drift", 0], ["pressure", 1]]:
		var q := _make(2, pair[0])
		var t2 := _first_real(q, q.words[0][0])
		t2.vel = Vector2.ZERO
		q.fire(t2.id)
		t2.pos += Vector2(0.07, 0.0)
		q.step(0.5)
		assert_eq(_of_type(q.drain_events(), "escape").size(), pair[1], pair[0])


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


func test_pressure_drains_and_loses() -> void:
	var r := _make(3, "pressure")
	r.step(10.0)
	assert_true(absf(r.oxygen - 90.0) < 0.2, "drain 1/s")
	r.step(200.0)
	assert_eq(r.state, "lost")
	assert_eq(r.oxygen, 0.0)
	var ev := r.drain_events()
	assert_eq(ev[ev.size() - 1], {"type": "round_end", "won": false})
	assert_eq(_of_type(ev, "round_end").size(), 1)
	assert_true(float(r.stats["secs"]) > 99.0 and float(r.stats["secs"]) < 101.0)
	assert_eq(r.stats["min_oxygen"], 0.0)
	assert_false(r.fire(r.tiles[0].id), "no shots after the round")
	r.step(1.0)
	assert_true(r.drain_events().is_empty())


func test_pressure_ramps_the_drain_and_drift_never_loses() -> void:
	var r := _make(3, "pressure", 3)
	r.step(10.0)
	assert_true(absf(r.oxygen - 88.0) < 0.3, "drain x1.2: %f" % r.oxygen)
	var d := _make(3, "drift")
	d.step(300.0)
	assert_eq(d.state, "play")
	assert_eq(d.oxygen, 100.0)


func test_pressure_wrong_catch_costs_oxygen_and_can_end_the_round() -> void:
	var r := _make(21, "pressure")
	var decoy: RefCounted = null
	for t in r.tiles:
		if t.plane < 2 and t.decoy:
			decoy = t
			break
	decoy.vel = Vector2.ZERO
	var before := r.oxygen
	r.fire(decoy.id)
	r.step(0.4)
	assert_true(absf((before - r.oxygen) - (4.0 + 0.4)) < 0.1, "cost 4 plus drain: %f" % (before - r.oxygen))
	r.oxygen = 3.0
	decoy.vel = Vector2.ZERO
	r.fire(decoy.id)
	r.step(0.4)
	assert_eq(r.state, "lost")
	var ev := r.drain_events()
	assert_eq(_types(ev).slice(_types(ev).size() - 2), PackedStringArray(["wrong", "round_end"]))


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


func test_restore_gives_oxygen_in_pressure_and_win_pays_the_bonus() -> void:
	var r := _make(50, "pressure")
	r.step(20.0)
	var ev := Bot.play(r, 0.0166667, 600.0)
	assert_eq(r.state, "won")
	var sum := 0.0
	for e in _of_type(ev, "restore"):
		sum += e["score"]
	assert_true(absf(r.score - (sum + 2.0 * r.oxygen)) < 1e-6, "bonus: %f vs %f + 2*%f" % [r.score, sum, r.oxygen])
	assert_true(r.oxygen > 0.0 and r.oxygen <= 100.0)
	assert_true(float(r.stats["min_oxygen"]) < 100.0)
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
	for mode in ["drift", "pressure"]:
		var a := Bot.play(_make(77, mode), 0.0166667, 600.0)
		var b := Bot.play(_make(77, mode), 0.0166667, 600.0)
		assert_true(a.size() > 20)
		assert_eq(a, b, mode)
	var c := Bot.play(_make(78), 0.0166667, 600.0)
	assert_true(c != Bot.play(_make(77), 0.0166667, 600.0))


func test_step_size_does_not_change_the_outcome_of_the_sim() -> void:
	var a := _make(5)
	var b := _make(5)
	for _i in 120:
		a.step(1.0 / 60.0)
	b.step(2.0)
	assert_true(absf(float(a.stats["secs"]) - float(b.stats["secs"])) < 0.02, "%f %f" % [a.stats["secs"], b.stats["secs"]])
	for i in a.tiles.size():
		assert_true(a.tiles[i].pos.distance_to(b.tiles[i].pos) < 0.01)


func test_thousand_seeded_rounds_are_solvable_in_drift() -> void:
	var acts: Array = _content["acts"].keys()
	assert_eq(acts.size(), 4)
	var worst := 0.0
	var wins := 0
	for i in 1000:
		var r := _make(1000 + i, "drift", 1 + i % 3, acts[i % 4])
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
	assert_true(worst < 600.0)

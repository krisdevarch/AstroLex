extends "res://tests/test_case.gd"
## WP-F.1: counterfeits, anagram traps and Stroop jamming (rules only; the look is in test_hazard_view.gd).

const Round := preload("res://rules/round.gd")
const Bot := preload("res://tests/rules/bot.gd")
const GameData := preload("res://rules/game_data.gd")

var _tun: Dictionary = GameData.load_tunables()
var _content: Dictionary = GameData.load_content()


func _mods(forged: float, traps: int, stroop: int) -> Array:
	return [{"set": {"hazard.counterfeitRatio": forged, "hazard.traps": traps, "hazard.stroop": stroop, "burst.seconds": 200}}]


func _make(seed_value: int, forged: float, traps: int, stroop: int) -> Round:
	return Round.create(_tun, _content, "act2_nebula", seed_value, 1, _mods(forged, traps, stroop))


func _catch(r: Round, tile: RefCounted) -> void:
	tile.vel = Vector2.ZERO
	assert_true(r.fire(tile.id), "fire")
	r.step(0.5)


func _needed(r: Round, ch: String) -> bool:
	for s in r.active:
		if s["ch"] == ch and not s["filled"]:
			return true
	for s in r.preview:
		if s["ch"] == ch and not s["filled"]:
			return true
	return false


func _kind_tiles(r: Round, kind: String) -> Array:
	var out: Array = []
	for t in r.tiles:
		if t.kind == kind and t.plane < 2:
			out.append(t)
	return out


func _of_type(events: Array[Dictionary], type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in events:
		if e["type"] == type:
			out.append(e)
	return out


func _signature(r: Round) -> String:
	var parts := PackedStringArray()
	for t in r.tiles:
		parts.append("%d%s%s%d" % [t.id, t.ch, t.kind, t.plane])
	return ",".join(parts) + "|" + r.trap_word


# --- counterfeits ------------------------------------------------------------------------

func test_no_hazards_by_default() -> void:
	for s in 40:
		var r := Round.create(_tun, _content, "act2_nebula", s)
		assert_eq(r.trap_word, "", "no trap word by default")
		for t in r.tiles:
			assert_eq(t.kind, "", "plain tile")
		r.step(20.0)
		assert_false(r.jammed, "no jam by default")


func test_ratio_zero_changes_nothing_in_the_spawn_stream() -> void:
	var a := Round.create(_tun, _content, "act2_nebula", 7)
	var b := _make(7, 0.0, 0, 0)
	var sa := _signature(a)
	var sb := _signature(b)
	assert_eq(sa, sb, "ratio 0 spawns the same letters")


func test_counterfeits_only_with_ratio_and_only_on_needed_letters() -> void:
	for s in 200:
		var r := _make(s, 0.5, 0, 0)
		var forged := _kind_tiles(r, "counterfeit")
		assert_true(forged.size() >= 1, "seed %d has a counterfeit" % s)
		for t in forged:
			assert_true(t.decoy, "a counterfeit is a decoy")
			assert_true(_needed(r, t.ch), "seed %d: counterfeit %s is a needed letter" % [s, t.ch])
		var decoys := 0
		for t in r.tiles:
			if t.decoy and t.plane < 2:
				decoys += 1
		assert_true(forged.size() <= decoys, "a share of the decoys")


func test_catching_a_counterfeit_costs_time_and_emits_the_event() -> void:
	var r := _make(3, 0.5, 0, 0)
	var f: RefCounted = _kind_tiles(r, "counterfeit")[0]
	var ch: String = f.ch
	var real: RefCounted = null
	for t in r.tiles:
		if t.ch == ch and not t.decoy and t.plane < 2:
			real = t
	assert_true(real != null, "the real letter is out there")
	r.drain_events()
	var before := r.time_left
	var slots_filled := 0
	_catch(r, f)
	var ev := r.drain_events()
	var got := _of_type(ev, "counterfeit")
	assert_eq(got.size(), 1, "one counterfeit event")
	assert_eq(_of_type(ev, "catch").size(), 0, "not a catch")
	var cost := _of_type(ev, "time_cost")
	assert_eq(cost.size(), 1, "one time cost")
	assert_eq(float(cost[0]["amount"]), float(_tun["burst.wrongCost"]), "costs the wrong-catch price")
	assert_true(r.time_left < before - 0.4, "clock lost the cost on top of the half second")
	assert_eq(int(r.stats["counterfeits"]), 1, "stat")
	assert_eq(r.combo, 1.0, "combo resets")
	for s in r.active:
		if s["filled"]:
			slots_filled += 1
	assert_eq(slots_filled, 0, "no slot filled")
	assert_true(r.find_tile(real.id) != null, "the real letter stays")
	assert_true(r.find_tile(f.id) == null, "the forgery is gone")
	assert_true(_kind_tiles(r, "counterfeit").size() >= 1, "a new forgery is made")


func test_counterfeits_do_not_fill_hints_or_survive_their_letter() -> void:
	var r := _make(11, 0.5, 0, 0)
	var id := r.use_hint()
	assert_true(id >= 0, "hint works")
	assert_eq(r.find_tile(id).kind, "", "the hint never points at a forgery")
	# Finish the word: forgeries of its letters must not linger as forgeries of nothing.
	var guard := 0
	while r.state == "play" and r.word_index == 0 and guard < 20:
		guard += 1
		var tid := Bot.target(r)
		if tid < 0:
			r.step(0.2)
			continue
		_catch(r, r.find_tile(tid))
	for t in _kind_tiles(r, "counterfeit"):
		assert_true(_needed(r, t.ch), "every live forgery fools a needed letter")


# --- anagram traps -----------------------------------------------------------------------

func _trap_round() -> Round:
	for s in 100:
		var r := _make(s, 0.0, 1, 0)
		if r.trap_word != "":
			return r
	return null


func test_trap_word_uses_only_unneeded_letters_and_is_in_the_lexicon() -> void:
	var lex := {}
	for e: Array in _content["lexicon"]:
		lex[e[0]] = true
	var with_trap := 0
	for s in 200:
		var r := _make(s, 0.0, 1, 0)
		if r.trap_word == "":
			continue
		with_trap += 1
		assert_true(lex.has(r.trap_word), "lexicon word")
		for w in r.words:
			for c in r.trap_word:
				assert_false(w.contains(c), "seed %d: trap letter %s is in word %s" % [s, c, w])
		var letters := PackedStringArray()
		for t in _kind_tiles(r, "trap"):
			letters.append(t.ch)
		letters.sort()
		var want := PackedStringArray()
		for c in r.trap_word:
			want.append(c)
		want.sort()
		assert_eq(",".join(letters), ",".join(want), "the trap tiles spell the word")
	assert_true(with_trap > 150, "most seeds can build a trap (%d / 200)" % with_trap)


func test_two_trap_letters_in_the_window_set_it_off_once() -> void:
	var r := _trap_round()
	assert_true(r != null, "a trap round exists")
	var tiles := _kind_tiles(r, "trap")
	r.drain_events()
	var before := r.time_left
	_catch(r, tiles[0])
	assert_eq(_of_type(r.drain_events(), "trap").size(), 0, "one letter is not enough")
	_catch(r, tiles[1])
	var ev := r.drain_events()
	var traps := _of_type(ev, "trap")
	assert_eq(traps.size(), 1, "trap event")
	assert_eq(traps[0]["word"], r.trap_word, "Babel's word")
	assert_eq(float(traps[0]["cost"]), float(_tun["hazard.trapCost"]), "cost")
	var lines := _of_type(ev, "babel")
	assert_eq(lines.size(), 1, "Babel speaks")
	assert_eq(str(lines[0]["text"]).to_lower().trim_suffix("."), r.trap_word, "he says the word")
	var trap_costs := 0
	for c in _of_type(ev, "time_cost"):
		if c["reason"] == "trap":
			trap_costs += 1
	assert_eq(trap_costs, 1, "the clock loses the trap cost")
	assert_true(r.time_left <= before - float(_tun["hazard.trapCost"]) - 1.0, "clock")
	assert_eq(int(r.stats["traps"]), 1, "stat")
	# More trap letters do not set it off again.
	var more := _kind_tiles(r, "trap")
	if not more.is_empty():
		_catch(r, more[0])
	assert_eq(_of_type(r.drain_events(), "trap").size(), 0, "once per round")


func test_trap_letters_outside_the_window_do_not_count() -> void:
	var r := _trap_round()
	var tiles := _kind_tiles(r, "trap")
	_catch(r, tiles[0])
	tiles[1].vel = Vector2.ZERO
	r.step(float(_tun["hazard.trapWindowSec"]) + 1.0)
	r.drain_events()
	_catch(r, tiles[1])
	assert_eq(_of_type(r.drain_events(), "trap").size(), 0, "too late")
	assert_false(r.trap_fired, "not fired")


# --- Stroop jam --------------------------------------------------------------------------

func test_jam_toggles_on_schedule() -> void:
	var r := _make(5, 0.0, 0, 1)
	var every := float(_tun["hazard.stroopEverySec"])
	var dur := float(_tun["hazard.stroopSec"])
	var ons: Array[float] = []
	var offs: Array[float] = []
	while float(r.stats["secs"]) < every * 2.0 + dur + 1.0 and r.state == "play":
		r.step(0.05)
		for e in r.drain_events():
			if e["type"] == "jam_on":
				ons.append(float(r.stats["secs"]))
				assert_true(r.jammed, "jammed when on")
			elif e["type"] == "jam_off":
				offs.append(float(r.stats["secs"]))
				assert_false(r.jammed, "clear when off")
	assert_eq(ons.size(), 2, "two jams")
	assert_eq(offs.size(), 2, "two clears")
	assert_true(absf(ons[0] - every) < 0.1, "first jam at the mark")
	assert_true(absf(offs[0] - (every + dur)) < 0.1, "lasts stroopSec")
	assert_true(absf(ons[1] - every * 2.0) < 0.1, "second jam")
	assert_eq(int(r.stats["jams"]), 2, "stat")


func test_jam_off_when_disabled() -> void:
	var r := _make(5, 0.0, 0, 0)
	r.step(40.0)
	assert_eq(int(r.stats["jams"]), 0, "never")


# --- determinism and properties ----------------------------------------------------------

func test_deterministic_for_a_seed() -> void:
	var a := _make(21, 0.5, 1, 1)
	var b := _make(21, 0.5, 1, 1)
	assert_eq(_signature(a), _signature(b), "same start")
	var ea := Bot.play(a, 1.0 / 30.0, 40.0)
	var eb := Bot.play(b, 1.0 / 30.0, 40.0)
	assert_eq(ea.size(), eb.size(), "same event count")
	assert_eq(_signature(a), _signature(b), "same end")
	assert_eq(a.state, b.state, "same outcome")


func test_all_hazards_stay_winnable_for_the_bot() -> void:
	var won := 0
	for s in 60:
		var r := _make(s, 0.5, 1, 1)
		Bot.play(r, 1.0 / 30.0, 190.0)
		if r.state == "won":
			won += 1
		assert_eq(int(r.stats["counterfeits"]), 0, "the bot never takes a forgery")
	assert_eq(won, 60, "every hazard board is solvable")

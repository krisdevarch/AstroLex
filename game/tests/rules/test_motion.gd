extends "res://tests/test_case.gd"
## WP-F.18: drones from three sides, letter motion styles, shy and ripple reactions.

const Round := preload("res://rules/round.gd")
const Bot := preload("res://tests/rules/bot.gd")
const GameData := preload("res://rules/game_data.gd")

const DT := 1.0 / 60.0
const NO_STYLE := {"drift.orbitShare": 0, "drift.dartShare": 0}

var _tun: Dictionary = GameData.load_tunables()
var _content: Dictionary = GameData.load_content()


func _make(seed_value: int, tuning := {}, act := "act1_low_orbit") -> Round:
	var t := {"burst.seconds": 500.0}
	t.merge(tuning, true)
	return Round.create_level(_tun, _content, act, {"id": "m", "seed": seed_value, "words": ["moon", "star", "orbit", "dust"], "tuning": t})


func _thief_round(seed_value: int, extra := {}) -> Round:
	var tuning := {"thief.firstAt": 1.0, "thief.interval": 100.0, "thief.max": 1}
	tuning.merge(extra, true)
	return _make(seed_value, tuning)


func _spawned_thief(r: Round) -> RefCounted:
	while r.thieves.is_empty() and float(r.stats["secs"]) < 5.0:
		r.step(DT)
	return null if r.thieves.is_empty() else r.thieves[0]


func _real_tiles(r: Round) -> Array:
	return r.tiles.filter(func(t): return not t.decoy and t.plane < 2)


func test_side_spawn_share_and_positions() -> void:
	var top := float(_tun["field.topMargin"])
	var h := float(_tun["field.height"])
	var max_y := top + float(_tun["thief.sideMaxY"]) * (h - top)
	var sides := 0
	var lefts := 0
	var rights := 0
	var n := 200
	for sd in n:
		var r := _thief_round(sd + 1, {"thief.sideShare": 0.6})
		var th := _spawned_thief(r)
		assert_true(th != null, "spawned")
		var ev: Array = r.drain_events().filter(func(e): return e["type"] == "thief_spawn")
		var p: Vector2 = ev[0]["pos"]
		if p.x == 0.0 or p.x == 1.0:
			sides += 1
			lefts += 1 if p.x == 0.0 else 0
			rights += 1 if p.x == 1.0 else 0
			assert_true(p.y >= top and p.y <= max_y + 1e-6, "side y in the upper band")
		else:
			assert_true(absf(p.y - top) < 1e-5, "top spawn on the top margin")
		assert_true(p.y <= h, "never spawns below the field")
	var share := float(sides) / float(n)
	assert_true(share > 0.48 and share < 0.72, "side share near 0.6: %f" % share)
	assert_true(lefts > 20 and rights > 20, "both edges used")


func test_act1_side_share_zero_is_top_only() -> void:
	var top := float(_tun["field.topMargin"])
	for sd in 40:
		var r := _thief_round(sd + 1, {"thief.sideShare": 0})
		_spawned_thief(r)
		var ev: Array = r.drain_events().filter(func(e): return e["type"] == "thief_spawn")
		assert_true(absf(ev[0]["pos"].y - top) < 1e-5, "top only")
	# The shipped Act I level data sets it on every level that has drones.
	var f := FileAccess.open("res://../data/levels/act1_low_orbit.json", FileAccess.READ)
	if f != null:
		var data: Dictionary = JSON.parse_string(f.get_as_text())
		for lv: Dictionary in data["levels"]:
			if lv.get("tuning", {}).has("thief.interval"):
				assert_eq(lv["tuning"].get("thief.sideShare"), 0, "level %s" % lv["id"])


## Puts the thief on the tile and steps until it grabs; returns the thief.
func _grab_at(r: Round, th: RefCounted, p: Vector2) -> RefCounted:
	var tile: RefCounted = _real_tiles(r)[0]
	tile.pos = p
	tile.vel = Vector2.ZERO
	th.pos = p
	th.target_id = tile.id
	for _i in 10:
		r.step(DT)
		if th.state == "flee":
			break
		tile.pos = p
	assert_eq(th.state, "flee", "grabbed")
	return th


func test_flee_to_nearest_edge_and_stolen_when_crossing() -> void:
	var cases := [
		{"p": Vector2(0.12, 0.9), "dir": Vector2(-1.0, 0.0)},
		{"p": Vector2(0.88, 0.9), "dir": Vector2(1.0, 0.0)},
		{"p": Vector2(0.5, 0.4), "dir": Vector2(0.0, -1.0)},
		{"p": Vector2(0.3, 1.4), "dir": Vector2(-1.0, 0.0)},
	]
	for c in cases:
		var r := _thief_round(5, {"thief.sideShare": 0})
		var th := _spawned_thief(r)
		_grab_at(r, th, c["p"])
		var dir: Vector2 = th.vel.normalized()
		assert_true(dir.distance_to(c["dir"]) < 1e-4, "flee dir for %s" % str(c["p"]))
		assert_true(th.vel.y <= 0.0, "never flees down")
		r.drain_events()
		for _i in 600:
			if r.thieves.is_empty():
				break
			r.step(DT)
		assert_true(r.thieves.is_empty(), "escaped")
		assert_eq(r.stats["stolen"], 1, "stolen")
		var crossed: bool = th.pos.x < 0.0 or th.pos.x > 1.0 or th.pos.y < 0.0
		assert_true(crossed, "left through the left, right or top edge")
		assert_true(th.pos.y <= 1.6, "never through the bottom")


func test_thieves_never_go_below_the_field() -> void:
	for sd in 12:
		var r := _thief_round(sd + 1, {"thief.sideShare": 1.0, "thief.interval": 4.0, "thief.max": 2})
		var floor_y := float(_tun["field.height"])
		var steps := 0
		while r.state == "play" and steps < 60 * 40:
			steps += 1
			r.step(DT)
			for th: RefCounted in r.thieves:
				assert_true(th.pos.y <= floor_y + 1e-6, "above the floor")
				if th.state == "flee":
					assert_true(th.vel.y <= 0.0, "flee never down")


func _styles(r: Round) -> Array:
	return r.tiles.map(func(t): return "%d:%s:%d" % [t.id, t.style, 1 if t.decoy else 0])


func test_styles_deterministic_per_seed_and_decoys_wander() -> void:
	var a := _styles(_make(7))
	assert_eq(a, _styles(_make(7)), "same seed same styles")
	var counts := {"wander": 0, "orbit": 0, "dart": 0}
	for sd in 40:
		var r := _make(sd + 1)
		for t: RefCounted in r.tiles:
			if t.decoy:
				assert_eq(t.style, "wander", "decoys wander")
			elif t.plane < 2:
				counts[t.style] += 1
	assert_true(counts["orbit"] > 0 and counts["dart"] > 0 and counts["wander"] > 0, "all three styles occur: %s" % str(counts))
	var differs := false
	for sd in 10:
		if _styles(_make(sd + 1)) != _styles(_make(sd + 100)):
			differs = true
	assert_true(differs, "styles vary with the seed")


func test_style_does_not_disturb_the_spawner() -> void:
	for sd in [3, 8]:
		var a := _make(sd)
		var b := _make(sd, NO_STYLE)
		assert_eq(a.tiles.size(), b.tiles.size(), "same tile count")
		for i in a.tiles.size():
			assert_eq(a.tiles[i].pos, b.tiles[i].pos, "same spawn position")
			assert_eq(a.tiles[i].ch, b.tiles[i].ch, "same letter")


func _mean_speed(r: Round, secs: float) -> float:
	var sum := 0.0
	var n := 0
	var steps := int(secs / DT)
	for _i in steps:
		var before := {}
		for t: RefCounted in _real_tiles(r):
			before[t.id] = t.pos
		r.step(DT)
		for t: RefCounted in _real_tiles(r):
			if before.has(t.id):
				sum += (t.pos - before[t.id]).length() / DT
				n += 1
	return sum / float(n)


func test_mean_speed_within_ten_percent_of_wander_only() -> void:
	var with_styles := 0.0
	var plain := 0.0
	var seeds := 8
	for sd in seeds:
		with_styles += _mean_speed(_make(sd + 1, {"drift.orbitShare": 0.4, "drift.dartShare": 0.4}), 40.0)
		plain += _mean_speed(_make(sd + 1, NO_STYLE), 40.0)
	var ratio := with_styles / plain
	assert_true(ratio > 0.9 and ratio < 1.1, "mean speed ratio %f" % ratio)
	var ratio_default := 0.0
	for sd in seeds:
		ratio_default += _mean_speed(_make(sd + 1), 40.0)
	ratio_default /= plain
	assert_true(ratio_default > 0.9 and ratio_default < 1.1, "default shares ratio %f" % ratio_default)


func test_dart_bursts_in_new_direction_and_is_catchable_mid_burst() -> void:
	var tried := 0
	for sd in 30:
		var r := _make(sd + 1, {"drift.orbitShare": 0, "drift.dartShare": 1.0})
		var needed: String = r.active[0]["ch"]
		var tile: RefCounted = null
		for t: RefCounted in _real_tiles(r):
			if t.ch == needed:
				tile = t
				break
		if tile == null:
			continue
		r.tiles = [tile]  # alone on the field: no collisions to blur the speed readings
		var speeds: Array = []
		var guard := 0
		r.step(DT)
		while tile.dart_burst and guard < 60 * 10:
			guard += 1
			r.step(DT)
		while not tile.dart_burst and guard < 60 * 10:
			guard += 1
			r.step(DT)
			speeds.append(tile.vel.length())
		assert_true(tile.dart_burst, "reaches a burst")
		var peak := 0.0
		for _i in 12:
			r.step(DT)
			peak = maxf(peak, tile.vel.length())
		assert_true(peak > tile.base_speed, "bursting is faster than base (seed %d peak %f base %f norm %f)" % [sd + 1, peak, tile.base_speed, tile.dart_norm])
		assert_true(peak <= tile.base_speed / tile.dart_norm * float(_tun["drift.dartBoost"]) + 1e-6, "capped (seed %d peak %f base %f norm %f)" % [sd + 1, peak, tile.base_speed, tile.dart_norm])
		r.drain_events()
		assert_true(r.fire(tile.id), "fire")
		var guard2 := 0
		var evs: Array[Dictionary] = []
		while r.shot.size() > 0 and guard2 < 120:
			guard2 += 1
			r.step(DT)
			evs.append_array(r.drain_events())
		var types := evs.map(func(e): return e["type"])
		assert_false(types.has("escape"), "darting letter caught (seed %d)" % (sd + 1))
		tried += 1
	assert_true(tried >= 10, "enough samples")


func test_ripple_pushes_neighbours_out() -> void:
	var r := _make(4, NO_STYLE)
	var needed: String = r.active[0]["ch"]
	var tile: RefCounted = null
	var nb: RefCounted = null
	for t: RefCounted in _real_tiles(r):
		if tile == null and t.ch == needed:
			tile = t
	for t: RefCounted in r.tiles:
		if t != tile and t.plane < 2:
			nb = t
			break
	for t: RefCounted in r.tiles:
		if t != tile and t != nb:
			t.pos = Vector2(0.1, 1.5)
			t.vel = Vector2.ZERO
	var c := Vector2(0.4, 0.9)
	tile.pos = c
	tile.vel = Vector2.ZERO
	nb.pos = c + Vector2(0.18, 0.0)
	nb.vel = Vector2.ZERO
	r.fire(tile.id)
	var guard := 0
	while r.find_tile(tile.id) != null and guard < 120:
		guard += 1
		r.step(DT)
	assert_true(r.find_tile(tile.id) == null, "caught")
	var d0: float = nb.pos.distance_to(c)
	for _i in 30:
		r.step(DT)
	assert_true(nb.pos.distance_to(c) > d0 + 0.01, "neighbour pushed out")
	for _i in 60:
		r.step(DT)
	var settled: Vector2 = nb.pos
	r.step(DT * 10.0)
	assert_true(nb.pos.distance_to(settled) < 1e-4, "impulse decays to nothing")


func test_shy_moves_letters_away_from_a_drone() -> void:
	var away_total := 0.0
	for sd in [2, 5, 9]:
		var shy := _thief_round(sd, {"thief.radius": 0.01, "drift.orbitShare": 0, "drift.dartShare": 0})
		var ctl := _thief_round(sd, {"thief.radius": 0.01, "drift.shyPush": 0, "drift.orbitShare": 0, "drift.dartShare": 0})
		var p := Vector2.ZERO
		var origin := Vector2(0.5, 0.8)
		for r: Round in [shy, ctl]:
			var th := _spawned_thief(r)
			var tile: RefCounted = _real_tiles(r)[0]
			for t: RefCounted in r.tiles:
				if t != tile:
					t.pos = Vector2(0.1, 1.5)
			tile.pos = origin + Vector2(0.1, 0.0)
			tile.vel = Vector2(0.0, 0.01)
			tile.base_speed = 0.0
			th.pos = origin
			th.target_id = tile.id
			th.vel = Vector2.ZERO
			for _i in 12:
				th.pos = origin
				r.step(DT)
			p = tile.pos if r == shy else p
			if r == ctl:
				away_total += p.distance_to(origin) - tile.pos.distance_to(origin)
	assert_true(away_total > 0.0, "shy letter ends farther from the drone than the control (%f)" % away_total)


func test_bot_still_wins_with_all_motion_on() -> void:
	for sd in 6:
		var r := _make(sd + 1, {"burst.seconds": 60.0})
		Bot.play(r, DT, 120.0)
		assert_eq(r.state, "won", "act1 seed %d" % (sd + 1))
	for sd in 4:
		var r2 := _make(sd + 20, {"burst.seconds": 60.0}, "act2_nebula")
		Bot.play(r2, DT, 120.0)
		assert_eq(r2.state, "won", "act2 seed %d" % (sd + 20))


func test_spawn_event_names_the_entry_side() -> void:
	for sd in 60:
		var r := _thief_round(sd + 1, {"thief.sideShare": 0.6})
		var th := _spawned_thief(r)
		var ev: Array = r.drain_events().filter(func(e): return e["type"] == "thief_spawn")
		var p: Vector2 = ev[0]["pos"]
		var want := -1 if p.x == 0.0 else (1 if p.x == 1.0 else 0)
		assert_eq(int(ev[0]["entry"]), want, "event entry matches the edge")
		assert_eq(th.entry, want, "thief keeps its entry after it moves")


func test_orbit_letter_does_not_jump_on_its_first_step() -> void:
	var r := _make(7, {"drift.orbitShare": 1.0, "drift.dartShare": 0, "drift.shyRadius": 0, "drift.rippleRadius": 0})
	var before := {}
	for t in _real_tiles(r):
		before[t.id] = t.pos
	r.step(DT)
	for t in _real_tiles(r):
		if t.style == "orbit":
			assert_true(t.pos.distance_to(before[t.id]) < 0.03, "orbit step is small: %f" % t.pos.distance_to(before[t.id]))


func test_slow_letters_wander_instead_of_orbiting() -> void:
	var r := _make(3, {"drift.orbitShare": 1.0, "drift.dartShare": 0, "drift.speed": 0.03})
	for t in _real_tiles(r):
		assert_eq(t.style, "wander", "too slow to orbit without speeding up")


func test_letter_fired_mid_round_cannot_be_caught_until_it_lands() -> void:
	var r := _make(5)
	r.step(0.5)
	var any: Array = _real_tiles(r)
	var stolen: RefCounted = any[0]
	r._remove(stolen)
	r._refill()
	var fresh: Array = r.tiles.filter(func(t): return t.landing > 0.0)
	assert_true(not fresh.is_empty(), "a mid-round spawn is landing")
	var id: int = fresh[0].id
	assert_true(not r.fire(id), "cannot be caught while it flies in")
	r.step(float(_tun["babel.throwSec"]) + 0.05)
	assert_true(r.fire(id) or not r.shot.is_empty(), "catchable once landed")

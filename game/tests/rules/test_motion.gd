extends "res://tests/test_case.gd"
## WP-F.18 and WP-F.21: drones from three sides, anchored drift, hops, shy and ripple reactions.

const Round := preload("res://rules/round.gd")
const Bot := preload("res://tests/rules/bot.gd")
const GameData := preload("res://rules/game_data.gd")

const DT := 1.0 / 60.0
const Thief := preload("res://rules/thief.gd")
## Tunables that make every tile sit exactly on its anchor.
const STILL := {"anchors.swayX": 0, "anchors.swayY": 0, "anchors.waveAmp": 0, "drift.bob": 0, "hop.every": 0}
## Everything on: Babel's moves every few seconds, hops every second or so.
const BUSY := {"burst.seconds": 5000.0, "thief.interval": 0, "babel.moveEvery": 3.0, "babel.moveFirstAt": 2.0, "babel.tellSec": 0.5, "hop.every": 1.2, "hop.jitter": 0.4, "hop.firstAt": 1.0}

var _tun: Dictionary = GameData.load_tunables()
var _content: Dictionary = GameData.load_content()


func _make(seed_value: int, tuning := {}, act := "act1_low_orbit") -> Round:
	var t := {"burst.seconds": 500.0}
	t.merge(tuning, true)
	return Round.create_level(_tun, _content, act, {"id": "m", "seed": seed_value, "words": ["moon", "star", "orbit", "dust"], "tuning": t})


func _thief_round(seed_value: int, extra := {}) -> Round:
	var tuning := {"thief.firstAt": 1.0, "thief.interval": 100.0, "thief.max": 1, "babel.moveEvery": 0}
	tuning.merge(STILL, true)
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
	r._anchors[tile.anchor] = p
	tile.pos = p
	th.pos = p
	th.target_id = tile.id
	for _i in 10:
		r.step(DT)
		if th.state == "flee":
			break
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


# --- anchored drift (WP-F.21) ---------------------------------------------------------------

func _catchables(r: Round) -> Array:
	return r.tiles.filter(func(t): return t.plane < 2 and t.carried_by < 0)


## Letters resting on their anchors: a hopper in flight is lifted over the others and left out.
func _resting(r: Round) -> Array:
	return r.tiles.filter(func(t): return t.plane < 2 and t.carried_by < 0 and not t.hop_air)


func _types(evs: Array) -> Array:
	return evs.map(func(e): return e["type"])


func test_anchor_layout_is_a_honeycomb_inside_the_field() -> void:
	var r := _make(1)
	var n: int = r.anchor_count()
	assert_eq(n, 18, "anchor count at the default tunables")
	var spacing := float(_tun["anchors.spacing"])
	var inset := float(_tun["tile.size"]) * 0.5 + float(_tun["anchors.maxOffset"])
	var closest := INF
	for i in n:
		var a: Vector2 = r.anchor_pos(i)
		assert_true(a.x >= inset - 1e-6 and a.x <= 1.0 - inset + 1e-6, "anchor %d x inside" % i)
		assert_true(a.y >= float(_tun["field.topMargin"]) + inset - 1e-6 and a.y <= float(_tun["field.height"]) - inset + 1e-6, "anchor %d y inside" % i)
		for j in range(i + 1, n):
			closest = minf(closest, a.distance_to(r.anchor_pos(j)))
	assert_true(absf(closest - spacing) < 1e-6, "neighbouring anchors sit one spacing apart: %f" % closest)


func test_spacing_keeps_offset_letters_apart() -> void:
	var need := float(_tun["tile.size"]) + float(_tun["tile.minGap"]) + 2.0 * float(_tun["anchors.maxOffset"])
	assert_true(float(_tun["anchors.spacing"]) >= need - 1e-9, "spacing %f >= %f" % [float(_tun["anchors.spacing"]), need])
	assert_true(float(_tun["anchors.waveAmp"]) <= float(_tun["anchors.maxOffset"]), "the wave fits in the offset budget")


func test_every_catchable_tile_holds_a_unique_anchor() -> void:
	for sd in 8:
		var r := _make(sd + 1, BUSY, "act4_core")
		for _i in 600:
			r.step(DT)
			var seen := {}
			for t: RefCounted in _catchables(r):
				assert_true(t.anchor >= 0, "tile %d has an anchor" % t.id)
				assert_false(seen.has(t.anchor), "anchor %d held twice (seed %d)" % [t.anchor, sd + 1])
				seen[t.anchor] = true
				assert_eq(r._owner[t.anchor], t.id, "owner table agrees")


## No two catchable tiles ever closer than tile.size + minGap, with sway, wave, bob, hops, gust, volley and
## scramble all running; the separation safety net never has anything to do. `play` adds the autoplay bot
## (catches, ripples and respawns during hops).
func _overlap_run(seed_value: int, play: bool) -> Dictionary:
	var r := _make(seed_value, BUSY, "act4_core")
	var need := float(_tun["tile.size"]) + float(_tun["tile.minGap"]) - 1e-6
	var seen := {}
	var worst := INF
	for _i in 2000:
		if play and r.shot.is_empty():
			var id := Bot.target(r)
			if id >= 0:
				r.fire(id)
		r.step(DT)
		if r.state != "play":
			break
		for e: Dictionary in r.drain_events():
			seen[e["type"]] = int(seen.get(e["type"], 0)) + 1
			if e["type"] == "babel_move":
				seen[e["move"]] = int(seen.get(e["move"], 0)) + 1
		var live := _resting(r)
		for i in live.size():
			for j in range(i + 1, live.size()):
				worst = minf(worst, live[i].pos.distance_to(live[j].pos))
		if worst < need:
			assert_true(false, "overlap %f < %f at step %d (seed %d, play %s)" % [worst, need, _i, seed_value, play])
			break
		assert_false(r._separate_tiles(), "separation moved nothing (seed %d step %d)" % [seed_value, _i])
	return seen


func test_no_overlap_over_2000_steps_with_everything_on() -> void:
	var totals := {}
	for sd in 20:
		var seen := _overlap_run(sd + 1, sd % 2 == 1)
		for k in seen:
			totals[k] = int(totals.get(k, 0)) + int(seen[k])
	for k in ["hop", "gust", "scramble", "volley", "shield", "catch"]:
		assert_true(int(totals.get(k, 0)) > 0, "the run exercised %s: %s" % [k, str(totals)])


func test_motion_is_smooth_between_steps() -> void:
	var r := _make(3, {"hop.every": 0, "babel.moveEvery": 0, "thief.interval": 0})
	var m := float(_tun["anchors.maxOffset"])
	var before := {}
	for t: RefCounted in _catchables(r):
		before[t.id] = t.pos
	for _i in 1200:
		r.step(DT)
		for t: RefCounted in _catchables(r):
			assert_true(t.pos.distance_to(before[t.id]) <= m, "step %d moved %f" % [_i, t.pos.distance_to(before[t.id])])
			before[t.id] = t.pos


func test_body_and_bob_move_letters_off_their_anchor() -> void:
	var r := _make(2, {"hop.every": 0})
	var moved := 0.0
	var t0: RefCounted = _catchables(r)[0]
	for _i in 600:
		r.step(DT)
		moved = maxf(moved, t0.pos.distance_to(r.anchor_pos(t0.anchor)))
	assert_true(moved > 0.01, "the field is never still: %f" % moved)
	var still := _make(2, STILL)
	var t1: RefCounted = _catchables(still)[0]
	for _i in 120:
		still.step(DT)
	assert_true(t1.pos.distance_to(still.anchor_pos(t1.anchor)) < 1e-6, "all motion off: the letter sits on its anchor")


func _hop_log(seed_value: int, secs: float) -> Array:
	var r := _make(seed_value, {"hop.every": 1.5, "hop.jitter": 0.4, "hop.firstAt": 1.0, "babel.moveEvery": 0, "thief.interval": 0})
	var log: Array = []
	while float(r.stats["secs"]) < secs:
		r.step(DT)
		for e: Dictionary in r.drain_events():
			if str(e["type"]).begins_with("hop"):
				log.append("%s:%d:%.3f" % [e["type"], int(e["tile_id"]), float(r.stats["secs"])])
	return log


func test_hops_happen_in_order_and_are_deterministic() -> void:
	var a := _hop_log(4, 20.0)
	assert_eq(a, _hop_log(4, 20.0), "same seed, same hops")
	assert_true(a != _hop_log(5, 20.0), "hops vary with the seed")
	var tells := a.filter(func(x): return x.begins_with("hop_tell"))
	var lands := a.filter(func(x): return x.begins_with("hop_land"))
	assert_true(tells.size() >= 4, "several hops in 20 s: %d" % tells.size())
	assert_true(absi(tells.size() - lands.size()) <= 1, "every hop lands")
	var first_tell := float((tells[0] as String).split(":")[2])
	assert_true(first_tell >= 1.0 - 0.05 and first_tell < 4.0, "first hop near hop.firstAt: %f" % first_tell)


func test_hop_tell_then_takeoff_then_flight_then_landing() -> void:
	for sd in [4, 6, 9]:
		var r := _make(sd, {"hop.every": 1.5, "hop.firstAt": 1.0, "babel.moveEvery": 0, "thief.interval": 0})
		var at := {}
		var tile_id := -1
		var guard := 0
		var from_pos := Vector2.ZERO
		while not at.has("hop_land") and guard < 60 * 20:
			guard += 1
			r.step(DT)
			for e: Dictionary in r.drain_events():
				if e["type"].begins_with("hop") and (tile_id < 0 or e["tile_id"] == tile_id):
					tile_id = int(e["tile_id"])
					at[e["type"]] = float(r.stats["secs"])
					if e["type"] == "hop":
						assert_eq(float(e["sec"]), float(_tun["hop.flySec"]), "flight time")
						from_pos = e["from"]
						assert_true(not r.find_tile(tile_id).decoy, "a real letter hops")
		assert_true(at.has("hop_land"), "a hop completes (seed %d)" % sd)
		assert_true(absf(at["hop"] - at["hop_tell"] - float(_tun["hop.windSec"])) < 0.05, "wind-up lasts hop.windSec")
		assert_true(absf(at["hop_land"] - at["hop"] - float(_tun["hop.flySec"])) < 0.05, "flight lasts hop.flySec")
		var t: RefCounted = r.find_tile(tile_id)
		assert_true(t.hop_to < 0 and t.anchor >= 0, "landed on its destination")


func _shielded_round(seed_value: int) -> Round:
	var r := _make(seed_value, {"hop.every": 1.5, "babel.moveEvery": 0, "thief.interval": 0})
	return r


func test_hop_skips_target_queued_hinted_shielded_landing_and_drone_targets() -> void:
	var controls := 0
	for sd in 40:
		var probe := _shielded_round(sd + 1)
		var reals := _real_tiles(probe)
		for t: RefCounted in reals.slice(1):
			t.shield_t = 99.0
		probe.drain_events()
		probe._start_hop()
		if not _types(probe.drain_events()).has("hop_tell"):
			continue
		controls += 1
		for kind in ["shot", "queued", "hinted", "shield", "landing", "drone"]:
			var r := _shielded_round(sd + 1)
			var x: RefCounted = _real_tiles(r)[0]
			for t: RefCounted in _real_tiles(r).slice(1):
				t.shield_t = 99.0
			match kind:
				"shot":
					r.shot = {"tile_id": x.id, "kind": "tile", "from": Vector2.ZERO, "to": x.pos, "elapsed": 0.0, "dur": 9.0}
				"queued":
					r.queued_id = x.id
				"hinted":
					r._hinted_id = x.id
				"shield":
					x.shield_t = 99.0
				"landing":
					x.landing = 5.0
				"drone":
					var th := Thief.new()
					th.id = 9999
					th.target_id = x.id
					r.thieves.append(th)
			r.drain_events()
			r._start_hop()
			assert_false(_types(r.drain_events()).has("hop_tell"), "no hop for a %s letter (seed %d)" % [kind, sd + 1])
		if controls >= 6:
			break
	assert_true(controls >= 3, "the control hop happened often enough: %d" % controls)


func test_hops_are_gated_by_act_level_and_hop_every() -> void:
	var cases := [
		{"act": "act1_low_orbit", "id": "1-02", "tune": {}, "hops": false},
		{"act": "act1_low_orbit", "id": "1-03", "tune": {}, "hops": true},
		{"act": "act2_nebula", "id": "2-01", "tune": {}, "hops": true},
		{"act": "act2_nebula", "id": "2-01", "tune": {"hop.every": 0}, "hops": false},
	]
	for c in cases:
		var tune := {"burst.seconds": 500.0, "hop.firstAt": 1.0, "hop.every": 1.0, "babel.moveEvery": 0, "thief.interval": 0}
		tune.merge(c["tune"], true)
		var r := Round.create_level(_tun, _content, c["act"], {"id": c["id"], "seed": 11, "words": ["moon", "star", "orbit", "dust"], "tuning": tune})
		var hopped := false
		for _i in 60 * 15:
			r.step(DT)
			if _types(r.drain_events()).has("hop_tell"):
				hopped = true
				break
		assert_eq(hopped, c["hops"], "%s %s %s" % [c["act"], c["id"], str(c["tune"])])


## Steps until some letter has a hop under way; "wind" stops during the wind-up, "air" in flight.
func _until_hop(r: Round, phase: String) -> RefCounted:
	for _i in 60 * 30:
		r.step(DT)
		for t: RefCounted in r.tiles:
			if t.hop_to >= 0 and (t.hop_air == (phase == "air")):
				return t
	return null


func test_firing_at_a_hopping_letter_still_catches_it() -> void:
	var tried := 0
	for sd in 10:
		for phase in ["wind", "air"]:
			var r := _make(sd + 1, {"hop.every": 1.5, "hop.firstAt": 1.0, "babel.moveEvery": 0, "thief.interval": 0})
			var t := _until_hop(r, phase)
			if t == null or _open_slot_missing(r, t):
				continue
			tried += 1
			r.drain_events()
			var left: float = r._hop_left(t)
			assert_true(r.fire(t.id), "fire at a hopper")
			assert_true(float(r.shot["dur"]) >= left - 1e-6, "the shot lasts at least the rest of the hop")
			assert_true((r.shot["to"] as Vector2).distance_to(r._rest_pos(t, t.hop_to)) < 1e-6, "aims at the destination")
			var evs: Array = []
			var guard := 0
			while r.find_tile(t.id) != null and guard < 120:
				guard += 1
				r.step(DT)
				evs.append_array(r.drain_events())
			var types := _types(evs)
			assert_true(types.has("catch"), "caught a %s hopper (seed %d)" % [phase, sd + 1])
			assert_false(types.has("escape"), "no escape")
	assert_true(tried >= 8, "enough samples: %d" % tried)


func _open_slot_missing(r: Round, t: RefCounted) -> bool:
	return r._open_slot(r.active, t.ch) < 0 and r._open_slot(r.preview, t.ch) < 0


func test_needed_letter_spawns_when_every_anchor_is_full() -> void:
	var r := _make(2, STILL)
	for _i in 40:
		r._spawn("e", true, 0)
	assert_eq(r._free_count(), 0, "every anchor held")
	assert_true(r._spawn("e", true, 0) == null, "a decoy has nowhere to go")
	r.drain_events()
	var tile: RefCounted = r._spawn("q", false, 0)
	assert_true(tile != null and tile.anchor >= 0, "a needed letter still spawns")
	var types := _types(r.drain_events())
	assert_true(types.has("dissolve") and types.has("spawn"), "a decoy dissolved to make room")
	var seen := {}
	for t: RefCounted in _catchables(r):
		assert_false(seen.has(t.anchor), "anchors stay unique")
		seen[t.anchor] = true


func test_decoy_room_and_volley_are_capped_by_free_anchors() -> void:
	var r := _make(3, STILL)
	for _i in 40:
		r._spawn("e", true, 0)
	assert_eq(r._decoy_room(), 0, "no room with every anchor held")
	var ids: Array = []
	var r2 := _make(3, STILL, "act2_nebula")
	var free: int = r2._free_count()
	r2._do_move("volley")
	for e: Dictionary in r2.drain_events():
		if e["type"] == "babel_move":
			ids = e["tile_ids"]
	assert_true(ids.size() <= free, "a volley never needs more anchors than are free")


func test_gust_pushes_the_whole_field_and_springs_back() -> void:
	for sd in [1, 2, 3]:
		var r := _make(sd, {"hop.every": 0, "babel.moveEvery": 100.0, "thief.interval": 0}, "act2_nebula")
		var gust_sec := float(_tun["babel.gustSec"])
		r._do_move("gust")
		var peak := 0.0
		for _i in int(gust_sec / DT):
			r.step(DT)
			peak = maxf(peak, r._gust_off.length())
		assert_true(peak > 0.02, "the gust moves the body: %f" % peak)
		for _i in int(2.0 * gust_sec / DT):
			r.step(DT)
		assert_true(r._gust_off.length() < 0.002, "springs back within 2 x gustSec: %f" % r._gust_off.length())


func test_scramble_lands_every_letter_on_a_distinct_anchor() -> void:
	for sd in 8:
		var r := _make(sd + 1, {"hop.every": 1.0, "hop.firstAt": 0.5, "babel.moveEvery": 100.0, "thief.interval": 0}, "act4_core")
		for _i in 90:  # long enough for a hop to be under way on some seeds
			r.step(DT)
		r.drain_events()
		var before := _catchables(r).size()
		var hopping := {}
		for t: RefCounted in r.tiles:
			if t.hop_to >= 0:
				hopping[t.id] = true
		r._do_move("scramble")
		var moves: Array = []
		var hop_events := 0
		for e: Dictionary in r.drain_events():
			if e["type"] == "babel_move":
				moves = e["moves"]
				assert_eq(e["move"], "scramble", "the event names the move")
			elif str(e["type"]).begins_with("hop") and not hopping.has(e["tile_id"]):
				hop_events += 1  # only a hop already under way may finish
		assert_eq(hop_events, 0, "no per-letter hop events")
		assert_eq(moves.size(), before, "every letter moves")
		var seen := {}
		for t: RefCounted in _catchables(r):
			assert_true(t.anchor >= 0 and not seen.has(t.anchor), "distinct anchor (seed %d)" % (sd + 1))
			seen[t.anchor] = true
			assert_true(t.landing > 0.0, "uncatchable while it lands")
			assert_eq(r._owner[t.anchor], t.id, "owner table agrees")
		for m: Dictionary in moves:
			assert_eq(r.find_tile(int(m["tile_id"])).pos, m["to"], "to is where the letter now is")


func test_ripple_pushes_neighbours_out_then_they_settle() -> void:
	var r := _make(4, STILL)
	var tile: RefCounted = _real_tiles(r)[0]
	var c: Vector2 = tile.pos
	var near: Array = []
	for t: RefCounted in r.tiles:
		if t != tile and t.plane < 2 and t.pos.distance_to(c) < float(_tun["drift.rippleRadius"]):
			near.append(t)
	assert_true(not near.is_empty(), "the caught letter has a neighbour in range")
	r.fire(tile.id)
	var guard := 0
	while r.find_tile(tile.id) != null and guard < 120:
		guard += 1
		r.step(DT)
	assert_true(r.find_tile(tile.id) == null, "caught")
	var peak := 0.0
	for _i in 60:
		r.step(DT)
		for t: RefCounted in near:
			if r.find_tile(t.id) == t:
				var away: Vector2 = t.off
				if away.dot((t.pos - c).normalized()) > 0.0:
					peak = maxf(peak, away.length())
	assert_true(peak > 0.003, "a neighbour bobbed outward: %f" % peak)
	assert_true(peak <= float(_tun["anchors.maxOffset"]) + 1e-9, "never beyond maxOffset")
	for _i in 240:
		r.step(DT)
	for t: RefCounted in near:
		if r.find_tile(t.id) == t:
			assert_true(t.off.length() < 1e-3, "the offset settles back")


func test_shy_leans_letters_away_from_a_drone() -> void:
	var away_total := 0.0
	for sd in [2, 5, 9]:
		var shy := _thief_round(sd, {"thief.radius": 0.01})
		var ctl := _thief_round(sd, {"thief.radius": 0.01, "drift.shyPush": 0})
		var gap := 0.0
		for r: Round in [shy, ctl]:
			var th := _spawned_thief(r)
			var tile: RefCounted = _real_tiles(r)[0]
			var origin: Vector2 = tile.pos - Vector2(0.13, 0.0)  # inside shyRadius, outside the grab distance
			th.target_id = -1
			th.vel = Vector2.ZERO
			for _i in 30:
				th.pos = origin
				th.vel = Vector2.ZERO
				r.step(DT)
			var d: float = tile.pos.distance_to(origin)
			gap += d if r == shy else -d
		away_total += gap
	assert_true(away_total > 0.0, "shy letter ends farther from the drone than the control (%f)" % away_total)


func test_a_dropped_letter_takes_the_nearest_free_anchor() -> void:
	var r := _thief_round(5)
	var th := _spawned_thief(r)
	_grab_at(r, th, Vector2(0.4, 0.9))
	var tile: RefCounted = r.find_tile(th.carrying_id)
	assert_eq(tile.anchor, -1, "a drone lifts the letter off its anchor")
	r.drain_events()
	r._resolve_thief_hit(th.id, th.pos)
	var evs := r.drain_events()
	assert_true(_types(evs).has("thief_down"), "drone down")
	assert_true(tile.anchor >= 0, "the letter holds an anchor again")
	assert_eq(r._owner[tile.anchor], tile.id, "owner table agrees")
	assert_true(_types(evs).has("hop"), "it flies to its anchor")
	for _i in 60:
		r.step(DT)
	assert_true(tile.hop_to < 0, "and lands")


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

extends RefCounted
## One round of AstroLex: seeded spawner, fixed-step drift, tether shots, catch taxonomy,
## preview carry-over, surplus dissolve, a time-only 30 s burst clock, Babel-army thief drones,
## score and combo, per-round ramp, tunable modifiers (difficulty, character perks).
## Reference behaviour is toy v1.3 (web/toy/index.html). The view animates from drain_events()
## and never re-derives rules. Pure GDScript: no Node, no wall clock, one seeded RNG.
##
## Events (dictionaries with "type" plus the fields below; extras such as ch and pos are for the view):
##   spawn{tile_id,ch,plane,decoy,pos} fire{tile_id} queue{tile_id}
##   catch{tile_id,where,slot,ch,pos} wrong{tile_id,kind,ch} escape{tile_id}
##   dissolve{tile_id,ch,decoy,pos} restore{word,score} babel{text} round_end{won}
##   time_cost{amount,reason} (reason "wrong" or "stolen"; time_left already reduced)
##   thief_spawn{thief_id,pos} thief_grab{thief_id,tile_id} (the tile stops being catchable)
##   stolen{thief_id,tile_id,ch} (thief left the top with the tile; both are gone, the letter respawns later)
##   thief_down{thief_id,tile_id,pos} (shot; tile_id is the released tile or -1)
##   thief_miss{thief_id} (a shot at a thief missed or the thief was gone; counts as an escape)
## Thieves live in `thieves` (thief.gd: id, pos, vel, target_id, carrying_id, state "seek"/"flee") and
## share the tile id space; fire(id) accepts a thief id. A shot dict has "kind": "tile" or "thief".
## Tiles leave `tiles` when caught or dissolved; the view keeps its own node per tile_id.
## While a shot is in flight `shot` is {tile_id, from, to, elapsed, dur} (else empty).

const Tile := preload("res://rules/tile.gd")
const Babel := preload("res://rules/babel.gd")
const LetterPool := preload("res://rules/letter_pool.gd")
const Thief := preload("res://rules/thief.gd")
const Self := preload("res://rules/round.gd")

const BABEL_SEED_XOR := 0x5BAB31
const THIEF_SEED_XOR := 0x7E1EF5
const THIEF_IDLE_MUL := 0.25
## Letter weights for decoys and back tiles: English frequency is language data, not a feel number.
const FREQ := {"e": 127, "t": 91, "a": 82, "o": 75, "i": 70, "n": 67, "s": 63, "h": 61, "r": 60, "d": 43, "l": 40, "c": 28, "u": 28, "m": 24, "w": 24, "f": 22, "g": 20, "y": 20, "p": 19, "b": 15, "v": 10, "k": 8, "j": 2, "x": 2, "q": 1, "z": 1}
const EPS := 1e-6

var words: PackedStringArray = []
var word_index: int = 0
var active: Array[Dictionary] = []
var preview: Array[Dictionary] = []
var tiles: Array = []
var time_left: float = 0.0
var thieves: Array = []
var score: float = 0.0
var combo: float = 1.0
var state: String = "play"
var stats: Dictionary = {}
var shot: Dictionary = {}
var queued_id: int = -1
var restored_words: PackedStringArray = []
## Kept so telemetry has a field; there is only one mode now.
var mode: String = "burst"
var act: String = ""
var round_no: int = 1
var seed_value: int = 0
var level_id: String = ""
var babel_on: bool = true

var _t: Dictionary = {}
var _content: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _babel_rng := RandomNumberGenerator.new()
var _thief_rng := RandomNumberGenerator.new()
var _events: Array[Dictionary] = []
var _by_id: Dictionary = {}
var _next_id: int = 0
var _acc: float = 0.0
var _pool: Dictionary = {}
var _shown: Dictionary = {}
var _thief_by_id: Dictionary = {}
var _next_thief_at: float = INF
var _pending_respawn: Array[Dictionary] = []


static func create(tunables: Dictionary, content: Dictionary, act_key: String, seed_value_in: int, round_number: int = 1, mods: Array = []) -> Self:
	var r: Self = Self.new()
	r._t = _apply_mods(tunables.duplicate(), mods)
	r._setup(content, act_key, seed_value_in, round_number, PackedStringArray())
	return r


## An authored level: its words in order, its seed, and its tuning keys over the base tunables.
## Mods apply after the level tuning, in order.
static func create_level(tunables: Dictionary, content: Dictionary, act_key: String, level: Dictionary, mods: Array = []) -> Self:
	var r: Self = Self.new()
	var t: Dictionary = tunables.duplicate()
	var tuning: Dictionary = level.get("tuning", {})
	for k: String in tuning:
		t[k] = float(tuning[k])
	r._t = _apply_mods(t, mods)
	r.level_id = str(level.get("id", ""))
	r.babel_on = bool(level.get("babel", true))
	var w := PackedStringArray()
	for x in (level["words"] as Array):
		w.append(str(x))
	r._setup(content, act_key, int(level["seed"]), 1, w)
	return r


## Each mod is {"set":{k:v},"mul":{k:v},"add":{k:v}}; applied in order, set then mul then add.
static func _apply_mods(t: Dictionary, mods: Array) -> Dictionary:
	for m: Dictionary in mods:
		var sets: Dictionary = m.get("set", {})
		for k: String in sets:
			t[k] = sets[k]
		var muls: Dictionary = m.get("mul", {})
		for k: String in muls:
			t[k] = float(t[k]) * float(muls[k])
		var adds: Dictionary = m.get("add", {})
		for k: String in adds:
			t[k] = float(t[k]) + float(adds[k])
	t["spawner.decoys"] = maxi(0, int(round(float(t["spawner.decoys"]))))
	return t


## Shared init. Empty `fixed_words` means the seeded random pick (create()).
func _setup(content: Dictionary, act_key: String, seed_value_in: int, round_number: int, fixed_words: PackedStringArray) -> void:
	_content = content
	act = act_key
	seed_value = seed_value_in
	round_no = round_number
	_rng.seed = seed_value_in
	_babel_rng.seed = seed_value_in ^ BABEL_SEED_XOR
	_thief_rng.seed = seed_value_in ^ THIEF_SEED_XOR
	time_left = _num("burst.seconds")
	_next_thief_at = _num("thief.firstAt") if _num("thief.interval") > 0.0 else INF
	stats = {"catches": 0, "wrong": 0, "escapes": 0, "secs": 0.0, "min_time": time_left, "stolen": 0, "thieves_down": 0}
	if fixed_words.is_empty():
		_pick_words()
	else:
		words = fixed_words
	active = _slots_of(words[0])
	preview = _slots_of(words[1]) if words.size() > 1 else ([] as Array[Dictionary])
	for _i in int(_num("plane.backTiles")):
		_spawn(_weighted_letter([]), true, 2)
	_refill()


## Per-round ramp multipliers and counts (toy ramp()).
func ramp() -> Dictionary:
	var k := maxi(0, round_no - 1)
	return {
		"drift": 1.0 + _num("ramp.driftStep") * k,
		"decoys": mini(int(_num("ramp.decoyMax")), int(_num("spawner.decoys")) + int(_num("ramp.decoyStep")) * k),
	}


func step(dt: float) -> void:
	if state != "play":
		return
	_acc += dt
	var h := _num("sim.stepSec")
	while _acc + EPS >= h and state == "play":
		_acc -= h
		_tick(h)


## Starts a shot at the tile, or queues one while another is in flight. False when the tile
## cannot be caught (unknown, gone, back plane, round over, already the target or queued).
func fire(tile_id: int) -> bool:
	if state != "play":
		return false
	var thief: Thief = _thief_by_id.get(tile_id)
	var tile: Tile = _by_id.get(tile_id)
	if thief == null:
		if tile == null or not tile.alive or tile.plane >= 2 or tile.carried_by >= 0:
			return false
	if not shot.is_empty():
		if shot["tile_id"] == tile_id or queued_id == tile_id:
			return false
		queued_id = tile_id
		_emit({"type": "queue", "tile_id": tile_id})
		return true
	if thief != null:
		_start_shot_at(tile_id, thief.pos, "thief")
	else:
		_start_shot_at(tile_id, tile.pos, "tile")
	return true


func drain_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out


## Shot origin in field units.
func origin() -> Vector2:
	return Vector2(0.5, _num("field.height"))


func find_tile(tile_id: int) -> Tile:
	return _by_id.get(tile_id)


func find_thief(thief_id: int) -> Thief:
	return _thief_by_id.get(thief_id)


## 0 unless won; 3 / 2 / 1 by seconds left.
func stars() -> int:
	if state != "won":
		return 0
	if time_left >= _num("stars.three"):
		return 3
	if time_left >= _num("stars.two"):
		return 2
	return 1


# --- setup -------------------------------------------------------------------------------

func _num(key: String) -> float:
	return float(_t[key])


func _emit(e: Dictionary) -> void:
	_events.append(e)


func _pick_words() -> void:
	var pool: Array = (_content["acts"][act]["words"] as Array).duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp: Variant = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var n := mini(int(_num("spawner.wordsPerLevel")), pool.size())
	words = PackedStringArray()
	for i in n:
		words.append(pool[i])


func _slots_of(word: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ch in word:
		out.append({"ch": ch, "filled": false})
	return out


func _scale_of(plane: int) -> float:
	match plane:
		0:
			return _num("plane.frontScale")
		1:
			return _num("plane.midScale")
	return _num("plane.backScale")


func _spawn(ch: String, decoy: bool, plane: int) -> Tile:
	var tile: Tile = Tile.new()
	tile.id = _next_id
	_next_id += 1
	tile.ch = ch
	tile.decoy = decoy
	tile.plane = plane
	tile.radius = _num("tile.size") * _scale_of(plane) / 2.0
	var r := tile.radius
	tile.pos = Vector2(_rng.randf_range(r, 1.0 - r), _rng.randf_range(_num("field.topMargin") + r, _num("field.height") - r))
	var angle := _rng.randf() * TAU
	var var_frac := _num("drift.speedVariation")
	var speed := _num("drift.speed") * float(ramp()["drift"]) * (1.0 + _rng.randf_range(-var_frac, var_frac))
	if plane >= 2:
		speed *= _num("plane.backSpeedMul")
	tile.vel = Vector2(cos(angle), sin(angle)) * speed
	tiles.append(tile)
	_by_id[tile.id] = tile
	_emit({"type": "spawn", "tile_id": tile.id, "ch": ch, "plane": plane, "decoy": decoy, "pos": tile.pos})
	return tile


## A weighted-random letter that is not in `excluded` (an Array of single-character strings).
func _weighted_letter(excluded: Array) -> String:
	var letters: Array = []
	var total := 0
	for c: String in FREQ:
		if not excluded.has(c):
			letters.append(c)
			total += int(FREQ[c])
	var roll := _rng.randf() * total
	for c: String in letters:
		roll -= int(FREQ[c])
		if roll <= 0.0:
			return c
	return letters[letters.size() - 1]


func _word_letters() -> Array:
	var out: Array = []
	for s in active:
		if not out.has(s["ch"]):
			out.append(s["ch"])
	for s in preview:
		if not out.has(s["ch"]):
			out.append(s["ch"])
	return out


func _needed_counts() -> Dictionary:
	var need := {}
	for s in active:
		if not s["filled"]:
			need[s["ch"]] = int(need.get(s["ch"], 0)) + 1
	for s in preview:
		if not s["filled"]:
			need[s["ch"]] = int(need.get(s["ch"], 0)) + 1
	return need


func _pick_plane() -> int:
	return 0 if _rng.randf() < _num("spawner.frontShare") else 1


## After every catch and word change: missing needed letters, then surplus, then decoys.
func _refill() -> void:
	_spawn_needed()
	_trim_surplus()
	_ensure_decoys()


func _spawn_needed() -> void:
	var need := _needed_counts()
	var have := {}
	for t: Tile in tiles:
		if t.plane < 2 and not t.decoy:
			have[t.ch] = int(have.get(t.ch, 0)) + 1
	for p in _pending_respawn:
		have[p["ch"]] = int(have.get(p["ch"], 0)) + 1
	var letters: Array = need.keys()
	letters.sort()
	for ch: String in letters:
		for _k in range(int(have.get(ch, 0)), int(need[ch])):
			_spawn(ch, false, _pick_plane())


## Real copies beyond the need dissolve first, then decoys of letters in the active or preview word.
func _trim_surplus() -> void:
	var need := _needed_counts()
	var in_words := _word_letters()
	var seen := {}
	var order: Array = []
	for t: Tile in tiles:
		if t.plane < 2 and not t.decoy:
			order.append(t)
	for t: Tile in tiles:
		if t.plane < 2 and t.decoy and in_words.has(t.ch):
			order.append(t)
	for t: Tile in order:
		seen[t.ch] = int(seen.get(t.ch, 0)) + 1
		if int(seen[t.ch]) > int(need.get(t.ch, 0)):
			_remove(t)
			_emit({"type": "dissolve", "tile_id": t.id, "ch": t.ch, "decoy": t.decoy, "pos": t.pos})


func _ensure_decoys() -> void:
	var want := int(ramp()["decoys"])
	var n := 0
	for t: Tile in tiles:
		if t.plane < 2 and t.decoy:
			n += 1
	var excluded := _word_letters()
	while n < want:
		_spawn(_weighted_letter(excluded), true, _pick_plane())
		n += 1


func _remove(t: Tile) -> void:
	if t.carried_by >= 0:
		var th: Thief = _thief_by_id.get(t.carried_by)
		if th != null:
			th.carrying_id = -1
			th.state = "seek"
			th.vel = Vector2.ZERO
		t.carried_by = -1
	t.alive = false
	tiles.erase(t)
	_by_id.erase(t.id)


# --- simulation --------------------------------------------------------------------------

func _tick(h: float) -> void:
	stats["secs"] = float(stats["secs"]) + h
	for t: Tile in tiles:
		if t.carried_by < 0:
			_drift(t, h)
	_tick_thieves(h)
	if not shot.is_empty():
		shot["elapsed"] = float(shot["elapsed"]) + h
		if float(shot["elapsed"]) + EPS >= float(shot["dur"]):
			_resolve_shot()
	if state == "play":
		_tick_respawns(h)
	if state == "play":
		time_left -= h
		_note_time()
		if time_left <= 0.0:
			time_left = 0.0
			_end(false)


func _note_time() -> void:
	stats["min_time"] = minf(float(stats["min_time"]), maxf(0.0, time_left))


## Takes time off the clock; ends the round when it reaches zero.
func _cost(amount: float, reason: String) -> void:
	time_left = maxf(0.0, time_left - amount)
	_note_time()
	_emit({"type": "time_cost", "amount": amount, "reason": reason})
	if time_left <= 0.0 and state == "play":
		_end(false)


func _tick_respawns(h: float) -> void:
	if _pending_respawn.is_empty():
		return
	var due := false
	for p in _pending_respawn:
		p["t"] = float(p["t"]) - h
	var keep: Array[Dictionary] = []
	for p in _pending_respawn:
		if float(p["t"]) <= 0.0:
			due = true
		else:
			keep.append(p)
	_pending_respawn = keep
	if due:
		_refill()


# --- thieves -----------------------------------------------------------------------------

func _tick_thieves(h: float) -> void:
	if float(stats["secs"]) + EPS >= _next_thief_at and thieves.size() < int(_num("thief.max")):
		_spawn_thief()
		_next_thief_at = float(stats["secs"]) + _num("thief.interval")
	for th: Thief in thieves.duplicate():
		if state != "play":
			return
		if th.state == "flee":
			_flee(th, h)
		else:
			_seek(th, h)


func _spawn_thief() -> void:
	var th: Thief = Thief.new()
	th.id = _next_id
	_next_id += 1
	th.pos = Vector2(_thief_rng.randf_range(0.0, 1.0), _num("field.topMargin"))
	var angle := _thief_rng.randf() * TAU
	th.vel = Vector2(cos(angle), sin(angle)) * _num("thief.speed") * THIEF_IDLE_MUL
	thieves.append(th)
	_thief_by_id[th.id] = th
	_emit({"type": "thief_spawn", "thief_id": th.id, "pos": th.pos})


func _targeted_by_other(tile_id: int, me: Thief) -> bool:
	for o: Thief in thieves:
		if o != me and o.target_id == tile_id:
			return true
	return false


func _pick_target(th: Thief) -> int:
	var shot_id := int(shot["tile_id"]) if not shot.is_empty() and shot.get("kind", "tile") == "tile" else -1
	var best := -1
	var best_d := INF
	for t: Tile in tiles:
		if t.decoy or t.plane >= 2 or t.carried_by >= 0 or t.id == shot_id or t.id == queued_id:
			continue
		if _targeted_by_other(t.id, th):
			continue
		var d := th.pos.distance_to(t.pos)
		if d < best_d:
			best_d = d
			best = t.id
	return best


func _seek(th: Thief, h: float) -> void:
	var tgt: Tile = _by_id.get(th.target_id)
	if tgt == null or not tgt.alive or tgt.carried_by >= 0:
		th.target_id = _pick_target(th)
		tgt = _by_id.get(th.target_id)
	if tgt != null:
		var to := tgt.pos - th.pos
		th.vel = to.normalized() * _num("thief.speed") if to.length() > EPS else Vector2.ZERO
	th.pos += th.vel * h
	if tgt == null:
		# Idle drift: bounce inside the field.
		if th.pos.x < 0.0 or th.pos.x > 1.0:
			th.vel.x = -th.vel.x
			th.pos.x = clampf(th.pos.x, 0.0, 1.0)
		if th.pos.y < _num("field.topMargin") or th.pos.y > _num("field.height"):
			th.vel.y = -th.vel.y
			th.pos.y = clampf(th.pos.y, _num("field.topMargin"), _num("field.height"))
		return
	if th.pos.distance_to(tgt.pos) <= _num("thief.radius") + tgt.radius:
		th.carrying_id = tgt.id
		tgt.carried_by = th.id
		th.target_id = -1
		th.state = "flee"
		th.vel = Vector2(0.0, -_num("thief.fleeSpeed"))
		_emit({"type": "thief_grab", "thief_id": th.id, "tile_id": tgt.id})


func _flee(th: Thief, h: float) -> void:
	th.pos += th.vel * h
	var tile: Tile = _by_id.get(th.carrying_id)
	if tile != null:
		tile.pos = th.pos
	if th.pos.y < 0.0:
		var tile_id := th.carrying_id
		var ch := ""
		if tile != null:
			ch = tile.ch
			_remove(tile)
			_pending_respawn.append({"ch": ch, "t": _num("thief.respawnDelay")})
		_remove_thief(th)
		stats["stolen"] = int(stats["stolen"]) + 1
		_emit({"type": "stolen", "thief_id": th.id, "tile_id": tile_id, "ch": ch})
		_cost(_num("thief.stealCost"), "stolen")


func _remove_thief(th: Thief) -> void:
	thieves.erase(th)
	_thief_by_id.erase(th.id)


func _drift(t: Tile, h: float) -> void:
	var r := t.radius
	t.pos += t.vel * h
	if t.pos.x < r:
		t.pos.x = r
		t.vel.x = absf(t.vel.x)
	elif t.pos.x > 1.0 - r:
		t.pos.x = 1.0 - r
		t.vel.x = -absf(t.vel.x)
	var top := _num("field.topMargin") + r
	var bottom := _num("field.height") - r
	if t.pos.y < top:
		t.pos.y = top
		t.vel.y = absf(t.vel.y)
	elif t.pos.y > bottom:
		t.pos.y = bottom
		t.vel.y = -absf(t.vel.y)


func _start_shot_at(target_id: int, at: Vector2, kind: String) -> void:
	var from := origin()
	var dist := from.distance_to(at)
	var dur := _num("tether.travelTime") * (_num("tether.travelMinMul") + _num("tether.travelDistMul") * dist / _num("field.height"))
	shot = {"tile_id": target_id, "kind": kind, "from": from, "to": at, "elapsed": 0.0, "dur": dur}
	_emit({"type": "fire", "tile_id": target_id})


func _start_queued(id: int) -> void:
	var th: Thief = _thief_by_id.get(id)
	if th != null:
		_start_shot_at(id, th.pos, "thief")
		return
	var nt: Tile = _by_id.get(id)
	if nt != null and nt.alive and nt.carried_by < 0:
		_start_shot_at(id, nt.pos, "tile")


func _resolve_shot() -> void:
	var id := int(shot["tile_id"])
	var kind: String = shot["kind"]
	var target: Vector2 = shot["to"]
	shot = {}
	var next_id := queued_id
	queued_id = -1
	if kind == "thief":
		_resolve_thief_hit(id, target)
	else:
		var tile: Tile = _by_id.get(id)
		if tile != null and tile.alive:
			_resolve_hit(tile, target)
	if state == "play" and next_id >= 0:
		_start_queued(next_id)


func _tolerance() -> float:
	return _num("tether.hitTolerance") * _num("tether.driftToleranceMul")


func _resolve_thief_hit(thief_id: int, target: Vector2) -> void:
	var th: Thief = _thief_by_id.get(thief_id)
	if th == null or th.pos.distance_to(target) > _tolerance():
		stats["escapes"] = int(stats["escapes"]) + 1
		_emit({"type": "thief_miss", "thief_id": thief_id})
		return
	var tile_id := th.carrying_id
	var pos := th.pos
	var tile: Tile = _by_id.get(tile_id)
	if tile != null:
		tile.carried_by = -1
		tile.pos = Vector2(clampf(pos.x, tile.radius, 1.0 - tile.radius), clampf(pos.y, _num("field.topMargin") + tile.radius, _num("field.height") - tile.radius))
	else:
		tile_id = -1
	_remove_thief(th)
	stats["thieves_down"] = int(stats["thieves_down"]) + 1
	_emit({"type": "thief_down", "thief_id": thief_id, "tile_id": tile_id, "pos": pos})


func _resolve_hit(tile: Tile, target: Vector2) -> void:
	if tile.carried_by >= 0 or tile.pos.distance_to(target) > _tolerance():
		stats["escapes"] = int(stats["escapes"]) + 1
		_emit({"type": "escape", "tile_id": tile.id})
		return
	var where := "active"
	var idx := _open_slot(active, tile.ch)
	if idx < 0:
		where = "preview"
		idx = _open_slot(preview, tile.ch)
	if idx < 0:
		_wrong_catch(tile)
		return
	stats["catches"] = int(stats["catches"]) + 1
	var slots: Array[Dictionary] = active if where == "active" else preview
	slots[idx]["filled"] = true
	combo = minf(_num("combo.max"), combo + _num("combo.step"))
	_remove(tile)
	_emit({"type": "catch", "tile_id": tile.id, "where": where, "slot": idx, "ch": tile.ch, "pos": tile.pos})
	if _all_filled(active):
		_restore_words()
	else:
		_refill()


func _open_slot(slots: Array[Dictionary], ch: String) -> int:
	for i in slots.size():
		if not slots[i]["filled"] and slots[i]["ch"] == ch:
			return i
	return -1


func _all_filled(slots: Array[Dictionary]) -> bool:
	for s in slots:
		if not s["filled"]:
			return false
	return true


func _wrong_catch(tile: Tile) -> void:
	stats["wrong"] = int(stats["wrong"]) + 1
	combo = 1.0
	tile.vel = -tile.vel
	var in_words := _word_letters().has(tile.ch)
	_emit({"type": "wrong", "tile_id": tile.id, "kind": "surplus" if in_words else "unneeded", "ch": tile.ch})
	_cost(_num("burst.wrongCost"), "wrong")


## Restores the active word, and keeps going while the carried-over next word is already full.
func _restore_words() -> void:
	while true:
		var w := words[word_index]
		var n := w.length()
		var gained := _num("score.letterValue") * n * (1.0 + _num("score.lengthStep") * (n - 3)) * combo
		score += gained
		time_left += _num("burst.restoreBonus")
		restored_words.append(w)
		var counts := LetterPool.count(w)
		for c: String in counts:
			_pool[c] = int(_pool.get(c, 0)) + int(counts[c])
		_emit({"type": "restore", "word": w, "score": gained})
		if babel_on:
			var lines := Babel.compose(_pool, restored_words, _content, int(_num("babel.minLineLetters")), _babel_rng)
			var text := Babel.pick(lines, _shown, _babel_rng)
			if text != "":
				_shown[text] = true
				# One babel event per restored word in a chain; the view shows only the latest.
				_emit({"type": "babel", "text": text})
		word_index += 1
		if word_index >= words.size():
			score += _num("score.timeBonus") * time_left
			_end(true)
			return
		active = preview
		preview = _slots_of(words[word_index + 1]) if word_index + 1 < words.size() else ([] as Array[Dictionary])
		_refill()
		if not _all_filled(active):
			return


func _end(won: bool) -> void:
	state = "won" if won else "lost"
	shot = {}
	queued_id = -1
	_emit({"type": "round_end", "won": won})

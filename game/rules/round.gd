extends RefCounted
## One round of AstroLex: seeded spawner, fixed-step drift, tether shots, catch taxonomy,
## preview carry-over, surplus dissolve, oxygen (Pressure), score and combo, per-round ramp.
## Reference behaviour is toy v1.3 (web/toy/index.html). The view animates from drain_events()
## and never re-derives rules. Pure GDScript: no Node, no wall clock, one seeded RNG.
##
## Events (dictionaries with "type" plus the fields below; extras such as ch and pos are for the view):
##   spawn{tile_id,ch,plane,decoy,pos} fire{tile_id} queue{tile_id}
##   catch{tile_id,where,slot,ch,pos} wrong{tile_id,kind,ch} escape{tile_id}
##   dissolve{tile_id,ch,decoy,pos} restore{word,score} babel{text} round_end{won}
## Tiles leave `tiles` when caught or dissolved; the view keeps its own node per tile_id.
## While a shot is in flight `shot` is {tile_id, from, to, elapsed, dur} (else empty).

const Tile := preload("res://rules/tile.gd")
const Babel := preload("res://rules/babel.gd")
const LetterPool := preload("res://rules/letter_pool.gd")
const Self := preload("res://rules/round.gd")

## Share of catchable tiles that start on the front plane (toy: 0.62). Not a tunable yet.
const FRONT_SHARE := 0.62
## Letter weights for decoys and back tiles (English frequency, as the toy).
const FREQ := {"e": 127, "t": 91, "a": 82, "o": 75, "i": 70, "n": 67, "s": 63, "h": 61, "r": 60, "d": 43, "l": 40, "c": 28, "u": 28, "m": 24, "w": 24, "f": 22, "g": 20, "y": 20, "p": 19, "b": 15, "v": 10, "k": 8, "j": 2, "x": 2, "q": 1, "z": 1}
const EPS := 1e-6

var words: PackedStringArray = []
var word_index: int = 0
var active: Array[Dictionary] = []
var preview: Array[Dictionary] = []
var tiles: Array = []
var oxygen: float = 0.0
var score: float = 0.0
var combo: float = 1.0
var state: String = "play"
var stats: Dictionary = {}
var shot: Dictionary = {}
var queued_id: int = -1
var restored_words: PackedStringArray = []
var mode: String = "drift"
var act: String = ""
var round_no: int = 1
var seed_value: int = 0

var _t: Dictionary = {}
var _content: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _events: Array[Dictionary] = []
var _by_id: Dictionary = {}
var _next_id: int = 0
var _acc: float = 0.0
var _pool: Dictionary = {}
var _shown: Dictionary = {}


static func create(tunables: Dictionary, content: Dictionary, act_key: String, mode_key: String, seed_value_in: int, round_number: int = 1) -> Self:
	var r: Self = Self.new()
	r._t = tunables
	r._content = content
	r.act = act_key
	r.mode = mode_key
	r.seed_value = seed_value_in
	r.round_no = round_number
	r._rng.seed = seed_value_in
	r.oxygen = r._num("oxygen.max")
	r.stats = {"catches": 0, "wrong": 0, "escapes": 0, "secs": 0.0, "min_oxygen": r.oxygen}
	r._pick_words()
	r.active = r._slots_of(r.words[0])
	r.preview = r._slots_of(r.words[1]) if r.words.size() > 1 else ([] as Array[Dictionary])
	for _i in int(r._num("plane.backTiles")):
		r._spawn(r._weighted_letter([]), true, 2)
	r._refill()
	return r


## Per-round ramp multipliers and counts (toy ramp()).
func ramp() -> Dictionary:
	var k := maxi(0, round_no - 1)
	return {
		"drift": 1.0 + _num("ramp.driftStep") * k,
		"decoys": mini(int(_num("ramp.decoyMax")), int(_num("spawner.decoys")) + int(_num("ramp.decoyStep")) * k),
		"drain": 1.0 + _num("ramp.drainStep") * k,
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
	var tile: Tile = _by_id.get(tile_id)
	if tile == null or not tile.alive or tile.plane >= 2:
		return false
	if not shot.is_empty():
		if shot["tile_id"] == tile_id or queued_id == tile_id:
			return false
		queued_id = tile_id
		_emit({"type": "queue", "tile_id": tile_id})
		return true
	_start_shot(tile)
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
	return 0 if _rng.randf() < FRONT_SHARE else 1


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
	t.alive = false
	tiles.erase(t)
	_by_id.erase(t.id)


# --- simulation --------------------------------------------------------------------------

func _tick(h: float) -> void:
	stats["secs"] = float(stats["secs"]) + h
	for t: Tile in tiles:
		_drift(t, h)
	if not shot.is_empty():
		shot["elapsed"] = float(shot["elapsed"]) + h
		if float(shot["elapsed"]) + EPS >= float(shot["dur"]):
			_resolve_shot()
	if state == "play" and mode == "pressure":
		oxygen -= _num("oxygen.drainPerSec") * float(ramp()["drain"]) * h
		stats["min_oxygen"] = minf(float(stats["min_oxygen"]), maxf(0.0, oxygen))
		if oxygen <= 0.0:
			oxygen = 0.0
			_end(false)


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


func _start_shot(tile: Tile) -> void:
	var from := origin()
	var dist := from.distance_to(tile.pos)
	var dur := _num("tether.travelTime") * (0.7 + 0.3 * dist / _num("field.height"))
	shot = {"tile_id": tile.id, "from": from, "to": tile.pos, "elapsed": 0.0, "dur": dur}
	_emit({"type": "fire", "tile_id": tile.id})


func _resolve_shot() -> void:
	var tile: Tile = _by_id.get(int(shot["tile_id"]))
	var target: Vector2 = shot["to"]
	shot = {}
	var next_id := queued_id
	queued_id = -1
	if tile != null and tile.alive:
		_resolve_hit(tile, target)
	if state == "play" and next_id >= 0:
		var nt: Tile = _by_id.get(next_id)
		if nt != null and nt.alive:
			_start_shot(nt)


func _resolve_hit(tile: Tile, target: Vector2) -> void:
	var tol := _num("tether.hitTolerance")
	if mode == "drift":
		tol *= _num("tether.driftToleranceMul")
	if tile.pos.distance_to(target) > tol:
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
	if mode == "pressure":
		oxygen = maxf(0.0, oxygen - _num("oxygen.wrongCost"))
		stats["min_oxygen"] = minf(float(stats["min_oxygen"]), oxygen)
		if oxygen <= 0.0:
			_end(false)


## Restores the active word, and keeps going while the carried-over next word is already full.
func _restore_words() -> void:
	while true:
		var w := words[word_index]
		var n := w.length()
		var gained := _num("score.letterValue") * n * (1.0 + _num("score.lengthStep") * (n - 3)) * combo
		score += gained
		oxygen = minf(_num("oxygen.max"), oxygen + _num("oxygen.restoreBase") + _num("oxygen.restorePerLetter") * n)
		restored_words.append(w)
		var counts := LetterPool.count(w)
		for c: String in counts:
			_pool[c] = int(_pool.get(c, 0)) + int(counts[c])
		_emit({"type": "restore", "word": w, "score": gained})
		var lines := Babel.compose(_pool, restored_words, _content, int(_num("babel.minLineLetters")), _rng)
		var text := Babel.pick(lines, _shown, _rng)
		if text != "":
			_shown[text] = true
			_emit({"type": "babel", "text": text})
		word_index += 1
		if word_index >= words.size():
			if mode == "pressure":
				score += _num("score.oxygenBonus") * oxygen
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

extends RefCounted
## One round of AstroLex: seeded spawner, fixed-step drift, tether shots, catch taxonomy,
## preview carry-over, surplus dissolve, a time-only 30 s burst clock, Babel-army thief drones,
## score and combo, per-round ramp, tunable modifiers (difficulty, character perks).
## Letters are anchored (WP-F.21); the toy v1.3 free drift is retired in the game. The view animates from drain_events()
## and never re-derives rules. Pure GDScript: no Node, no wall clock, one seeded RNG.
##
## Events (dictionaries with "type" plus the fields below; extras such as ch and pos are for the view):
##   spawn{tile_id,ch,plane,decoy,pos} fire{tile_id} queue{tile_id}
##   catch{tile_id,where,slot,ch,pos} wrong{tile_id,kind,ch} escape{tile_id}
##   dissolve{tile_id,ch,decoy,pos} restore{word,score} babel{text} round_end{won}
##   time_cost{amount,reason} (reason "wrong", "stolen" or "hint"; time_left already reduced)
##   hint{tile_id} (use_hint(): the tile to highlight; its time_cost follows)
##   thief_spawn{thief_id,pos,entry} (entry -1 left edge, 1 right, 0 top) thief_grab{thief_id,tile_id} (the tile stops being catchable)
##   stolen{thief_id,tile_id,ch} (thief left the top with the tile; both are gone, the letter respawns later)
##   thief_down{thief_id,tile_id,pos} (shot; tile_id is the released tile or -1)
##   thief_miss{thief_id} (a shot at a thief missed or the thief was gone; counts as an escape)
## Anchored drift (WP-F.21): every catchable tile holds one anchor of a honeycomb over the field and floats around it.
##   hop_tell{tile_id,to} (anchor index; the letter will hop after hop.windSec)
##   hop{tile_id,from,to,sec} (take-off; from and to are field positions, the flight is a straight line over sec)
##   hop_land{tile_id}
## Hazards (WP-F.1, all off unless the hazard.* tunables enable them):
##   counterfeit{tile_id,ch,pos} (a forged copy of a needed letter was caught: it is gone, burst.wrongCost
##   comes off with a time_cost reason "counterfeit", the real letter is still out there)
##   trap{word,cost} (two letters of Babel's counter-word caught within hazard.trapWindowSec; once per round;
##   a babel{text} event with the word follows and a time_cost reason "trap")
##   jam_on{} jam_off{} (every hazard.stroopEverySec the slot hints go dark for hazard.stroopSec: `jammed`)
## Babel's moves (WP-F.19; babel.moveEvery 0 turns them off, none while state != "play"):
##   babel_tell{move,sec} (move "volley"|"gust"|"shield"|"scramble"; babel.tellSec before the move)
##   babel_move{move,...} volley: tile_ids (new decoys, each also gets a normal spawn event and lands after babel.throwSec;
##   each dissolves after babel.volleyLifeSec)
##   gust: dir (unit Vector2, y <= 0.2, never down), sec  shield: tile_id, sec
##   scramble: moves (Array of {tile_id,from,to}), sec (letters are uncatchable for that long)
##   shield_bounce{tile_id} (a shot reached a shielded letter: no catch, no time cost, no wrong, combo unchanged, the letter stays)
## Thieves live in `thieves` (thief.gd: id, pos, vel, target_id, carrying_id, state "seek"/"flee") and
## share the tile id space; fire(id) accepts a thief id. A shot dict has "kind": "tile" or "thief".
## Tiles leave `tiles` when caught or dissolved; the view keeps its own node per tile_id.
## While a shot is in flight `shot` is {tile_id, from, to, elapsed, dur} (else empty).

const Tile := preload("res://rules/tile.gd")
const Babel := preload("res://rules/babel.gd")
const LetterPool := preload("res://rules/letter_pool.gd")
const Thief := preload("res://rules/thief.gd")
const Self := preload("res://rules/round.gd")

const GOLDEN_ANGLE := 2.39996  # radians; spreads per-tile phases evenly
const BABEL_SEED_XOR := 0x5BAB31
const THIEF_SEED_XOR := 0x7E1EF5
const HAZARD_SEED_XOR := 0x4A2A2D
const TRAP_MIN_LEN := 3
const TRAP_MAX_LEN := 4
const THIEF_IDLE_MUL := 0.25
const HOP_SEED_XOR := 0x57A1E5
const MOVE_SEED_XOR := 0x3B0E5A
const MOVE_NAMES: Array[String] = ["volley", "gust", "shield", "scramble"]
## Shapes of the motion (not feel numbers): the sway's y runs at this multiple of its x frequency,
## the wave's phase advances by x plus this share of y, a bob component carries this share of its amplitude.
const SWAY_Y_RATIO := 1.37
const WAVE_SKEW := 0.5
const INV_SQRT2 := 0.70710678
const BOB_PHASE_MUL := 1.7
## A scramble reshuffles at most this many times to leave no letter on its own anchor.
const SCRAMBLE_TRIES := 16
## Letter weights for decoys and back tiles: English frequency is language data, not a feel number.
const FREQ := {"e": 127, "t": 91, "a": 82, "o": 75, "i": 70, "n": 67, "s": 63, "h": 61, "r": 60, "d": 43, "l": 40, "c": 28, "u": 28, "m": 24, "w": 24, "f": 22, "g": 20, "y": 20, "p": 19, "b": 15, "v": 10, "k": 8, "j": 2, "x": 2, "q": 1, "z": 1}
const EPS := 1e-6
const FINALE_SINCERE := "I hear you."

var words: PackedStringArray = []
var word_index: int = 0
var active: Array[Dictionary] = []
var preview: Array[Dictionary] = []
var tiles: Array = []
var time_left: float = 0.0
## The clock this round started with: burst.seconds plus burst.perLetterSec for every letter of its
## words (after level tuning and mods); stars scale with it.
var burst_seconds: float = 0.0
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
## The finale (4-12, WP-F.2): words are LISTEN then the Catcher's name; Babel's two lines are scripted.
var finale: bool = false
## Presentation only: the share of each step's drift the letters move (1.0 = full). The field eases
## it from 0 to 1 after Babel's throw so the letters start drifting gently. The clock, thieves and
## shots are unaffected, and the default keeps the rules identical to the Python reference.
var drift_scale: float = 1.0
## True while the Stroop jam is on: the slot hints are dark and the view lies about colour.
var jammed: bool = false
## Babel's counter-word for this round ("" when hazard.traps is 0 or no lexicon word fits) and whether it fired.
var trap_word: String = ""
var trap_fired: bool = false

var _t: Dictionary = {}
var _content: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _babel_rng := RandomNumberGenerator.new()
var _thief_rng := RandomNumberGenerator.new()
var _hazard_rng := RandomNumberGenerator.new()
var _move_rng := RandomNumberGenerator.new()
## Babel's moves: when the next tell fires, the move chosen at the tell, when it lands, the last move made.
var _move_at: float = INF
var _move_tell_sent: bool = false
var _move_next: String = ""
var _move_last: String = ""
var _gust_dir: Vector2 = Vector2.ZERO
var _gust_t: float = 0.0
## Anchored drift: anchor positions, the tile id holding each (or reserved by a hop, -1 free), the hop clock and rng,
## the field's body offset this tick (sway plus gust) and the gust's own spring.
var _anchors: Array[Vector2] = []
var _owner: Array[int] = []
var _hop_rng := RandomNumberGenerator.new()
var _hop_at: float = INF
var _body: Vector2 = Vector2.ZERO
## How far the body offset may go each way before an anchored letter's centre (with its offset) would leave the field.
var _body_lo: Vector2 = Vector2.ZERO
var _body_hi: Vector2 = Vector2.ZERO
var _gust_off: Vector2 = Vector2.ZERO
var _gust_vel: Vector2 = Vector2.ZERO
var _trap_hits: Array[Dictionary] = []
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
	r.finale = bool(level.get("finale", false)) and (level["words"] as Array).size() == 2
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
	_hazard_rng.seed = seed_value_in ^ HAZARD_SEED_XOR
	_move_rng.seed = seed_value_in ^ MOVE_SEED_XOR
	_hop_rng.seed = seed_value_in ^ HOP_SEED_XOR
	_next_thief_at = _num("thief.firstAt") if _num("thief.interval") > 0.0 else INF
	if fixed_words.is_empty():
		_pick_words()
	else:
		words = fixed_words
	var letters := 0
	for w in words:
		letters += w.length()
	burst_seconds = _num("burst.seconds") + _num("burst.perLetterSec") * letters
	time_left = burst_seconds
	stats = {"catches": 0, "wrong": 0, "escapes": 0, "secs": 0.0, "min_time": time_left, "stolen": 0, "thieves_down": 0, "hints": 0, "counterfeits": 0, "traps": 0, "jams": 0}
	_move_at = _num("babel.moveFirstAt") if _num("babel.moveEvery") > 0.0 else INF
	_pick_trap_word()
	_build_anchors()
	_hop_at = _num("hop.firstAt") if _hops_enabled() else INF
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
		if tile == null or not tile.alive or tile.plane >= 2 or tile.carried_by >= 0 or tile.landing > 0.0:
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
		_start_shot_at(tile_id, _aim_pos(tile), "tile", _hop_left(tile))
	return true


## Hint: picks the catchable tile whose letter fills the lowest unfilled slot of the active word
## (ties: lowest tile id), charges burst.hintCost, emits hint{tile_id} and returns the id.
## Repeating while the hinted tile is still alive, catchable and needed returns the same id free
## (hint event again, no cost, no stat). Refused (-1, no cost) when time_left <= burst.hintCost, so a
## hint never ends the round. Also -1 when the round is not in play or no such tile exists.
func use_hint() -> int:
	if state != "play":
		return -1
	var word_key := _active_key()
	if _hinted_id >= 0 and _hinted_word == word_key and _hint_ok(find_tile(_hinted_id)):
		_emit({"type": "hint", "tile_id": _hinted_id})
		return _hinted_id
	_hinted_id = -1
	if time_left <= _num("burst.hintCost"):
		return -1
	var best_id := -1
	var best_slot := 1 << 30
	for t in tiles:
		if not _hint_ok(t):
			continue
		var idx := _open_slot(active, t.ch)
		if idx < best_slot or (idx == best_slot and t.id < best_id):
			best_slot = idx
			best_id = t.id
	if best_id < 0:
		return -1
	_hinted_id = best_id
	_hinted_word = word_key
	stats["hints"] = int(stats["hints"]) + 1
	_emit({"type": "hint", "tile_id": best_id})
	_cost(_num("burst.hintCost"), "hint")
	return best_id


var _hinted_id := -1
var _hinted_word := ""


func _active_key() -> String:
	var k := ""
	for sl in active:
		k += sl["ch"]
	return k


## Catchable now and its letter fills an open slot of the active word.
func _hint_ok(t: Tile) -> bool:
	if t == null or not t.alive or t.plane >= 2 or t.carried_by >= 0 or t.kind == "counterfeit" or t.shield_t > 0.0 or t.landing > 0.0:
		return false
	if (not shot.is_empty() and shot["tile_id"] == t.id) or queued_id == t.id:
		return false
	return _open_slot(active, t.ch) >= 0


func drain_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out


## Shot origin in field units.
func origin() -> Vector2:
	return Vector2(_w() * 0.5, _num("field.height"))


## Field width in field units (the height is field.height); the view fits the field to the screen.
func _w() -> float:
	return _num("field.width")


func find_tile(tile_id: int) -> Tile:
	return _by_id.get(tile_id)


func find_thief(thief_id: int) -> Thief:
	return _thief_by_id.get(thief_id)


## 0 unless won; 3 / 2 / 1 by the share of the starting clock left, so a 60 s burst
## needs 20 s left for three stars where a 30 s burst needs 10 s.
func stars() -> int:
	if state != "won":
		return 0
	if time_left >= _star_line("stars.threeShare"):
		return 3
	if time_left >= _star_line("stars.twoShare"):
		return 2
	return 1


## Seconds left needed for a star tier, rounded to 0.1 s so 1/3 of 30 s is exactly 10 s.
func _star_line(key: String) -> float:
	return snappedf(burst_seconds * _num(key), 0.1) - 1e-3


# --- setup -------------------------------------------------------------------------------

func _num(key: String) -> float:
	return float(_t[key])


## A hazard tunable; 0 when the key is absent so older tunables dictionaries still work.
func _hnum(key: String) -> float:
	return float(_t.get(key, 0.0))


## Babel's counter-word: a short lexicon word whose letters appear in none of the round's words
## (so catching them is always wrong). Picked once, from the hazard RNG, so it is stable per seed.
func _pick_trap_word() -> void:
	if _hnum("hazard.traps") < 1.0:
		return
	var used := {}
	for w in words:
		for c in w:
			used[c] = true
	var cands: Array[String] = []
	for entry: Array in _content.get("lexicon", []):
		var w: String = entry[0]
		if w.length() < TRAP_MIN_LEN or w.length() > TRAP_MAX_LEN or cands.has(w):
			continue
		var ok := true
		for c in w:
			if used.has(c) or not FREQ.has(c):
				ok = false
				break
		if ok:
			cands.append(w)
	if not cands.is_empty():
		trap_word = cands[_hazard_rng.randi_range(0, cands.size() - 1)]


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


## A new tile. Catchable tiles take the free anchor with the best spread; a decoy returns null when none is
## free, a needed letter dissolves a plain decoy to make room. Back-plane shards drift in straight lines.
func _spawn(ch: String, decoy: bool, plane: int) -> Tile:
	var anchor := -1
	if plane < 2:
		anchor = _pick_anchor()
		if anchor < 0:
			if decoy:
				return null
			if _make_room():
				anchor = _pick_anchor()
	var tile: Tile = Tile.new()
	tile.id = _next_id
	_next_id += 1
	tile.ch = ch
	tile.decoy = decoy
	tile.plane = plane
	tile.radius = _num("tile.size") * _scale_of(plane) / 2.0
	if plane >= 2:
		var r := tile.radius
		tile.pos = Vector2(_rng.randf_range(r, _w() - r), _rng.randf_range(_num("field.topMargin") + r, _num("field.height") - r))
		var speed := _num("drift.speed") * float(ramp()["drift"]) * _num("plane.backSpeedMul")
		var angle := _rng.randf() * TAU
		tile.vel = Vector2(cos(angle), sin(angle)) * speed
	elif anchor >= 0:
		tile.anchor = anchor
		_owner[anchor] = tile.id
		tile.pos = _rest_pos(tile, anchor)
	else:
		# No anchor anywhere (more real letters than anchors): sit mid-field and let separation sort it out.
		tile.pos = Vector2(_w() * 0.5, (_num("field.topMargin") + _num("field.height")) * 0.5)
	if float(stats.get("secs", 0.0)) > 0.0:
		tile.landing = _num("babel.throwSec")
	tiles.append(tile)
	_by_id[tile.id] = tile
	_emit({"type": "spawn", "tile_id": tile.id, "ch": ch, "plane": plane, "decoy": decoy, "pos": tile.pos})
	return tile


# --- anchors (WP-F.21) ---------------------------------------------------------------------

## A honeycomb over the field: rows from field.topMargin to field.height, spaced spacing * sqrt(3) / 2 apart,
## odd rows shifted half a spacing; any anchor that would leave the field (with maxOffset to spare) is dropped.
func _build_anchors() -> void:
	_anchors = []
	_owner = []
	var spacing := _num("anchors.spacing")
	var inset := _num("tile.size") * 0.5 + _num("anchors.maxOffset")
	# The lattice stops anchors.bodyRoom short of the walls so the sway and the gust have room to move it.
	var lat := inset + _num("anchors.bodyRoom")
	var clear := Vector2(_num("anchors.clearX"), _num("anchors.clearY"))
	# Rows and columns are spread evenly over the whole field (pitch at least the spacing), so the
	# lattice reaches every edge instead of hugging the top-left corner.
	var span_x := _w() - 2.0 * lat
	var span_y := _num("field.height") - _num("field.topMargin") - 2.0 * lat
	var cols := maxi(1, int(floorf(span_x / spacing + EPS)) + 1)
	var rows := maxi(1, int(floorf(span_y / (spacing * sqrt(3.0) * 0.5) + EPS)) + 1)
	var pitch_x := span_x / float(cols - 1) if cols > 1 else 0.0
	var pitch_y := span_y / float(rows - 1) if rows > 1 else 0.0
	for row in rows:
		var y := _num("field.topMargin") + lat + pitch_y * float(row)
		var n := cols - 1 if row % 2 == 1 else cols  # odd rows sit between the columns above
		for c in n:
			var x := lat + pitch_x * float(c) + (pitch_x * 0.5 if row % 2 == 1 else 0.0)
			# No anchor under Babel's porthole (anchors.clear* mirror babel.corner* in field units).
			if Vector2(x, y).distance_to(clear) >= _num("anchors.clearRadius") + _num("tile.size") * 0.5:
				_anchors.append(Vector2(x, y))
				_owner.append(-1)
	if _anchors.is_empty():
		return
	var lo := _anchors[0]
	var hi := _anchors[0]
	for a in _anchors:
		lo = Vector2(minf(lo.x, a.x), minf(lo.y, a.y))
		hi = Vector2(maxf(hi.x, a.x), maxf(hi.y, a.y))
	# The body may move the lattice only as far as keeps every anchored tile (edge plus its offset) in the field.
	_body_lo = Vector2(inset - lo.x, _num("field.topMargin") + inset - lo.y)
	_body_hi = Vector2(_w() - inset - hi.x, _num("field.height") - inset - hi.y)


func anchor_count() -> int:
	return _anchors.size()


func anchor_pos(i: int) -> Vector2:
	return _anchors[i]


func _free_count() -> int:
	var n := 0
	for o in _owner:
		if o < 0:
			n += 1
	return n


## The free anchor farthest from the occupied ones (ties broken from the spawn rng); -1 when none is free.
func _pick_anchor() -> int:
	var best := -1.0
	var ties: Array[int] = []
	for i in _anchors.size():
		if _owner[i] >= 0:
			continue
		var score := 1e9
		for j in _anchors.size():
			if _owner[j] >= 0:
				score = minf(score, _anchors[i].distance_to(_anchors[j]))
		if score > best + EPS:
			best = score
			ties = [i]
		elif score >= best - EPS:
			ties.append(i)
	if ties.is_empty():
		return -1
	return ties[_rng.randi_range(0, ties.size() - 1)]


## The free anchor nearest to p, -1 when none is free.
func _nearest_free_anchor(p: Vector2) -> int:
	var best := -1
	var best_d := INF
	for i in _anchors.size():
		if _owner[i] < 0 and p.distance_to(_anchors[i]) < best_d:
			best_d = p.distance_to(_anchors[i])
			best = i
	return best


## Dissolves the oldest plain decoy nobody is using, to free its anchor. False when there is none.
func _make_room() -> bool:
	var shot_id := int(shot.get("tile_id", -1))
	for t: Tile in tiles:
		if t.plane < 2 and t.decoy and t.kind == "" and t.carried_by < 0 and t.hop_to < 0 and t.id != shot_id and t.id != queued_id and t.anchor >= 0:
			_remove(t)
			_emit({"type": "dissolve", "tile_id": t.id, "ch": t.ch, "decoy": t.decoy, "pos": t.pos})
			return true
	return false


func _release(t: Tile) -> void:
	for i in _owner.size():
		if _owner[i] == t.id:
			_owner[i] = -1
	t.anchor = -1
	t.hop_to = -1
	t.hop_air = false


## How fast the sway, the wave and the hops run: 1 at drift.speed == anchors.speedRef.
func _pace() -> float:
	return _num("drift.speed") * float(ramp()["drift"]) / maxf(_num("anchors.speedRef"), EPS)


## The field's body offset at round time: a slow sway plus the gust's spring (set each tick by _update_body).
func _body_at(secs: float) -> Vector2:
	var hz := TAU * _num("anchors.swayHz") * _pace()
	return Vector2(_num("anchors.swayX") * sin(secs * hz), _num("anchors.swayY") * sin(secs * hz * SWAY_Y_RATIO + 1.0)) * drift_scale


## Wave, bob and spring offset of tile t as if it held anchor i, the total clamped to anchors.maxOffset.
func _dev(t: Tile, i: int) -> Vector2:
	var secs := float(stats.get("secs", 0.0))
	var a := _anchors[i]
	var phase := TAU * (_num("anchors.waveHz") * _pace() * secs - (a.x + WAVE_SKEW * a.y) / _num("anchors.waveLen"))
	var wave := Vector2(0.0, sin(phase)) * _num("anchors.waveAmp") * drift_scale
	var ph := float(t.id) * GOLDEN_ANGLE
	var bt := TAU * _num("drift.bobHz") * secs
	var bob := Vector2(sin(bt + ph), cos(bt * SWAY_Y_RATIO + ph * BOB_PHASE_MUL)) * (_num("drift.bob") * INV_SQRT2) * drift_scale
	var d := wave + bob + t.off
	var m := _num("anchors.maxOffset")
	if d.length() > m:
		d = d.normalized() * m
	return d


func _rest_pos(t: Tile, i: int) -> Vector2:
	return _anchors[i] + _body + _dev(t, i)


## Where a shot at the tile should aim: its destination when it is hopping.
func _aim_pos(t: Tile) -> Vector2:
	if t.hop_to >= 0:
		return _rest_pos(t, t.hop_to)
	return t.pos


## Seconds until a hopping tile has landed (0 when it is not hopping).
func _hop_left(t: Tile) -> float:
	if t.hop_to < 0:
		return 0.0
	if t.hop_air:
		return maxf(0.0, t.hop_sec - t.hop_t)
	return t.hop_wind + _num("hop.flySec")


## Safety net: pushes overlapping catchable tiles on the same plane apart, in list order. Anchored drift never needs it;
## a hopping letter in flight is lifted over the others and ignored.
## Returns true when it moved any tile.
func _separate_tiles() -> bool:
	var moved := false
	var gap := _num("tile.minGap")
	var n := tiles.size()
	for i in n:
		var a: Tile = tiles[i]
		if not a.alive or a.plane >= 2 or a.carried_by >= 0 or a.hop_air:
			continue
		for j in range(i + 1, n):
			var b: Tile = tiles[j]
			if not b.alive or b.plane != a.plane or b.carried_by >= 0 or b.hop_air:
				continue
			var need := a.radius + b.radius + gap
			var d := b.pos - a.pos
			var dist_sq := d.length_squared()
			if dist_sq >= need * need:
				continue
			var dist := sqrt(dist_sq)
			var normal := Vector2(1.0, 0.0)
			if dist > 1e-6:
				normal = d / dist
			var push := (need - dist) * 0.5
			moved = true
			a.pos -= normal * push
			b.pos += normal * push
			_clamp_to_field(a)
			_clamp_to_field(b)
	return moved


func _clamp_to_field(t: Tile) -> void:
	var r := t.radius
	t.pos.x = clampf(t.pos.x, r, _w() - r)
	t.pos.y = clampf(t.pos.y, _num("field.topMargin") + r, _num("field.height") - r)


## A weighted-random letter that is not in `excluded` (an Array of single-character strings).
## Letters that already show spawner.maxCopies times on the field (catchable tiles), so a plain decoy
## never makes a third copy of one letter. 0 turns the cap off.
func _capped_letters() -> Array:
	var cap := int(_num("spawner.maxCopies"))
	if cap <= 0:
		return []
	var counts := {}
	for t: Tile in tiles:
		if t.plane < 2 and t.alive:
			counts[t.ch] = int(counts.get(t.ch, 0)) + 1
	var out: Array = []
	for c in counts:
		if int(counts[c]) >= cap:
			out.append(c)
	return out


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
	for _pass in 256:  # settle any spawn that found no free spot; stop once nothing moves
		if not _separate_tiles():
			break


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
		if t.plane < 2 and t.decoy and t.kind == "" and in_words.has(t.ch):
			order.append(t)
	for t: Tile in order:
		seen[t.ch] = int(seen.get(t.ch, 0)) + 1
		if int(seen[t.ch]) > int(need.get(t.ch, 0)):
			_remove(t)
			_emit({"type": "dissolve", "tile_id": t.id, "ch": t.ch, "decoy": t.decoy, "pos": t.pos})
	# A forgery of a letter nobody needs any more has nothing to fool: it dissolves and a new one is made.
	for t: Tile in tiles.duplicate():
		if t.kind == "counterfeit" and not need.has(t.ch):
			_remove(t)
			_emit({"type": "dissolve", "tile_id": t.id, "ch": t.ch, "decoy": t.decoy, "pos": t.pos})


func _ensure_decoys() -> void:
	var n := 0
	var real := 0
	var forged := 0
	var trap_have := {}
	for t: Tile in tiles:
		if t.plane < 2:
			if t.decoy:
				n += 1
				if t.kind == "counterfeit":
					forged += 1
				elif t.kind == "trap":
					trap_have[t.ch] = int(trap_have.get(t.ch, 0)) + 1
			elif t.alive:
				real += 1
	var want := mini(int(_num("ramp.decoyMax")), maxi(int(ramp()["decoys"]), ceili(_num("spawner.decoyRatio") * real)))
	# Babel's counter-word: its letters are decoys too, made again until the trap has gone off.
	var trap_missing: Array[String] = []
	var trap_len := 0
	if trap_word != "" and not trap_fired:
		trap_len = trap_word.length()
		var left := trap_have.duplicate()
		for c in trap_word:
			if int(left.get(c, 0)) > 0:
				left[c] = int(left[c]) - 1
			else:
				trap_missing.append(c)
		want = maxi(want, trap_len)
	var want_forged := 0
	if _hnum("hazard.counterfeitRatio") > 0.0 and want > 0 and not _needed_counts().is_empty():
		want_forged = maxi(1, roundi(want * _hnum("hazard.counterfeitRatio")))
		want = maxi(want, want_forged + trap_len)
	for c: String in trap_missing:
		var trap_tile: Tile = _spawn(c, true, _pick_plane())
		if trap_tile == null:
			return  # every anchor is held
		trap_tile.kind = "trap"
		n += 1
	while forged < want_forged:
		var letters: Array = _needed_counts().keys()
		letters.sort()
		var forged_tile: Tile = _spawn(letters[_hazard_rng.randi_range(0, letters.size() - 1)], true, _pick_plane())
		if forged_tile == null:
			return
		forged_tile.kind = "counterfeit"
		forged += 1
		n += 1
	while n < want:
		var excluded := _word_letters()
		excluded.append_array(_capped_letters())
		if _spawn(_weighted_letter(excluded), true, _pick_plane()) == null:
			return
		n += 1


func _remove(t: Tile) -> void:
	_release(t)
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
	_tick_jam()
	_tick_moves()
	for t: Tile in tiles.duplicate():
		t.landing = maxf(0.0, t.landing - h)
		t.shield_t = maxf(0.0, t.shield_t - h)
		if t.plane < 2 and t.anchor < 0 and t.carried_by < 0 and t.alive:
			_drop_to_anchor(t)  # a letter that found no anchor when it arrived takes the first one that frees up
		if t.expire_t > 0.0:
			t.expire_t -= h
			if t.expire_t <= 0.0 and t.carried_by < 0 and t.id != int(shot.get("tile_id", -1)) and t.id != queued_id:
				_remove(t)
				_emit({"type": "dissolve", "tile_id": t.id, "ch": t.ch, "decoy": t.decoy, "pos": t.pos})
				continue
		if t.carried_by < 0 and t.plane >= 2:
			_drift_back(t, h)
	_tick_hops(h)
	_move_tiles(h)
	for _pass in 4:  # a few passes settle crowded clusters
		_separate_tiles()
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


## The Stroop jam: dark for hazard.stroopSec at every multiple of hazard.stroopEverySec (first at that mark).
func _tick_jam() -> void:
	var every := _hnum("hazard.stroopEverySec")
	var secs := float(stats["secs"]) + EPS
	var on := _hnum("hazard.stroop") >= 1.0 and every > 0.0 and secs >= every and fmod(secs, every) < _hnum("hazard.stroopSec")
	if on == jammed:
		return
	jammed = on
	if on:
		stats["jams"] = int(stats["jams"]) + 1
	_emit({"type": "jam_on" if on else "jam_off"})


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


# --- Babel's moves (WP-F.19) ---------------------------------------------------------------

## The moves Babel's act and level allow.
func _allowed_moves() -> Array[String]:
	var out: Array[String] = []
	if not babel_on or _num("babel.moveEvery") <= 0.0:
		return out
	var act_no := _act_no()
	var order := _level_order()
	if act_no >= 2 or order >= int(_num("babel.movesFromLevel")):
		out.append("volley")
	if act_no >= int(_num("babel.gustFromAct")):
		out.append("gust")
	if act_no >= int(_num("babel.shieldFromAct")):
		out.append("shield")
	if act_no >= int(_num("babel.scrambleFromAct")):
		out.append("scramble")
	return out


func _act_no() -> int:
	if act.begins_with("act") and act.length() > 3 and act[3].is_valid_int():
		return int(act[3])
	return 1


## The level's number within its act ("2-05" is 5); effectively infinite for a round without a level id.
func _level_order() -> int:
	var parts := level_id.split("-")
	if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
		return int(parts[1])
	return 1 << 30


func _move_feasible(m: String) -> bool:
	match m:
		"volley":
			return _decoy_room() > 0
		"shield":
			return _shield_target() != null
		"scramble":
			for t: Tile in tiles:
				if t.plane < 2 and t.carried_by < 0:
					return true
			return false
	return true


## Decoys that may still be added: the room under ramp.decoyMax, capped by the free anchors.
func _decoy_room() -> int:
	var n := 0
	for t: Tile in tiles:
		if t.plane < 2 and t.decoy:
			n += 1
	return mini(int(_num("ramp.decoyMax")) - n, _free_count())


func _tick_moves() -> void:
	if state != "play" or _move_at == INF:
		return
	var secs := float(stats["secs"]) + EPS
	var tell := _num("babel.tellSec")
	if not _move_tell_sent and secs >= _move_at - tell:
		var options: Array[String] = []
		for m in _allowed_moves():
			if _move_feasible(m):
				options.append(m)
		if options.size() > 1 and options.has(_move_last):
			options.erase(_move_last)
		if options.is_empty():
			_move_at += _num("babel.moveEvery")
			return
		_move_next = options[_move_rng.randi_range(0, options.size() - 1)]
		_move_tell_sent = true
		_emit({"type": "babel_tell", "move": _move_next, "sec": tell})
	if _move_tell_sent and secs >= _move_at:
		_move_tell_sent = false
		_move_at += _num("babel.moveEvery")
		if _move_feasible(_move_next):
			_do_move(_move_next)
			_move_last = _move_next


func _do_move(m: String) -> void:
	match m:
		"volley":
			var ids: Array = []
			var excluded := _word_letters()
			for _i in mini(int(_num("babel.volleyDecoys")), _decoy_room()):
				var d: Tile = _spawn(_weighted_letter(excluded), true, _pick_plane())
				if d == null:
					break
				d.expire_t = _num("babel.volleyLifeSec")
				ids.append(d.id)
			_emit({"type": "babel_move", "move": m, "tile_ids": ids})
		"gust":
			var y := _move_rng.randf_range(-1.0, 0.2)
			var x := sqrt(maxf(0.0, 1.0 - y * y)) * (1.0 if _move_rng.randf() < 0.5 else -1.0)
			_gust_dir = Vector2(x, y)
			_gust_t = _num("babel.gustSec")
			_emit({"type": "babel_move", "move": m, "dir": _gust_dir, "sec": _gust_t})
		"shield":
			var tgt := _shield_target()
			tgt.shield_t = _num("babel.shieldSec")
			_emit({"type": "babel_move", "move": m, "tile_id": tgt.id, "sec": tgt.shield_t})
		"scramble":
			_scramble()


## The letter the next open slot wants if it is on the field and catchable, else any needed real letter.
func _shield_target() -> Tile:
	for t: Tile in tiles:
		if t.shield_t > 0.0:
			return null
	for slots: Array[Dictionary] in [active]:
		var want := ""
		for s in slots:
			if not s["filled"]:
				want = s["ch"]
				break
		var fallback: Tile = null
		for t: Tile in tiles:
			if t.plane >= 2 or t.decoy or t.carried_by >= 0 or not t.alive or t.landing > 0.0 or t.id == _hinted_id:
				continue
			if t.ch == want:
				return t
			if fallback == null and _open_slot(active, t.ch) >= 0:
				fallback = t
		return fallback
	return null


## Every eligible letter lands on a distinct anchor of a seeded permutation of its own anchors and the free
## ones. The rules move them at once and make them uncatchable for babel.scrambleSec; the view flies them
## from `from` to `to` over `sec` (straight lines would cross, so no letter is simulated in flight).
func _scramble() -> void:
	for t: Tile in tiles.duplicate():
		if t.hop_to >= 0:
			_land(t)  # a hop in progress finishes first
	var shot_id := int(shot.get("tile_id", -1))
	var group: Array[Tile] = []
	var slots: Array[int] = []
	for t: Tile in tiles:
		if t.plane >= 2 or t.carried_by >= 0 or not t.alive or t.id == shot_id or t.id == queued_id or t.anchor < 0:
			continue  # a letter the tether is already flying at (or queued for) stays put
		group.append(t)
		slots.append(t.anchor)
	for i in _anchors.size():
		if _owner[i] < 0:
			slots.append(i)
	for _try in SCRAMBLE_TRIES:  # reshuffle until every letter really moves (or give up)
		for i in range(slots.size() - 1, 0, -1):
			var j := _move_rng.randi_range(0, i)
			var tmp := slots[i]
			slots[i] = slots[j]
			slots[j] = tmp
		var stays := false
		for k in group.size():
			stays = stays or slots[k] == group[k].anchor
		if not stays:
			break
	for t: Tile in group:
		_owner[t.anchor] = -1
	var moves: Array = []
	for k in group.size():
		var t: Tile = group[k]
		var from := t.pos
		t.anchor = slots[k]
		_owner[t.anchor] = t.id
		t.pos = _rest_pos(t, t.anchor)
		t.landing = maxf(t.landing, _num("babel.scrambleSec"))
		moves.append({"tile_id": t.id, "from": from, "to": t.pos})
	_emit({"type": "babel_move", "move": "scramble", "moves": moves, "sec": _num("babel.scrambleSec")})


# --- thieves -----------------------------------------------------------------------------

func _tick_thieves(h: float) -> void:
	if float(stats["secs"]) + EPS >= _next_thief_at:
		if thieves.size() < int(_num("thief.max")):
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
	var top := _num("field.topMargin")
	var side := _num("thief.sideShare")
	var from_side := side > 0.0 and _thief_rng.randf() < side
	if from_side:
		# The left (x = 0) or right (x = 1) edge, in the upper part of the play area; the view reads x.
		var right := _thief_rng.randf() < 0.5
		var max_y := top + _num("thief.sideMaxY") * (_num("field.height") - top)
		th.pos = Vector2(_w() if right else 0.0, _thief_rng.randf_range(top, max_y))
		th.entry = 1 if right else -1
	else:
		th.pos = Vector2(_thief_rng.randf_range(0.0, _w()), top)
	var angle := _thief_rng.randf() * TAU
	th.vel = Vector2(cos(angle), sin(angle)) * _num("thief.speed") * THIEF_IDLE_MUL
	if from_side:
		th.vel.x = -absf(th.vel.x) if th.pos.x > _w() * 0.5 else absf(th.vel.x)
	thieves.append(th)
	_thief_by_id[th.id] = th
	_emit({"type": "thief_spawn", "thief_id": th.id, "pos": th.pos, "entry": th.entry})


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
		if t.decoy or t.plane >= 2 or t.carried_by >= 0 or t.landing > 0.0 or t.shield_t > 0.0 or t.hop_to >= 0 or t.id == shot_id or t.id == queued_id:
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
	var shot_id := int(shot["tile_id"]) if not shot.is_empty() and shot.get("kind", "tile") == "tile" else -1
	if tgt == null or not tgt.alive or tgt.carried_by >= 0 or tgt.shield_t > 0.0 or tgt.id == shot_id or tgt.id == queued_id:
		var had_target := th.target_id >= 0
		th.target_id = _pick_target(th)
		tgt = _by_id.get(th.target_id)
		if tgt == null and had_target:
			th.vel = th.vel.normalized() * _num("thief.speed") * THIEF_IDLE_MUL
	if tgt != null:
		var to := tgt.pos - th.pos
		th.vel = to.normalized() * _num("thief.speed") if to.length() > EPS else Vector2.ZERO
	th.pos += th.vel * h
	if tgt == null:
		# Idle drift: bounce inside the field.
		if th.pos.x < 0.0 or th.pos.x > _w():
			th.vel.x = -th.vel.x
			th.pos.x = clampf(th.pos.x, 0.0, _w())
		if th.pos.y < _num("field.topMargin") or th.pos.y > _num("field.height"):
			th.vel.y = -th.vel.y
			th.pos.y = clampf(th.pos.y, _num("field.topMargin"), _num("field.height"))
		return
	if th.pos.distance_to(tgt.pos) <= _num("thief.radius") + tgt.radius:
		th.carrying_id = tgt.id
		tgt.carried_by = th.id
		_release(tgt)  # a drone lifts the letter off its anchor
		th.target_id = -1
		th.state = "flee"
		# Flee to the nearest of the left, right and top edges (never the bottom); ties go to the top.
		var to_left := th.pos.x
		var to_right := _w() - th.pos.x
		var to_top := th.pos.y
		var dir := Vector2(0.0, -1.0)
		if to_left < to_top and to_left <= to_right:
			dir = Vector2(-1.0, 0.0)
		elif to_right < to_top and to_right < to_left:
			dir = Vector2(1.0, 0.0)
		th.vel = dir * _num("thief.fleeSpeed")
		_emit({"type": "thief_grab", "thief_id": th.id, "tile_id": tgt.id})


func _flee(th: Thief, h: float) -> void:
	th.pos += th.vel * h
	var tile: Tile = _by_id.get(th.carrying_id)
	if tile != null:
		tile.pos = th.pos
	if th.pos.y < 0.0 or th.pos.x < 0.0 or th.pos.x > _w():
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


## Back-plane shards: straight drift, bouncing off the walls.
func _drift_back(t: Tile, h: float) -> void:
	var r := t.radius
	t.pos += t.vel * h * drift_scale
	if t.pos.x < r:
		t.pos.x = r
		t.vel.x = absf(t.vel.x)
	elif t.pos.x > _w() - r:
		t.pos.x = _w() - r
		t.vel.x = -absf(t.vel.x)
	var top := _num("field.topMargin") + r
	var bottom := _num("field.height") - r
	if t.pos.y < top:
		t.pos.y = top
		t.vel.y = absf(t.vel.y)
	elif t.pos.y > bottom:
		t.pos.y = bottom
		t.vel.y = -absf(t.vel.y)


## The anchored letters' motion for one step: the body offset (sway, gust), shy and ripple forces, the
## offset springs, then every tile's position = anchor + body + wave + bob + offset (or its hop flight).
func _move_tiles(h: float) -> void:
	if _gust_t > 0.0:
		_gust_off += _gust_dir * _num("babel.gustPush") * (_gust_t / _num("babel.gustSec")) * h * drift_scale
		_gust_t = maxf(0.0, _gust_t - h)
	_gust_vel += (-_num("anchors.spring") * _gust_off - _num("anchors.damping") * _gust_vel) * h
	_gust_off += _gust_vel * h
	_body = (_body_at(float(stats["secs"])) + _gust_off).clamp(_body_lo, _body_hi)
	_react(h)
	var m := _num("anchors.maxOffset")
	for t: Tile in tiles:
		if t.plane >= 2 or t.carried_by >= 0 or t.anchor < 0:
			continue
		t.off_vel += (-_num("anchors.spring") * t.off - _num("anchors.damping") * t.off_vel) * h
		t.off += t.off_vel * h
		if t.off.length() > m:
			var n := t.off.normalized()
			t.off = n * m
			t.off_vel -= n * maxf(0.0, t.off_vel.dot(n))
		if t.hop_air:
			var s := smoothstep(0.0, 1.0, t.hop_t / maxf(t.hop_sec, EPS))
			t.pos = _body + t.hop_from.lerp(_anchors[t.hop_to] + _dev(t, t.hop_to), s)
		else:
			t.pos = _rest_pos(t, t.anchor)


## Shy and ripple: letters lean away from a seeking drone and are shoved outward by a catch. Both add to
## the offset spring's velocity; the spring brings the letter home.
func _react(h: float) -> void:
	var shy_r := _num("drift.shyRadius")
	var shy_push := _num("drift.shyPush") * _num("anchors.damping")
	var ripple_sec := maxf(_num("drift.rippleSec"), EPS)
	var shot_id := int(shot["tile_id"]) if not shot.is_empty() and shot.get("kind", "tile") == "tile" else -1
	for t: Tile in tiles:
		if t.carried_by >= 0 or t.plane >= 2 or t.id == shot_id or t.id == queued_id:
			continue
		var push := Vector2.ZERO
		for th: Thief in thieves:
			if th.state != "seek":
				continue
			var away := t.pos - th.pos
			var d := away.length()
			if d < shy_r:
				var dir := away / d if d > EPS else Vector2(0.0, 1.0)
				push += dir * shy_push * (1.0 - d / shy_r)
		if t.kick_t > 0.0:
			push += t.kick * (t.kick_t / ripple_sec) * (2.0 / ripple_sec)
			t.kick_t = maxf(0.0, t.kick_t - h)
		if push != Vector2.ZERO:
			t.off_vel += push * h * drift_scale


## A catch at `at` shoves the nearby letters outward (a velocity kick on their offset spring, spread over drift.rippleSec).
func _ripple(at: Vector2, except_id: int) -> void:
	var rad := _num("drift.rippleRadius")
	var shot_id := int(shot["tile_id"]) if not shot.is_empty() and shot.get("kind", "tile") == "tile" else -1
	for t: Tile in tiles:
		if t.id == except_id or t.carried_by >= 0 or t.plane >= 2 or t.id == shot_id or t.id == queued_id:
			continue
		var away := t.pos - at
		var d := away.length()
		if d >= rad:
			continue
		var dir := away / d if d > EPS else Vector2(0.0, 1.0)
		t.kick = dir * _num("drift.ripplePush") * (1.0 - d / rad)
		t.kick_t = _num("drift.rippleSec")


# --- hops (WP-F.21) ------------------------------------------------------------------------

## Hops need hop.every above 0 and Act II or later, or a level at or past hop.fromLevel.
func _hops_enabled() -> bool:
	if _num("hop.every") <= 0.0:
		return false
	return _act_no() >= 2 or _level_order() >= int(_num("hop.fromLevel"))


func _hop_in_progress() -> bool:
	for t: Tile in tiles:
		if t.hop_to >= 0:
			return true
	return false


## Advances hops in progress (wind-up, flight, landing) and starts the next one when it is due.
func _tick_hops(h: float) -> void:
	for t: Tile in tiles.duplicate():
		if t.hop_to < 0:
			continue
		if not t.hop_air:
			t.hop_wind -= h
			if t.hop_wind <= EPS:
				_takeoff(t)
		else:
			t.hop_t += h
			if t.hop_t + EPS >= t.hop_sec:
				_land(t)
	if _hop_at == INF or float(stats["secs"]) + EPS < _hop_at or _hop_in_progress():
		return
	var every := _num("hop.every") + _hop_rng.randf_range(-_num("hop.jitter"), _num("hop.jitter"))
	_hop_at = float(stats["secs"]) + maxf(every, _num("hop.windSec") + _num("hop.flySec") + EPS) / maxf(_pace(), EPS)
	_start_hop()


## A real letter nothing is using and a free anchor are chosen from the hop rng; nothing happens when the
## field has no free anchor. The flight is a straight line: a flying letter is lifted over the others.
func _start_hop() -> void:
	var shot_id := int(shot.get("tile_id", -1))
	var targeted := {}
	for th: Thief in thieves:
		targeted[th.target_id] = true
		targeted[th.carrying_id] = true
	var pairs: Array[Vector2i] = []
	for t: Tile in tiles:
		if t.plane >= 2 or t.decoy or not t.alive or t.carried_by >= 0 or t.anchor < 0 or t.hop_to >= 0 or t.landing > 0.0 or t.shield_t > 0.0:
			continue
		if t.id == shot_id or t.id == queued_id or t.id == _hinted_id or targeted.has(t.id):
			continue
		for j in _anchors.size():
			if _owner[j] < 0:
				pairs.append(Vector2i(t.id, j))
	if pairs.is_empty():
		return
	var pick := pairs[_hop_rng.randi_range(0, pairs.size() - 1)]
	var tile: Tile = _by_id[pick.x]
	tile.hop_to = pick.y
	tile.hop_wind = _num("hop.windSec")
	tile.hop_air = false
	tile.hop_t = 0.0
	_owner[pick.y] = tile.id  # reserved until it lands
	_emit({"type": "hop_tell", "tile_id": tile.id, "to": pick.y})
	if tile.hop_wind <= EPS:
		_takeoff(tile)


func _takeoff(t: Tile) -> void:
	var from_pos := t.pos
	if t.anchor >= 0:
		_owner[t.anchor] = -1
	t.anchor = t.hop_to
	t.hop_air = true
	t.hop_t = 0.0
	t.hop_sec = _num("hop.flySec")
	t.hop_from = t.pos - _body
	_emit({"type": "hop", "tile_id": t.id, "from": from_pos, "to": _rest_pos(t, t.hop_to), "sec": t.hop_sec})


func _land(t: Tile) -> void:
	if not t.hop_air:
		_takeoff(t)
	t.hop_to = -1
	t.hop_air = false
	t.hop_t = 0.0
	t.pos = _rest_pos(t, t.anchor)
	_emit({"type": "hop_land", "tile_id": t.id})


## A letter a downed drone dropped takes the nearest free anchor (a decoy dissolves if none is free) and flies there.
func _drop_to_anchor(t: Tile) -> void:
	var i := _nearest_free_anchor(t.pos)
	if i < 0 and _make_room():
		i = _nearest_free_anchor(t.pos)
	if i < 0:
		return
	t.anchor = i
	_owner[i] = t.id
	t.hop_to = i
	t.hop_from = t.pos - _body
	t.hop_air = true
	t.hop_t = 0.0
	t.hop_sec = _num("hop.flySec")
	_emit({"type": "hop", "tile_id": t.id, "from": t.pos, "to": _rest_pos(t, i), "sec": t.hop_sec})


func _start_shot_at(target_id: int, at: Vector2, kind: String, min_dur: float = 0.0) -> void:
	var from := origin()
	var dist := from.distance_to(at)
	var dur := _num("tether.travelTime") * (_num("tether.travelMinMul") + _num("tether.travelDistMul") * dist / _num("field.height"))
	dur = maxf(dur, min_dur)  # a shot at a hopping letter lasts until it has landed
	shot = {"tile_id": target_id, "kind": kind, "from": from, "to": at, "elapsed": 0.0, "dur": dur}
	_emit({"type": "fire", "tile_id": target_id})


func _start_queued(id: int) -> void:
	var th: Thief = _thief_by_id.get(id)
	if th != null:
		_start_shot_at(id, th.pos, "thief")
		return
	var nt: Tile = _by_id.get(id)
	if nt != null and nt.alive and nt.carried_by < 0 and nt.landing <= 0.0:
		_start_shot_at(id, _aim_pos(nt), "tile", _hop_left(nt))


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
		tile.pos = Vector2(clampf(pos.x, tile.radius, _w() - tile.radius), clampf(pos.y, _num("field.topMargin") + tile.radius, _num("field.height") - tile.radius))
		_drop_to_anchor(tile)
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
	if tile.shield_t > 0.0:
		_emit({"type": "shield_bounce", "tile_id": tile.id})
		return
	if tile.kind == "counterfeit":
		_counterfeit_catch(tile)
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
	_ripple(tile.pos, tile.id)
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
	var in_words := _word_letters().has(tile.ch)
	_emit({"type": "wrong", "tile_id": tile.id, "kind": "surplus" if in_words else "unneeded", "ch": tile.ch})
	_cost(_num("burst.wrongCost"), "wrong")
	if tile.kind == "trap" and state == "play":
		_note_trap(tile)


## A forged letter: it costs a wrong catch, resets the combo and is gone; the real one is still out there.
func _counterfeit_catch(tile: Tile) -> void:
	stats["counterfeits"] = int(stats["counterfeits"]) + 1
	combo = 1.0
	_remove(tile)
	_emit({"type": "counterfeit", "tile_id": tile.id, "ch": tile.ch, "pos": tile.pos})
	_cost(_num("burst.wrongCost"), "counterfeit")
	if state == "play":
		_refill()


## Babel's counter-word goes off when two different trap letters are caught within hazard.trapWindowSec.
func _note_trap(tile: Tile) -> void:
	if trap_fired:
		return
	var now := float(stats["secs"])
	var keep: Array[Dictionary] = []
	for h in _trap_hits:
		if now - float(h["t"]) <= _hnum("hazard.trapWindowSec") + EPS and int(h["id"]) != tile.id:
			keep.append(h)
	keep.append({"id": tile.id, "t": now})
	_trap_hits = keep
	if keep.size() < 2:
		return
	trap_fired = true
	stats["traps"] = int(stats["traps"]) + 1
	_emit({"type": "trap", "word": trap_word, "cost": _hnum("hazard.trapCost")})
	if babel_on:
		_emit({"type": "babel", "text": trap_word.capitalize() + "."})
	_cost(_hnum("hazard.trapCost"), "trap")


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
		if babel_on and finale:
			var fl := _finale_line(w)
			if fl != "":
				_emit({"type": "babel", "text": fl})
		elif babel_on:
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


## Babel's scripted finale. LISTEN is its own letters turned back (the pool holds them, so the
## letters-only rule holds). Then it says the name, and one sincere line (the one allowed exception
## to the letters-only rule, bible 3: Babel voice sheet).
func _finale_line(w: String) -> String:
	if restored_words.size() == 1:
		return "SILENT. No. LISTEN."
	return "%s. %s" % [w.to_upper(), FINALE_SINCERE]


func _end(won: bool) -> void:
	state = "won" if won else "lost"
	jammed = false
	shot = {}
	queued_id = -1
	_emit({"type": "round_end", "won": won})

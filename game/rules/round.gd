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
##   time_cost{amount,reason} (reason "wrong", "stolen" or "hint"; time_left already reduced)
##   hint{tile_id} (use_hint(): the tile to highlight; its time_cost follows)
##   thief_spawn{thief_id,pos,entry} (entry -1 left edge, 1 right, 0 top) thief_grab{thief_id,tile_id} (the tile stops being catchable)
##   stolen{thief_id,tile_id,ch} (thief left the top with the tile; both are gone, the letter respawns later)
##   thief_down{thief_id,tile_id,pos} (shot; tile_id is the released tile or -1)
##   thief_miss{thief_id} (a shot at a thief missed or the thief was gone; counts as an escape)
## Hazards (WP-F.1, all off unless the hazard.* tunables enable them):
##   counterfeit{tile_id,ch,pos} (a forged copy of a needed letter was caught: it is gone, burst.wrongCost
##   comes off with a time_cost reason "counterfeit", the real letter is still out there)
##   trap{word,cost} (two letters of Babel's counter-word caught within hazard.trapWindowSec; once per round;
##   a babel{text} event with the word follows and a time_cost reason "trap")
##   jam_on{} jam_off{} (every hazard.stroopEverySec the slot hints go dark for hazard.stroopSec: `jammed`)
## Babel's moves (WP-F.19; babel.moveEvery 0 turns them off, none while state != "play"):
##   babel_tell{move,sec} (move "volley"|"gust"|"shield"|"scramble"; babel.tellSec before the move)
##   babel_move{move,...} volley: tile_ids (new decoys, each also gets a normal spawn event and lands after babel.throwSec)
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
const STYLE_SEED_XOR := 0x57A1E5
const MOVE_SEED_XOR := 0x3B0E5A
const MOVE_NAMES: Array[String] = ["volley", "gust", "shield", "scramble"]
const ORBIT_MIN_K := 0.25
## Slow letters whose circling alone would reach this share of their speed wander instead (keeps the mean speed).
const ORBIT_MAX_RATIO := 0.9
const DART_LOW := 0.3  # a darting letter eases toward this share of its cruise speed before a burst
const DART_RAMP := 0.15  # share of the glide spent recovering from the burst
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
var _trap_hits: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _by_id: Dictionary = {}
var _next_id: int = 0
var _acc: float = 0.0
var _pool: Dictionary = {}
var _shown: Dictionary = {}
var _thief_by_id: Dictionary = {}
var _next_thief_at: float = INF
var _shot_dur: float = 0.0  # flight time of the shot being resolved (widens a dart's tolerance)
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
		_start_shot_at(tile_id, tile.pos, "tile")
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
	if t == null or not t.alive or t.plane >= 2 or t.carried_by >= 0 or t.kind == "counterfeit" or t.shield_t > 0.0:
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
	return Vector2(0.5, _num("field.height"))


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


func _spawn(ch: String, decoy: bool, plane: int) -> Tile:
	var tile: Tile = Tile.new()
	tile.id = _next_id
	_next_id += 1
	tile.ch = ch
	tile.decoy = decoy
	tile.plane = plane
	tile.radius = _num("tile.size") * _scale_of(plane) / 2.0
	var r := tile.radius
	var gap := _num("tile.minGap")
	# Rejection-sample a free spot; if none turns up, keep the roomiest try (separation does the rest).
	var best_slack := -INF
	var best_pos := Vector2.ZERO
	for _try in 256:
		var p := Vector2(_rng.randf_range(r, 1.0 - r), _rng.randf_range(_num("field.topMargin") + r, _num("field.height") - r))
		var slack := INF if plane >= 2 else _catchable_slack(p, r, gap, plane)
		if slack > best_slack:
			best_slack = slack
			best_pos = p
		if slack >= 0.0:
			break
	tile.pos = best_pos
	var angle := _rng.randf() * TAU
	var var_frac := _num("drift.speedVariation")
	var speed := _num("drift.speed") * float(ramp()["drift"]) * (1.0 + _rng.randf_range(-var_frac, var_frac))
	if plane >= 2:
		speed *= _num("plane.backSpeedMul")
	elif plane == 1:
		speed *= _num("plane.midSpeedMul")  # parallax: the deeper layer drifts a little slower
	tile.vel = Vector2(cos(angle), sin(angle)) * speed
	tile.base_speed = speed
	if not decoy:
		_assign_style(tile)
	if float(stats.get("secs", 0.0)) > 0.0:
		tile.landing = _num("babel.throwSec")
	tiles.append(tile)
	_by_id[tile.id] = tile
	_emit({"type": "spawn", "tile_id": tile.id, "ch": ch, "plane": plane, "decoy": decoy, "pos": tile.pos, "style": tile.style})
	return tile


## Motion style from a throwaway rng keyed on (seed, tile id), so the spawner's own sequence is untouched.
func _assign_style(tile: Tile) -> void:
	var g := RandomNumberGenerator.new()
	g.seed = hash([seed_value, tile.id, STYLE_SEED_XOR])
	var roll := g.randf()
	var orbit_share := _num("drift.orbitShare")
	var dart_share := _num("drift.dartShare")
	var orbit_angle := g.randf() * TAU
	var tang := _num("drift.orbitRadius") * TAU * _num("drift.orbitHz")
	var ratio := tang / maxf(tile.base_speed, EPS)
	if roll < orbit_share:
		if ratio >= ORBIT_MAX_RATIO:
			return  # too slow to circle without speeding up: wanders
		tile.style = "orbit"
		tile.orbit_angle = orbit_angle
		# Start on the circle (the centre sits one radius away), so the first step does not jump.
		tile.orbit_off = Vector2(cos(orbit_angle), sin(orbit_angle)) * _num("drift.orbitRadius")
		tile.orbit_k = sqrt(maxf(ORBIT_MIN_K * ORBIT_MIN_K, 1.0 - ratio * ratio))
	elif roll < orbit_share + dart_share:
		tile.style = "dart"
		tile.dart_len = maxf(_num("drift.dartEvery") * g.randf_range(0.85, 1.15), _num("drift.dartSec") * 2.0)
		tile.dart_phase = g.randf() * tile.dart_len
		# Normalise the cycle so the mean speed equals the base speed (cruise speed = base / norm).
		var n := 64
		var sum := 0.0
		for i in n:
			sum += _dart_mul(tile, (float(i) + 0.5) / float(n) * tile.dart_len)
		tile.dart_norm = maxf(sum / float(n), 0.1)


## Dart speed multiplier at u seconds into a cycle: eases from the cruise speed toward DART_LOW over the
## glide, then a burst up to drift.dartBoost for drift.dartSec; a short ramp-up after the burst.
func _dart_mul(t: Tile, u: float) -> float:
	var burst := _num("drift.dartSec")
	var glide := t.dart_len - burst
	if u >= glide:
		var b := (u - glide) / burst
		return DART_LOW + (_num("drift.dartBoost") - DART_LOW) * sin(PI * b)
	var g := u / glide
	var ease_down := 1.0 - (1.0 - DART_LOW) * sin(g * PI * 0.5)
	var k := clampf(g / DART_RAMP, 0.0, 1.0)
	return ease_down * (DART_LOW + (1.0 - DART_LOW) * k * k * (3.0 - 2.0 * k))


## The smallest clearance between a tile of radius r at p and any live catchable tile on the same
## plane (negative: overlap). The front and mid planes may overlap: a letter can drift behind another
## (2.5D, owner 13 Oct 2026: "letters ... one behind another").
func _catchable_slack(p: Vector2, r: float, gap: float, plane: int) -> float:
	var worst := INF
	for o: Tile in tiles:
		if o.alive and o.plane == plane:
			worst = minf(worst, p.distance_to(o.pos) - (r + o.radius + gap))
	return worst


## Pushes overlapping catchable tiles on the same plane apart and bounces them (equal masses), in list order.
## Returns true when it moved any tile.
func _separate_tiles() -> bool:
	var moved := false
	var gap := _num("tile.minGap")
	var n := tiles.size()
	for i in n:
		var a: Tile = tiles[i]
		if not a.alive or a.plane >= 2 or a.carried_by >= 0:
			continue
		for j in range(i + 1, n):
			var b: Tile = tiles[j]
			if not b.alive or b.plane != a.plane or b.carried_by >= 0:
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
			var rel := (b.vel - a.vel).dot(normal)
			if rel < 0.0:
				a.vel += normal * rel
				b.vel -= normal * rel
	return moved


func _clamp_to_field(t: Tile) -> void:
	var r := t.radius
	t.pos.x = clampf(t.pos.x, r, 1.0 - r)
	t.pos.y = clampf(t.pos.y, _num("field.topMargin") + r, _num("field.height") - r)


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
		_spawn(c, true, _pick_plane()).kind = "trap"
		n += 1
	while forged < want_forged:
		var letters: Array = _needed_counts().keys()
		letters.sort()
		_spawn(letters[_hazard_rng.randi_range(0, letters.size() - 1)], true, _pick_plane()).kind = "counterfeit"
		forged += 1
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
	_tick_jam()
	_tick_moves()
	if _gust_t > 0.0:
		_gust_t = maxf(0.0, _gust_t - h)
	for t: Tile in tiles:
		t.landing = maxf(0.0, t.landing - h)
		t.shield_t = maxf(0.0, t.shield_t - h)
		if t.carried_by < 0:
			_drift(t, h)
	_react(h)
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
	var act_no := 1
	if act.begins_with("act") and act.length() > 3 and act[3].is_valid_int():
		act_no = int(act[3])
	var order := 1 << 30
	var parts := level_id.split("-")
	if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
		order = int(parts[1])
	if act_no >= 2 or order >= int(_num("babel.movesFromLevel")):
		out.append("volley")
	if act_no >= int(_num("babel.gustFromAct")):
		out.append("gust")
	if act_no >= int(_num("babel.shieldFromAct")):
		out.append("shield")
	if act_no >= int(_num("babel.scrambleFromAct")):
		out.append("scramble")
	return out


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


func _decoy_room() -> int:
	var n := 0
	for t: Tile in tiles:
		if t.plane < 2 and t.decoy:
			n += 1
	return int(_num("ramp.decoyMax")) - n


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
				ids.append(_spawn(_weighted_letter(excluded), true, _pick_plane()).id)
			for _pass in 16:
				if not _separate_tiles():
					break
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
			if t.plane >= 2 or t.decoy or t.carried_by >= 0 or not t.alive or t.landing > 0.0:
				continue
			if t.ch == want:
				return t
			if fallback == null and _open_slot(active, t.ch) >= 0:
				fallback = t
		return fallback
	return null


func _scramble() -> void:
	var moves: Array = []
	var gap := _num("tile.minGap")
	for t: Tile in tiles:
		if t.plane >= 2 or t.carried_by >= 0 or not t.alive:
			continue
		var r := t.radius
		var best_slack := -INF
		var best_pos := t.pos
		for _try in 64:
			var p := Vector2(_move_rng.randf_range(r, 1.0 - r), _move_rng.randf_range(_num("field.topMargin") + r, _num("field.height") - r))
			var worst := INF
			for o: Tile in tiles:
				if o != t and o.alive and o.plane == t.plane:
					worst = minf(worst, p.distance_to(o.pos) - (r + o.radius + gap))
			if worst > best_slack:
				best_slack = worst
				best_pos = p
			if worst >= 0.0:
				break
		moves.append({"tile_id": t.id, "from": t.pos, "to": best_pos})
		t.pos = best_pos
		t.landing = maxf(t.landing, _num("babel.scrambleSec"))
	for _pass in 16:
		if not _separate_tiles():
			break
	for m: Dictionary in moves:
		m["to"] = find_tile(int(m["tile_id"])).pos
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
		th.pos = Vector2(1.0 if right else 0.0, _thief_rng.randf_range(top, max_y))
		th.entry = 1 if right else -1
	else:
		th.pos = Vector2(_thief_rng.randf_range(0.0, 1.0), top)
	var angle := _thief_rng.randf() * TAU
	th.vel = Vector2(cos(angle), sin(angle)) * _num("thief.speed") * THIEF_IDLE_MUL
	if from_side:
		th.vel.x = -absf(th.vel.x) if th.pos.x > 0.5 else absf(th.vel.x)
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
		if t.decoy or t.plane >= 2 or t.carried_by >= 0 or t.landing > 0.0 or t.shield_t > 0.0 or t.id == shot_id or t.id == queued_id:
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
		# Flee to the nearest of the left, right and top edges (never the bottom); ties go to the top.
		var to_left := th.pos.x
		var to_right := 1.0 - th.pos.x
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
	if th.pos.y < 0.0 or th.pos.x < 0.0 or th.pos.x > 1.0:
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
	_steer(t, h)
	var r := t.radius
	if t.style == "orbit" and t.base_speed > 0.0 and t.vel.length() >= EPS:
		_orbit_move(t, h)
	else:
		t.pos += t.vel * h * drift_scale
	if _gust_t > 0.0 and t.plane < 2:
		t.pos += _gust_dir * _num("babel.gustPush") * (_gust_t / _num("babel.gustSec")) * h * drift_scale
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


## Orbit: the tile circles a centre that wanders like a plain letter (bouncing off the walls with the
## circle's radius as extra inset). The centre is recovered from the position each step, so separation
## pushes carry over.
func _orbit_move(t: Tile, h: float) -> void:
	var rad := _num("drift.orbitRadius")
	var anchor := t.pos - t.orbit_off
	anchor += t.vel * h * drift_scale
	var inset := t.radius + rad
	var top := _num("field.topMargin") + inset
	var bottom := _num("field.height") - inset
	if anchor.x < inset:
		anchor.x = inset
		t.vel.x = absf(t.vel.x)
	elif anchor.x > 1.0 - inset:
		anchor.x = 1.0 - inset
		t.vel.x = -absf(t.vel.x)
	if anchor.y < top:
		anchor.y = top
		t.vel.y = absf(t.vel.y)
	elif anchor.y > bottom:
		anchor.y = bottom
		t.vel.y = -absf(t.vel.y)
	t.orbit_angle += TAU * _num("drift.orbitHz") * h * drift_scale
	t.orbit_off = Vector2(cos(t.orbit_angle), sin(t.orbit_angle)) * rad
	t.pos = anchor + t.orbit_off


## Shy and ripple: letters edge away from a seeking drone and are shoved outward by a catch.
func _react(h: float) -> void:
	var shy_r := _num("drift.shyRadius")
	var shy_push := _num("drift.shyPush")
	var ripple_sec := maxf(_num("drift.rippleSec"), EPS)
	var shot_id := int(shot["tile_id"]) if not shot.is_empty() and shot.get("kind", "tile") == "tile" else -1
	for t: Tile in tiles:
		if t.carried_by >= 0 or t.plane >= 2 or t.id == shot_id or t.id == queued_id:
			continue
		var move := Vector2.ZERO
		if t.vel.length() >= EPS:
			for th: Thief in thieves:
				if th.state != "seek":
					continue
				var away := t.pos - th.pos
				var d := away.length()
				if d < shy_r:
					var dir := away / d if d > EPS else Vector2(0.0, 1.0)
					move += dir * shy_push * (1.0 - d / shy_r)
		if t.kick_t > 0.0:
			move += t.kick * (t.kick_t / ripple_sec)
			t.kick_t = maxf(0.0, t.kick_t - h)
		if move != Vector2.ZERO:
			t.pos += move * h * drift_scale
			_clamp_to_field(t)


## A catch at `at` shoves the nearby letters outward (decaying over drift.rippleSec).
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


## Letters swoop instead of sliding in straight lines (owner, 13 Oct 2026: "very slow"): the heading
## turns one way then the other, and the speed surges and eases. Both follow sine waves whose phase
## comes from the tile id, so neighbours move out of step and the drift stays deterministic.
## A tile someone stopped (vel zero) stays stopped.
func _steer(t: Tile, h: float) -> void:
	if t.base_speed <= 0.0 or t.vel.length() < EPS:
		return
	var ph := float(t.id) * GOLDEN_ANGLE
	var secs := float(stats["secs"])
	var turn := _num("drift.curve") * sin(secs * TAU * _num("drift.curveHz") + ph)
	if t.style == "dart":
		_steer_dart(t, h, turn)
		return
	var surge := 1.0 + _num("drift.surge") * sin(secs * TAU * _num("drift.surgeHz") + ph * 1.7)
	t.vel = t.vel.normalized().rotated(turn * h) * t.base_speed * surge * (t.orbit_k if t.style == "orbit" else 1.0)


## Dart: glide (curving like a wanderer) and ease off, then a burst in a fresh direction. The cycle clock
## is the round clock plus a per-tile phase; the new heading is hashed from (seed, tile id, cycle).
func _steer_dart(t: Tile, h: float, turn: float) -> void:
	var tt := float(stats["secs"]) + t.dart_phase
	var idx := int(floorf(tt / t.dart_len))
	var u := tt - float(idx) * t.dart_len
	var bursting := u >= t.dart_len - _num("drift.dartSec")
	var dir := t.vel.normalized().rotated(turn * h)
	if bursting and not t.dart_burst:
		var g := RandomNumberGenerator.new()
		g.seed = hash([seed_value, t.id, idx, STYLE_SEED_XOR])
		dir = Vector2.RIGHT.rotated(g.randf() * TAU)
	t.dart_burst = bursting
	t.dart_idx = idx
	t.vel = dir * (t.base_speed / t.dart_norm) * _dart_mul(t, u)


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
	_shot_dur = float(shot["dur"])
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


func _tolerance(tile: Tile = null) -> float:
	var tol := _num("tether.hitTolerance") * _num("tether.driftToleranceMul")
	# A letter in a dart burst covers ground while the tether flies: widen by half that distance.
	if tile != null and tile.style == "dart" and tile.dart_burst:
		tol += 0.5 * tile.vel.length() * _shot_dur
	return tol


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
	if tile.carried_by >= 0 or tile.pos.distance_to(target) > _tolerance(tile):
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
	tile.vel = -tile.vel
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

extends RefCounted
## Progress save (WP-3.5a). The only code that reads or writes the save file.
## Format v2: {version, player_id, updated_at, profile: {character, pronouns, difficulty},
##   progress: {act: {next, levels: {id: {best_score, best_stars, won, plays}}}}}.
## v1 had no profile and `won` was a per-mode dictionary; it migrates on load (a win becomes 1 star).
## On the web Godot keeps user:// in the browser's IndexedDB. Save.fake() is in-memory and touches no disk.

const VERSION := 2
const ACT_ORDER := ["act1_low_orbit", "act2_nebula", "act3_tower", "act4_core"]
const DEFAULT_ACT_SIZE := 12
const DEFAULT_PATH := "user://save.json"
## Older saves recorded a win per mode (drift/pressure); any of them counts as a burst win.
const LEGACY_MODES := ["drift", "pressure", "burst"]

var path: String = ""
var _d: Dictionary = {}
## Act order and level counts, for unlocked(); main sets them from the dictionary.
var act_order: Array = ACT_ORDER.duplicate()
var act_sizes: Dictionary = {}


static func real(p: String = DEFAULT_PATH) -> RefCounted:
	return load("res://services/save.gd").new(p)


static func fake() -> RefCounted:
	return load("res://services/save.gd").new("")


func _init(p: String = "") -> void:
	path = p
	load_progress()


## Reads the file (real) or keeps the memory copy (fake). Missing or bad data starts fresh.
## If the main file does not parse, a leftover temp file from an interrupted write is tried.
func load_progress() -> void:
	if path == "":
		if _d.is_empty():
			_d = _fresh()
		return
	var parsed: Variant = _read_json(path)
	if not parsed is Dictionary:
		var alt: Variant = _read_json(path + ".tmp")
		if alt is Dictionary:
			parsed = alt
	_d = _migrate(parsed)


static func _read_json(p: String) -> Variant:
	if not FileAccess.file_exists(p):
		return null
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return null
	var j := JSON.new()
	if j.parse(f.get_as_text()) != OK:
		push_warning("save: %s is not valid JSON" % p)
		return null
	return j.data


func data() -> Dictionary:
	return _d


func player_id() -> String:
	return str(_d["player_id"])


func next_level(act: String) -> int:
	return int(_act(act).get("next", 0))


func act_complete(act: String, n_levels: int) -> bool:
	return n_levels > 0 and next_level(act) >= n_levels


func has_progress(act: String) -> bool:
	return next_level(act) > 0


func record_level(act: String, level_id: String, index: int, won: bool, score: int, stars: int = 0) -> void:
	var a := _act(act, true)
	var levels: Dictionary = a["levels"]
	levels[level_id] = _level(levels.get(level_id))
	var l: Dictionary = levels[level_id]
	l["plays"] = int(l.get("plays", 0)) + 1
	if won:
		l["best_score"] = maxi(int(l.get("best_score", 0)), score)
		l["best_stars"] = maxi(int(l.get("best_stars", 0)), clampi(stars, 1, 3))
		l["won"] = true
		a["next"] = maxi(int(a.get("next", 0)), index + 1)
	_write()


## A level entry repaired to the full shape (missing or wrong-typed parts get defaults).
## Accepts v1 entries, where `won` was {mode: bool}; any win counts and earns 1 star.
static func _level(v: Variant) -> Dictionary:
	var src: Dictionary = v if v is Dictionary else {}
	var won := false
	var sw: Variant = src.get("won")
	if sw is Dictionary:
		for m in LEGACY_MODES:
			if (sw as Dictionary).get(m, false) == true:
				won = true
	elif sw == true:
		won = true
	var stars := mini(_int(src.get("best_stars")), 3)
	if won and stars == 0:
		stars = 1
	return {"best_score": _int(src.get("best_score")), "best_stars": stars if won else 0, "won": won, "plays": _int(src.get("plays"))}


## True when the player may start level `index` (0-based) of `act`: levels open in order,
## and the first level of an act opens when the previous act is finished.
func unlocked(act: String, index: int) -> bool:
	if index < 0 or index >= _size(act):
		return false
	if index > 0:
		return index <= next_level(act)
	var at := act_order.find(act)
	if at <= 0:
		return true
	var prev: String = act_order[at - 1]
	return act_complete(prev, _size(prev))


func _size(act: String) -> int:
	return int(act_sizes.get(act, DEFAULT_ACT_SIZE))


func stars(act: String, level_id: String) -> int:
	var l: Variant = _act(act).get("levels", {}).get(level_id)
	return _int((l as Dictionary).get("best_stars")) if l is Dictionary else 0


func total_stars() -> int:
	var n := 0
	for act in (_d["progress"] as Dictionary):
		for id in (_d["progress"][act]["levels"] as Dictionary):
			n += _int(_d["progress"][act]["levels"][id].get("best_stars"))
	return n


func has_profile() -> bool:
	return str(profile().get("character", "")) != ""


func profile() -> Dictionary:
	return _d["profile"]


func set_profile(character: String, pronouns: String, difficulty: String) -> void:
	_d["profile"] = {"character": character, "pronouns": pronouns, "difficulty": difficulty}
	_write()


static func _int(v: Variant) -> int:
	return maxi(int(v), 0) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else 0


## Wipes progress, keeps the anonymous player_id.
func reset() -> void:
	_d["progress"] = {}
	_write()


func _act(act: String, create: bool = false) -> Dictionary:
	var p: Dictionary = _d["progress"]
	if not p.has(act):
		if not create:
			return {}
		p[act] = {"next": 0, "levels": {}}
	return p[act]


static func _fresh() -> Dictionary:
	return {"version": VERSION, "player_id": _new_id(), "updated_at": 0, "profile": {"character": "", "pronouns": "they", "difficulty": ""}, "progress": {}}


static func _new_id() -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_usec() ^ int(Time.get_unix_time_from_system() * 1000.0)
	var s := ""
	for i in 16:
		s += "0123456789abcdef"[rng.randi() % 16]
	return s


## Accepts versions 1 (migrated to 2) and 2; anything else becomes a fresh save.
static func _migrate(d: Variant) -> Dictionary:
	if d == null:
		return _fresh()
	if not d is Dictionary:
		push_warning("save: not a dictionary; starting fresh")
		return _fresh()
	var dict: Dictionary = d
	if not dict.has("version") or typeof(dict["version"]) not in [TYPE_INT, TYPE_FLOAT] or int(dict["version"]) not in [1, VERSION]:
		push_warning("save: unknown version; starting fresh")
		return _fresh()
	if not dict.get("progress") is Dictionary or typeof(dict.get("player_id")) != TYPE_STRING or str(dict["player_id"]) == "":
		push_warning("save: malformed save; starting fresh")
		return _fresh()
	dict["version"] = VERSION
	var prof: Variant = dict.get("profile")
	var pf: Dictionary = prof if prof is Dictionary else {}
	dict["profile"] = {"character": str(pf.get("character", "")), "pronouns": str(pf.get("pronouns", "they")), "difficulty": str(pf.get("difficulty", ""))}
	var clean: Dictionary = {}
	for act in (dict["progress"] as Dictionary):
		var a: Variant = dict["progress"][act]
		if not a is Dictionary:
			push_warning("save: dropping malformed act %s" % str(act))
			continue
		var levels: Dictionary = {}
		var raw: Variant = (a as Dictionary).get("levels")
		if raw is Dictionary:
			for id in raw:
				levels[str(id)] = _level(raw[id])
		clean[str(act)] = {"next": _int((a as Dictionary).get("next")), "levels": levels}
	dict["progress"] = clean
	return dict


func _write() -> void:
	_d["updated_at"] = int(Time.get_unix_time_from_system())
	if path == "":
		return
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("save: cannot write %s" % tmp)
		return
	var ok := f.store_string(JSON.stringify(_d))
	f.close()
	if not ok:
		push_warning("save: write to %s failed; keeping the old file" % tmp)
		return
	# The live file is never truncated: it is replaced by the rename or left as it was.
	if DirAccess.rename_absolute(tmp, path) != OK:
		push_warning("save: rename failed; the new data stays in %s" % tmp)
		return
	if FileAccess.file_exists(tmp):
		DirAccess.remove_absolute(tmp)

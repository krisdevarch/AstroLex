extends RefCounted
## Progress save (WP-3.5a). The only code that reads or writes the save file.
## Format: {version, player_id, updated_at, progress: {act: {next, levels: {id: {best_score, won{mode}, plays}}}}}.
## On the web Godot keeps user:// in the browser's IndexedDB. Save.fake() is in-memory and touches no disk.

const VERSION := 1
const DEFAULT_PATH := "user://save.json"
const MODES := ["drift", "pressure"]

var path: String = ""
var _d: Dictionary = {}


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


func record_level(act: String, level_id: String, index: int, mode: String, won: bool, score: int) -> void:
	var a := _act(act, true)
	var levels: Dictionary = a["levels"]
	levels[level_id] = _level(levels.get(level_id))
	var l: Dictionary = levels[level_id]
	l["plays"] = int(l.get("plays", 0)) + 1
	if won:
		l["best_score"] = maxi(int(l.get("best_score", 0)), score)
		(l["won"] as Dictionary)[mode] = true
		a["next"] = maxi(int(a.get("next", 0)), index + 1)
	_write()


## A level entry repaired to the full shape (missing or wrong-typed parts get defaults).
static func _level(v: Variant) -> Dictionary:
	var src: Dictionary = v if v is Dictionary else {}
	var won: Dictionary = {}
	var sw: Dictionary = src["won"] if src.get("won") is Dictionary else {}
	for m in MODES:
		won[m] = sw.get(m, false) == true
	return {"best_score": _int(src.get("best_score")), "won": won, "plays": _int(src.get("plays"))}


static func _int(v: Variant) -> int:
	return maxi(int(v), 0) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else 0


## Play the act again from the first level; best scores and won flags stay.
func restart_act(act: String) -> void:
	_act(act, true)["next"] = 0
	_write()


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
	return {"version": VERSION, "player_id": _new_id(), "updated_at": 0, "progress": {}}


static func _new_id() -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_usec() ^ int(Time.get_unix_time_from_system() * 1000.0)
	var s := ""
	for i in 16:
		s += "0123456789abcdef"[rng.randi() % 16]
	return s


## Accepts version 1 only; anything else becomes a fresh save.
static func _migrate(d: Variant) -> Dictionary:
	if d == null:
		return _fresh()
	if not d is Dictionary:
		push_warning("save: not a dictionary; starting fresh")
		return _fresh()
	var dict: Dictionary = d
	if not dict.has("version") or typeof(dict["version"]) not in [TYPE_INT, TYPE_FLOAT] or int(dict["version"]) != VERSION:
		push_warning("save: unknown version; starting fresh")
		return _fresh()
	if not dict.get("progress") is Dictionary or typeof(dict.get("player_id")) != TYPE_STRING or str(dict["player_id"]) == "":
		push_warning("save: malformed v1 save; starting fresh")
		return _fresh()
	dict["version"] = VERSION
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

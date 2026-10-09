extends RefCounted
## The one place game code gets words and levels (WP-B.6). See docs/dictionary-storage.md.
## Sources: "bundled" (res://data/content.json), "cache" (a remote document saved on an earlier run),
## "remote" (only via accept(); a fetch is cached for the next start) and "fake" (tests). Any failure keeps what is already loaded.
## Interface: content(), levels(act), act_order(), source_name(), version().

const GameData := preload("res://rules/game_data.gd")

## Empty in the beta: no server yet. ?dict=<url> on the web overrides it for testing.
const REMOTE_URL := ""
const CACHE_PATH := "user://dictionary_cache.json"
const REQUIRED := ["acts", "levels", "lexicon", "templates"]
const DEFAULT_ORDER := ["act1_low_orbit", "act2_nebula", "act3_tower", "act4_core"]

signal updated

var cache_path: String = CACHE_PATH
var _content: Dictionary = {}
var _source: String = "bundled"
var _http: HTTPRequest


## Bundled content, replaced by a valid cached remote document when its version is not older.
static func bundled(use_cache: bool = true, p: String = CACHE_PATH) -> RefCounted:
	var d: RefCounted = load("res://services/dictionary.gd").new()
	d.cache_path = p
	d._content = GameData.load_content()
	if use_cache:
		d.load_cache()
	return d


## In-memory dictionary for tests; touches neither disk nor network.
static func fake(content: Dictionary) -> RefCounted:
	var d: RefCounted = load("res://services/dictionary.gd").new()
	d._content = content
	d._source = "fake"
	d.cache_path = ""
	return d


func content() -> Dictionary:
	return _content


func levels(act: String) -> Array:
	var l: Variant = (_content.get("levels", {}) as Dictionary).get(act, [])
	return l if l is Array else []


## Acts in play order: the known order first, then any extra act the content has.
func act_order() -> Array:
	var have: Dictionary = _content.get("levels", {})
	var out: Array = []
	for a in DEFAULT_ORDER:
		if have.has(a):
			out.append(a)
	for a in have:
		if not out.has(a):
			out.append(a)
	return out


func source_name() -> String:
	return _source


func version() -> int:
	return int(_content.get("version", 0))


## True when `doc` has the content shape the game dereferences and an integer version. Pure.
static func valid(doc: Variant) -> bool:
	if not doc is Dictionary:
		return false
	var d: Dictionary = doc
	for k in REQUIRED:
		if not d.has(k):
			return false
	if not (d["acts"] is Dictionary and d["levels"] is Dictionary and d["lexicon"] is Array):
		return false
	if typeof(d.get("version")) not in [TYPE_INT, TYPE_FLOAT] or float(d["version"]) != floorf(float(d["version"])):
		return false
	for act in (d["acts"] as Dictionary):
		var a: Variant = d["acts"][act]
		if not (a is Dictionary and (a as Dictionary).get("words") is Array):
			return false
	for act in (d["levels"] as Dictionary):
		if not d["levels"][act] is Array:
			return false
		for lv in (d["levels"][act] as Array):
			if not _valid_level(lv):
				return false
	var ch: Variant = d.get("characters")
	if not (ch is Array and not (ch as Array).is_empty()):
		return false
	for c in (ch as Array):
		if not (c is Dictionary):
			return false
		var cd: Dictionary = c
		if not (cd.get("id") is String and cd.get("name") is String and cd.get("colour") is String and cd.get("mod") is Dictionary):
			return false
	var df: Variant = d.get("difficulty")
	if not (df is Dictionary and (df as Dictionary).has("default") and (df as Dictionary).get("levels") is Array):
		return false
	return true


static func _valid_level(lv: Variant) -> bool:
	if not lv is Dictionary:
		return false
	var l: Dictionary = lv
	if not (l.get("id") is String and typeof(l.get("seed")) in [TYPE_INT, TYPE_FLOAT]):
		return false
	var w: Variant = l.get("words")
	if not (w is Array and not (w as Array).is_empty()):
		return false
	for x in (w as Array):
		if not x is String:
			return false
	return true


## Uses `doc` when it is valid and not older than the current content. True if it was taken.
func accept(doc: Variant, source: String = "remote") -> bool:
	if not valid(doc):
		return false
	if int((doc as Dictionary)["version"]) < version():
		return false
	_content = (doc as Dictionary).duplicate()
	_source = source
	updated.emit()
	return true


func load_cache() -> bool:
	if cache_path == "" or not FileAccess.file_exists(cache_path):
		return false
	var f := FileAccess.open(cache_path, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return accept(parsed, "cache")


func _save_cache(doc: Dictionary) -> void:
	if cache_path == "":
		return
	var f := FileAccess.open(cache_path, FileAccess.WRITE)
	if f == null:
		push_warning("dictionary: cannot write %s" % cache_path)
		return
	f.store_string(JSON.stringify(doc))
	f.close()


## The address to fetch: ?dict=<url> on the web in debug builds only, else REMOTE_URL ("" means off).
static func remote_url() -> String:
	if OS.has_feature("web") and OS.is_debug_build():
		var q := str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('dict') || ''"))
		if q != "":
			return q
	return REMOTE_URL


## Starts the fetch under `parent` (needs the scene tree). Does nothing when no address is set.
func start_remote(parent: Node, url: String = "") -> bool:
	var u := url if url != "" else remote_url()
	if u == "" or _http != null:
		return false
	_http = HTTPRequest.new()
	_http.name = "DictionaryRequest"
	_http.timeout = 15.0
	parent.add_child(_http)
	_http.request_completed.connect(_on_done)
	if _http.request(u) != OK:
		_cleanup()
		return false
	return true


func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		handle_remote(JSON.parse_string(body.get_string_from_utf8()))
	else:
		push_warning("dictionary: remote fetch failed (%d/%d); keeping %s" % [result, code, _source])
	_cleanup()


## A fetched document never replaces the running content. If it is valid and not older, it is
## written to the cache (only when REMOTE_URL is set) and used from the next app start.
func handle_remote(parsed: Variant) -> bool:
	if not valid(parsed) or int((parsed as Dictionary)["version"]) < version():
		push_warning("dictionary: remote document rejected; keeping %s" % _source)
		return false
	if REMOTE_URL != "":
		_save_cache(parsed)
	return true


func _cleanup() -> void:
	if _http != null:
		_http.queue_free()
		_http = null

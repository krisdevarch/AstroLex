extends RefCounted
## The one place game code gets words and levels (WP-B.6). See docs/dictionary-storage.md.
## Sources: "bundled" (res://data/content.json), "cache" (a remote document saved on an earlier run),
## "remote" (fetched this run) and "fake" (tests). Any failure keeps what is already loaded.
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


## True when `doc` has the content shape and an integer version. Pure; no side effects.
static func valid(doc: Variant) -> bool:
	if not doc is Dictionary:
		return false
	var d: Dictionary = doc
	for k in REQUIRED:
		if not d.has(k):
			return false
	if not (d["acts"] is Dictionary and d["levels"] is Dictionary and d["lexicon"] is Dictionary):
		return false
	if typeof(d.get("version")) not in [TYPE_INT, TYPE_FLOAT] or float(d["version"]) != floorf(float(d["version"])):
		return false
	for act in (d["levels"] as Dictionary):
		if not d["levels"][act] is Array:
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


## The address to fetch: ?dict=<url> on the web, else REMOTE_URL ("" means off).
static func remote_url() -> String:
	if OS.has_feature("web"):
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
		var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		if accept(parsed, "remote"):
			_save_cache(parsed)
		else:
			push_warning("dictionary: remote document rejected; keeping %s" % _source)
	else:
		push_warning("dictionary: remote fetch failed (%d/%d); keeping %s" % [result, code, _source])
	_cleanup()


func _cleanup() -> void:
	if _http != null:
		_http.queue_free()
		_http = null

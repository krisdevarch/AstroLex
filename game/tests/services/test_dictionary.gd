extends "res://tests/test_case.gd"

const GameData := preload("res://rules/game_data.gd")
const Dict := preload("res://services/dictionary.gd")
const CACHE := "user://test_dictionary_cache.json"


func _doc(version: Variant) -> Dictionary:
	return {
		"version": version,
		"acts": {"a": {"words": ["x"]}},
		"levels": {"act1_low_orbit": [{"id": "1-01", "seed": 7, "words": ["x"]}]},
		"lexicon": [["able", "A"]],
		"templates": [],
		"characters": [{"id": "w", "name": "W", "colour": "#fff", "mod": {}}],
		"difficulty": {"default": "normal", "levels": []},
	}


func _clean() -> void:
	if FileAccess.file_exists(CACHE):
		DirAccess.remove_absolute(CACHE)


func test_bundled_has_four_acts_of_twelve_levels() -> void:
	var d: RefCounted = Dict.bundled(false)
	assert_eq(d.source_name(), "bundled")
	assert_eq(d.act_order(), ["act1_low_orbit", "act2_nebula", "act3_tower", "act4_core"])
	for a in d.act_order():
		assert_eq(d.levels(a).size(), 12, a)
	assert_eq(d.levels("nope"), [])
	assert_true(d.version() > 0, "exporter writes a content version")
	assert_true(d.content().has("lexicon"))


func test_fake_serves_what_it_is_given() -> void:
	var d: RefCounted = Dict.fake(_doc(5))
	assert_eq(d.source_name(), "fake")
	assert_eq(d.version(), 5)
	assert_eq(d.act_order(), ["act1_low_orbit"])
	assert_eq(d.levels("act1_low_orbit").size(), 1)


func test_remote_validation_rejects_bad_shapes() -> void:
	var d: RefCounted = Dict.bundled(false)
	for bad in [null, 5, [], {}, {"version": 1}, _doc("1"), _doc(1.5), _doc(null)]:
		assert_false(d.accept(bad), "rejected: %s" % var_to_str(bad))
	var no_lex := _doc(3)
	no_lex.erase("lexicon")
	assert_false(d.accept(no_lex), "missing key")
	var bad_levels := _doc(3)
	bad_levels["levels"] = {"act1_low_orbit": "x"}
	assert_false(d.accept(bad_levels), "levels must be arrays")
	assert_eq(d.source_name(), "bundled", "bundled kept")
	assert_eq(d.levels("act2_nebula").size(), 12)


func test_real_content_is_valid() -> void:
	var c: Dictionary = GameData.load_content()
	assert_true(c.has("version"))
	assert_true(Dict.valid(c), "bundled content.json passes the shape check")


func test_valid_checks_what_the_game_dereferences() -> void:
	var no_seed := _doc(2)
	no_seed["levels"]["act1_low_orbit"][0].erase("seed")
	assert_false(Dict.valid(no_seed), "missing seed")
	var no_chars := _doc(2)
	no_chars.erase("characters")
	assert_false(Dict.valid(no_chars), "missing characters")
	var empty_chars := _doc(2)
	empty_chars["characters"] = []
	assert_false(Dict.valid(empty_chars), "empty characters")
	var no_diff := _doc(2)
	no_diff["difficulty"] = {"default": "normal"}
	assert_false(Dict.valid(no_diff), "difficulty without levels")
	var no_words := _doc(2)
	no_words["acts"]["a"] = {}
	assert_false(Dict.valid(no_words), "act without words")
	var empty_words := _doc(2)
	empty_words["levels"]["act1_low_orbit"][0]["words"] = []
	assert_false(Dict.valid(empty_words), "level with no words")
	assert_true(Dict.valid(_doc(2)))


func test_remote_document_never_swaps_running_content_or_writes_cache_without_url() -> void:
	_clean()
	var d: RefCounted = Dict.bundled(false, CACHE)
	var b: int = d.version()
	assert_true(d.handle_remote(_doc(b + 1)), "valid newer document is acceptable for next start")
	assert_eq(d.version(), b, "running content unchanged")
	assert_eq(d.source_name(), "bundled")
	assert_false(FileAccess.file_exists(CACHE), "no cache write when REMOTE_URL is empty")
	assert_false(d.handle_remote(_doc(b - 1)), "older rejected")


func test_remote_accepts_a_valid_newer_document_and_ignores_older() -> void:
	var d: RefCounted = Dict.bundled(false)
	var b: int = d.version()
	assert_false(d.accept(_doc(b - 1)), "older than bundled ignored")
	assert_eq(d.source_name(), "bundled")
	assert_true(d.accept(_doc(b + 4)), "valid")
	assert_eq(d.source_name(), "remote")
	assert_eq(d.version(), b + 4)
	assert_false(d.accept(_doc(b + 3)), "older version ignored")
	assert_eq(d.version(), b + 4)
	assert_true(d.accept(_doc(b + 4)), "same version taken")
	assert_true(d.accept(_doc(b + 7)))
	assert_eq(d.version(), b + 7)


func test_cache_is_used_when_not_older_than_bundled() -> void:
	_clean()
	var f := FileAccess.open(CACHE, FileAccess.WRITE)
	var b: int = Dict.bundled(false).version()
	f.store_string(JSON.stringify(_doc(b + 2)))
	f.close()
	var d: RefCounted = Dict.bundled(true, CACHE)
	assert_eq(d.source_name(), "cache")
	assert_eq(d.version(), b + 2)
	_clean()
	var o := FileAccess.open(CACHE, FileAccess.WRITE)
	o.store_string(JSON.stringify(_doc(b - 1)))
	o.close()
	assert_eq(Dict.bundled(true, CACHE).source_name(), "bundled", "older cache ignored")
	_clean()
	var g := FileAccess.open(CACHE, FileAccess.WRITE)
	g.store_string("{broken")
	g.close()
	var e: RefCounted = Dict.bundled(true, CACHE)
	assert_eq(e.source_name(), "bundled", "bad cache keeps bundled")
	_clean()
	assert_eq(Dict.bundled(true, CACHE).source_name(), "bundled", "no cache keeps bundled")


func test_start_remote_is_off_without_an_address() -> void:
	var d: RefCounted = Dict.bundled(false)
	assert_eq(Dict.REMOTE_URL, "")
	assert_false(d.start_remote(tree.root), "no URL, no fetch")


func test_main_uses_the_dictionary_it_is_given() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	var doc := _doc(1)
	doc["characters"] = []
	main.dictionary = Dict.fake(doc)
	tree.root.add_child(main)
	assert_eq(main.levels.size(), 1)
	assert_eq(main.act, "act1_low_orbit")
	main.free()

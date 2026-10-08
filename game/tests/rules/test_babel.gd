extends "res://tests/test_case.gd"

const Babel := preload("res://rules/babel.gd")
const GameData := preload("res://rules/game_data.gd")
const LetterPool := preload("res://rules/letter_pool.gd")

var _content: Dictionary = GameData.load_content()
var _tun: Dictionary = GameData.load_tunables()


func _words_of(act: String, n: int, rng: RandomNumberGenerator) -> PackedStringArray:
	var all: Array = _content["acts"][act]["words"]
	var out := PackedStringArray()
	for _i in n:
		out.append(all[rng.randi_range(0, all.size() - 1)])
	return out


func _pool_of(ws: PackedStringArray) -> Dictionary:
	return LetterPool.count("".join(ws))


func test_empty_pool_composes_nothing() -> void:
	assert_eq(Babel.compose({}, PackedStringArray(), _content, 4).size(), 0)


func test_lines_use_only_pool_letters_with_multiplicity() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var acts: Array = _content["acts"].keys()
	var min_letters := int(_tun["babel.minLineLetters"])
	var total_lines := 0
	for i in 200:
		var ws := _words_of(acts[i % acts.size()], 1 + i % 4, rng)
		var pool := _pool_of(ws)
		var lines := Babel.compose(pool, ws, _content, min_letters, rng)
		var seen := {}
		for l: Dictionary in lines:
			total_lines += 1
			var text: String = l["text"]
			assert_true(LetterPool.fits(text, pool), "pool %s line %s" % [ws, text])
			assert_true(LetterPool.count(text).values().reduce(func(a: int, b: int) -> int: return a + b, 0) >= min_letters, "min letters: " + text)
			assert_false(seen.has(text), "duplicate line " + text)
			seen[text] = true
			var toks := PackedStringArray()
			for tok in text.to_lower().split(" "):
				toks.append(tok.strip_edges().rstrip(".,?!"))
			var uniq := {}
			for tok in toks:
				uniq[tok] = true
			assert_eq(uniq.size(), toks.size(), "duplicate word in " + text)
	assert_true(total_lines > 200, "composer should find lines for most pools (%d)" % total_lines)


func test_compose_without_rng_is_deterministic() -> void:
	var ws := PackedStringArray(["stone", "water", "light"])
	var a := Babel.compose(_pool_of(ws), ws, _content, 4)
	var b := Babel.compose(_pool_of(ws), ws, _content, 4)
	assert_true(a.size() > 0)
	assert_eq(a, b)


func test_min_letters_filters_short_lines() -> void:
	var ws := PackedStringArray(["stone", "water"])
	for l: Dictionary in Babel.compose(_pool_of(ws), ws, _content, 9):
		assert_true(String(l["text"]).replace(" ", "").length() >= 9, l["text"])


func test_pick_never_repeats_a_shown_line() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var ws := PackedStringArray(["silence", "listen", "stone", "water"])
	var lines := Babel.compose(_pool_of(ws), ws, _content, 4, rng)
	assert_true(lines.size() > 3)
	var shown := {}
	var picked := 0
	for _i in lines.size() + 3:
		var text := Babel.pick(lines, shown, rng)
		if text == "":
			break
		assert_false(shown.has(text), "repeat: " + text)
		shown[text] = true
		picked += 1
	assert_eq(picked, lines.size(), "every line is offered once, then pick returns empty")
	assert_eq(Babel.pick(lines, shown, rng), "")

extends RefCounted
## Babel's composer, ported from the toy's JS composer (which mirrors
## tools/astrolex_tools/babel/compose.py). Lines use only letters in the pool, with multiplicity.
## Pure GDScript: no Node, no wall clock; randomness comes from a seeded RandomNumberGenerator.
##
## Differences from the Python reference (listed in the WP report): fills are sampled (40 tries
## per template, as the toy does) instead of enumerated up to a cap, and there is no blocklist
## pass, because content.json does not carry data/words/blocklist.txt.

const LetterPool := preload("res://rules/letter_pool.gd")

const TRIES_PER_TEMPLATE := 40
## The toy's preference order and the chance each family is taken when it has candidates.
const PREFERENCE: Array[String] = ["signature", "not_that", "you_i", "is", "or", "then", "no", "so", "who", "still", "adj_noun", "theme"]
const SIGNATURE_CHANCE := 0.9
const OTHER_CHANCE := 0.55
const FALLBACK_SEED := 1

static var _prepared_src: Dictionary = {}
static var _prepared: Dictionary = {}


## Lines buildable from `pool` ({letter: count}); each is {text, id}. `targets` are the
## words restored so far. With rng == null a fixed-seed generator is used, so the result
## is still a pure function of the arguments.
static func compose(pool: Dictionary, targets: PackedStringArray, content: Dictionary, min_letters: int, rng: RandomNumberGenerator = null) -> Array:
	var prep := _prepare(content)
	var r := rng
	if r == null:
		r = RandomNumberGenerator.new()
		r.seed = FALLBACK_SEED
	var lines: Array = []
	var seen := {}
	for tpl: Dictionary in prep["templates"]:
		var literal_count: Dictionary = tpl["literal_count"]
		if not _fits_counts(literal_count, pool):
			continue
		var remaining := pool.duplicate()
		for k: String in literal_count:
			remaining[k] = int(remaining.get(k, 0)) - int(literal_count[k])
		var parts: Array = tpl["parts"]
		var options: Array = []
		var ok := true
		for p: Dictionary in parts:
			if p["slot"]:
				var cands := _slot_candidates(p["core"], remaining, targets, prep, content)
				if cands.is_empty():
					ok = false
					break
				options.append(cands)
		if not ok:
			continue
		for _try in TRIES_PER_TEMPLATE:
			var ws: PackedStringArray = []
			var oi := 0
			for p: Dictionary in parts:
				if p["slot"]:
					var cands: Array = options[oi]
					ws.append(cands[r.randi_range(0, cands.size() - 1)])
					oi += 1
				else:
					ws.append(String(p["core"]).to_lower())
			if _has_duplicates(ws):
				continue
			if not LetterPool.fits("".join(ws), pool):
				continue
			if "".join(ws).length() < min_letters:
				continue
			var shown_words: PackedStringArray = []
			for i in ws.size():
				shown_words.append(ws[i].to_upper() + String(parts[i]["punct"]))
			var text := " ".join(shown_words)
			if not seen.has(text):
				seen[text] = true
				lines.append({"text": text, "id": tpl["id"]})
	return lines


## One line from `lines` whose text is not in `shown`, or "" if none. Does not modify `shown`;
## the caller records what it displays.
static func pick(lines: Array, shown: Dictionary, rng: RandomNumberGenerator) -> String:
	var fresh: Array = []
	for l: Dictionary in lines:
		if not shown.has(l["text"]):
			fresh.append(l)
	if fresh.is_empty():
		return ""
	for id in PREFERENCE:
		var cands: Array = fresh.filter(func(l: Dictionary) -> bool: return l["id"] == id)
		var chance := SIGNATURE_CHANCE if id == "signature" else OTHER_CHANCE
		if not cands.is_empty() and rng.randf() < chance:
			return cands[rng.randi_range(0, cands.size() - 1)]["text"]
	return fresh[rng.randi_range(0, fresh.size() - 1)]["text"]


static func _has_duplicates(ws: PackedStringArray) -> bool:
	var seen := {}
	for w in ws:
		if seen.has(w):
			return true
		seen[w] = true
	return false


static func _fits_counts(need: Dictionary, pool: Dictionary) -> bool:
	for k: String in need:
		if int(need[k]) > int(pool.get(k, 0)):
			return false
	return true


static func _slot_candidates(slot_token: String, pool: Dictionary, targets: PackedStringArray, prep: Dictionary, content: Dictionary) -> Array:
	var slot := slot_token.substr(1, slot_token.length() - 2)
	var out: Array = []
	if slot == "T":
		for t in targets:
			if LetterPool.fits(t, pool):
				out.append(t)
	elif slot == "ANAGRAM_T":
		var anagrams: Dictionary = content.get("anagrams", {})
		for t in targets:
			for a: String in anagrams.get(t, []):
				if LetterPool.fits(a, pool):
					out.append(a)
	else:
		var theme: Dictionary = prep["theme"]
		for l: Dictionary in prep["lex"]:
			if not _fits_counts(l["c"], pool):
				continue
			if slot == "THEME":
				if theme.has(l["w"]):
					out.append(l["w"])
			elif slot == "W" or l["pos"] == slot:
				out.append(l["w"])
	return out


## Parsed templates and counted lexicon, cached per content dictionary (by reference).
static func _prepare(content: Dictionary) -> Dictionary:
	if not _prepared.is_empty() and is_same(content, _prepared_src):
		return _prepared
	var rx := RegEx.new()
	rx.compile("^(\\{[A-Z_]+\\}|[A-Za-z']+)([.,?!]*)$")
	var templates: Array = []
	for tp: Dictionary in content.get("templates", []):
		var parts: Array = []
		var literals := ""
		for tok: String in String(tp["pattern"]).split(" "):
			var m := rx.search(tok)
			if m == null:
				push_error("babel: bad template token '%s' in %s" % [tok, tp["id"]])
				continue
			var core := m.get_string(1)
			var slot := core.begins_with("{")
			if not slot:
				literals += core.to_lower()
			parts.append({"core": core, "punct": m.get_string(2), "slot": slot})
		templates.append({"id": tp["id"], "parts": parts, "literal_count": LetterPool.count(literals)})
	var lex: Array = []
	for entry: Array in content.get("lexicon", []):
		lex.append({"w": entry[0], "pos": entry[1], "c": LetterPool.count(entry[0])})
	var theme := {}
	for w: String in content.get("theme", []):
		theme[w] = true
	_prepared = {"templates": templates, "lex": lex, "theme": theme}
	_prepared_src = content
	return _prepared

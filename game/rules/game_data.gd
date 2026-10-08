extends RefCounted
## Loads the generated game data (game/data/*.json, written by
## python -m astrolex_tools.export_game_data). Never edit those files by hand.
## Pure GDScript: no Node, no scene tree (plan §3.5 rule 1).

const TUNABLES_PATH := "res://data/tunables.json"
const CONTENT_PATH := "res://data/content.json"


## Flat dictionary keyed like "oxygen.max" (numbers arrive as floats).
static func load_tunables() -> Dictionary:
	return _load(TUNABLES_PATH)


## {acts, lexicon, theme, templates, anagrams}.
static func load_content() -> Dictionary:
	return _load(CONTENT_PATH)


static func _load(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("game_data: cannot open %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("game_data: %s is not a JSON object" % path)
		return {}
	var data: Dictionary = parsed
	data.erase("_generated")
	return data

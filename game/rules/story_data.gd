extends RefCounted
## Codex notes and Tomas's messages (WP-F.5), read from the generated content.json. Pure GDScript.
## Also the inbox rules: which act messages are unlocked and unread, and name substitution.

const GameData := preload("res://rules/game_data.gd")
static var _cache: Dictionary = {}


static func _content() -> Dictionary:
	if _cache.is_empty():
		_cache = GameData.load_content()
	return _cache


## {level id: {word, text}} for all 48 codex notes.
static func codex() -> Dictionary:
	var out: Dictionary = {}
	for e: Dictionary in _content().get("codex", []):
		out[str(e["level"])] = e
	return out


## Tomas's messages, oldest first: the prologue entry, then one per act.
static func tomas() -> Array:
	return _content().get("tomas", [])


## Acts finished in order (Act I, then II ...). `dictionary` is the dictionary service.
static func completed_acts(save: RefCounted, dictionary: RefCounted) -> int:
	var n := 0
	for a: String in dictionary.act_order():
		if save.act_complete(a, dictionary.levels(a).size()):
			n += 1
		else:
			break
	return n


## Full messages not opened yet.
static func unread(save: RefCounted, dictionary: RefCounted) -> int:
	return maxi(completed_acts(save, dictionary) - save.inbox_read(), 0)


## BBCode for the full text with each `fills` word in `colour`, found left to right.
## `{name}` becomes the Catcher's name (or "Catcher").
static func filled_bbcode(msg: Dictionary, catcher: String, colour: String) -> String:
	var who := catcher if catcher != "" else "Catcher"
	var full := str(msg.get("text_full", "")).replace("{name}", who)
	var out := ""
	var cursor := 0
	for f: Variant in msg.get("fills", []):
		var w := str(f).replace("{name}", who)
		var at := full.find(w, cursor)
		if at < 0:
			continue
		out += full.substr(cursor, at - cursor).replace("[", "[lb]") + "[color=%s]%s[/color]" % [colour, w]
		cursor = at + w.length()
	return out + full.substr(cursor).replace("[", "[lb]")

extends RefCounted
## The Catcher's name (WP-F.2): 3 to 8 letters A-Z, shown upper-case. It is the last word of 4-12.

const MIN_LEN := 3
const MAX_LEN := 8


## Letters A-Z only, upper-cased, cut to MAX_LEN. Everything else is dropped.
static func clean(raw: String) -> String:
	var out := ""
	for ch in raw.to_upper():
		if ch >= "A" and ch <= "Z":
			out += ch
	return out.substr(0, MAX_LEN)


static func long_enough(name: String) -> bool:
	return name.length() >= MIN_LEN


## True when the name is in the exported blocklist (content["blocklist"], lower-case tokens).
static func blocked(name: String, blocklist: Array) -> bool:
	return blocklist.has(name.to_lower())


## "ADA" -> "Ada", for running text.
static func display(name: String) -> String:
	return name.substr(0, 1).to_upper() + name.substr(1).to_lower()

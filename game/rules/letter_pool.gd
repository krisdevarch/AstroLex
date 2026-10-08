extends RefCounted
## Letter multisets, the rule Babel and the spawner share. Mirrors count() and fits() in
## tools/astrolex_tools/babel/compose.py; the conformance vectors (WP-3.1) keep them in step.
## Pure GDScript: no Node, no scene tree (plan §3.5 rule 1).


static func count(word: String) -> Dictionary:
	var counts := {}
	for ch in word.to_lower():
		if ch >= "a" and ch <= "z":
			counts[ch] = counts.get(ch, 0) + 1
	return counts


## True when every letter of `word` is available in `pool`, respecting multiplicity.
static func fits(word: String, pool: Dictionary) -> bool:
	var need := count(word)
	for ch in need:
		if need[ch] > pool.get(ch, 0):
			return false
	return true

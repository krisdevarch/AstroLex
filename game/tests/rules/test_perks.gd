extends "res://tests/test_case.gd"
## WP-F.27: every Catcher's perk changes the round it says it changes.

const Round := preload("res://rules/round.gd")
const GameData := preload("res://rules/game_data.gd")

var _tun: Dictionary = GameData.load_tunables()
var _content: Dictionary = GameData.load_content()


func _mod(id: String) -> Dictionary:
	for c: Dictionary in _content["characters"]:
		if str(c["id"]) == id:
			return c["mod"]
	return {}


func _decoys(r: Round) -> int:
	var n := 0
	for t in r.tiles:
		if t.plane < 2 and t.alive and t.decoy:
			n += 1
	return n


func _easy() -> Dictionary:
	for d: Dictionary in _content["difficulty"]["levels"]:
		if str(d["id"]) == "easy":
			return d["mod"]
	return {}


## Pip wants one decoy fewer in every level of every act, on Normal and on Easy. Where the field
## can place every decoy it wants (all of Act I), Pip also starts with exactly one fewer.
func test_pip_wants_one_fewer_decoy_everywhere() -> void:
	for act: String in _content["levels"]:
		for lv: Dictionary in _content["levels"][act]:
			for base: Array in [[], [_easy()]]:
				var plain := Round.create_level(_tun, _content, act, lv, base)
				var pip := Round.create_level(_tun, _content, act, lv, base + [_mod("pip")])
				assert_eq(pip._letters_target, plain._letters_target - 1, "%s target" % lv["id"])
				assert_true(_decoys(pip) <= _decoys(plain), "%s never more decoys" % lv["id"])
	for lv: Dictionary in _content["levels"]["act1_low_orbit"]:
		var plain := Round.create_level(_tun, _content, "act1_low_orbit", lv)
		var pip := Round.create_level(_tun, _content, "act1_low_orbit", lv, [_mod("pip")])
		assert_eq(_decoys(pip), _decoys(plain) - 1, "level %s" % lv["id"])


func test_decoy_bonus_never_goes_below_zero() -> void:
	var lv: Dictionary = _content["levels"]["act1_low_orbit"][0]
	var r := Round.create_level(_tun, _content, "act1_low_orbit", lv, [{"set": {"spawner.decoyBonus": -5, "spawner.decoyRatio": 0, "spawner.decoys": 0}}])
	assert_eq(_decoys(r), 0)

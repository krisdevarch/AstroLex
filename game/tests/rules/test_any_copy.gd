extends "res://tests/test_case.gd"
## WP-F.31 (owner, 6 Nov 2026): "if there are two A for example, it should accept every A that i can
## tap on. we should not make them different color." Every copy of a letter the words still need is
## a right catch, in every shipped level, and no level makes letters look different by role.

const Round := preload("res://rules/round.gd")
const GameData := preload("res://rules/game_data.gd")

const DT := 1.0 / 60.0

var _tun: Dictionary = GameData.load_tunables()
var _content: Dictionary = GameData.load_content()


func _open(r: Round, ch: String) -> bool:
	for s in r.active + r.preview:
		if s["ch"] == ch and not s["filled"]:
			return true
	return false


## Taps a random catchable letter the words still need, whichever copy it is, until the round ends.
func _play_any_copy(r: Round, rng: RandomNumberGenerator, max_secs: float) -> Dictionary:
	var out := {"catch": 0, "wrong": 0, "counterfeit": 0, "jam": 0, "marked": 0}
	while r.state == "play" and float(r.stats["secs"]) < max_secs:
		if r.jammed:
			out["jam"] += 1
		if r.shot.is_empty():
			var picks: Array = []
			for t in r.tiles:
				if t.plane < 2 and t.alive and t.carried_by < 0 and t.landing <= 0.0 and t.shield_t <= 0.0 and _open(r, t.ch):
					picks.append(t)
			if not picks.is_empty():
				var t = picks[rng.randi_range(0, picks.size() - 1)]
				if t.kind == "counterfeit":
					out["marked"] += 1
				t.vel = Vector2.ZERO
				r.fire(t.id)
		r.step(DT)
		for e in r.drain_events():
			if out.has(e["type"]):
				out[e["type"]] += 1
	return out


func test_every_copy_of_a_needed_letter_is_accepted_in_every_level() -> void:
	var levels := 0
	var catches := 0
	for act: String in _content["levels"]:
		for lv: Dictionary in _content["levels"][act]:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(str(lv.get("id", "")))
			var r := Round.create_level(_tun, _content, act, lv, [{"set": {"burst.seconds": 200}}])
			var got := _play_any_copy(r, rng, 120.0)
			var id := str(lv.get("id", ""))
			assert_eq(got["counterfeit"], 0, "level %s: a needed letter was refused as forged" % id)
			assert_eq(got["wrong"], 0, "level %s: a needed letter was refused as wrong" % id)
			assert_eq(got["marked"], 0, "level %s: a forged copy was on the field" % id)
			assert_eq(got["jam"], 0, "level %s: the colour jam came on" % id)
			catches += int(got["catch"])
			levels += 1
	assert_true(levels >= 48, "every level checked: %d" % levels)
	assert_true(catches > levels * 4, "the bot caught letters: %d" % catches)


func test_two_copies_of_a_letter_both_fill_its_two_slots() -> void:
	var lv := {"id": "aa", "seed": 3, "words": ["banana", "lava"], "tuning": {"burst.seconds": 200}}
	var r := Round.create_level(_tun, _content, "act2_nebula", lv)
	r.step(DT)
	var a_slots := 0
	for s in r.active:
		if s["ch"] == "a":
			a_slots += 1
	var filled := 0
	var guard := 0
	while filled < a_slots and guard < 4000:
		guard += 1
		if r.shot.is_empty():
			for t in r.tiles:
				if t.ch == "a" and t.plane < 2 and t.alive and t.carried_by < 0 and t.landing <= 0.0 and t.shield_t <= 0.0:
					t.vel = Vector2.ZERO
					r.fire(t.id)
					break
		r.step(DT)
		for e in r.drain_events():
			assert_true(e["type"] != "wrong" and e["type"] != "counterfeit", "an A while an A slot is open is never wrong")
			if e["type"] == "catch" and e["ch"] == "a" and e["where"] == "active":
				filled += 1
	assert_eq(filled, a_slots, "every A slot of BANANA filled by whichever A was tapped")

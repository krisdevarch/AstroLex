extends "res://tests/test_case.gd"
## WP-F.27: the Catcher speaks in the picked suit's voice, Babel's new comms lines, VANTA's time on
## the end card.

const Main := preload("res://scenes/main.gd")
const LevelCard := preload("res://scenes/level_card.gd")
const GameData := preload("res://rules/game_data.gd")

var _content: Dictionary = GameData.load_content()


func _char(id: String) -> Dictionary:
	for c: Dictionary in _content["characters"]:
		if str(c["id"]) == id:
			return c
	return {}


func _catcher_comms() -> Array:
	var out: Array = []
	for act: String in _content["levels"]:
		for lv: Dictionary in _content["levels"][act]:
			for key in ["commsBefore", "commsAfter"]:
				for m: Dictionary in lv[key]:
					if str(m["who"]) == "catcher":
						out.append([lv["id"], m])
	return out


func test_the_catcher_speaks_four_times_with_a_line_per_suit() -> void:
	var found := _catcher_comms()
	var ids: Array = []
	for f in found:
		ids.append(f[0])
		for suit in ["wren", "juno", "ash", "pip"]:
			assert_true(str((f[1] as Dictionary)["lines"].get(suit, "")) != "", "%s has a %s line" % [f[0], suit])
	assert_eq(ids, ["1-01", "2-12", "3-08", "4-12"])


func test_catcher_comms_use_the_suit_line_colour_and_name() -> void:
	var m := {"who": "catcher", "text": "Ready.", "lines": {"wren": "Already there.", "juno": "Aye. Show me the haul.", "ash": "Shh. Ready.", "pip": "Ooh. Yes. Ready."}}
	var crew := {"who": "rhee", "text": "Ready?"}
	var out: Array = Main.catcher_comms([crew, m], _char("juno"), "ADA")
	assert_eq(out[0], crew, "crew lines pass through")
	assert_eq(out[1]["text"], "Aye. Show me the haul.")
	assert_eq(out[1]["suit"], "juno")
	assert_eq(out[1]["name"], "Ada")
	assert_eq(Color(str(out[1]["colour"])), Color("f2b544"))
	var nameless: Array = Main.catcher_comms([m], _char("ash"), "")
	assert_eq(nameless[0]["name"], "Ash", "the suit's name when the player has none")
	var no_suit: Array = Main.catcher_comms([m], {}, "")
	assert_eq(no_suit[0]["text"], "Ready.", "the plain line without a suit")


func test_story_strip_shows_the_catcher_bubble_in_suit_colour() -> void:
	var c: Control = load("res://scenes/story_strip.gd").new()
	c.messages = Main.catcher_comms([{"who": "catcher", "text": "Ready.", "lines": {"wren": "Already there.", "juno": "Aye.", "ash": "Shh.", "pip": "Ooh."}}], _char("wren"), "KIT")
	c.size = Vector2(1080, 1000)
	tree.root.add_child(c)
	var name_label := c.find_child("Speaker", true, false) as Label
	assert_eq(name_label.text, "Kit")
	assert_eq(name_label.get_theme_color("font_color"), Color("4fd8eb"))
	assert_eq(str(c.find_child("Avatar", true, false).get("who")), "wren", "the suit's portrait")
	c.free()


func test_babel_has_comms_lines_in_act_one_and_act_four() -> void:
	var said := {}
	for act: String in _content["levels"]:
		for lv: Dictionary in _content["levels"][act]:
			for m: Dictionary in lv["commsAfter"]:
				if str(m["who"]) == "babel":
					said[lv["id"]] = m["text"]
	assert_eq(said.get("1-12", ""), "BRAVE TRICK.")
	assert_eq(said.get("4-07", ""), "SPEAK. I REPLY.")
	assert_eq(said.get("4-11", ""), "ONE QUESTION.")


func test_vanta_time_shows_after_a_win_only() -> void:
	assert_eq(LevelCard.vanta_text({"won": true, "vanta": 38.0, "secs": 31.2}), "VANTA 38 s   ·   You 32 s   ·   Beaten!")
	assert_eq(LevelCard.vanta_text({"won": true, "vanta": 30.0, "secs": 41.0}), "VANTA 30 s   ·   You 41 s   ·   Keep up.")
	assert_eq(LevelCard.vanta_text({"won": false, "vanta": 30.0, "secs": 12.0}), "")
	assert_eq(LevelCard.vanta_text({"won": true, "secs": 12.0}), "")
	var card: Control = LevelCard.new()
	card.summary = {"won": true, "stars": 2, "score": 100, "time_left": 10.0, "vanta": 38.0, "secs": 30.0}
	card.reduced_motion = true
	tree.root.add_child(card)
	var vl := card.find_child("VantaStat", true, false) as Label
	assert_true(vl != null and vl.text.ends_with("Beaten!"))
	var next := card.find_child("NextButton", true, false) as Control
	assert_true(next.position.y >= 392.0 + 52.0, "the buttons move down to make room")
	card.free()


func test_vanta_posts_times_in_act_two() -> void:
	var times := {}
	for lv: Dictionary in _content["levels"]["act2_nebula"]:
		if lv.has("vanta"):
			times[lv["id"]] = int(lv["vanta"])
	assert_eq(times, {"2-02": 38, "2-08": 36, "2-12": 30})

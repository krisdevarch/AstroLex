extends "res://tests/test_case.gd"
## WP-3.N game feel: placeholder sounds, the combo pop, the restored-word banner, the shake.

const FieldScene: PackedScene = preload("res://scenes/field.tscn")
const Sfx := preload("res://scenes/sfx.gd")
const GameData := preload("res://rules/game_data.gd")


func _make_field(autoplay: bool) -> Node2D:
	var f: Node2D = FieldScene.instantiate()
	f.autoplay = autoplay
	tree.root.add_child(f)
	f.begin(1, 12345)
	f.skip_intro()
	return f


func test_sounds_are_synthesised_and_catch_notes_climb_the_scale() -> void:
	var s: Sfx = Sfx.new()
	tree.root.add_child(s)
	s.catch_note(0)
	s.catch_note(3)
	s.restore()
	s.wrong()
	s.heartbeat()
	assert_eq(s.played, ["catch0", "catch3", "restore", "wrong", "heartbeat"] as Array[String], "each call plays its sound")
	var w: AudioStreamWAV = s._cache["catch0"]
	assert_true(w.data.size() > 1000, "a real buffer")
	assert_true(Sfx.SCALE[3] > Sfx.SCALE[0], "later letters sound higher")
	s.free()


func test_a_round_plays_a_note_per_catch_and_a_chord_per_word() -> void:
	var f := _make_field(true)
	var steps := 0
	while f.game_round.state == "play" and steps < 300 * 60:
		f.advance(1.0 / 60.0)
		steps += 1
	var played: Array[String] = f.sfx.played
	var notes := played.filter(func(k: String) -> bool: return k.begins_with("catch")).size()
	assert_true(notes >= 3, "catch notes play (%d)" % notes)
	assert_true(played.has("fire"), "the tether zip plays")
	assert_true(played.has("restore"), "a restored word plays its chord")
	f.free()


func test_a_restored_word_shows_its_banner_and_shakes_the_field() -> void:
	var f := _make_field(false)
	f._celebrate("bread")
	var banner := f.find_child("WordBanner", true, false) as Label
	f.advance(1.0 / 60.0)
	assert_eq(banner.text, "BREAD!", "the word, shouted")
	assert_true(banner.visible, "the banner shows")
	assert_true(f._world.offset.length() > 0.5, "the field shakes")
	for _i in 120:
		f.advance(1.0 / 60.0)
	assert_false(banner.visible, "the banner goes after fx.bannerSec")
	assert_eq(f._world.offset, Vector2.ZERO, "the field settles")
	f.free()


func test_reduced_motion_keeps_the_field_still() -> void:
	var f := _make_field(false)
	f.settings.reduced_motion = true
	f._celebrate("cup")
	f.advance(1.0 / 60.0)
	assert_eq(f._world.offset, Vector2.ZERO, "no shake under reduced motion")
	f.free()


func test_a_combo_pops_up_where_the_letter_was_caught() -> void:
	var f := _make_field(false)
	f._combo_pop(Vector2(400, 700), 1.3)
	var pop := f.find_child("ComboPop", true, false) as Label
	assert_true(pop != null, "a pop appears")
	assert_eq(pop.text, "×1.3", "it shows the combo")
	for _i in 60:
		f.advance(1.0 / 60.0)
	assert_true(not is_instance_valid(pop) or pop.is_queued_for_deletion(), "and floats away")
	var tun := GameData.load_tunables()
	f._combo_pop(Vector2(400, 700), float(tun["combo.max"]))
	var top: Label = f._pops[f._pops.size() - 1][0]
	assert_true(top.text.ends_with("MAX"), "the top combo says MAX")
	f.free()


func test_the_heartbeat_sounds_in_the_last_seconds() -> void:
	var f := _make_field(false)
	f.game_round.time_left = 3.5
	f.advance(1.0 / 60.0)
	assert_true(f.sfx.played.has("heartbeat"), "a heartbeat when the clock is low")
	f.free()

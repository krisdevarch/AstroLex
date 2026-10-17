extends "res://tests/test_case.gd"
## WP-F.8: synthesised music beds, cross-fade, duck, leitmotif stings and the audio sliders.

const Music := preload("res://scenes/music.gd")
const Sfx := preload("res://scenes/sfx.gd")
const AppSettings := preload("res://scenes/app_settings.gd")
const SettingsScreen := preload("res://scenes/settings_screen.gd")


func _music() -> Music:
	var m: Music = Music.new()
	tree.root.add_child(m)
	return m


func test_a_bed_exists_for_every_act_and_the_menu() -> void:
	var m := _music()
	var t0 := Time.get_ticks_msec()
	var keys: Array = Music.ACTS.duplicate()
	keys.append(Music.MENU)
	for k: String in keys:
		var w := m.bed(k)
		assert_true(w.data.size() >= 2 * 8 * Music.RATE, k + " is at least 8 s")
		assert_true(w.data.size() <= 2 * 16 * Music.RATE, k + " is at most 16 s")
		assert_eq(w.loop_mode, AudioStreamWAV.LOOP_FORWARD, k + " loops")
	print("music: 5 beds rendered in %d ms" % (Time.get_ticks_msec() - t0))
	assert_true(m.bed("act1_low_orbit") != m.bed("act4_core"), "the beds differ")
	m.free()


func test_play_sets_the_stream_and_crossfades() -> void:
	var m := _music()
	m.play("act1_low_orbit")
	assert_eq(m.current_key, "act1_low_orbit")
	assert_true(m._front.stream == m.bed("act1_low_orbit"), "front player has the bed")
	m.advance(2.0)
	var first: AudioStreamPlayer = m._front
	m.play("act3_tower")
	assert_true(m._front != first, "the new bed takes the other player")
	assert_true(m._front.stream == m.bed("act3_tower"), "new stream")
	assert_true(first.stream == m.bed("act1_low_orbit"), "old bed still fading out")
	m.advance(0.75)
	assert_true(first.volume_db > Music.SILENT_DB and m._front.volume_db > Music.SILENT_DB, "both audible mid-fade")
	m.advance(1.0)
	assert_false(first.playing, "old bed stops after the fade")
	m.stop()
	assert_eq(m.current_key, "")
	m.free()


func test_duck_lowers_the_music_and_restores_it() -> void:
	var m := _music()
	m.play("act2_nebula")
	m.advance(2.0)
	var loud := m.front_db()
	m.duck(true)
	m.advance(2.0)
	assert_true(m.front_db() < loud - 5.0, "ducked is quieter")
	m.duck(false)
	m.advance(2.0)
	assert_true(absf(m.front_db() - loud) < 0.1, "restored")
	m.free()


func test_motifs_and_stings() -> void:
	var r := Music.motif("rhee")
	var b := Music.motif("babel")
	var rev := r.duplicate()
	rev.reverse()
	assert_eq(b, rev, "Babel is Rhee backward")
	for who in ["rhee", "babel", "ade", "kit", "vanta", "tomas", "catcher"]:
		var n := Music.motif(who).size()
		assert_true(n >= 4 and n <= 6, who + " has 4 to 6 notes")
	var m := _music()
	m.sting("babel")
	m.sting("nobody")
	assert_eq(m.stings, ["babel"] as Array[String], "unknown speakers are ignored")
	m.free()


func test_sliders_persist_and_drive_the_buses() -> void:
	var path := "user://test_music_settings.cfg"
	var s := AppSettings.new()
	assert_eq(s.music_volume, 70, "music default")
	assert_eq(s.sound_volume, 100, "sound default")
	s.music_volume = 35
	s.sound_volume = 0
	s.save_to(path)
	var t := AppSettings.new()
	t.load_from(path)
	assert_eq(t.music_volume, 35)
	assert_eq(t.sound_volume, 0)
	t.apply_audio()
	var mi := AudioServer.get_bus_index("Music")
	var si := AudioServer.get_bus_index("Sfx")
	assert_true(mi >= 0 and si >= 0, "buses exist")
	assert_true(absf(AudioServer.get_bus_volume_db(mi) - linear_to_db(0.35)) < 0.01, "music bus volume")
	assert_true(AudioServer.is_bus_mute(si), "sound 0 mutes the Sfx bus")
	AppSettings.new().apply_audio()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_settings_screen_sliders_save() -> void:
	var sc: Control = SettingsScreen.new()
	sc.save_path = "user://test_music_settings2.cfg"
	tree.root.add_child(sc)
	var sl: HSlider = sc.find_child("Slider", true, false)
	assert_true(sl != null, "slider present")
	sl.value = 20
	assert_eq(sc.settings.music_volume, 20, "Music slider writes the setting")
	var back := AppSettings.new()
	back.load_from(sc.save_path)
	assert_eq(back.music_volume, 20, "and saves it")
	sc.free()
	AppSettings.new().apply_audio()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_music_settings2.cfg"))


func test_sfx_players_use_the_sfx_bus() -> void:
	var s: Sfx = Sfx.new()
	tree.root.add_child(s)
	assert_eq(s._players[0].bus, &"Sfx")
	s.free()

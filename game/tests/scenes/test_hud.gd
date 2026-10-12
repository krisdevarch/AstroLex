extends "res://tests/test_case.gd"
## WP-3.H: the v2 game screen: nodes, portrait, buttons, sound persistence, field vs panel.

const FieldScene: PackedScene = preload("res://scenes/field.tscn")
const AppSettings := preload("res://scenes/app_settings.gd")
const Flow := preload("res://tests/scenes/flow.gd")


func _field(character: String = "", size: Vector2 = Vector2(1080, 1920)) -> Node2D:
	var f: Node2D = FieldScene.instantiate()
	f.print_ready = false
	f.view_size = size
	f.character_id = character
	f.character_name = character.capitalize()
	f.level_counter = "Level 1 / 12"
	f.settings_path = "user://test_hud_settings.cfg"
	tree.root.add_child(f)
	f.begin(1, 4242)
	f.skip_intro()
	return f


func _has(f: Node, n: String) -> bool:
	return f.find_child(n, true, false) != null


func test_hud_nodes_exist_and_portrait_only_with_a_character() -> void:
	var f := _field("wren")
	for n in ["NightPanel", "Portrait", "PortraitBust", "PortraitName", "SlotTray", "ActiveSlots", "PreviewSlots", "ScoreLabel", "ComboLabel", "HintButton", "PauseButton", "SoundButton", "SettingsButton", "TimeBar", "ClockLabel", "LevelCounterChip", "BabelBand"]:
		assert_true(_has(f, n), "node %s exists" % n)
	assert_eq((f.find_child("LevelCounter", true, false) as Label).text, "Level 1 / 12", "counter text")
	assert_eq((f.find_child("PortraitNameLabel", true, false) as Label).text, "WREN", "uppercase name pill")
	f.free()
	var g := _field("")
	assert_true(not _has(g, "Portrait"), "no portrait without a character")
	assert_true(_has(g, "NightPanel"), "panel still there")
	g.free()


func test_bottom_hud_anchors_to_the_real_bottom_on_a_taller_screen() -> void:
	var f := _field("ash", Vector2(1080, 2342))
	var bar := f.find_child("TimeBar", true, false) as Control
	assert_true(bar.position.y > 2342.0 - 100.0 and bar.position.y < 2342.0, "clock bar hugs the bottom")
	var btn := f.find_child("HintButton", true, false) as Control
	assert_true(btn.position.y + btn.size.y < 2342.0 and btn.position.y > 2342.0 - 300.0, "buttons sit above the bar")
	assert_eq(f.panel_top(), 2342.0 - 520.0, "panel top follows the bottom")
	f.free()


func test_hint_button_glows_a_tile_and_costs_time_and_flashes_on_nothing() -> void:
	var f := _field("wren")
	var t0: float = f.game_round.time_left
	Flow.press(f, "HintButton")
	assert_eq(int(f.game_round.stats["hints"]), 1, "hint counted")
	assert_true(f.game_round.time_left < t0, "hint cost time")
	var glowing := 0
	for v in f._views.values():
		if v.glow_left() > 0.0:
			glowing += 1
	assert_eq(glowing, 1, "one tile glows amber")
	# No needed tile catchable: paused round gives -1.
	f.set_paused(true)
	assert_eq(f.request_hint(), -1, "paused: no hint")
	f.set_paused(false)
	f.game_round.state = "lost"
	f.request_hint()
	assert_true(f._hint_flash_t == 0.0, "no flash when the round is over (button ignored)")
	f.game_round.state = "play"
	for t in f.game_round.tiles:
		t.plane = 2
	assert_eq(f.request_hint(), -1, "no catchable tile: -1")
	assert_true(f._hint_flash_t > 0.0, "hint button flashes on -1")
	f.free()


func test_hint_icon_is_first_button_icon() -> void:
	var f := _field("wren")
	assert_eq((f.find_child("HintButton", true, false).get_node("Icon") as Control).get("kind"), "hint", "hint icon")
	f.free()


func test_preview_row_fits_the_tray_for_an_eleven_letter_word() -> void:
	var f := _field("wren")
	var n := 11
	var total: float = f._slot_size("preview", n) * n + 8.0 * (n - 1)
	assert_true(total <= f.SLOT_ROW_W + 0.01, "preview row within tray width (%.0f)" % total)
	f.free()


func test_pause_and_settings_buttons_emit() -> void:
	var f := _field("wren")
	var got := {"pause": 0, "settings": 0}
	f.pause_requested.connect(func() -> void: got["pause"] += 1)
	f.settings_requested.connect(func() -> void: got["settings"] += 1)
	Flow.press(f, "PauseButton")
	Flow.press(f, "SettingsButton")
	assert_eq(got["pause"], 1, "pause_requested")
	assert_eq(got["settings"], 1, "settings_requested")
	f.free()


func test_sound_button_toggles_mutes_and_persists() -> void:
	var path := "user://test_hud_settings.cfg"
	AudioServer.set_bus_mute(0, false)
	var f := _field("wren")
	assert_true(f.settings.sound_on, "sound on by default")
	Flow.press(f, "SoundButton")
	assert_true(not f.settings.sound_on, "toggled off")
	assert_true(AudioServer.is_bus_mute(0), "master bus muted")
	var loaded := AppSettings.new()
	loaded.load_from(path)
	assert_true(not loaded.sound_on, "sound_on persisted")
	Flow.press(f, "SoundButton")
	assert_true(f.settings.sound_on and not AudioServer.is_bus_mute(0), "unmuted")
	f.free()
	AudioServer.set_bus_mute(0, false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_no_tile_is_drawn_under_the_bottom_panel() -> void:
	for size in [Vector2(1080, 1920), Vector2(1080, 2342), Vector2(1179, 2556)]:
		var f := _field("juno", size)
		var worst := -INF
		var frames := 0
		var top: float = f.panel_top()
		var bubble := float(f._tun["glass.bubbleScale"])
		for _i in 600:
			f.advance(1.0 / 60.0)
			if f.game_round.state != "play":
				break
			frames += 1
			for t in f.game_round.tiles:
				if t.alive and t.plane < 2:
					worst = maxf(worst, f.to_screen(t.pos).y + f.radius_px(t) * bubble)
		assert_true(frames >= 60, "sampled %d frames" % frames)
		assert_true(worst < top, "tiles stay above the panel (worst bottom %.0f, panel %.0f)" % [worst, top])
		f.free()

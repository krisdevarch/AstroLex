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
	for n in ["NightPanel", "Console", "Portrait", "PortraitBust", "SlotTray", "Liquid", "ActiveSlots", "PreviewSlots", "ScoreLabel", "ComboLabel", "HintButton", "PauseButton", "SoundButton", "SettingsButton", "TimeBar", "ClockLabel", "LevelCounterChip", "BabelBand"]:
		assert_true(_has(f, n), "node %s exists" % n)
	assert_eq((f.find_child("LevelCounter", true, false) as Label).text, "Level 1 / 12", "counter text")
	assert_true(not _has(f, "PortraitName"), "no name pill under the porthole (target mock)")
	f.free()
	var g := _field("")
	assert_true(not _has(g, "Portrait"), "no portrait without a character")
	assert_true(_has(g, "NightPanel"), "panel still there")
	g.free()


func test_bottom_hud_anchors_to_the_real_bottom_on_a_taller_screen() -> void:
	var f := _field("ash", Vector2(1080, 2342))
	var bar := f.find_child("TimeBar", true, false) as Control
	assert_true(bar.position.y > 2342.0 - 140.0 and bar.position.y < 2342.0, "clock bar hugs the bottom")
	var btn := f.find_child("SettingsButton", true, false) as Control
	assert_true(btn.position.y + btn.size.y < 2342.0 and btn.position.y > 2342.0 - 300.0, "the bottom button hugs the bottom too")
	var hint := f.find_child("HintButton", true, false) as Control
	assert_true(hint.position.y > 2342.0 - 720.0, "the hint bulb stays with the console")
	assert_eq(f.panel_top(), 2342.0 - 530.0, "panel top follows the bottom")
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


func test_preview_row_fits_its_width_for_an_eleven_letter_word() -> void:
	var f := _field("wren")
	var n := 11
	var total: float = f._slot_size("preview", n) * n + f.SLOT_GAP * (n - 1)
	assert_true(total <= f._row_width("preview") + 0.01, "next word's row fits beside Hint (%.0f)" % total)
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


func test_hud_follows_the_target_mock() -> void:
	for size in [Vector2(1080, 1920), Vector2(1179, 2556)]:
		var f := _field("ash", size)
		var right: float = size.x - f.EDGE
		var tray := f.find_child("SlotTray", true, false) as Control
		var hint := f.find_child("HintButton", true, false) as Control
		var gear := f.find_child("SettingsButton", true, false) as Control
		var pause := f.find_child("PauseButton", true, false) as Control
		var sound := f.find_child("SoundButton", true, false) as Control
		var bar := f.find_child("TimeBar", true, false) as Control
		var counter := f.find_child("LevelCounterChip", true, false) as Control
		var chip := f.find_child("LevelChip", true, false) as Control
		var portrait := f.find_child("Portrait", true, false) as Control
		assert_true(absf(counter.position.x + counter.size.x - right) < 0.5, "Level n / N pill on the right margin")
		assert_true(absf(chip.position.x - f.SIDE_PAD) < 0.5, "level name pill on the left margin")
		assert_true(chip.position.x + chip.size.x < counter.position.x, "the two pills do not overlap")
		assert_true(f.find_child("TitleChip", true, false) == null, "no AstroLex chip")
		# The right column: hint bulb, pause, sound, settings, top to bottom, one x.
		for c: Control in [hint, sound, gear]:
			# The mock's bulb sits a hair left of the buttons' centre line.
			var tol := 6.0 if c == hint else 0.5
			assert_true(absf(c.position.x + c.size.x * 0.5 - (pause.position.x + pause.size.x * 0.5)) < tol, "%s in the button column" % c.name)
		assert_true(hint.position.y + hint.size.y <= pause.position.y + 1.0, "hint above pause")
		assert_true(pause.position.y < sound.position.y and sound.position.y < gear.position.y, "pause, sound, settings stacked")
		assert_true(gear.position.x + gear.size.x <= size.x - 10.0, "buttons inside the screen")
		assert_true(tray.position.x + tray.size.x < pause.position.x, "slot screen left of the buttons")
		var p_right: float = portrait.position.x + portrait.size.x * portrait.scale.x
		assert_true(portrait.position.x < tray.position.x and p_right < tray.position.x + 20.0, "porthole left of the slot screen")
		assert_true(bar.position.y > tray.position.y + tray.size.y, "clock bar under the console")
		assert_true(bar.position.x < tray.position.x and bar.position.x + bar.size.x > tray.position.x + tray.size.x - 40.0, "clock bar runs under the console")
		assert_true(bar.position.x + bar.size.x < gear.position.x, "clock bar ends before the buttons")
		# Both words are centred in the slot screen, the next word under the active one.
		for rn in ["ActiveSlots", "PreviewSlots"]:
			var row := f.find_child(rn, true, false) as Control
			if row.get_child_count() == 0:
				continue
			var first := row.get_child(0) as Control
			var last := row.get_child(row.get_child_count() - 1) as Control
			var left_gap: float = first.position.x - tray.position.x
			var right_gap: float = tray.position.x + tray.size.x - (last.position.x + last.size.x)
			assert_true(absf(left_gap - right_gap) < 1.0, "%s centred in the slot screen" % rn)
		var prow := f.find_child("PreviewSlots", true, false) as Control
		var arow := f.find_child("ActiveSlots", true, false) as Control
		if prow.get_child_count() > 0:
			assert_true((prow.get_child(0) as Control).position.y > (arow.get_child(0) as Control).position.y, "next word under the active word")
			assert_true((prow.get_child(0) as Control).position.y + (prow.get_child(0) as Control).size.y < tray.position.y + tray.size.y, "inside the slot screen")
		f.free()


func test_babel_bubble_fits_his_line() -> void:
	var f := _field("wren")
	var band := f.find_child("BabelBand", true, false) as Control
	f.last_babel = "HI."
	f.advance(0.5)
	var short_w: float = band.size.x
	assert_true(band.visible, "bubble shows once Babel speaks")
	f.last_babel = "THE COSMOS IS SILENT WITHOUT WORDS AND YOU WILL NOT FIND THEM"
	f.advance(0.5)
	assert_true(band.size.x > short_w, "a longer line makes a wider bubble")
	assert_true(band.size.x <= f.BAND_MAX_W + 0.5, "never wider than the cap")
	assert_true(band.size.y > f.BAND_LINE_H * 2.0, "a long line wraps to more rows")
	assert_true(band.position.x >= 0.0 and band.position.x + band.size.x <= 1080.0, "on screen")
	f.free()


func test_hud_idles_with_life_and_rests_under_reduced_motion() -> void:
	var f := _field("wren")
	var hint := f.find_child("HintButton", true, false).get_node("Icon") as Control
	var seen := {}
	for _i in 90:
		f.advance(1.0 / 30.0)
		seen[snappedf(hint.rotation, 0.001)] = true
	assert_true(seen.size() > 5, "the hint bulb wobbles")
	assert_true(float(f.find_child("Liquid", true, false).get("t")) > 2.0, "the clock liquid animates")
	f.free()
	var g := _field("wren")
	g.settings.reduced_motion = true
	var icon := g.find_child("HintButton", true, false).get_node("Icon") as Control
	var r0 := icon.rotation
	for _i in 60:
		g.advance(1.0 / 30.0)
	assert_eq(icon.rotation, r0, "no wobble under reduced motion")
	g.free()


func test_backdrop_regains_colour_as_words_are_restored() -> void:
	var f := _field("wren")
	var bg := f.find_child("ActScene", true, false)
	assert_true(bg != null, "act scene backdrop exists")
	var s0: float = bg.saturation()
	assert_true(s0 < 1.0, "starts drained (%.2f)" % s0)
	f.game_round.word_index = f.game_round.words.size() - 1
	f._update_hud()
	assert_true(f.restored_share() > 0.5, "share follows the word index")
	for _i in 120:
		bg._process(1.0 / 30.0)
	assert_true(bg.saturation() > s0 + 0.1, "colour comes back (%.2f)" % bg.saturation())
	var night := f.find_child("NightPanel", true, false)
	assert_true(float(night.get("lit")) > 0.5, "city lights come on")
	f.free()


func test_back_plane_is_quiet_twinkling_stars() -> void:
	var f := _field("wren")
	var back: Array = []
	for t in f.game_round.tiles:
		var v = f._views[t.id]
		assert_eq(v.is_star, t.plane >= 2, "a tile is a star exactly when it is on the back plane")
		if t.plane >= 2:
			back.append(t)
			assert_true(v.body.texture != null, "star art")
			assert_false(v.glyph.visible, "no letter on a star")
			assert_true(v.z_index < 1, "drawn behind the letters")
			assert_true(v.body.scale.x * 128.0 < v.size_px, "smaller than a letter")
		else:
			assert_true(v.glyph.visible, "letters, decoys included, are bubbles with a glyph")
	assert_true(back.size() >= 1, "the field has back stars")
	var t0: Object = back[0]
	var p0: Vector2 = f._views[t0.id].position
	var a0: float = f._views[t0.id].body.self_modulate.a
	var changed := false
	for _i in 60:
		f.advance(1.0 / 30.0)
		changed = changed or absf(f._views[t0.id].body.self_modulate.a - a0) > 0.02
	assert_true(f._views[t0.id].position.distance_to(p0) > 1.0, "stars drift")
	assert_true(changed, "stars twinkle")
	assert_eq(f.tap(f.to_screen(t0.pos)) == t0.id, false, "a back star cannot be tapped")
	f.free()


func test_backdrop_has_quiet_stars_and_shooting_stars() -> void:
	var bg: Node2D = load("res://scenes/act_backdrop.gd").new()
	tree.root.add_child(bg)
	assert_true(bg._dots.size() >= 20, "a field of tiny stars")
	assert_true(bg._sparkles.size() <= 8, "only a few glints, so the sky stays calm")
	var tints := {}
	for sp in bg._sparkles:
		tints[(sp[3] as Color).to_html()] = true
	assert_true(tints.size() >= 3, "sparkles come in a few pale tints")
	var seen := false
	for i in 600:
		bg._process(1.0 / 30.0)
		if bg.shooting():
			seen = true
			break
	assert_true(seen, "a shooting star crosses within 20 s")
	bg.free()
	var calm: Node2D = load("res://scenes/act_backdrop.gd").new()
	calm.reduced_motion = true
	tree.root.add_child(calm)
	for i in 600:
		calm._process(1.0 / 30.0)
	assert_false(calm.shooting(), "no shooting stars under reduced motion")
	calm.free()

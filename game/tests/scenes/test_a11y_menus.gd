extends "res://tests/test_case.gd"
## WP-F.33c: menu tap targets, tooltips, safe-area insets, focus and text contrast.

const Flow := preload("res://tests/scenes/flow.gd")
const Ui := preload("res://scenes/ui.gd")
const SettingsScreen := preload("res://scenes/settings_screen.gd")
const CharacterSelect := preload("res://scenes/character_select.gd")
const DifficultySelect := preload("res://scenes/difficulty_select.gd")
const PauseMenu := preload("res://scenes/pause_menu.gd")

const MIN_TAP := 88.0


static func luminance(c: Color) -> float:
	var ch: Array[float] = []
	for v: float in [c.r, c.g, c.b]:
		ch.append(v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * ch[0] + 0.7152 * ch[1] + 0.0722 * ch[2]


static func contrast(a: Color, b: Color) -> float:
	var la := luminance(a)
	var lb := luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _opaque(c: Color) -> Color:
	return Color(c.r, c.g, c.b, 1.0)


func test_text_colours_meet_wcag_aa() -> void:
	for bg: Color in [Ui.NAVY_DEEP, _opaque(Ui.NAVY)]:
		for fg: Color in [Ui.CREAM, Ui.MUTED, Ui.DIM]:
			assert_true(contrast(fg, bg) >= 4.5, "%s on %s is %.2f" % [fg.to_html(), bg.to_html(), contrast(fg, bg)])
	assert_true(contrast(Ui.BUTTON_INK, Ui.ORANGE) >= 4.5, "ink on orange %.2f" % contrast(Ui.BUTTON_INK, Ui.ORANGE))


func _check_taps(root: Node, what: String) -> void:
	var n := 0
	for node in root.find_children("*", "BaseButton", true, false):
		var b := node as BaseButton
		if not b.is_visible_in_tree():
			continue
		n += 1
		var w := maxf(b.size.x, b.custom_minimum_size.x)
		var h := maxf(b.size.y, b.custom_minimum_size.y)
		assert_true(w >= MIN_TAP and h >= MIN_TAP, "%s: %s is %dx%d" % [what, b.name, int(w), int(h)])
	assert_true(n > 0, "%s has buttons" % what)


func test_tap_targets_are_at_least_88() -> void:
	var save: RefCounted = load("res://services/save.gd").fake()
	save.set_profile("wren", "normal", "ADA")
	var main: Node = Flow.returning(tree, save)
	Flow.press(main, "StartButton")
	var map := main.find_child("LevelMap", true, false)
	assert_true(map != null, "map open")
	_check_taps(map, "map")
	var dict: RefCounted = main.dictionary
	var content: Dictionary = dict.content()
	main.free()

	var s: Control = SettingsScreen.new()
	s.save = save
	s.save_path = "user://test_a11y_settings.cfg"
	tree.root.add_child(s)
	_check_taps(s, "settings")
	s.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_a11y_settings.cfg"))

	var cs: Control = CharacterSelect.new()
	cs.characters = content.get("characters", [])
	cs.can_cancel = true
	tree.root.add_child(cs)
	_check_taps(cs, "character")
	cs.free()

	var ds: Control = DifficultySelect.new()
	ds.options = (content.get("difficulty", {}) as Dictionary).get("levels", [])
	ds.can_cancel = true
	tree.root.add_child(ds)
	_check_taps(ds, "difficulty")
	ds.free()

	var pm: Control = PauseMenu.new()
	tree.root.add_child(pm)
	_check_taps(pm, "pause")
	pm.free()


func test_map_icon_buttons_are_named() -> void:
	var main: Node = Flow.returning(tree)
	Flow.press(main, "StartButton")
	var want := {"BackButton": "Home", "DailyButton": "Daily Signal", "SettingsButton": "Settings", "DifficultyButton": "Difficulty", "CharacterButton": "Catcher", "CodexButton": "Codex", "InboxButton": "Inbox"}
	for k: String in want:
		var b := main.find_child(k, true, false) as Button
		assert_true(b != null, "%s exists" % k)
		if b:
			assert_eq(b.tooltip_text, want[k], "%s tooltip" % k)
			if "accessibility_name" in b:
				assert_eq(str(b.get("accessibility_name")), want[k], "%s accessible name" % k)
	main.free()


func test_safe_insets_floor_the_top() -> void:
	var i := Ui.safe_insets(Vector2(1080, 2338))
	assert_true(float(i["top"]) >= 24.0, "top is at least 24")
	assert_true(float(i["bottom"]) >= 0.0, "bottom is not negative")


func test_settings_header_footer_and_escape() -> void:
	var s: Control = SettingsScreen.new()
	s.save_path = "user://test_a11y_settings2.cfg"
	tree.root.add_child(s)
	var title := s.find_child("SettingsTitle", true, false) as Control
	var done := s.find_child("BackButton", true, false) as Control
	assert_true(title.get_parent() == s, "title is in the fixed header, not the scroll")
	assert_true(done.get_parent() == s, "Done is in the fixed footer, not the scroll")
	assert_true(title.offset_top >= 24.0, "title below the safe top")
	var got := [false]
	s.closed.connect(func() -> void: got[0] = true)
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	s._unhandled_input(ev)
	assert_true(got[0], "Esc closes settings")
	s.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_a11y_settings2.cfg"))

extends "res://tests/test_case.gd"

const AppSettings := preload("res://scenes/app_settings.gd")
const GameFont := preload("res://scenes/game_font.gd")
const Credits := preload("res://scenes/credits.gd")
const Ui := preload("res://scenes/ui.gd")
const PATH := "user://test_f9.cfg"


func test_comfort_settings_round_trip_and_drive_game_font() -> void:
	var a := AppSettings.new()
	assert_false(a.large_text)
	assert_false(a.high_contrast)
	a.large_text = true
	a.high_contrast = true
	a.save_to(PATH)
	var b := AppSettings.new()
	b.load_from(PATH)
	assert_true(b.large_text and b.high_contrast, "restored")
	assert_eq(GameFont.ui_scale, 1.2)
	assert_true(GameFont.high_contrast)
	assert_eq(Ui.text("x", 40).get_theme_font_size("font_size"), 48, "ui text scales by 1.2")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	AppSettings.new().apply_comfort()
	assert_eq(GameFont.ui_scale, 1.0)
	assert_eq(Ui.text("x", 40).get_theme_font_size("font_size"), 40)


func test_high_contrast_thickens_the_tile_halo() -> void:
	var tun: Dictionary = {}
	var content := FileAccess.get_file_as_string("res://data/tunables.json")
	tun = JSON.parse_string(content)
	assert_true(float(tun["tile.glyphOutline"]) > float(tun["tile.glyphOutlineNormal"]) * 2.0)


func test_credits_screen_shows_the_text_and_privacy() -> void:
	var c: Control = Credits.new()
	c.credits_text = "Kris: design"
	tree.root.add_child(c)
	assert_eq((c.find_child("CreditsBody", true, false) as Label).text, "Kris: design")
	assert_true((c.find_child("PrivacyText", true, false) as Label).text.contains("this browser only"))
	assert_true((c.find_child("PrivacyText", true, false) as Label).text.contains("only when you press Send"))
	var got := [false]
	c.closed.connect(func() -> void: got[0] = true)
	(c.find_child("BackButton", true, false) as Button).pressed.emit()
	assert_true(got[0])
	c.queue_free()

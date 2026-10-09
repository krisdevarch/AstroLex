extends "res://tests/test_case.gd"

const AppSettings := preload("res://scenes/app_settings.gd")
const PATH := "user://test_settings.cfg"


func test_settings_round_trip() -> void:
	var a := AppSettings.new()
	assert_eq(a.treatment, "bubble", "default look is bubble (O-22, 9 Oct 2026)")
	assert_false(a.reduced_motion, "motion on by default")
	a.treatment = "glass"
	a.reduced_motion = true
	assert_eq(a.save_to(PATH), OK, "saved")
	var b := AppSettings.new()
	b.load_from(PATH)
	assert_eq(b.treatment, "glass")
	assert_true(b.reduced_motion, "reduced motion restored")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_a_saved_opaque_look_falls_back_to_bubble() -> void:
	for old in ["flat", "tilt", "bevel"]:
		var cf := ConfigFile.new()
		cf.set_value("look", "treatment", old)
		cf.save(PATH)
		var a := AppSettings.new()
		a.load_from(PATH)
		assert_eq(a.treatment, "bubble", "%s is gone, so bubble" % old)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_settings_ignore_an_unknown_treatment() -> void:
	var cf := ConfigFile.new()
	cf.set_value("look", "treatment", "wobble")
	cf.save(PATH)
	var a := AppSettings.new()
	a.load_from(PATH)
	assert_eq(a.treatment, "bubble", "falls back to the default")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_hint_defaults_to_one_and_round_trips() -> void:
	var a := AppSettings.new()
	assert_eq(a.hint, "one", "default hint")
	for h in AppSettings.HINTS:
		a.hint = h
		a.save_to(PATH)
		var b := AppSettings.new()
		b.load_from(PATH)
		assert_eq(b.hint, h, "hint %s survives save" % h)
	var cf := ConfigFile.new()
	cf.set_value("look", AppSettings.HINT_KEY, "bogus")
	cf.save(PATH)
	var c := AppSettings.new()
	c.load_from(PATH)
	assert_eq(c.hint, "one", "unknown hint falls back")
	var old := ConfigFile.new()
	old.set_value("look", "hint", "edges")
	old.set_value("look", "hint_v2", "none")
	old.save(PATH)
	var d := AppSettings.new()
	d.load_from(PATH)
	assert_eq(d.hint, "one", "a hint saved by an older build is ignored")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

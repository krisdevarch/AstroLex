extends "res://tests/test_case.gd"

const AppSettings := preload("res://scenes/app_settings.gd")
const PATH := "user://test_settings.cfg"


func test_settings_round_trip() -> void:
	var a := AppSettings.new()
	assert_eq(a.treatment, "tilt", "default treatment is tilt (O-22)")
	assert_false(a.reduced_motion, "motion on by default")
	a.treatment = "bevel"
	a.reduced_motion = true
	assert_eq(a.save_to(PATH), OK, "saved")
	var b := AppSettings.new()
	b.load_from(PATH)
	assert_eq(b.treatment, "bevel")
	assert_true(b.reduced_motion, "reduced motion restored")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_settings_ignore_an_unknown_treatment() -> void:
	var cf := ConfigFile.new()
	cf.set_value("look", "treatment", "wobble")
	cf.save(PATH)
	var a := AppSettings.new()
	a.load_from(PATH)
	assert_eq(a.treatment, "tilt", "falls back to the default")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_hint_defaults_to_edges_and_round_trips() -> void:
	var a := AppSettings.new()
	assert_eq(a.hint, "edges", "default hint")
	for h in AppSettings.HINTS:
		a.hint = h
		a.save_to(PATH)
		var b := AppSettings.new()
		b.load_from(PATH)
		assert_eq(b.hint, h, "hint %s survives save" % h)
	var cf := ConfigFile.new()
	cf.set_value("look", "hint", "bogus")
	cf.save(PATH)
	var c := AppSettings.new()
	c.load_from(PATH)
	assert_eq(c.hint, "edges", "unknown hint falls back")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

extends "res://tests/test_case.gd"
## Glass tile treatment (O-22 spike): settings, tile view, bench and settings screen.

const AppSettings := preload("res://scenes/app_settings.gd")
const GameData := preload("res://rules/game_data.gd")
const TileViewScene: PackedScene = preload("res://scenes/tile_view.tscn")
const GlassBench := preload("res://scenes/glass_bench.gd")
const FpsMeter := preload("res://scenes/fps_meter.gd")
const PATH := "user://test_glass_settings.cfg"


func test_settings_round_trip_with_glass_and_show_fps() -> void:
	assert_true(AppSettings.TREATMENTS.has("glass"), "glass is a treatment")
	var a := AppSettings.new()
	assert_eq(a.treatment, "tilt", "default stays tilt")
	assert_false(a.show_fps, "fps hidden by default")
	a.treatment = "glass"
	a.show_fps = true
	assert_eq(a.save_to(PATH), OK, "saved")
	var b := AppSettings.new()
	b.load_from(PATH)
	assert_eq(b.treatment, "glass")
	assert_true(b.show_fps, "show_fps restored")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func _glass_view(back: bool = false, look: String = "glass") -> Node2D:
	var tun := GameData.load_tunables()
	var v: Node2D = TileViewScene.instantiate()
	tree.root.add_child(v)
	v.setup("q", 130.0, 1.0, 2 if back else 0, look, false, tun, 0.3)
	if back:
		v.set_back(0.28, 0.7)
	v.place(Vector2(200, 300), 1.0, 0.4)
	return v


func test_tile_view_glass_setup() -> void:
	var v := _glass_view()
	var mat := v.body.material as ShaderMaterial
	assert_true(mat != null and mat.shader.resource_path.ends_with("glass.gdshader"), "body uses the glass shader")
	assert_eq(v.glyph.get_theme_color("font_color"), Color.WHITE, "glyph is white")
	assert_true(v.glyph.get_theme_constant("outline_size") > 0, "glyph has an ink halo")
	assert_eq(v.body.light_mask, 2, "glass is off the lamp")
	assert_true(mat.get_shader_parameter("tilt_deg") != Vector2.ZERO, "glass tile tilts")
	v.flash(0.2)
	v.tick(0.05)
	assert_true(float(mat.get_shader_parameter("flash")) > 0.0, "flash uniform works")
	v.free()


func test_tile_view_bubble_is_round_and_untilted() -> void:
	assert_true(AppSettings.TREATMENTS.has("bubble"), "bubble is a treatment")
	var v := _glass_view(false, "bubble")
	var mat := v.body.material as ShaderMaterial
	assert_true(mat.shader.resource_path.ends_with("glass.gdshader"), "bubble uses the glass shader")
	assert_true(bool(mat.get_shader_parameter("bubble")), "bubble mode on")
	assert_eq(float(mat.get_shader_parameter("corner")), 61.0, "corner = half width, a circle")
	assert_eq(v.current_tilt, Vector2.ZERO, "a bubble does not tilt")
	assert_true(v.body.scale.x > 130.0 / 128.0 * 1.1, "the ball is bigger than a tile")
	assert_eq(v.glyph.get_theme_font_size("font_size"), int(130.0 * 0.62), "the letter keeps its size")
	assert_eq(v.glyph.get_theme_color("font_color"), Color.WHITE, "glyph is white")
	v.free()


func test_back_plane_glass_is_a_glyphless_shard() -> void:
	var v := _glass_view(true)
	assert_false(v.glyph.visible, "no glyph on the back plane")
	assert_eq(v.current_tilt, Vector2.ZERO, "no tilt")
	assert_true(bool((v.body.material as ShaderMaterial).get_shader_parameter("shard")), "shard mode")
	v.free()


func test_bench_builds_tiles_and_cycles() -> void:
	var b: Node = GlassBench.new()
	tree.root.add_child(b)
	assert_eq(b.tile_count(), 20, "20 tiles by default")
	assert_eq(b.treatment, "glass", "glass first")
	assert_true(b.find_child("RunButton", true, false) != null, "run button")
	b.cycle_count()
	assert_eq(b.tile_count(), 30, "cycles to 30")
	b.cycle_look()
	assert_eq(b.treatment, "bubble", "look cycles")
	b._process(1.0 / 60.0)
	b.free()


func test_bench_result_pass_and_below() -> void:
	var good: Array = []
	for i in 600:
		good.append(1.0 / 60.0)
	var r := GlassBench.compute_result(good, "glass", 20)
	assert_true(bool(r["pass"]), "steady 60 fps passes")
	assert_true(str(r["line"]).ends_with("PASS"), "line says PASS")
	var slow: Array = []
	for i in 300:
		slow.append(1.0 / 30.0)
	var r2 := GlassBench.compute_result(slow, "glass", 20)
	assert_false(bool(r2["pass"]), "30 fps fails")
	assert_true(str(r2["line"]).ends_with("BELOW 60"), "line says BELOW 60")
	# Good average but a hitchy tail: p95 over 20 ms fails.
	var hitchy: Array = []
	for i in 100:
		hitchy.append(0.012 if i % 8 != 0 else 0.030)
	assert_false(bool(GlassBench.compute_result(hitchy, "glass", 20)["pass"]), "p95 over 20 ms fails")
	assert_false(bool(GlassBench.compute_result([], "glass", 20)["pass"]), "no frames fails")


func test_fps_meter_line() -> void:
	var f: Array = []
	for i in 60:
		f.append(1.0 / 60.0)
	assert_eq(FpsMeter.format_line(f, 20), "60 fps · p95 17 ms · 20 tiles")


func test_settings_screen_has_five_treatments_fps_and_bench() -> void:
	var s: Control = load("res://scenes/settings_screen.gd").new()
	tree.root.add_child(s)
	for t in AppSettings.TREATMENTS:
		var b := s.find_child("Treatment_%s" % t, true, false) as Button
		assert_true(b != null, "button for %s" % t)
		if b:
			assert_true(b.custom_minimum_size.x <= 1080.0 / 5.0, "fits the row")
	assert_eq(AppSettings.TREATMENTS.size(), 5, "five treatments")
	assert_true(s.find_child("ShowFps", true, false) is CheckButton, "show frame rate toggle")
	var bench := s.find_child("BenchButton", true, false) as Button
	assert_true(bench != null, "bench button")
	var hit := [false]
	s.bench_pressed.connect(func() -> void: hit[0] = true)
	bench.pressed.emit()
	assert_true(hit[0], "bench signal")
	s.free()

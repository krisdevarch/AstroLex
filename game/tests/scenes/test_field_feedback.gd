extends "res://tests/test_case.gd"
## View feedback, leak and treatment checks for the field. Frees happen at end of frame, which
## these synchronous tests never reach, so "freed" means queued for deletion or erased.

const FieldScene: PackedScene = preload("res://scenes/field.tscn")
const AppSettings := preload("res://scenes/app_settings.gd")
const DT := 1.0 / 60.0


func _make(autoplay: bool, seed_value: int = 12345, treatment: String = "tilt", reduced: bool = false) -> Node2D:
	var f: Node2D = FieldScene.instantiate()
	f.autoplay = autoplay
	f.print_ready = false
	f.settings.treatment = treatment
	f.settings.reduced_motion = reduced
	tree.root.add_child(f)
	f.begin("drift", 1, seed_value)
	return f


func _live_views(f: Node2D) -> int:
	var n := 0
	for c in f._tiles_root.get_children():
		if not c.is_queued_for_deletion():
			n += 1
	return n


func _play(f: Node2D, max_steps: int = 300 * 60) -> void:
	var steps := 0
	while f.game_round.state == "play" and steps < max_steps:
		f.advance(DT)
		steps += 1
	for _i in 10:
		f.advance(DT)


func test_wrong_catch_flashes_the_tile_and_shows_the_toast() -> void:
	var f := _make(false)
	var need := {}
	for s in f.game_round.active:
		need[s["ch"]] = true
	for s in f.game_round.preview:
		need[s["ch"]] = true
	var target = null
	for t in f.game_round.tiles:
		if t.alive and t.plane < 2 and not need.has(t.ch):
			target = t
			break
	assert_true(target != null, "an unneeded catchable tile exists")
	if target == null:
		f.free()
		return
	target.vel = Vector2.ZERO  # keep it under the tether so the shot lands
	assert_true(f.game_round.fire(target.id), "fire accepted")
	var view = f._views[target.id]
	assert_eq(f._toast.text, "", "no toast before the catch")
	var steps := 0
	while f.game_round.stats["wrong"] == 0 and steps < 600:
		f.advance(DT)
		steps += 1
	assert_eq(int(f.game_round.stats["wrong"]), 1, "the catch was wrong")
	assert_eq(f._toast.text, "Not in the record", "toast text")
	assert_true(f._toast.modulate.a > 0.0, "toast visible")
	assert_true(view._flash_t > 0.0, "tile view is flashing")
	assert_true(f._views.has(target.id), "wrong tile stays in play")
	f.free()


func test_surplus_dissolve_frees_the_view_within_dissolve_time() -> void:
	var f := _make(false)
	f.advance(DT)
	var ch: String = f.game_round.active[0]["ch"]
	var extra = f.game_round._spawn(ch, false, 0)
	f.advance(DT)  # the spawn event gives the extra copy a view
	assert_true(f._views.has(extra.id), "extra copy has a view")
	f.game_round._trim_surplus()  # the newest copy is the one trimmed
	var dissolved: int = extra.id
	assert_true(f.game_round.find_tile(dissolved) == null, "surplus tile left the round")
	f.advance(DT)
	var v = f._views.get(dissolved)
	assert_true(v != null, "view exists while dissolving")
	if v == null:
		f.free()
		return
	assert_eq(v.anim, "dissolve", "dissolve animation running")
	var frames := int(ceil(float(f._tun["fx.dissolveSec"]) / DT)) + 3
	for _i in frames:
		f.advance(DT)
	assert_false(f._views.has(dissolved), "view dropped from _views")
	assert_true(v.is_queued_for_deletion(), "view node queued for free")
	f.free()


func test_won_round_leaves_no_dead_views_or_pending_state_and_no_leak() -> void:
	var counts: Array[int] = []
	for round_no in 2:
		var f := _make(true, 777 + round_no)
		_play(f)
		assert_eq(f.game_round.state, "won", "round %d won" % round_no)
		for _i in 90:
			f.advance(DT)
		for id in f._views.keys():
			assert_true(f.game_round.find_tile(int(id)) != null, "view %d belongs to a live tile" % id)
		assert_eq(f._views.size(), f.game_round.tiles.size(), "one view per live tile")
		assert_eq(_live_views(f), f.game_round.tiles.size(), "no stray tile nodes")
		assert_true(f._pending.is_empty(), "_pending empty")
		assert_true(f._fly_keys.is_empty(), "_fly_keys empty")
		counts.append(f.get_child_count())
		f.free()
	assert_eq(counts[0], counts[1], "field child count stable across rounds")


func test_tether_visible_only_while_a_shot_is_in_flight() -> void:
	var f := _make(false)
	f.advance(DT)
	assert_false(f._tether.visible, "hidden before any shot")
	var target = null
	for t in f.game_round.tiles:
		if t.alive and t.plane < 2:
			target = t
			break
	assert_true(f.game_round.fire(target.id), "fire accepted")
	f.advance(DT)
	assert_false(f.game_round.shot.is_empty(), "shot in flight")
	assert_true(f._tether.visible, "tether visible during the shot")
	assert_eq(f._tether.points.size(), 2, "tether has two points")
	var steps := 0
	while not f.game_round.shot.is_empty() and steps < 600:
		f.advance(DT)
		assert_true(f._tether.visible or f.game_round.shot.is_empty(), "visible every frame of the shot")
		steps += 1
	assert_true(f.game_round.shot.is_empty(), "shot resolved")
	for _i in int(ceil(f.TETHER_FADE / DT)) + 3:
		f.advance(DT)
	assert_false(f._tether.visible, "tether hidden after the fade")
	f.free()


func _first_view(f: Node2D) -> Node:
	for id in f._views.keys():
		if not f._views[id].is_back:
			return f._views[id]
	return null


func test_treatments_differ_and_reduced_motion_stops_tilt_and_sway() -> void:
	var seen := {}
	for tr in AppSettings.TREATMENTS:
		var f := _make(false, 12345, tr)
		f.advance(DT)
		var v = _first_view(f)
		var mat: ShaderMaterial = v.body.material
		seen[tr] = {
			"tex": v.body.texture,
			"gain": mat.get_shader_parameter("unlit_gain"),
			"light_mask": v.body.light_mask,
			"tilt": v.current_tilt,
		}
		f.free()
	assert_true(seen["flat"]["gain"] != null, "flat sets unlit_gain")
	assert_eq(seen["flat"]["light_mask"], 2, "flat body is unlit by the lamp")
	assert_eq(seen["flat"]["tilt"], Vector2.ZERO, "flat does not tilt")
	assert_true(seen["tilt"]["tilt"] != Vector2.ZERO, "tilt treatment tilts")
	assert_true(seen["bevel"]["tilt"] != Vector2.ZERO, "bevel treatment tilts")
	assert_true(seen["glass"]["tilt"] != Vector2.ZERO, "glass treatment tilts")
	assert_eq(seen["glass"]["light_mask"], 2, "glass body is unlit by the lamp")
	assert_true(seen["flat"]["gain"] != seen["tilt"]["gain"], "flat vs tilt shader params differ")
	assert_true(seen["bevel"]["tex"] != seen["tilt"]["tex"], "bevel uses a different body texture")
	assert_true(seen["flat"]["light_mask"] != seen["tilt"]["light_mask"], "flat vs tilt light mask differs")
	# Reduced motion: no tilt or sway, at several times.
	var f := _make(false, 12345, "tilt", true)
	for _i in 120:
		f.advance(DT)
		for id in f._views.keys():
			var v = f._views[id]
			if v.anim == "":
				assert_eq(v.current_tilt, Vector2.ZERO, "reduced motion keeps tilt at 0")
				assert_eq(v._mat.get_shader_parameter("tilt_deg"), Vector2.ZERO, "shader tilt_deg is 0")
	f.free()


func test_back_tiles_are_dim_flat_and_untilted() -> void:
	var f := _make(false)
	var cap: float = f._n("plane.backAlpha")
	var n := 0
	for t in f.game_round.tiles:
		if t.plane >= 2:
			n += 1
			var v = f._views[t.id]
			assert_true(v.modulate.a <= cap + 0.0001, "back alpha <= backAlpha")
			assert_true(not v.shadow.visible, "no shadow")
			assert_true(v.body.light_mask == 2, "no lamp light")
	assert_true(n > 0, "back tiles exist")
	for _i in 30:
		f.advance(DT)
	for t in f.game_round.tiles:
		if t.plane >= 2:
			assert_eq(f._views[t.id].current_tilt, Vector2.ZERO)
	f.free()


func _back_tap_point(f: Node2D) -> Vector2:
	for t in f.game_round.tiles:
		if t.plane >= 2:
			return f.to_screen(t.pos)
	return Vector2.ZERO


func test_back_plane_tap_does_nothing() -> void:
	var f := _make(false)
	var p := _back_tap_point(f)
	for t in f.game_round.tiles:
		if t.plane < 2:
			t.pos = Vector2(-5.0, -5.0)
	var air_before: float = f.game_round.oxygen
	var wrong_before: int = int(f.game_round.stats["wrong"])
	var fx_before: int = f._fx_layer.get_child_count()
	assert_eq(f.tap(p), -1)
	assert_true(f.game_round.shot.is_empty(), "no fire")
	assert_eq(f._fx_layer.get_child_count(), fx_before, "no effect")
	assert_eq(f.game_round.oxygen, air_before, "no air cost")
	assert_eq(int(f.game_round.stats["wrong"]), wrong_before)
	f.free()


func test_back_tiles_draw_no_letter() -> void:
	var f := _make(false)
	var n := 0
	for t in f.game_round.tiles:
		if t.plane >= 2:
			n += 1
			assert_true(not f._views[t.id].glyph.visible, "back debris has no glyph")
			assert_true(t.ch != "", "rules still carry ch")
	assert_true(n > 0, "back tiles exist")
	f.free()

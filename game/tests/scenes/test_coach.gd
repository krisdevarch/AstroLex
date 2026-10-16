extends "res://tests/test_case.gd"
## WP-3.Q: the first-play coach points at a needed letter, then at the slots, then at the first drone.

const FieldScene: PackedScene = preload("res://scenes/field.tscn")
const GameData := preload("res://rules/game_data.gd")
const Save := preload("res://services/save.gd")
const Flow := preload("res://tests/scenes/flow.gd")
const Targeting := preload("res://rules/targeting.gd")
const DT := 1.0 / 60.0


func _level(i: int) -> Dictionary:
	return GameData.load_content()["levels"]["act1_low_orbit"][i]


func _field(level_i: int, coach: bool, drones: bool = false, autoplay: bool = false, reduced: bool = false) -> Node2D:
	var f: Node2D = FieldScene.instantiate()
	f.print_ready = false
	f.autoplay = autoplay
	f.coach_enabled = coach
	f.coach_drones = drones
	f.settings.reduced_motion = reduced
	tree.root.add_child(f)
	f.begin_level(_level(level_i))
	return f


func _coach(f: Node) -> Control:
	return f.find_child("Coach", true, false) as Control


func _catch_one(f: Node2D) -> void:
	var id: int = Targeting.letter_target(f.game_round)
	f.game_round.fire(id)
	var n := 0
	while f._coach_stage == 1 and n < 600:
		f.advance(DT)
		n += 1


func test_points_at_a_needed_letter_after_the_throw_and_hides_on_the_first_catch() -> void:
	var f := _field(0, true)
	var c := _coach(f)
	assert_true(f.intro_active(), "throw first")
	f.advance(DT)
	assert_false(c.visible, "nothing during the throw")
	f.skip_intro()
	f.advance(DT)
	assert_true(c.visible and c.ring_visible, "ring after the throw")
	assert_eq(c.caption(), "Tap a letter you need", "caption")
	var id: int = Targeting.letter_target(f.game_round)
	var v = f._views[id]
	assert_eq(c.target, v.position, "ring sits on a needed letter")
	_catch_one(f)
	assert_false(c.ring_visible, "ring hidden on the first catch")
	f.advance(DT)
	assert_true(c.visible and not c.ring_visible, "slot caption, no ring")
	assert_true(c.caption().begins_with("Fill every slot"), "slot caption text")
	var left := 0
	while c.visible and left < 600:
		f.advance(DT)
		left += 1
	assert_false(c.visible, "gone after afterCatchSec")
	assert_true(left > 100, "the slot caption stayed a while")
	f.free()


func test_not_shown_when_off_or_in_autoplay() -> void:
	var f := _field(0, false)
	f.skip_intro()
	for i in 30:
		f.advance(DT)
	assert_false(_coach(f).visible, "coach off")
	f.free()
	var g := _field(0, true, true, true)
	g.skip_intro()
	for i in 30:
		g.advance(DT)
	assert_false(_coach(g).visible, "never in autoplay")
	g.free()


func test_pause_hides_it_and_a_new_level_clears_it() -> void:
	var f := _field(0, true)
	f.skip_intro()
	f.advance(DT)
	assert_true(_coach(f).visible, "shown")
	f.set_paused(true)
	assert_true(_coach(f).modulate.a < 0.01, "hidden while paused")
	f.set_paused(false)
	assert_true(_coach(f).modulate.a > 0.99, "back after resume")
	f.begin_level(_level(1))
	assert_false(_coach(f).visible, "cleared on a new level")
	f.free()


func test_drone_step_appears_and_clears() -> void:
	var f := _field(11, false, true)
	f.skip_intro()
	var n := 0
	while f.game_round.thieves.is_empty() and f.game_round.state == "play" and n < 60 * 60:
		f.advance(DT)
		n += 1
	f.advance(DT)
	var c := _coach(f)
	assert_true(c.visible, "drone hint shown")
	assert_eq(c.caption(), "Tap the drone to save the letter", "drone caption")
	var th = f.game_round.thieves[0]
	f.tap(f.to_screen(th.pos))
	n = 0
	while not f.game_round.thieves.is_empty() and n < 900:
		f.advance(DT)
		n += 1
	f.advance(DT)
	assert_false(c.visible, "hidden once the drone is gone")
	f.free()


func test_main_enables_it_only_for_a_save_without_a_win() -> void:
	var main := Flow.returning(tree)
	var f := Flow.to_field(main)
	assert_true(f != null and f.coach_enabled and f.coach_drones, "fresh save is coached")
	main.free()
	var s := Save.fake()
	s.set_profile("wren", "they", "normal")
	s.record_level("act1_low_orbit", "1-01", 0, true, 100, 1)
	var m2 := Flow.returning(tree, s)
	var g := Flow.to_field(m2, "1-02")
	assert_true(g != null and not g.coach_enabled and g.coach_drones, "after a win: letters no, drones yes")
	m2.free()


func test_reduced_motion_has_no_pulse() -> void:
	var f := _field(0, true, false, false, true)
	var c := _coach(f)
	f.skip_intro()
	for i in 20:
		f.advance(DT)
		c._process(0.1)
	assert_eq(c.pulse_scale(), 1.0, "static ring")
	f.free()
	var g := _field(0, true)
	var d := _coach(g)
	g.skip_intro()
	g.advance(DT)
	d._process(0.3)
	assert_true(d.pulse_scale() != 1.0, "pulses by default")
	g.free()

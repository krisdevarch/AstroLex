extends "res://tests/test_case.gd"
## WP-F.1: the look of Babel's hazards (shimmer, trap ring, jam colours, toasts, summary counters).

const FieldScene: PackedScene = preload("res://scenes/field.tscn")
const GameData := preload("res://rules/game_data.gd")


func _field(tuning: Dictionary = {}) -> Node2D:
	var level: Dictionary = (GameData.load_content()["levels"]["act4_core"][0] as Dictionary).duplicate(true)
	for k: String in tuning:
		level["tuning"][k] = tuning[k]
	var f: Node2D = FieldScene.instantiate()
	f.autoplay = false
	f.intro_enabled = false
	tree.root.add_child(f)
	f.begin_level(level, "act4_core")
	return f


func _run(f: Node2D, secs: float) -> void:
	for _i in int(secs * 60.0):
		f.advance(1.0 / 60.0)


func _view(f: Node2D, id: int) -> Node2D:
	return f._views.get(id)


func test_counterfeit_and_trap_tiles_get_their_marks() -> void:
	var f := _field({"hazard.counterfeitRatio": 0.5, "hazard.traps": 1})
	_run(f, 0.5)
	var forged := 0
	var trap := 0
	for t in f.game_round.tiles:
		if t.plane >= 2:
			continue
		var v := _view(f, t.id)
		assert_true(v != null, "tile has a view")
		assert_eq(v.kind, t.kind, "view knows the kind")
		if t.kind == "counterfeit":
			forged += 1
			assert_true(v.get_node_or_null("HazardRing") != null, "forgery has the shimmer node")
		elif t.kind == "trap":
			trap += 1
			assert_true(v.get_node_or_null("HazardRing") != null, "trap has a ring")
		else:
			assert_true(v.get_node_or_null("HazardRing") == null, "plain tile has none")
	assert_true(forged >= 1, "a forgery is on the field")
	assert_true(trap >= 1, "a trap letter is on the field")
	f.free()


func test_shimmer_sweeps_once_per_period() -> void:
	var f := _field({"hazard.counterfeitRatio": 0.5})
	_run(f, 0.2)
	var id := -1
	for t in f.game_round.tiles:
		if t.kind == "counterfeit":
			id = t.id
	var v := _view(f, id)
	var period := float(f.game_round.get("_t")["hazard.shimmerSec"])
	assert_true(absf(period - 2.0) < 0.01, "about 2 s")
	assert_true(absf(v.shimmer_at(1.0) - v.shimmer_at(1.0 + period)) < 0.001, "same spot one period later")
	assert_true(absf(v.shimmer_at(1.0) - v.shimmer_at(1.0 + period * 0.5)) > 0.4, "half a period moves it")
	f.free()


func test_jam_hides_slot_hints_and_lies_with_colour() -> void:
	var f := _field({"hazard.stroop": 1, "hazard.stroopEverySec": 2, "hazard.stroopSec": 1, "hazard.traps": 0, "hazard.counterfeitRatio": 0, "thief.interval": 0})
	f.settings.hint = "full"
	_run(f, 0.5)
	assert_false(f.game_round.jammed, "clear before the first mark")
	var row: Control = f._active_row
	var shown := 0
	for c in row.get_children():
		if (c.get_node("Glyph") as Label).text != "":
			shown += 1
	assert_eq(shown, row.get_child_count(), "hints visible when clear")
	_run(f, 1.7)
	assert_true(f.game_round.jammed, "jammed after 2 s")
	for c in row.get_children():
		assert_eq((c.get_node("Glyph") as Label).text, "", "slot hints dark")
	var cyan := 0
	var peri := 0
	for t in f.game_round.tiles:
		if t.plane >= 2:
			continue
		var v := _view(f, t.id)
		assert_eq(v.jam_colour, 1 if t.decoy else 2, "decoys cyan, needed letters periwinkle")
		if t.decoy:
			cyan += 1
		else:
			peri += 1
	assert_true(cyan >= 1 and peri >= 1, "both colours present")
	assert_true(str(f._toast.text).begins_with("Visor jammed"), "first-jam toast")
	_run(f, 1.0)
	assert_false(f.game_round.jammed, "clear again")
	for t in f.game_round.tiles:
		if t.plane < 2:
			assert_eq(_view(f, t.id).jam_colour, 0, "colour back to normal")
	f.free()


func test_forged_letter_toast_and_summary_counter() -> void:
	var f := _field({"hazard.counterfeitRatio": 0.5, "thief.interval": 0})
	_run(f, 0.3)
	var forged = null
	for t in f.game_round.tiles:
		if t.kind == "counterfeit" and t.plane < 2:
			forged = t
			break
	assert_true(forged != null, "a forgery to catch")
	forged.vel = Vector2.ZERO
	f.game_round.fire(forged.id)
	_run(f, 0.5)
	assert_true(str(f._toast.text).begins_with("Forged letter"), "toast the first time")
	assert_eq(int(f.summary()["counterfeits"]), 1, "counter in the summary")
	assert_eq(int(f.summary()["traps"]), 0, "traps counter present")
	assert_eq(int(f.summary()["jams"]), 0, "jams counter present")
	f.free()

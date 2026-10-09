extends "res://tests/test_case.gd"
## Hint setting: which unfilled slots show a ghost letter in the HUD word rows.

const FieldScene: PackedScene = preload("res://scenes/field.tscn")
const Telemetry := preload("res://services/telemetry.gd")


func _make(hint: String) -> Node2D:
	var f: Node2D = FieldScene.instantiate()
	f.print_ready = false
	f.settings.hint = hint
	tree.root.add_child(f)
	f.begin(1, 12345)
	f.skip_intro()
	f.advance(1.0 / 60.0)
	return f


func _check(hint: String, expect: Callable) -> void:
	var f := _make(hint)
	for where in ["active", "preview"]:
		var row: Control = f._active_row if where == "active" else f._preview_row
		var slots: Array[Dictionary] = f.game_round.active if where == "active" else f.game_round.preview
		assert_true(slots.size() > 0 and row.get_child_count() == slots.size(), "%s row built" % where)
		for i in slots.size():
			if slots[i]["filled"]:
				continue
			var g := row.get_child(i).get_node("Glyph") as Label
			var want: bool = expect.call(i, slots.size())
			assert_eq(g.text, str(slots[i]["ch"]).to_upper() if want else "", "%s %s slot %d text" % [hint, where, i])
			assert_eq(g.text != "", want, "%s %s slot %d visibility" % [hint, where, i])
			if want:
				assert_true(g.modulate.a < 0.5, "ghost is faint")


func test_full_shows_every_unfilled_slot() -> void:
	_check("full", func(_i: int, _n: int) -> bool: return true)


func test_edges_shows_first_and_last_only() -> void:
	_check("edges", func(i: int, n: int) -> bool: return n <= 2 or i == 0 or i == n - 1)


func test_none_shows_nothing() -> void:
	_check("none", func(_i: int, _n: int) -> bool: return false)


func test_telemetry_settings_include_hint() -> void:
	var t: RefCounted = Telemetry.fake()
	t.set_settings("glass", false, "full")
	assert_eq(t.settings["hint"], "full")


func test_autoplay_still_wins_with_each_hint() -> void:
	for h in ["full", "edges", "none"]:
		var f := _make(h)
		f.autoplay = true
		var steps := 0
		while f.game_round.state == "play" and steps < 300 * 60:
			f.advance(1.0 / 60.0)
			steps += 1
		assert_eq(f.game_round.state, "won", "autoplay wins with hint %s" % h)

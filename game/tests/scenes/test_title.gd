extends "res://tests/test_case.gd"
## The title screen (WP-F.29) wears the intro's look: the wordmark and the four Catcher bubbles from
## `crew_title.gd`, with the menu under the lower bubbles and nothing overlapping.

const Flow := preload("res://tests/scenes/flow.gd")
const CrewTitle := preload("res://scenes/crew_title.gd")
const StartScreen := preload("res://scenes/start_screen.gd")


func _title(note: String = "") -> Control:
	var s: Control = StartScreen.new()
	s.daily_note = note
	tree.root.add_child(s)
	return s


func test_title_has_the_wordmark_four_bubbles_and_the_menu() -> void:
	var s := _title("Streak: 3 days")
	assert_true(s.find_child("Wordmark", true, false) is Label, "wordmark")
	assert_eq((s.find_child("Wordmark", true, false) as Label).text, "AstroLex")
	for id in ["wren", "juno", "ash", "pip"]:
		var b := s.find_child("CrewBubble_%s" % id, true, false)
		assert_true(b != null and b.find_child("Glass", true, false) != null, "bubble %s" % id)
		assert_eq((b as Node2D).scale, Vector2.ONE, "bubble %s at rest, no pop" % id)
	for n in ["StartButton", "DailyButton", "DailyStreak", "SettingsButton", "VersionLabel", "Title"]:
		assert_true(s.find_child(n, true, false) != null, n)
	assert_true(s.find_child("TitleBabel", true, false) == null, "Babel's corner is gone")
	assert_eq(s.tile_count, 4, "ready count is the bubbles")
	s.free()


func _check_no_overlap(size: Vector2) -> void:
	var s: Control = StartScreen.new()
	s.daily_note = "Streak: 3 days"
	s.view_size = size
	tree.root.add_child(s)
	var view := size
	var crew: RefCounted = s._crew
	var circles: Array = crew.rest_circles()
	assert_eq(circles.size(), 4)
	(s.find_child("Buttons", true, false) as Container).notification(Container.NOTIFICATION_SORT_CHILDREN)
	var rects: Array = []
	for n in ["StartButton", "DailyButton", "SettingsButton", "VersionLabel"]:
		var c := s.find_child(n, true, false) as Control
		rects.append(Rect2(c.global_position, c.size if c.size.y > 0.0 else c.get_combined_minimum_size()))
	for r: Rect2 in rects:
		assert_true(Rect2(Vector2.ZERO, view).encloses(r), "button on screen %s" % str(r))
		for c: Array in circles:
			var nearest := Vector2(clampf(c[0].x, r.position.x, r.end.x), clampf(c[0].y, r.position.y, r.end.y))
			assert_true(nearest.distance_to(c[0]) > c[1] + 16.0, "button %s clear of a bubble" % str(r))
	var wm := s.find_child("Tagline", true, false) as Control
	var tag := Rect2(wm.global_position, wm.size)
	for c: Array in circles:
		var nearest := Vector2(clampf(c[0].x, tag.position.x, tag.end.x), clampf(c[0].y, tag.position.y, tag.end.y))
		assert_true(nearest.distance_to(c[0]) > c[1] - 6.0, "tagline clear of a bubble")
	s.free()


func test_menu_clears_the_bubbles_at_the_design_size() -> void:
	_check_no_overlap(Vector2(1080, 1920))


func test_menu_clears_the_bubbles_on_a_tall_phone() -> void:
	_check_no_overlap(Vector2(1080, 2340))


func test_crew_layout_is_the_same_on_both_screens() -> void:
	var a: RefCounted = CrewTitle.new()
	var host := Control.new()
	tree.root.add_child(host)
	a.build(host, Vector2(1080, 2340), load("res://scenes/app_settings.gd").new(), false)
	var view := Vector2(1080, 2340)
	for e in a.bubbles:
		assert_true(e[2].y < CrewTitle.menu_top(view), "bubble above the menu on a tall view")
	for c: Array in a.rest_circles():
		assert_true(c[0].y + c[1] < CrewTitle.menu_top(view) - 16.0, "tall view clear")
	host.free()

extends "res://tests/test_case.gd"
## Drag scrolling on the level map (owner report, 17 Oct 2026): a swipe that starts on a level badge
## scrolls the map and does not open the level; a tap still opens it.

const DragScroll := preload("res://scenes/drag_scroll.gd")


func _list(n: int) -> Array:
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(400, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tree.root.add_child(scroll)
	var box := VBoxContainer.new()
	scroll.add_child(box)
	for i in n:
		var b := Button.new()
		b.custom_minimum_size = Vector2(400, 100)
		box.add_child(b)
	var drag: Node = DragScroll.attach(scroll)
	return [scroll, drag]


func test_a_drag_past_the_deadzone_scrolls_with_the_finger() -> void:
	var r := _list(20)
	var scroll: ScrollContainer = r[0]
	var drag: Node = r[1]
	await tree.process_frame
	drag.press(Vector2(200, 250))
	assert_false(drag.move(Vector2(200, 240)), "a small wobble is still a tap")
	assert_eq(scroll.scroll_vertical, 0)
	assert_true(drag.move(Vector2(200, 100)), "past the deadzone it is a drag")
	assert_true(drag.dragging())
	assert_eq(scroll.scroll_vertical, 150 - int(DragScroll.DEADZONE))
	drag.release()
	scroll.free()


func test_the_drag_stops_at_the_top_and_the_bottom() -> void:
	var r := _list(20)
	var scroll: ScrollContainer = r[0]
	var drag: Node = r[1]
	await tree.process_frame
	drag.press(Vector2(200, 50))
	drag.move(Vector2(200, 290))
	assert_eq(scroll.scroll_vertical, 0, "no scrolling above the top")
	drag.release()
	drag.press(Vector2(200, 290))
	for k in 30:
		drag.move(Vector2(200, 290 - 100 * (k + 1)))
	assert_eq(scroll.scroll_vertical, 20 * 100 - 300, "stops at the bottom")
	drag.release()
	scroll.free()


func test_a_press_outside_the_scroll_area_is_ignored() -> void:
	var r := _list(20)
	var scroll: ScrollContainer = r[0]
	var drag: Node = r[1]
	await tree.process_frame
	drag.press(Vector2(200, 900))
	assert_false(drag.move(Vector2(200, 500)))
	assert_eq(scroll.scroll_vertical, 0)
	scroll.free()


func _mouse(at: Vector2, down: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = at
	e.global_position = at
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	return e


func _motion(at: Vector2) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	return e


func test_a_swipe_from_a_button_does_not_press_it_but_a_tap_does() -> void:
	var r := _list(20)
	var scroll: ScrollContainer = r[0]
	var first: Button = scroll.get_child(0).get_child(0)
	var hits := [0]
	first.pressed.connect(func() -> void: hits[0] += 1)
	await tree.process_frame
	tree.root.push_input(_mouse(Vector2(200, 50), true))
	for k in 6:
		tree.root.push_input(_motion(Vector2(200, 40 - 30 * k)))
		await tree.process_frame
	tree.root.push_input(_mouse(Vector2(200, 50), false))
	await tree.process_frame
	assert_eq(hits[0], 0, "a swipe does not press the button under the finger")
	assert_true(scroll.scroll_vertical > 0, "the swipe scrolled")
	scroll.scroll_vertical = 0
	await tree.process_frame
	tree.root.push_input(_mouse(Vector2(200, 50), true))
	tree.root.push_input(_mouse(Vector2(200, 50), false))
	await tree.process_frame
	assert_eq(hits[0], 1, "a tap still presses it")
	scroll.free()

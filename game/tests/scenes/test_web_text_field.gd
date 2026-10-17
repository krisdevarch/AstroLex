extends "res://tests/test_case.gd"
## The page-input overlay for the name field (owner report, 17 Oct 2026) is web only: off the web the
## LineEdit keeps its own focus and typing.

const WebTextField := preload("res://scenes/web_text_field.gd")


func test_attach_is_a_no_op_off_the_web() -> void:
	var line := LineEdit.new()
	tree.root.add_child(line)
	WebTextField.attach(line)
	assert_eq(line.get_child_count(), 0, "no overlay node off the web")
	assert_eq(line.focus_mode, Control.FOCUS_ALL, "the field still takes focus")
	line.free()

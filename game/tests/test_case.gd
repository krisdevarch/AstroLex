extends RefCounted
## Base for headless tests. Each test file extends this and defines test_* methods.
## Run them all with: scripts/godot/test.sh

var failures: Array[String] = []
## Set by the runner so scene tests can add nodes to the live tree.
var tree: SceneTree


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if actual != expected:
		failures.append("%sexpected %s, got %s" % [_prefix(message), var_to_str(expected), var_to_str(actual)])


func assert_true(condition: bool, message := "") -> void:
	if not condition:
		failures.append("%sexpected true" % _prefix(message))


func assert_false(condition: bool, message := "") -> void:
	if condition:
		failures.append("%sexpected false" % _prefix(message))


func _prefix(message: String) -> String:
	return message + ": " if message != "" else ""

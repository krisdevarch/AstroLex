extends SceneTree
## Headless test runner (no plugin needed):
##   godot --headless --path game -s res://tests/run_tests.gd
## Loads every res://tests/**/test_*.gd, calls each test_* method, and exits 1 if any fail
## or none ran. GDScript cannot catch runtime errors, so scripts/godot/test.sh also fails
## the run when the log contains SCRIPT ERROR.


var _started := false


# Tests start on the first frame, once the tree is ready, so scene tests get _ready() calls.
func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run_all()
	return false


func _run_all() -> void:
	var passed := 0
	var failed := 0
	for path in _find_tests("res://tests"):
		var script := load(path) as GDScript
		if script == null:
			printerr("  FAIL %s: does not load" % path)
			failed += 1
			continue
		for method in script.get_script_method_list():
			var test_name: String = method["name"]
			if not test_name.begins_with("test_"):
				continue
			var case: Object = script.new()
			case.set("tree", self)
			case.call(test_name)
			var failures: Array = case.get("failures")
			if failures.is_empty():
				passed += 1
				print("  ok   %s::%s" % [path.get_file(), test_name])
			else:
				failed += 1
				for failure in failures:
					printerr("  FAIL %s::%s: %s" % [path.get_file(), test_name, failure])
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 or passed == 0 else 0)


func _find_tests(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub in dir.get_directories():
		found.append_array(_find_tests(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_case.gd":
			found.append(dir_path.path_join(file))
	return found

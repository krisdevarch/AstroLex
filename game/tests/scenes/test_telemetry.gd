extends "res://tests/test_case.gd"

const Telemetry := preload("res://services/telemetry.gd")
const FieldScene: PackedScene = preload("res://scenes/field.tscn")

const KEYS := ["schema", "build", "session", "device", "load", "settings", "rounds", "perf", "errors", "events"]
const ROUND_KEYS := ["round", "mode", "act", "seed", "won", "words", "total", "score", "secs", "catches", "wrong", "escapes", "first_catch_s", "min_oxygen", "tap_misses", "near_miss_px_p50", "babel_lines"]


## Plays one autoplay round on a fresh field with the telemetry listening.
func _play(tel: RefCounted, round_no: int) -> Node2D:
	var f: Node2D = FieldScene.instantiate()
	f.autoplay = true
	f.print_ready = false
	tree.root.add_child(f)
	tel.begin_round(f, "drift", round_no, 12345)
	f.begin("drift", round_no, 12345)
	var steps := 0
	while f.game_round.state == "play" and steps < 300 * 60:
		f.advance(1.0 / 60.0)
		tel.sample_frame(1.0 / 60.0)
		steps += 1
	return f


func test_percentiles_on_a_known_list() -> void:
	var v: Array = []
	for i in range(100, 0, -1):
		v.append(float(i))
	assert_eq(Telemetry.percentile(v, 0.5), 50.0)
	assert_eq(Telemetry.percentile(v, 0.95), 95.0)
	assert_eq(Telemetry.percentile([7.0], 0.95), 7.0)
	assert_eq(Telemetry.percentile([], 0.5), 0.0)
	assert_eq(Telemetry.percentile([1.0, 2.0, 3.0, 4.0], 0.5), 2.0)


func test_perf_from_frame_samples() -> void:
	var t: RefCounted = Telemetry.fake()
	for i in 100:
		t.sample_frame(0.01)
	var p: Dictionary = t.perf()
	assert_eq(p["frames"], 100)
	assert_eq(p["fps_avg"], 100.0)
	assert_eq(p["frame_ms_p50"], 10.0)


func test_summary_json_matches_the_contract() -> void:
	var t: RefCounted = Telemetry.fake()
	var f := _play(t, 1)
	assert_eq(f.game_round.state, "won", "autoplay still wins")
	var res: Dictionary = t.results(true)
	assert_eq(res.keys(), KEYS)
	assert_eq(res["schema"], "astrolex.playtest.v1")
	assert_eq((res["build"] as Dictionary).keys(), ["version", "commit", "platform"])
	assert_eq(res["build"]["commit"], "dev")
	assert_eq(str(res["session"]).length(), 6)
	assert_eq((res["device"] as Dictionary).keys(), ["os", "model", "ua", "screen", "dpr"])
	assert_eq((res["load"] as Dictionary).keys(), ["boot_ms", "ready_ms"])
	assert_eq((res["settings"] as Dictionary).keys(), ["treatment", "reduced_motion"])
	assert_eq((res["perf"] as Dictionary).keys(), ["fps_avg", "frame_ms_p50", "frame_ms_p95", "frames"])
	assert_eq(res["rounds"].size(), 1)
	var r: Dictionary = res["rounds"][0]
	for k in ROUND_KEYS:
		assert_true(r.has(k), "round has " + k)
	assert_eq(r["won"], true)
	assert_eq(r["score"], int(round(f.game_round.score)))
	assert_true(r["first_catch_s"] != null and r["catches"] > 0)
	var types: Dictionary = {}
	for e in res["events"]:
		types[e["type"]] = true
	for k in ["fire", "catch", "restore", "round_end"]:
		assert_true(types.has(k), "event " + k)
	assert_eq(t.results(false)["events"].size(), 0, "issue json has no events")
	f.free()


func test_missed_taps_are_counted_with_nearest_distance() -> void:
	var t: RefCounted = Telemetry.fake()
	var f: Node2D = FieldScene.instantiate()
	f.print_ready = false
	tree.root.add_child(f)
	t.begin_round(f, "drift", 1, 1)
	f.begin("drift", 1, 1)
	assert_eq(f.tap(Vector2(-5000, -5000)), -1)
	assert_eq(f.tap(Vector2(-5000, -5000)), -1)
	assert_eq(t._round["tap_misses"], 2)
	assert_eq((t._round["near"] as Array).size(), 2)
	assert_true(float(t._round["near"][0]) > 1000.0)
	f.free()


func test_issue_url_stays_under_6000_for_a_long_session() -> void:
	var t: RefCounted = Telemetry.fake()
	for n in 3:
		_play(t, n + 1).free()
	for i in 20:
		t.report_error("TypeError: cannot read properties of undefined (reading 'x%d') at https://example.com/a/b/c/d/index.js:%d:%d {\"quoted\": [1,2,3]} " % [i, i, i] + "é".repeat(150))
	t.device["ua"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 " + "x".repeat(200)
	assert_eq(t.rounds.size(), 3)
	var out: Dictionary = t.issue_body_and_url()
	var url: String = out["url"]
	assert_true(url.length() < 6000, "url length %d" % url.length())
	assert_true(url.begins_with("https://github.com/krisdevarch/AstroLex/issues/new?title="))
	assert_true(url.contains("&body="))
	assert_true(str(out["title"]).begins_with("[playtest] drift won "))
	assert_true(str(out["body"]).contains("```json"))
	t.send_results()
	assert_eq(t.opened_urls.size(), 1)
	assert_true(t.copy_text().length() > 0)
	t.copy_results()
	assert_true(JSON.parse_string(t.clipboard_text) is Dictionary)
	assert_eq(JSON.parse_string(t.clipboard_text)["events"].size() > 0, true)


func test_end_screen_buttons_send_and_copy_with_a_toast() -> void:
	var t: RefCounted = Telemetry.fake()
	var end: Control = load("res://scenes/end_screen.gd").new()
	end.summary = {"won": true, "mode": "drift", "score": 1}
	end.telemetry = t
	tree.root.add_child(end)
	(end.find_child("SendResultsButton", true, false) as Button).pressed.emit()
	assert_eq(t.opened_urls.size(), 1)
	(end.find_child("CopyResultsButton", true, false) as Button).pressed.emit()
	assert_true(t.clipboard_text.contains("astrolex.playtest.v1"))
	assert_eq((end.find_child("CopyToast", true, false) as Label).text, "Copied")
	end.free()

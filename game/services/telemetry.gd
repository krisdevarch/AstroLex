extends RefCounted
## Playtest telemetry service (docs/playtest-telemetry.md, results format v1).
## Records round events by listening to the field, samples frame times, collects browser errors
## and builds the results JSON. Sending is "open a prefilled GitHub issue" or "copy to clipboard";
## both sit behind the open_url and clipboard callables, so tests use Telemetry.fake().

const SCHEMA := "astrolex.playtest.v1"
const ISSUE_BASE := "https://github.com/krisdevarch/AstroLex/issues/new"
const URL_LIMIT := 6000
const EVENT_CAP := 600
const ERROR_CAP := 100
const ERROR_MSG_CAP := 200
const ID_CHARS := "abcdefghijklmnopqrstuvwxyz0123456789"
const BUILD_PATH := "res://data/build.json"

const HOOK_JS := """
(function () {
  if (window.__alx) { return; }
  var s = window.__alx = { errs: [], t0: performance.now() };
  function push(m) {
    if (s.errs.length < 200) { s.errs.push({ t: (performance.now() - s.t0) / 1000, msg: String(m).slice(0, 300) }); }
  }
  window.onerror = function (m, src, line) { push(m + ' @' + line); };
  var ce = console.error;
  console.error = function () { push(Array.prototype.join.call(arguments, ' ')); return ce.apply(console, arguments); };
})();
"""

var session: String = ""
var web: bool = false
var build: Dictionary = {}
var device: Dictionary = {}
var load_ms: Dictionary = {"boot_ms": null, "ready_ms": null}
var settings: Dictionary = {"treatment": "bubble", "reduced_motion": false, "hint": "none"}
var rounds: Array = []
var errors: Array = []
var events: Array = []
var frames_ms: PackedFloat32Array = PackedFloat32Array()
var playing: bool = false

## Replaceable for tests: open_url.call(url), clipboard.call(text).
var open_url: Callable = func(url: String) -> void: OS.shell_open(url)
var clipboard: Callable = func(text: String) -> void: DisplayServer.clipboard_set(text)
## Fake only: what was "sent".
var opened_urls: Array = []
var clipboard_text: String = ""

var _t0_ms: int = 0
var _round: Dictionary = {}  # accumulators for the round in progress
var _field: Object = null


## A telemetry that touches no OS service: records what would have been opened or copied.
static func fake() -> RefCounted:
	var t: RefCounted = load("res://services/telemetry.gd").new(false)
	t.open_url = func(url: String) -> void: t.opened_urls.append(url)
	t.clipboard = func(text: String) -> void: t.clipboard_text = text
	return t


func _init(real_services: bool = true) -> void:
	_t0_ms = Time.get_ticks_msec()
	session = _new_session_id()
	web = real_services and OS.has_feature("web")
	build = _read_build()
	device = _read_device()
	if web:
		JavaScriptBridge.eval(HOOK_JS, true)
		var ms: Variant = _js_json("JSON.stringify(performance.now())")
		if ms != null:
			load_ms["boot_ms"] = int(round(float(ms)))


func _new_session_id() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var s := ""
	for i in 6:
		s += ID_CHARS[rng.randi() % ID_CHARS.length()]
	return s


func _read_build() -> Dictionary:
	var b := {"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")), "commit": "dev"}
	if FileAccess.file_exists(BUILD_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BUILD_PATH))
		if parsed is Dictionary:
			if parsed.has("version"):
				b["version"] = str(parsed["version"])
			if parsed.has("commit") and str(parsed["commit"]) != "":
				b["commit"] = str(parsed["commit"])
	b["platform"] = "web" if OS.has_feature("web") else OS.get_name().to_lower()
	return b


func _read_device() -> Dictionary:
	var d := {"os": OS.get_name(), "model": OS.get_model_name(), "ua": "", "screen": [0, 0], "dpr": 1}
	if web:
		var j: Variant = _js_json("JSON.stringify([navigator.userAgent, screen.width, screen.height, window.devicePixelRatio])")
		if j is Array and j.size() == 4:
			d["ua"] = str(j[0])
			d["screen"] = [int(j[1]), int(j[2])]
			d["dpr"] = snappedf(float(j[3]), 0.01)
			d["model"] = device_from_ua(d["ua"], str(d["model"]))
	else:
		var sz := DisplayServer.screen_get_size()
		d["screen"] = [sz.x, sz.y]
	return d


# Browsers hide the model; the user agent at least names the device family.
static func device_from_ua(ua: String, fallback: String) -> String:
	for family in ["iPhone", "iPad", "Android", "Macintosh", "Windows", "Linux"]:
		if ua.contains(family):
			return "Mac" if family == "Macintosh" else family
	return fallback


func _js_json(code: String) -> Variant:
	if not web:
		return null
	var raw: Variant = JavaScriptBridge.eval(code, true)
	if raw == null:
		return null
	return JSON.parse_string(str(raw))


func now_s() -> float:
	return float(Time.get_ticks_msec() - _t0_ms) / 1000.0


## First screen is up: load.ready_ms is performance.now() on the web, null elsewhere.
func mark_ready() -> void:
	var ms: Variant = _js_json("JSON.stringify(performance.now())")
	if ms != null:
		load_ms["ready_ms"] = int(round(float(ms)))


func set_settings(treatment: String, reduced_motion: bool, hint: String = "none") -> void:
	settings = {"treatment": treatment, "reduced_motion": reduced_motion, "hint": hint}


# --- recording -------------------------------------------------------------------------

## Starts listening to a field. Call before field.begin().
func begin_round(field: Object, round_no: int, seed_value: int, level_id: String = "", act: String = "", character: String = "", difficulty: String = "") -> void:
	_field = field
	_round = {
		"round": round_no, "mode": "burst", "act": act if act != "" else str(field.get("ACT")), "character": character, "difficulty": difficulty,
		"seed": seed_value, "level": level_id,
		"first_catch_s": null, "tap_misses": 0, "near": [], "babel_lines": [], "wrong_surplus": 0, "wrong_unneeded": 0,
	}
	playing = true
	field.connect("game_event", _on_game_event)
	field.connect("tap_missed", _on_tap_missed)


func _add_event(type: String, extra: Dictionary = {}) -> void:
	var e := {"t": snappedf(now_s(), 0.1), "type": type, "round": int(_round.get("round", 0))}
	e.merge(extra)
	events.append(e)
	if events.size() > EVENT_CAP:
		events.pop_front()


func _on_game_event(e: Dictionary) -> void:
	var type: String = e["type"]
	var gr: Object = _field.get("game_round") if _field != null else null
	match type:
		"fire":
			_add_event("fire")
		"catch":
			if _round["first_catch_s"] == null and gr != null:
				_round["first_catch_s"] = snappedf(float(gr.stats["secs"]), 0.1)
			_add_event("catch", {"ch": str(e.get("ch", ""))})
		"wrong":
			# surplus: a letter of the word whose slot is already filled; unneeded: not in the word at all
			var kind := str(e.get("kind", ""))
			if kind == "surplus" or kind == "unneeded":
				_round["wrong_" + kind] = int(_round["wrong_" + kind]) + 1
			_add_event("wrong", {"ch": str(e.get("ch", "")), "kind": kind})
		"escape":
			_add_event("escape")
		"restore":
			_add_event("restore", {"word": str(e.get("word", ""))})
		"babel":
			(_round["babel_lines"] as Array).append(str(e["text"]))
			_add_event("babel", {"text": str(e["text"])})
		"round_end":
			_add_event("round_end", {"won": bool(e["won"])})
			_finish_round(bool(e["won"]))


func _on_tap_missed(nearest_px: float) -> void:
	_round["tap_misses"] = int(_round["tap_misses"]) + 1
	var extra := {}
	if nearest_px >= 0.0:
		(_round["near"] as Array).append(nearest_px)
		extra["near_px"] = int(round(nearest_px))
	_add_event("tap_miss", extra)


func _finish_round(won: bool) -> void:
	playing = false
	var gr: Object = _field.get("game_round")
	var st: Dictionary = gr.stats
	var near: Array = _round["near"]
	var r := {
		"round": _round["round"], "mode": _round["mode"], "act": _round["act"], "character": _round["character"], "difficulty": _round["difficulty"], "seed": _round["seed"],
		"won": won, "words": gr.restored_words.size(), "total": gr.words.size(),
		"score": int(round(gr.score)), "secs": snappedf(float(st["secs"]), 0.1),
		"catches": int(st["catches"]), "wrong": int(st["wrong"]), "escapes": int(st["escapes"]),
		"wrong_surplus": _round["wrong_surplus"], "wrong_unneeded": _round["wrong_unneeded"],
		"first_catch_s": _round["first_catch_s"], "min_time": snappedf(float(st["min_time"]), 0.1), "stolen": int(st.get("stolen", 0)), "thieves_down": int(st.get("thieves_down", 0)),
		"tap_misses": _round["tap_misses"],
		"near_miss_px_p50": null if near.is_empty() else int(round(percentile(near, 0.5))),
		"babel_lines": _round["babel_lines"],
	}
	rounds.append(r)
	pull_errors()


func sample_frame(delta_sec: float) -> void:
	if delta_sec > 0.0:
		frames_ms.append(delta_sec * 1000.0)


## The game reports its own error.
func report_error(msg: String) -> void:
	_push_error(now_s(), msg)


func _push_error(t: float, msg: String) -> void:
	errors.append({"t": snappedf(t, 0.1), "msg": msg.substr(0, ERROR_MSG_CAP)})
	if errors.size() > ERROR_CAP:
		errors.pop_front()


## Moves browser console errors buffered by the JS hook into errors.
func pull_errors() -> void:
	var list: Variant = _js_json("JSON.stringify(window.__alx ? window.__alx.errs.splice(0) : [])")
	if list is Array:
		for e in list:
			if e is Dictionary:
				_push_error(float(e.get("t", 0.0)), str(e.get("msg", "")))


# --- numbers ---------------------------------------------------------------------------

## Nearest-rank percentile (q in 0..1) of a list of numbers; 0.0 for an empty list.
static func percentile(values: Array, q: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var rank := int(ceil(q * float(sorted.size())))
	return float(sorted[clampi(rank - 1, 0, sorted.size() - 1)])


func perf() -> Dictionary:
	var vals: Array = Array(frames_ms)
	var total := 0.0
	for v in vals:
		total += float(v)
	return {
		"fps_avg": snappedf(float(vals.size()) / (total / 1000.0), 0.1) if total > 0.0 else 0.0,
		"frame_ms_p50": snappedf(percentile(vals, 0.5), 0.1),
		"frame_ms_p95": snappedf(percentile(vals, 0.95), 0.1),
		"frames": vals.size(),
	}


# --- output ----------------------------------------------------------------------------

## The results object. with_events adds events (clipboard only).
func results(with_events: bool = false) -> Dictionary:
	pull_errors()
	var out := {
		"schema": SCHEMA,
		"build": build.duplicate(),
		"session": session,
		"device": device.duplicate(true),
		"load": load_ms.duplicate(),
		"settings": settings.duplicate(),
		"rounds": rounds.duplicate(true),
		"perf": perf(),
		"errors": errors.duplicate(true),
		"events": events.duplicate(true) if with_events else [],
	}
	return out


func copy_text() -> String:
	return JSON.stringify(results(true))


func issue_title() -> String:
	var mode := "none"
	var res := "-"
	var score := 0
	if not rounds.is_empty():
		var r: Dictionary = rounds[rounds.size() - 1]
		mode = str(r["mode"])
		res = "won" if bool(r["won"]) else "lost"
		score = int(r["score"])
	return "[playtest] %s %s %d · %s · %s" % [mode, res, score, str(build["commit"]), session]


func _summary_md(res: Dictionary) -> String:
	var p: Dictionary = res["perf"]
	var lines := PackedStringArray()
	lines.append("**Playtest** build `%s` (%s) · session `%s` · %d round(s) · %d error(s)" % [build["commit"], build["platform"], session, rounds.size(), errors.size()])
	for r in rounds:
		lines.append("- round %d %s: %s, score %d, words %d/%d, %.0f s, %d catches, %d wrong (%d surplus, %d unneeded), %d missed taps" % [
			int(r["round"]), str(r["mode"]), "won" if bool(r["won"]) else "lost", int(r["score"]),
			int(r["words"]), int(r["total"]), float(r["secs"]), int(r["catches"]), int(r["wrong"]), int(r.get("wrong_surplus", 0)), int(r.get("wrong_unneeded", 0)), int(r["tap_misses"])])
	lines.append("- fps avg %.1f, frame p50 %.1f ms, p95 %.1f ms" % [float(p["fps_avg"]), float(p["frame_ms_p50"]), float(p["frame_ms_p95"])])
	return "\n".join(lines)


func _body_for(res: Dictionary) -> String:
	return "%s\n\n```json\n%s\n```\n" % [_summary_md(res), JSON.stringify(res)]


func url_for(title: String, body: String) -> String:
	return "%s?title=%s&body=%s" % [ISSUE_BASE, title.uri_encode(), body.uri_encode()]


## Issue body: summary plus the JSON without events, trimmed until the URL is under the limit
## (drop babel_lines, then keep the last 5 errors, then shorter messages and user agent).
func issue_body_and_url() -> Dictionary:
	var res := results(false)
	var title := issue_title()
	var body := _body_for(res)
	var url := url_for(title, body)
	for step in 5:
		if url.length() < URL_LIMIT:
			break
		_trim(res, step)
		body = _body_for(res)
		url = url_for(title, body)
	return {"title": title, "body": body, "url": url}


func _trim(res: Dictionary, step: int) -> void:
	var errs: Array = res["errors"]
	match step:
		0:
			for r in res["rounds"]:
				r.erase("babel_lines")
		1:
			res["errors"] = errs.slice(maxi(0, errs.size() - 5))
		2:
			for e in errs:
				e["msg"] = str(e["msg"]).substr(0, 80)
			res["device"]["ua"] = str(res["device"]["ua"]).substr(0, 100)
		3:
			res["errors"] = errs.slice(maxi(0, errs.size() - 2))
		4:
			var rs: Array = res["rounds"]
			res["rounds"] = rs.slice(maxi(0, rs.size() - 3))


func send_results() -> String:
	var u: String = issue_body_and_url()["url"]
	open_url.call(u)
	return u


func copy_results() -> void:
	clipboard.call(copy_text())

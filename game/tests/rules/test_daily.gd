extends "res://tests/test_case.gd"

const Daily := preload("res://rules/daily.gd")
const DailyRecord := preload("res://services/daily_record.gd")
const Save := preload("res://services/save.gd")
const GameData := preload("res://rules/game_data.gd")


func _content() -> Dictionary:
	return GameData.load_content()


func test_same_date_same_level_different_dates_differ() -> void:
	var a := Daily.make_level("2026-10-16", _content())
	var b := Daily.make_level("2026-10-16", _content())
	assert_eq(a, b, "deterministic")
	var seeds := {}
	var word_sets := {}
	for d in 30:
		var date := Daily.shift("2026-10-01", d)
		var lv := Daily.make_level(date, _content())
		seeds[lv["seed"]] = true
		word_sets[",".join(lv["words"])] = true
	assert_eq(seeds.size(), 30, "30 dates, 30 seeds")
	assert_true(word_sets.size() >= 28, "the words change from day to day")


func test_seed_is_fnv1a_of_the_date() -> void:
	assert_eq(Daily.seed_of(""), 2166136261, "FNV offset basis")
	assert_eq(Daily.seed_of("a"), 0xE40C292C, "FNV-1a of a")


func test_four_words_one_per_act_from_the_acts() -> void:
	var content := _content()
	for date in ["2026-10-16", "2027-01-01", "2026-02-28"]:
		var lv := Daily.make_level(date, content)
		var words: Array = lv["words"]
		assert_eq(words.size(), 4, "4 words")
		for i in 4:
			var w := str(words[i])
			assert_true((content["acts"][Daily.ACTS[i]]["words"] as Array).has(w), "%s is from act %d" % [w, i + 1])
			assert_true(w.length() >= 3 and w.length() <= 6, "%s length" % w)
		var seen := {}
		for w in words:
			seen[w] = true
		assert_eq(seen.size(), 4, "no repeats")


func test_level_shape_and_no_spoilers() -> void:
	var lv := Daily.make_level("2026-10-16", _content())
	assert_eq(lv["id"], "daily-2026-10-16")
	assert_eq(lv["title"], "Daily Signal")
	assert_eq(Daily.make_level("2027-03-04", _content())["title"], lv["title"], "the title is the same every day, so it gives nothing away")
	for w in lv["words"]:
		assert_false(str(lv["id"]).contains(str(w)), "nor does the id")
	assert_eq(lv["tuning"]["burst.seconds"], 45)
	assert_eq(lv["tuning"]["hazard.counterfeitRatio"], 0.3)
	assert_eq(lv["tuning"]["hazard.traps"], 1)
	assert_true((lv["commsBefore"] as Array).is_empty(), "no comms")
	assert_eq(lv["babelIntro"], Daily.INTRO)


func test_date_helpers() -> void:
	assert_true(Daily.valid_date("2026-10-16"))
	assert_false(Daily.valid_date("2026-13-01"))
	assert_false(Daily.valid_date("tomorrow"))
	assert_eq(Daily.shift("2026-10-31", 1), "2026-11-01")
	assert_eq(Daily.shift("2026-01-01", -1), "2025-12-31")


func test_share_text() -> void:
	var t := Daily.share_text("2026-10-16", 3, 4, 2, 22.3)
	assert_true(t.begins_with("AstroLex Daily Signal 2026-10-16\n3/4 words, ★★☆ stars, 23s left"), t)
	assert_true(t.contains("🟦🟦🟦⬛"), "squares")
	assert_true(t.ends_with("https://krisdevarch.github.io/AstroLex/"), "link")


func test_copy_matches_the_approved_story_data() -> void:
	var root := ProjectSettings.globalize_path("res://").path_join("../data/story/")
	var daily: Variant = JSON.parse_string(FileAccess.get_file_as_string(root + "daily.json"))
	if not daily is Dictionary:
		return  # the data folder is not next to the project (a stripped checkout)
	assert_eq(daily["title"], Daily.TITLE)
	assert_eq(daily["intro"], Daily.INTRO)
	assert_eq(daily["share_card"], Daily.SHARE_CARD)
	assert_eq(daily["streak_lines"], Daily.STREAK_LINES)
	var babel: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root + "babel_final.json"))
	var win: Array = []
	var lose: Array = []
	for l: Dictionary in babel["daily_lines"]:
		(win if l["kind"] == "win" else lose).append(l["text"])
	assert_eq(win, Daily.WIN_LINES)
	assert_eq(lose, Daily.LOSE_LINES)


func test_streak_counts_consecutive_days_and_replays_do_not_count() -> void:
	var s: RefCounted = Save.fake()
	assert_eq(DailyRecord.streak_line(s, "2026-10-16"), "", "no line before the first play")
	var r := DailyRecord.record(s, "2026-10-16", true, 2, 20.0)
	assert_true(r["first"] and r["streak"] == 1)
	assert_eq(DailyRecord.streak_line(s, "2026-10-16"), Daily.STREAK_LINES["first"])
	r = DailyRecord.record(s, "2026-10-16", true, 3, 30.0)
	assert_false(r["first"], "same day is a replay")
	assert_eq(r["streak"], 1)
	assert_eq(DailyRecord.result(s, "2026-10-16")["stars"], 3, "the better replay is kept")
	DailyRecord.record(s, "2026-10-17", false, 0, 0.0)
	r = DailyRecord.record(s, "2026-10-18", true, 1, 5.0)
	assert_eq(r["streak"], 3, "three days in a row, a loss still counts as played")
	assert_eq(DailyRecord.streak_line(s, "2026-10-18"), "A new best: 3 days in a row.")
	assert_eq(DailyRecord.streak(s, "2026-10-19"), 3, "still alive the next morning")
	assert_eq(DailyRecord.streak(s, "2026-10-20"), 0, "a missed day breaks it")
	assert_eq(DailyRecord.streak_line(s, "2026-10-20"), Daily.STREAK_LINES["broken"])
	r = DailyRecord.record(s, "2026-10-20", true, 1, 5.0)
	assert_eq(r["streak"], 1, "starts again")
	assert_eq(r["best"], 3)

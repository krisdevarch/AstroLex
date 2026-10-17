extends RefCounted
## The Daily Signal's seams into main.gd (WP-F.6), kept here so main only calls three functions:
## decorate_start (the title button and streak line), start (play today's level) and finished
## (record the run, raise the result card).

const Daily := preload("res://rules/daily.gd")
const DailyRecord := preload("res://services/daily_record.gd")
const LevelCard := preload("res://scenes/level_card.gd")


static func today(main: Node) -> String:
	return main.daily_today if main.daily_today != "" else Daily.today_utc()


## Title screen: the button text ("done" after today's run), the streak line and the signal.
static func decorate_start(main: Node, s: Control) -> void:
	var t := today(main)
	s.daily_label = "Daily Signal · done" if DailyRecord.done(main.save, t) else "Daily Signal"
	s.daily_note = DailyRecord.streak_line(main.save, t)
	s.daily_pressed.connect(main._start_daily)


## Plays today's level. A new player picks a Catcher and a difficulty first.
static func start(main: Node) -> void:
	if not main.save.has_profile():
		main._show_character(false, func() -> void: main._show_difficulty(false, main._start_daily))
		return
	main.daily_date = today(main)
	main._start_level()


## The run is over: record it (the first run of a day moves the streak) and show the result card.
static func finished(main: Node, summary: Dictionary) -> void:
	var date: String = main.daily_date
	var won: bool = summary.get("won", false)
	var stars := int(summary.get("stars", 1 if won else 0))
	summary["level"] = "daily-%s" % date
	summary["act"] = Daily.TELEMETRY_ACT
	DailyRecord.record(main.save, date, won, stars, float(summary.get("time_left", 0.0)))
	var f: Node = main._field()
	if f == null:
		main._show_start()
		return
	var c: Control = LevelCard.new()
	c.name = "LevelCard"
	c.summary = summary
	c.telemetry = main.telemetry
	c.daily = true
	c.daily_date = date
	c.daily_words = Daily.words_for(date, main.dictionary.content())
	c.map.connect(main._show_start)  # Back
	f.show_card(c)

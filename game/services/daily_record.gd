extends RefCounted
## What the save remembers about the Daily Signal (WP-F.6): per UTC date the best stars and the
## time left, and a streak of consecutive days played. Stored in save.data()["daily"] (an extra key
## the save's migration keeps): {last, streak, best, days: {date: {won, stars, time_left}}}.
## Only the first run of a day moves the streak; later runs that day are replays.

const Daily := preload("res://rules/daily.gd")
const KEEP_DAYS := 40


static func _d(save: RefCounted) -> Dictionary:
	var data: Dictionary = save.data()
	if not data.get("daily") is Dictionary:
		data["daily"] = {"last": "", "streak": 0, "best": 0, "days": {}}
	return data["daily"]


static func record(save: RefCounted, date: String, won: bool, stars: int, time_left: float) -> Dictionary:
	var d := _d(save)
	var days: Dictionary = d["days"]
	var first := not days.has(date)
	if first:
		var last := str(d["last"])
		d["streak"] = int(d["streak"]) + 1 if last == Daily.shift(date, -1) else 1
		d["best"] = maxi(int(d["best"]), int(d["streak"]))
		d["last"] = date
		days[date] = {"won": won, "stars": stars, "time_left": time_left}
		while days.size() > KEEP_DAYS:
			var keys := days.keys()
			keys.sort()
			days.erase(keys[0])
	else:
		var old: Dictionary = days[date]
		var os := int(old.get("stars", 0))
		if stars > os or (stars == os and time_left > float(old.get("time_left", 0.0))):
			days[date] = {"won": won or bool(old.get("won", false)), "stars": stars, "time_left": time_left}
	save.flush()
	return {"first": first, "streak": int(d["streak"]), "best": int(d["best"])}


static func done(save: RefCounted, date: String) -> bool:
	return (_d(save)["days"] as Dictionary).has(date)


static func result(save: RefCounted, date: String) -> Dictionary:
	return (_d(save)["days"] as Dictionary).get(date, {})


## The streak now: its length counts while the last play was today or yesterday, else 0.
static func streak(save: RefCounted, today: String) -> int:
	var d := _d(save)
	var last := str(d["last"])
	return int(d["streak"]) if last == today or last == Daily.shift(today, -1) else 0


## The line under the title button, from the approved streak lines ("" before the first play).
static func streak_line(save: RefCounted, today: String) -> String:
	var d := _d(save)
	if str(d["last"]) == "":
		return ""
	var n := streak(save, today)
	var key := "continue"
	if n == 0 or (n == 1 and int(d["best"]) > 1):
		key = "broken"
	elif n == 1:
		key = "first"
	elif n == int(d["best"]) and n >= 3:
		key = "best"
	return str(Daily.STREAK_LINES[key]).replace("{n}", str(n))

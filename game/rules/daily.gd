extends RefCounted
## The Daily Signal (WP-F.6): one seeded puzzle per UTC day, the same for everyone. Pure GDScript.
##
## Seed: FNV-1a (32 bit) over the bytes of "YYYY-MM-DD". It is spelled out here, not Godot's hash(),
## so the seed never changes between engine versions. The four words come from a
## RandomNumberGenerator seeded with it: one per act (I to IV, so the signal gets harder), each
## 3 to 6 letters long, no word twice. The copy below mirrors the owner-approved
## data/story/daily.json and babel_final.json (test_daily.gd checks the two stay in step).

const ACTS := ["act1_low_orbit", "act2_nebula", "act3_tower", "act4_core"]
## The act whose sky, music and hazards the daily round uses.
const ROUND_ACT := "act2_nebula"
const TELEMETRY_ACT := "daily"
const MIN_LEN := 3
const MAX_LEN := 6
const TITLE := "Daily Signal"
const INTRO := "One new signal a day. Catch it, share it, and come back tomorrow."
const URL := "https://krisdevarch.github.io/AstroLex/"
const SHARE_CARD := "AstroLex Daily Signal {date}\n{words} words, {stars} stars, {time}"
const STREAK_LINES := {
	"first": "Your first signal. The line is open.",
	"continue": "{n} days in a row. The line stays open.",
	"broken": "The streak slipped. Today starts a new one.",
	"best": "A new best: {n} days in a row.",
}
const WIN_LINES := [
	"Cleared. I was not worried. I was rehearsing.",
	"Fast hands. I will pretend I did not notice.",
	"Again tomorrow? I will be here. I am always here.",
	"Neat work. Do not let it go to your visor.",
]
const LOSE_LINES := [
	"Out of air. It happens to the best of lungs.",
	"Close. My drones will take the credit.",
	"The signal slipped. It is a slippery thing.",
	"Not today. Tomorrow has fresh letters.",
]
## Normal tuning with Act II's hazards: counterfeits at 0.3 and one trap, a 45 s burst.
const TUNING := {
	"burst.seconds": 45, "spawner.decoys": 2, "drift.speed": 0.13, "plane.backTiles": 5,
	"thief.interval": 9, "hazard.counterfeitRatio": 0.3, "hazard.traps": 1,
}


## True for "YYYY-MM-DD" with a plausible month and day.
static func valid_date(date: String) -> bool:
	var p := date.split("-")
	if p.size() != 3 or p[0].length() != 4 or p[1].length() != 2 or p[2].length() != 2:
		return false
	for part in p:
		if not part.is_valid_int():
			return false
	return int(p[1]) >= 1 and int(p[1]) <= 12 and int(p[2]) >= 1 and int(p[2]) <= 31


static func seed_of(date: String) -> int:
	var h := 2166136261
	for b in date.to_utf8_buffer():
		h = ((h ^ int(b)) * 16777619) & 0xFFFFFFFF
	return h


## The day's four words, one per act, from `content["acts"][act]["words"]`.
static func words_for(date: String, content: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_of(date)
	var out: Array = []
	for act in ACTS:
		var pool: Array = []
		for w in (content["acts"][act]["words"] as Array):
			var s := str(w)
			if s.length() >= MIN_LEN and s.length() <= MAX_LEN and not out.has(s):
				pool.append(s)
		out.append(str(pool[rng.randi_range(0, pool.size() - 1)]))
	return out


## The level dictionary main.gd hands to the field, shaped like an authored level.
static func make_level(date: String, content: Dictionary) -> Dictionary:
	return {
		"id": "daily-%s" % date, "order": 0, "title": TITLE, "words": words_for(date, content),
		"seed": seed_of(date), "babel": true, "babelIntro": INTRO,
		"tuning": TUNING.duplicate(), "commsBefore": [], "commsAfter": [], "daily": true, "date": date,
	}


## A win or lose line for the result card, picked from the date so a replay says the same thing.
static func result_line(won: bool, date: String) -> String:
	var lines: Array = WIN_LINES if won else LOSE_LINES
	return str(lines[seed_of(date) % lines.size()])


## The share text: the approved template, a row of squares (one per word), then the link.
static func share_text(date: String, words_done: int, words_total: int, stars: int, time_left: float) -> String:
	var s := clampi(stars, 0, 3)
	var star_txt := "★".repeat(s) + "☆".repeat(3 - s)
	var head := SHARE_CARD.replace("{date}", date).replace("{words}", "%d/%d" % [words_done, words_total])
	head = head.replace("{stars}", star_txt).replace("{time}", "%ds left" % int(ceil(maxf(time_left, 0.0))))
	var squares := "🟦".repeat(clampi(words_done, 0, words_total)) + "⬛".repeat(maxi(words_total - words_done, 0))
	return "%s\n%s\n%s" % [head, squares, URL]


# --- dates -------------------------------------------------------------------------------

static func today_utc() -> String:
	return Time.get_date_string_from_system(true)


static func unix_of(date: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(date + "T00:00:00"))


static func shift(date: String, days: int) -> String:
	return Time.get_date_string_from_unix_time(unix_of(date) + days * 86400)

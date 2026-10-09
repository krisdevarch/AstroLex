extends RefCounted
## Test helper: plays a round by firing at the nearest needed tile (not a test file).

const Round := preload("res://rules/round.gd")
const Targeting := preload("res://rules/targeting.gd")


static func target(r: Round) -> int:
	return Targeting.target(r)


## Steps the round one sim step at a time, firing whenever no shot is in flight.
## Returns all events. Stops when the round ends or max_secs of sim time have passed.
static func play(r: Round, step_sec: float, max_secs: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	events.append_array(r.drain_events())
	while r.state == "play" and float(r.stats["secs"]) < max_secs:
		if r.shot.is_empty():
			var id := target(r)
			if id >= 0:
				r.fire(id)
		r.step(step_sec)
		events.append_array(r.drain_events())
	return events

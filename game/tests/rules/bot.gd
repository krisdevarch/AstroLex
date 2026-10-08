extends RefCounted
## Test helper: plays a round by firing at the nearest needed tile (not a test file).

const Round := preload("res://rules/round.gd")


## Nearest catchable real tile whose letter fills an open active slot, else an open preview slot.
## Returns -1 when none exists.
static func target(r: Round) -> int:
	var origin := r.origin()
	for slots: Array[Dictionary] in [r.active, r.preview]:
		var open := {}
		for s in slots:
			if not s["filled"]:
				open[s["ch"]] = true
		var best := -1
		var best_d := INF
		for t in r.tiles:
			if t.plane < 2 and not t.decoy and open.has(t.ch):
				var d: float = origin.distance_to(t.pos)
				if d < best_d:
					best_d = d
					best = t.id
		if best >= 0:
			return best
	return -1


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

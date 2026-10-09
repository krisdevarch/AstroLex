extends RefCounted
## Shared by the test bot and the field autoplay: what to shoot next.

const Round := preload("res://rules/round.gd")


## Nearest catchable real tile whose letter fills an open active slot, else an open preview slot.
## Returns -1 when none exists.
static func target(r: Round) -> int:
	var th := thief_target(r)
	if th >= 0:
		return th
	return letter_target(r)


## A thief that carries a letter, else one within 0.15 of its target tile. -1 when none.
static func thief_target(r: Round) -> int:
	var origin := r.origin()
	var best := -1
	var best_d := INF
	for th in r.thieves:
		var d: float = origin.distance_to(th.pos)
		var danger: bool = th.carrying_id >= 0
		if not danger and th.target_id >= 0:
			var t = r.find_tile(th.target_id)
			danger = t != null and th.pos.distance_to(t.pos) <= 0.15
		if danger and d < best_d:
			best_d = d
			best = th.id
	return best


static func letter_target(r: Round) -> int:
	var origin := r.origin()
	for slots: Array[Dictionary] in [r.active, r.preview]:
		var open := {}
		for s in slots:
			if not s["filled"]:
				open[s["ch"]] = true
		var best := -1
		var best_d := INF
		for t in r.tiles:
			if t.plane < 2 and not t.decoy and t.carried_by < 0 and open.has(t.ch):
				var d: float = origin.distance_to(t.pos)
				if d < best_d:
					best_d = d
					best = t.id
		if best >= 0:
			return best
	return -1



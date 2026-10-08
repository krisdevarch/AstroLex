extends Control
## End of a round: Sector cleared or Out of air, the numbers, the last Babel line.

const Ui := preload("res://scenes/ui.gd")

signal play_again
signal switch_mode

var summary: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var won: bool = summary.get("won", false)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	centre.add_child(box)
	var title := Ui.label("Sector cleared" if won else "Out of air", 100, Ui.ACCENT if won else Color(1.0, 0.55, 0.5))
	title.name = "EndTitle"
	box.add_child(title)
	var secs: float = summary.get("secs", 0.0)
	var rows := [
		["ScoreStat", "Score  %d" % int(summary.get("score", 0))],
		["WordsStat", "Words  %d/%d" % [int(summary.get("words_done", 0)), int(summary.get("words_total", 0))]],
		["TimeStat", "Time  %d:%02d" % [int(secs) / 60, int(secs) % 60]],
		["CatchesStat", "Catches  %d" % int(summary.get("catches", 0))],
		["WrongStat", "Wrong  %d" % int(summary.get("wrong", 0))],
	]
	for r in rows:
		var l := Ui.label(r[1], 54)
		l.name = r[0]
		box.add_child(l)
	var line := Ui.label(str(summary.get("babel", "")), 50, Color(0.95, 0.8, 1.0))
	line.name = "BabelLine"
	line.custom_minimum_size = Vector2(880, 150)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(line)
	var again := Ui.button("Play again", 56, Vector2(560, 140))
	again.name = "PlayAgainButton"
	again.pressed.connect(func() -> void: play_again.emit())
	box.add_child(again)
	var other := "Pressure" if summary.get("mode", "drift") == "drift" else "Drift"
	var sw := Ui.button("Switch to %s" % other, 42, Vector2(560, 110))
	sw.name = "ModeSwitchButton"
	sw.pressed.connect(func() -> void: switch_mode.emit())
	box.add_child(sw)

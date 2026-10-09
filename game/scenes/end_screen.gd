extends Control
## End of a round: Sector cleared or Out of time, the numbers, the last Babel line.

const Ui := preload("res://scenes/ui.gd")

signal next
signal retry
signal map

var summary: Dictionary = {}
var telemetry: RefCounted  # optional; the send and copy buttons show only when set
var _toast: Label
var _toast_t: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var won: bool = summary.get("won", false)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	centre.add_child(box)
	var title_text := "Sector cleared" if won else "Out of time"
	var title := Ui.label(title_text, 100, Ui.ACCENT if won else Color(1.0, 0.55, 0.5))
	title.name = "EndTitle"
	box.add_child(title)
	var secs: float = summary.get("secs", 0.0)
	var stars := clampi(int(summary.get("stars", 1 if won else 0)), 0, 3)
	var st := Ui.label("Stars  " + "*".repeat(stars) + "-".repeat(3 - stars), 70, Ui.ACCENT)
	st.name = "StarsStat"
	box.add_child(st)
	var rows := [
		["ScoreStat", "Score  %d" % int(summary.get("score", 0))],
		["WordsStat", "Words  %d/%d" % [int(summary.get("words_done", 0)), int(summary.get("words_total", 0))]],
		["TimeStat", "Time left  %ds" % int(ceil(float(summary.get("time_left", 0.0))))],
		["SecsStat", "Played  %d:%02d" % [int(secs) / 60, int(secs) % 60]],
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
	if won:
		var nx := Ui.button("Next", 56, Vector2(560, 140))
		nx.name = "NextButton"
		nx.pressed.connect(func() -> void: next.emit())
		box.add_child(nx)
	var rt := Ui.button("Retry", 48 if won else 56, Vector2(560, 120 if won else 140))
	rt.name = "RetryButton"
	rt.pressed.connect(func() -> void: retry.emit())
	box.add_child(rt)
	var mp := Ui.button("Map", 48, Vector2(560, 110))
	mp.name = "MapButton"
	mp.pressed.connect(func() -> void: map.emit())
	box.add_child(mp)
	if telemetry != null:
		var row := HBoxContainer.new()
		row.name = "ResultsRow"
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 20)
		box.add_child(row)
		var send := Ui.button("Send results", 40, Vector2(380, 100))
		send.name = "SendResultsButton"
		send.pressed.connect(func() -> void: telemetry.send_results())
		row.add_child(send)
		var copy := Ui.button("Copy results", 40, Vector2(380, 100))
		copy.name = "CopyResultsButton"
		copy.pressed.connect(_on_copy)
		row.add_child(copy)
	_toast = Ui.label("", 44, Ui.ACCENT)
	_toast.name = "CopyToast"
	_toast.modulate.a = 0.0
	box.add_child(_toast)


func _on_copy() -> void:
	telemetry.copy_results()
	_toast.text = "Copied"
	_toast_t = 1.4


func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)

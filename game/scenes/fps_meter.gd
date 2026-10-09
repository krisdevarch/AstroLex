extends CanvasLayer
## Frame-rate overlay (top-right): "NN fps · p95 NN ms · N tiles", refreshed twice a second from a
## rolling ~3 s window of frame deltas. Used by the field (setting or ?fps=1) and always by the bench.

const WINDOW_SEC := 3.0
const REFRESH_SEC := 0.5

var tiles: int = 0
var label: Label

var _frames: Array[float] = []
var _sum: float = 0.0
var _since: float = 0.0


static func fps_requested() -> bool:
	if OS.get_cmdline_user_args().has("--fps"):
		return true
	if OS.has_feature("web"):
		var q: Variant = JavaScriptBridge.eval("window.location.search")
		return str(q).contains("fps=1")
	return false


## Percentile (0..1) of a frame-time list in seconds, nearest rank; 0 when empty.
static func percentile(frames: Array, p: float) -> float:
	if frames.is_empty():
		return 0.0
	var a: Array = frames.duplicate()
	a.sort()
	var i := clampi(int(ceil(p * float(a.size()))) - 1, 0, a.size() - 1)
	return float(a[i])


## "NN fps · p95 NN ms · N tiles" from the current window.
static func format_line(frames: Array, tile_count: int) -> String:
	var total := 0.0
	for f in frames:
		total += float(f)
	var fps := 0.0 if total <= 0.0 else float(frames.size()) / total
	return "%d fps · p95 %d ms · %d tiles" % [int(round(fps)), int(round(percentile(frames, 0.95) * 1000.0)), tile_count]


func _init() -> void:
	layer = 100
	name = "FpsMeter"
	label = Label.new()
	label.name = "FpsLabel"
	label.text = "-- fps"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.8))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	label.position = Vector2(1080 - 40 - 760, 150)
	label.size = Vector2(760, 44)
	add_child(label)


func _process(delta: float) -> void:
	push_frame(delta)


func push_frame(delta: float) -> void:
	_frames.append(delta)
	_sum += delta
	while _sum > WINDOW_SEC and _frames.size() > 1:
		_sum -= _frames.pop_front()
	_since += delta
	if _since >= REFRESH_SEC:
		_since = 0.0
		label.text = format_line(_frames, tiles)

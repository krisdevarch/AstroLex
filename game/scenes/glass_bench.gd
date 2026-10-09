extends Node
## Frame-rate bench for the tile treatments (O-22: glass needs 60 fps with 20 tiles on a phone).
## N tiles drift and bounce over the sky; the fps meter is always on; "Run 10 s test" records
## frame times and shows PASS (avg >= 58 fps and p95 <= 20 ms) or BELOW 60. Open it with ?bench=1
## (add &auto=1 to run the 10 s glass test at 20 tiles by itself), or --bench / --bench --auto.

const GameData := preload("res://rules/game_data.gd")
const TileViewScript := preload("res://scenes/tile_view.gd")
const TileViewScene: PackedScene = preload("res://scenes/tile_view.tscn")
const LightRig := preload("res://scenes/light_rig.gd")
const Starfield := preload("res://scenes/starfield.gd")
const FpsMeter := preload("res://scenes/fps_meter.gd")
const Ui := preload("res://scenes/ui.gd")

signal closed

const COUNTS: Array[int] = [20, 30, 40]
const LOOKS: Array[String] = ["bubble", "glass"]
const TEST_SEC := 10.0
const WARMUP_SEC := 1.0
const PASS_FPS := 58.0
const PASS_P95_MS := 20.0
const TOP := 260.0
const BOTTOM := 1650.0
const LETTERS := "etaoinshrdlucmfwypvbgk"

var view_size: Vector2 = Vector2(1080, 1920)
var auto: bool = false
var treatment: String = "bubble"
var count: int = 20
var result_line: String = ""

var _tun: Dictionary = {}
var _tiles_root: Node2D
var _tiles: Array = []  # [TileView, velocity]
var _meter: CanvasLayer
var _result_label: Label
var _tiles_btn: Button
var _look_btn: Button
var _run_btn: Button
var _rng := RandomNumberGenerator.new()
var _time: float = 0.0
var _recording: bool = false
var _rec_t: float = 0.0
var _warm: float = -1.0
var _frames: Array[float] = []


static func bench_requested() -> bool:
	if OS.get_cmdline_user_args().has("--bench"):
		return true
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("window.location.search")).contains("bench=1")
	return false


static func auto_requested() -> bool:
	if OS.get_cmdline_user_args().has("--auto"):
		return true
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("window.location.search")).contains("auto=1")
	return false


## Starting look from ?look=<name> (web) or --look=<name>; empty when absent or unknown.
static func look_requested() -> String:
	var src := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--look="):
			src = a.substr(7)
	if src == "" and OS.has_feature("web"):
		var q := str(JavaScriptBridge.eval("window.location.search"))
		var i := q.find("look=")
		if i >= 0:
			src = q.substr(i + 5).get_slice("&", 0)
	return src if LOOKS.has(src) else ""


## Pure: summary of a list of frame times (seconds). Pass needs avg >= 58 fps and p95 <= 20 ms.
static func compute_result(frames: Array, p_treatment: String, tiles: int) -> Dictionary:
	var total := 0.0
	for f in frames:
		total += float(f)
	var avg := 0.0 if total <= 0.0 else float(frames.size()) / total
	var p50 := FpsMeter.percentile(frames, 0.5) * 1000.0
	var p95 := FpsMeter.percentile(frames, 0.95) * 1000.0
	var ok := not frames.is_empty() and avg >= PASS_FPS and p95 <= PASS_P95_MS
	var line := "treatment=%s tiles=%d avg=%.1f fps p50=%.1f ms p95=%.1f ms %s" % [p_treatment, tiles, avg, p50, p95, "PASS" if ok else "BELOW 60"]
	return {"avg_fps": avg, "p50_ms": p50, "p95_ms": p95, "pass": ok, "line": line}


func _ready() -> void:
	_tun = GameData.load_tunables()
	_rng.seed = 777
	var backdrop := CanvasLayer.new()
	backdrop.name = "Backdrop"
	backdrop.layer = 0
	add_child(backdrop)
	var stars: Node2D = Starfield.new()
	stars.view_size = view_size
	backdrop.add_child(stars)
	var world := CanvasLayer.new()
	world.name = "World"
	world.layer = 1
	add_child(world)
	var rig: Node2D = LightRig.new()
	rig.name = "LightRig"
	world.add_child(rig)
	rig.configure(Vector2(view_size.x * 0.5, (TOP + BOTTOM) * 0.45), view_size.y * 1.1, world.layer)
	_tiles_root = Node2D.new()
	_tiles_root.name = "Tiles"
	world.add_child(_tiles_root)
	_meter = FpsMeter.new()
	add_child(_meter)
	var asked := look_requested()
	if asked != "":
		treatment = asked
	_build_ui()
	_rebuild_tiles()
	if auto:
		_warm = WARMUP_SEC


func tile_count() -> int:
	return _tiles.size()


func _build_ui() -> void:
	var hud := CanvasLayer.new()
	hud.name = "Hud"
	hud.layer = 10
	add_child(hud)
	var title := Ui.label("Frame-rate test", 56, Ui.INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(40, 24)
	title.size = Vector2(700, 80)
	hud.add_child(title)
	_result_label = Ui.label("", 30, Color(1.0, 0.95, 0.6))
	_result_label.name = "ResultLabel"
	_result_label.position = Vector2(20, 200)
	_result_label.size = Vector2(view_size.x - 40, 90)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(_result_label)
	var row := HBoxContainer.new()
	row.name = "Buttons"
	row.add_theme_constant_override("separation", 12)
	row.position = Vector2(24, view_size.y - 200)
	row.size = Vector2(view_size.x - 48, 150)
	hud.add_child(row)
	var back := Ui.button("Back", 36, Vector2(200, 130))
	back.name = "BackButton"
	back.pressed.connect(func() -> void: closed.emit())
	row.add_child(back)
	_tiles_btn = Ui.button("", 34, Vector2(240, 130))
	_tiles_btn.name = "TilesButton"
	_tiles_btn.pressed.connect(cycle_count)
	row.add_child(_tiles_btn)
	_look_btn = Ui.button("", 34, Vector2(240, 130))
	_look_btn.name = "LookButton"
	_look_btn.pressed.connect(cycle_look)
	row.add_child(_look_btn)
	_run_btn = Ui.button("Run 10 s test", 34, Vector2(320, 130))
	_run_btn.name = "RunButton"
	_run_btn.pressed.connect(start_test)
	row.add_child(_run_btn)
	_refresh_buttons()


func _refresh_buttons() -> void:
	_tiles_btn.text = "Tiles: %d" % count
	_look_btn.text = "Look: %s" % treatment
	_meter.tiles = _tiles.size()


func cycle_count() -> void:
	count = COUNTS[(COUNTS.find(count) + 1) % COUNTS.size()]
	_rebuild_tiles()


func cycle_look() -> void:
	treatment = LOOKS[(LOOKS.find(treatment) + 1) % LOOKS.size()]
	_rebuild_tiles()


func _rebuild_tiles() -> void:
	for e in _tiles:
		(e[0] as Node).queue_free()
		_tiles_root.remove_child(e[0])
	_tiles.clear()
	var size_px: float = float(_tun["tile.size"]) * view_size.x
	for i in count:
		var v: TileViewScript = TileViewScene.instantiate()
		_tiles_root.add_child(v)
		var ch := LETTERS[_rng.randi() % LETTERS.length()]
		v.setup(ch, size_px, 1.0, 0, treatment, false, _tun, float(i) * 1.7)
		v.name = "Tile_%d" % i
		var ang := _rng.randf() * TAU
		var vel := Vector2(cos(ang), sin(ang)) * _rng.randf_range(90.0, 240.0)
		v.place(Vector2(_rng.randf_range(80.0, view_size.x - 80.0), _rng.randf_range(TOP + 80.0, BOTTOM - 80.0)), _time, 0.5)
		_tiles.append([v, vel])
	if _tiles_btn != null:
		_refresh_buttons()


func start_test() -> void:
	_frames.clear()
	_recording = true
	_rec_t = 0.0
	_run_btn.disabled = true
	_result_label.text = "Recording %d s..." % int(TEST_SEC)


func _process(delta: float) -> void:
	_time += delta
	_step_tiles(delta)
	if _warm >= 0.0:
		_warm -= delta
		if _warm < 0.0:
			_warm = -1.0
			start_test()
		return
	if _recording:
		_frames.append(delta)
		_rec_t += delta
		if _rec_t >= TEST_SEC:
			finish_test()


func finish_test() -> void:
	_recording = false
	_run_btn.disabled = false
	var r := compute_result(_frames, treatment, _tiles.size())
	result_line = str(r["line"])
	_result_label.text = result_line
	print("AstroLex bench: %s" % result_line)


func _step_tiles(delta: float) -> void:
	var half := float(_tun["tile.size"]) * view_size.x * 0.5
	var lo := Vector2(half, TOP + half)
	var hi := Vector2(view_size.x - half, BOTTOM - half)
	for e in _tiles:
		var v: TileViewScript = e[0]
		var vel: Vector2 = e[1]
		var p := v.position + vel * delta
		if p.x < lo.x or p.x > hi.x:
			vel.x = -vel.x
		if p.y < lo.y or p.y > hi.y:
			vel.y = -vel.y
		p = p.clamp(lo, hi)
		e[1] = vel
		v.place(p, _time, p.x / view_size.x)

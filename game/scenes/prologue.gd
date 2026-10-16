extends Control
## The wordless Prologue (WP-F.7) and, with another `stills` list and no water ending, the Act III
## flashback. An animatic: each still fades in, holds with a slow Ken Burns drift (none under
## reduced motion) and fades out within its `seconds`. No text anywhere, except the one word at
## the end of the Prologue: on its last still a single tile "w" drifts in from the top; a tap
## anywhere catches it (the tether sound), WATER appears letter by letter in cream, the grey still
## gains its colour, and the scene ends. A Skip chip sits top right from the second still on.
## Placeholder stills from scripts/art/make_stills.py. Timings come from game/data/stills.json.

const Ui := preload("res://scenes/ui.gd")
const LightRig := preload("res://scenes/light_rig.gd")
const Sfx := preload("res://scenes/sfx.gd")
const TileView := preload("res://scenes/tile_view.gd")
const TileViewScene: PackedScene = preload("res://scenes/tile_view.tscn")
const GameData := preload("res://rules/game_data.gd")

const DATA_PATH := "res://data/stills.json"
const STILL_DIR := "res://art/stills/"
const FADE := 0.6  # seconds of fade at each end of a still, inside its time
const DRIFT_ZOOM := 0.06  # Ken Burns: share of extra scale reached by the end of a still
const DRIFT_SHIFT := 24.0  # px of slide over a still
const TILE_APPEAR := 1.0  # seconds into the last still when the tile starts to drift in
const TILE_DRIFT := 2.4  # seconds the tile takes to arrive
const TILE_PX := 260.0
const WORD := "water"
const LETTER_EVERY := 0.45
const COLOUR_TIME := 2.6  # seconds for the grey to gain colour
const END_HOLD := 1.6
const CREAM := Color("fff6d8")
const SAT_SHADER := "shader_type canvas_item;\nuniform float sat = 0.0;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV) * COLOR;\n\tfloat g = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(mix(vec3(g), c.rgb, sat), c.a);\n}\n"

signal finished(skipped: bool)

## [{path, seconds}]; set before adding to the tree. Empty means the Prologue's own seven.
var stills: Array = []
## True for the Prologue (the tile and WATER on the last still); false for the flashback.
var with_water: bool = true
var reduced_motion: bool = false
var treatment: String = TileView.DEFAULT_LOOK
var view_size: Vector2 = Vector2(1080, 1920)
## Saturation the stills start at (the Prologue is fully grey).
var base_sat: float = 0.0
var sfx: Node

var index: int = -1
var done: bool = false
var skipped: bool = false
var _t: float = 0.0  # seconds into the current still
var _caught: bool = false
var _water_t: float = 0.0
var _rect: TextureRect
var _mat: ShaderMaterial
var _skip: Control
var _tile: Node2D
var _letters: Array[Label] = []
var _letters_row: HBoxContainer
var _tun: Dictionary = {}


## The timings of "prologue" or "flashback" from game/data/stills.json, as still entries.
static func load_stills(key: String) -> Array:
	var d := GameData._load(DATA_PATH)
	var out: Array = []
	for b: Dictionary in d.get(key, []):
		out.append({"path": "%s%s.jpg" % [STILL_DIR, str(b["id"])], "seconds": float(b["seconds"])})
	return out


func _ready() -> void:
	name = "Prologue"
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if stills.is_empty():
		stills = load_stills("prologue")
	var vp := get_viewport_rect().size
	if vp.x > 0.0:
		view_size = vp
	var black := ColorRect.new()
	black.name = "Black"
	black.color = Color.BLACK
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	var sh := Shader.new()
	sh.code = SAT_SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_mat.set_shader_parameter("sat", base_sat)
	_rect = TextureRect.new()
	_rect.name = "Still"
	_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _mat
	_rect.size = view_size
	_rect.pivot_offset = view_size * 0.5
	add_child(_rect)
	_skip = Ui.link("Skip", 36, Vector2(170, 76))
	_skip.name = "PrologueSkip"
	_skip.position = Vector2(view_size.x - 170.0 - 36.0, 48.0)
	(_skip as Button).pressed.connect(skip)
	_skip.visible = false
	add_child(_skip)
	if sfx == null:
		sfx = Sfx.new()
		sfx.name = "Sfx"
		add_child(sfx)
	_next_still()


func current_seconds() -> float:
	return float((stills[index] as Dictionary)["seconds"]) if index >= 0 and index < stills.size() else 0.0


func _is_last() -> bool:
	return index == stills.size() - 1


## True while the water ending is waiting for the player to tap the tile.
func tile_waiting() -> bool:
	return with_water and _is_last() and not _caught and _tile != null


func caught() -> bool:
	return _caught


func shown_letters() -> int:
	var n := 0
	for l in _letters:
		if l.modulate.a > 0.5:
			n += 1
	return n


func saturation() -> float:
	return float(_mat.get_shader_parameter("sat"))


## Scale of the still (1.0 at rest): the Ken Burns drift; always 1.0 under reduced motion.
func drift_scale() -> float:
	return _rect.scale.x


func _next_still() -> void:
	index += 1
	_t = 0.0
	if index >= stills.size():
		_finish(false)
		return
	var path: String = str((stills[index] as Dictionary)["path"])
	_rect.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_rect.modulate.a = 0.0
	_rect.scale = Vector2.ONE
	_rect.position = Vector2.ZERO
	_skip.visible = index >= 1
	if with_water and _is_last():
		_build_tile()
		_build_word()


func _process(delta: float) -> void:
	advance(delta)


## Moves the animatic on by `delta` seconds (the frame loop calls this; tests call it directly).
func advance(delta: float) -> void:
	if done:
		return
	_t += delta
	var dur := current_seconds()
	var last_water := with_water and _is_last()
	var a := minf(_t / FADE, 1.0)
	if not last_water:
		a = minf(a, clampf((dur - _t) / FADE, 0.0, 1.0))
	_rect.modulate.a = a
	if not reduced_motion:
		var u := clampf(_t / maxf(dur, 0.1), 0.0, 1.0)
		var k := 1.0 + DRIFT_ZOOM * u
		_rect.scale = Vector2(k, k)
		_rect.position = Vector2(-DRIFT_SHIFT * u * (1.0 if index % 2 == 0 else -1.0), 0.0)
	if last_water:
		_tick_water(delta)
	elif _t >= dur:
		_next_still()


func _tick_water(delta: float) -> void:
	if _tile != null and not _caught:
		var u := clampf((_t - TILE_APPEAR) / TILE_DRIFT, 0.0, 1.0)
		var ease_u := 1.0 - pow(1.0 - u, 3.0)
		var bob := 0.0 if reduced_motion else sin(_t * 2.2) * 10.0
		var y := lerpf(-TILE_PX, view_size.y * 0.42, ease_u) + bob
		(_tile as Node2D).visible = _t >= TILE_APPEAR
		_tile.call("place", Vector2(view_size.x * 0.5, y), _t, 0.5)
		_tile.call("tick", delta)
	if not _caught:
		return
	_water_t += delta
	var shown := int(_water_t / LETTER_EVERY) + 1
	for i in _letters.size():
		var target := 1.0 if i < shown else 0.0
		_letters[i].modulate.a = move_toward(_letters[i].modulate.a, target, delta * 5.0)
	_mat.set_shader_parameter("sat", lerpf(base_sat, 1.0, clampf(_water_t / COLOUR_TIME, 0.0, 1.0)))
	if _water_t >= maxf(COLOUR_TIME, WORD.length() * LETTER_EVERY) + END_HOLD:
		_finish(false)


## The player taps anywhere: on the last still, once the tile is on its way, it is caught.
func tap() -> void:
	if done or not tile_waiting() or _t < TILE_APPEAR:
		return
	_caught = true
	_water_t = 0.0
	if sfx != null and sfx.has_method("fire"):
		sfx.call("fire")
	if _tile != null:
		_tile.visible = false
	_letters_row.visible = true
	_skip.visible = false


func skip() -> void:
	if not done:
		_finish(true)


func _finish(was_skipped: bool) -> void:
	if done:
		return
	done = true
	skipped = was_skipped
	finished.emit(was_skipped)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		tap()
	elif event is InputEventScreenTouch and event.pressed:
		tap()


func _build_tile() -> void:
	_tun = GameData.load_tunables()
	var layer := CanvasLayer.new()
	layer.name = "TileLayer"
	layer.layer = 2
	add_child(layer)
	var rig: Node2D = LightRig.new()
	layer.add_child(rig)
	rig.configure(Vector2(view_size.x * 0.5, view_size.y * 0.42 - 140.0), 900.0, layer.layer)
	_tile = TileViewScene.instantiate()
	_tile.name = "WaterTile"
	layer.add_child(_tile)
	_tile.call("setup", "w", TILE_PX, TILE_PX / (float(_tun["tile.size"]) * view_size.x), 0, treatment, reduced_motion, _tun, 0.0)
	(_tile as Node2D).visible = false
	_tile.call("place", Vector2(view_size.x * 0.5, -TILE_PX), 0.0, 0.5)


func _build_word() -> void:
	_letters_row = HBoxContainer.new()
	_letters_row.name = "Water"
	_letters_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_letters_row.add_theme_constant_override("separation", 14)
	_letters_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letters_row.visible = false
	_letters_row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_letters_row.position = Vector2(0.0, view_size.y * 0.55)
	_letters_row.size = Vector2(view_size.x, 220.0)
	add_child(_letters_row)
	for ch in WORD:
		var l := Ui.text(ch.to_upper(), 200, CREAM)
		l.name = "Letter_%s" % ch
		l.modulate.a = 0.0
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_letters_row.add_child(l)
		_letters.append(l)

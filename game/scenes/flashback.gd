extends Control
## The wordless Act III flashback (WP-F.7): an animatic shown once before level 3-06. Each still
## fades in, holds with a slow Ken Burns drift (none under reduced motion) and fades out within its
## `seconds`. The stills start part-grey (`base_sat`). A Skip chip sits top right from the second
## still on. Placeholder stills from scripts/art/make_stills.py; timings from game/data/stills.json.

const Ui := preload("res://scenes/ui.gd")
const GameData := preload("res://rules/game_data.gd")

const DATA_PATH := "res://data/stills.json"
const STILL_DIR := "res://art/stills/"
const FADE := 0.6  # seconds of fade at each end of a still, inside its time
const DRIFT_ZOOM := 0.06  # Ken Burns: share of extra scale reached by the end of a still
const DRIFT_SHIFT := 24.0  # px of slide over a still
const SAT_SHADER := "shader_type canvas_item;\nuniform float sat = 0.0;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV) * COLOR;\n\tfloat g = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(mix(vec3(g), c.rgb, sat), c.a);\n}\n"

signal finished(skipped: bool)

## [{path, seconds}]; set before adding to the tree. Empty means the flashback's own five.
var stills: Array = []
var reduced_motion: bool = false
var view_size: Vector2 = Vector2(1080, 1920)
## Saturation the stills are shown at.
var base_sat: float = 0.6

var index: int = -1
var done: bool = false
var skipped: bool = false
var _t: float = 0.0  # seconds into the current still
var _rect: TextureRect
var _mat: ShaderMaterial
var _skip: Control


## The timings under `key` in game/data/stills.json, as still entries.
static func load_stills(key: String = "flashback") -> Array:
	var d := GameData._load(DATA_PATH)
	var out: Array = []
	for b: Dictionary in d.get(key, []):
		out.append({"path": "%s%s.jpg" % [STILL_DIR, str(b["id"])], "seconds": float(b["seconds"])})
	return out


func _ready() -> void:
	name = "Flashback"
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if stills.is_empty():
		stills = load_stills()
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
	_skip.name = "FlashbackSkip"
	_skip.position = Vector2(view_size.x - 170.0 - 36.0, 48.0)
	(_skip as Button).pressed.connect(skip)
	_skip.visible = false
	add_child(_skip)
	_next_still()


func current_seconds() -> float:
	return float((stills[index] as Dictionary)["seconds"]) if index >= 0 and index < stills.size() else 0.0


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


func _process(delta: float) -> void:
	advance(delta)


## Moves the animatic on by `delta` seconds (the frame loop calls this; tests call it directly).
func advance(delta: float) -> void:
	if done:
		return
	_t += delta
	var dur := current_seconds()
	_rect.modulate.a = minf(minf(_t / FADE, 1.0), clampf((dur - _t) / FADE, 0.0, 1.0))
	if not reduced_motion:
		var u := clampf(_t / maxf(dur, 0.1), 0.0, 1.0)
		var k := 1.0 + DRIFT_ZOOM * u
		_rect.scale = Vector2(k, k)
		_rect.position = Vector2(-DRIFT_SHIFT * u * (1.0 if index % 2 == 0 else -1.0), 0.0)
	if _t >= dur:
		_next_still()


func skip() -> void:
	if not done:
		_finish(true)


func _finish(was_skipped: bool) -> void:
	if done:
		return
	done = true
	skipped = was_skipped
	finished.emit(was_skipped)

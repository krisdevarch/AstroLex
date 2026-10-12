extends Node2D
## Act I painted-sky backdrop (Low Orbit): the baked sky and stars, then a live layer with twinkling
## stars, a station drifting across the top, the odd shooting star, and the airglow and sunrise over
## Earth's limb (the limb itself is the HUD's night panel). Colour story: the scene starts drained
## and its colour comes back as words are restored (`restore` 0..1). Placeholder art (O-14).

const TileTextures := preload("res://scenes/tile_textures.gd")
const HudArt := preload("res://scenes/hud_art.gd")

const GREY_SAT := 0.6  # saturation before any word is restored
const RESTORE_RATE := 0.8  # per second, how fast colour eases back
const STATION_SEC := 90.0  # one crossing of the screen
const STATION_Y := 0.115  # share of the screen height
const SHOOT_EVERY := 9.0
const SHOOT_SEC := 0.7
const SUN_X := 0.86
const MOON := Vector2(0.03, 0.2)  # centre as a share of width and height (partly off the left edge)
const MOON_R := 150.0  # share of the width where the sun rises over the limb
const AIR := Color("8fe3ff")
const CORAL := Color("FF6B35")
const GOLD := Color("ffd27a")
const SAT_SHADER := "shader_type canvas_item;\nuniform float sat = 1.0;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV) * COLOR;\n\tfloat g = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(mix(vec3(g), c.rgb, sat), c.a);\n}\n"

var view_size: Vector2 = Vector2(1080, 1920)
## Share of the level's words restored; the flow sets it, the scene eases toward it.
var restore: float = 0.0
## Reduced motion: no station drift, no shooting stars, steady twinkles.
var reduced_motion: bool = false

var _shown: float = 0.0
var _t: float = 0.0
var _mat: ShaderMaterial
var _live: Node2D
var _twinkles: Array = []  # [pos, size, phase]


func _ready() -> void:
	var sh := Shader.new()
	sh.code = SAT_SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	for pair in [["Sky", TileTextures.sky()], ["Stars", TileTextures.stars()]]:
		var s := Sprite2D.new()
		s.name = pair[0]
		s.texture = pair[1]
		s.centered = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		s.scale = view_size / Vector2((pair[1] as Texture2D).get_size())
		s.material = _mat
		add_child(s)
	_live = Live.new()
	_live.name = "Live"
	_live.set("owner_bg", self)
	_live.material = _mat
	add_child(_live)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 9:
		# Bright stars sit near the galaxy band and the edges, away from the middle of the field.
		var u := rng.randf()
		var y := (0.12 + 0.62 * u) / 1.78 + rng.randfn(0.0, 0.05)
		if i >= 6:
			u = 0.04 + 0.92 * float(i % 2)
			y = rng.randf_range(0.35, 0.65)
		_twinkles.append([Vector2(u * view_size.x, y * view_size.y), rng.randf_range(9.0, 18.0), rng.randf() * TAU])
	_apply_sat()


func _process(delta: float) -> void:
	_t += delta
	_shown = move_toward(_shown, clampf(restore, 0.0, 1.0), RESTORE_RATE * delta)
	_apply_sat()
	_live.queue_redraw()


func saturation() -> float:
	return lerpf(GREY_SAT, 1.0, _shown)


func _apply_sat() -> void:
	_mat.set_shader_parameter("sat", saturation())


## Screen y of Earth's limb at x (the top edge of the HUD's night panel).
func limb_y(x: float) -> float:
	return view_size.y - HudArt.PANEL_H + HudArt.NightPanel.edge_y(x, view_size.x)


class Live extends Node2D:
	var owner_bg: Node2D

	func _draw() -> void:
		var bg := owner_bg
		var w: float = bg.view_size.x
		var t: float = bg._t
		var calm: bool = bg.reduced_motion
		_draw_moon(bg)
		_draw_airglow(bg, w)
		for tw in bg._twinkles:
			var k := 1.0 if calm else 0.65 + 0.35 * sin(t * 1.7 + float(tw[2]))
			_star(tw[0], float(tw[1]) * k, Color(0.85, 0.93, 1.0, 0.85 * k))
		if not calm:
			_draw_station(bg, w, t)
			_draw_shooting_star(bg, w, t)
		else:
			_draw_station(bg, w, STATION_SEC * 0.3)

	func _star(p: Vector2, s: float, c: Color) -> void:
		draw_circle(p, s * 0.9, Color(c.r, c.g, c.b, c.a * 0.12))
		draw_line(p - Vector2(s, 0), p + Vector2(s, 0), c, 2.0, true)
		draw_line(p - Vector2(0, s), p + Vector2(0, s), c, 2.0, true)
		draw_circle(p, 2.6, Color(1, 1, 1, c.a))

	## The Moon, half off the left edge: a crescent lit from the sunrise side, faint earthshine.
	func _draw_moon(bg: Node2D) -> void:
		var c := Vector2(bg.view_size.x * MOON.x, bg.view_size.y * MOON.y)
		var r := MOON_R
		for i in 6:
			draw_circle(c, r + 46.0 - float(i) * 8.0, Color(0.6, 0.8, 0.95, 0.03))
		draw_circle(c, r, Color("aebfd0"))
		var craters := [[Vector2(0.35, -0.3), 0.16], [Vector2(0.55, 0.25), 0.12], [Vector2(0.15, 0.5), 0.1], [Vector2(0.62, -0.05), 0.07], [Vector2(0.3, 0.1), 0.2]]
		for cr in craters:
			draw_circle(c + (cr[0] as Vector2) * r, float(cr[1]) * r, Color(0.45, 0.52, 0.62, 0.45))
		draw_circle(c + Vector2(-0.42, -0.3) * r, r * 0.98, Color(0.035, 0.075, 0.14, 0.97))
		draw_arc(c, r, 0.0, TAU, 96, Color(0.75, 0.88, 1.0, 0.25), 2.0, true)

	## Airglow over the limb (cyan, turning coral toward the sunrise) and the sun just rising.
	func _draw_airglow(bg: Node2D, w: float) -> void:
		var widths := [64.0, 40.0, 22.0, 10.0]
		var alphas := [0.05, 0.08, 0.12, 0.2]
		for j in widths.size():
			var pts := PackedVector2Array()
			var cols := PackedColorArray()
			var x := 0.0
			while x <= w + 0.1:
				pts.append(Vector2(x, bg.limb_y(x) - float(widths[j]) * 0.35))
				var warm := smoothstep(0.45, 0.9, x / w)
				var c := AIR.lerp(CORAL, warm)
				c.a = float(alphas[j]) * (1.0 + 1.5 * warm)
				cols.append(c)
				x += 12.0
			draw_polyline_colors(pts, cols, float(widths[j]), true)
		var sun := Vector2(w * SUN_X, bg.limb_y(w * SUN_X) - 6.0)
		for i in 8:
			draw_circle(sun, 150.0 - float(i) * 17.0, Color(CORAL.r, CORAL.g * 0.9, CORAL.b * 0.7, 0.045))
		draw_circle(sun, 30.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.55))
		draw_circle(sun, 16.0, Color(1.0, 0.97, 0.88, 0.95))
		# Flare: a long thin horizontal streak along the limb and a short vertical one.
		draw_line(sun - Vector2(320, 0), sun + Vector2(320, 0), Color(1.0, 0.85, 0.65, 0.22), 4.0, true)
		draw_line(sun - Vector2(140, 0), sun + Vector2(140, 0), Color(1.0, 0.92, 0.8, 0.5), 2.0, true)
		draw_line(sun - Vector2(0, 70), sun + Vector2(0, 30), Color(1.0, 0.9, 0.75, 0.3), 2.0, true)

	## A small station silhouette drifting right to left across the top, lit by the sunrise.
	func _draw_station(bg: Node2D, w: float, t: float) -> void:
		var span := w + 400.0
		var x := w + 200.0 - fmod(t / STATION_SEC, 1.0) * span
		var c := Vector2(x, bg.view_size.y * STATION_Y)
		var dark := Color(0.05, 0.08, 0.16, 0.95)
		var rim := Color(1.0, 0.72, 0.5, 0.75)
		var panel := Color(0.16, 0.3, 0.48, 0.95)
		var rot := -0.12
		var tf := Transform2D(rot, c)
		draw_set_transform_matrix(tf)
		draw_rect(Rect2(-92, -3, 184, 6), dark)  # truss
		for sx in [-80.0, -50.0, 50.0, 80.0]:
			for sy in [-1.0, 1.0]:
				var r := Rect2(sx - 12.0, 6.0 if sy > 0 else -40.0, 24.0, 34.0)
				draw_rect(r, panel)
				draw_rect(r, Color(0.55, 0.75, 0.95, 0.5), false, 1.5)
				draw_line(Vector2(sx, r.position.y), Vector2(sx, r.end.y), Color(0.55, 0.75, 0.95, 0.35), 1.0)
		draw_rect(Rect2(-26, -9, 52, 18), dark)  # modules
		draw_rect(Rect2(-40, -6, 14, 12), dark)
		draw_rect(Rect2(26, -6, 18, 12), dark)
		draw_line(Vector2(-26, 9), Vector2(44, 9), rim, 2.0)  # sunlit underside
		var blink := fmod(t, 1.6) < 0.12
		draw_circle(Vector2(-92, 0), 3.0, Color(1.0, 0.3, 0.3, 1.0 if blink else 0.3))
		draw_circle(Vector2(92, 0), 3.0, Color(0.4, 1.0, 0.6, 0.3 if blink else 1.0))
		draw_set_transform_matrix(Transform2D.IDENTITY)

	## Every SHOOT_EVERY seconds a meteor streaks down across the upper sky.
	func _draw_shooting_star(bg: Node2D, w: float, t: float) -> void:
		var n := floorf(t / SHOOT_EVERY)
		var age := t - n * SHOOT_EVERY
		if age > SHOOT_SEC:
			return
		var k := age / SHOOT_SEC
		var seed_x := fposmod(sin(n * 12.9898) * 43758.5453, 1.0)
		var start := Vector2(w * (0.2 + 0.7 * seed_x), bg.view_size.y * 0.04)
		var dir := Vector2(-0.82, 0.57)
		var head := start + dir * 520.0 * k
		var tail := head - dir * 170.0
		var a := sin(PI * k)
		draw_polyline_colors(PackedVector2Array([tail, head]), PackedColorArray([Color(0.7, 0.9, 1.0, 0.0), Color(1, 1, 1, 0.9 * a)]), 3.0, true)
		draw_circle(head, 3.0, Color(1, 1, 1, a))

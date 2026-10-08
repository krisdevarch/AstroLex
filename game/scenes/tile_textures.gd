extends RefCounted
## Procedural tile art: rounded body with a bevel (diffuse + normal map in a CanvasTexture)
## and a soft drop shadow. Generated once and cached. Placeholder until human art exists.

const SIZE := 128
const HALF := 61.0
const CORNER := 24.0
const BASE := Color(0.94, 0.92, 0.84)

static var _cache: Dictionary = {}


## kind: "tilt" (soft bevel) or "bevel" (wide, steep bevel).
static func body(kind: String) -> CanvasTexture:
	if _cache.has(kind):
		return _cache[kind]
	var tex: CanvasTexture
	if kind == "bevel":
		tex = _make_body(24.0, 1.7, 0.4)
	else:
		tex = _make_body(14.0, 1.0, 0.2)
	_cache[kind] = tex
	return tex


static func shadow() -> Texture2D:
	if _cache.has("shadow"):
		return _cache["shadow"]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var d := _sdf(Vector2(x + 0.5, y + 0.5) - Vector2(SIZE, SIZE) * 0.5, HALF - 8.0, CORNER)
			var a := clampf(0.5 - d / 16.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(0, 0, 0, a * a * 0.6))
	var tex := ImageTexture.create_from_image(img)
	_cache["shadow"] = tex
	return tex


static func _sdf(p: Vector2, half: float, corner: float) -> float:
	var q := p.abs() - Vector2(half - corner, half - corner)
	var qm := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0))
	return qm.length() + minf(maxf(q.x, q.y), 0.0) - corner


static func _make_body(bevel_w: float, slope: float, edge_dark: float) -> CanvasTexture:
	var diffuse := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var normal := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var centre := Vector2(SIZE, SIZE) * 0.5
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5) - centre
			var d := _sdf(p, HALF, CORNER)
			var alpha := clampf(0.5 - d, 0.0, 1.0)
			var t := clampf(-d / bevel_w, 0.0, 1.0)
			# Outward direction of the edge (gradient of the distance field).
			var q := p.abs() - Vector2(HALF - CORNER, HALF - CORNER)
			var qm := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0))
			var g: Vector2
			if qm.length() > 0.0:
				g = qm.normalized()
			elif q.x > q.y:
				g = Vector2(1, 0)
			else:
				g = Vector2(0, 1)
			g = Vector2(g.x * (1.0 if p.x >= 0.0 else -1.0), g.y * (1.0 if p.y >= 0.0 else -1.0))
			var s := (1.0 - t) * (1.0 - t) * slope
			var n := Vector3(g.x * s, -g.y * s, 1.0).normalized()  # Y+ up, as Godot expects
			normal.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0))
			var shade := 1.0 - edge_dark * (1.0 - t) * (1.0 - t)
			diffuse.set_pixel(x, y, Color(BASE.r * shade, BASE.g * shade, BASE.b * shade, alpha))
	var tex := CanvasTexture.new()
	tex.diffuse_texture = ImageTexture.create_from_image(diffuse)
	tex.normal_texture = ImageTexture.create_from_image(normal)
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return tex

extends RefCounted
## Procedural tile art: rounded body with a bevel (diffuse + normal map in a CanvasTexture)
## and a soft drop shadow. Generated once and cached. Placeholder until human art exists.

const SIZE := 128
const HALF := 61.0
const CORNER := 24.0
## Glass tiles are rounder (owner, 9 Oct). Keep in step with GLASS_CORNER in glass.gdshader.
const GLASS_CORNER := 38.0
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


## Blank debris for the back plane: a faint four-point star fragment, no bevel, no glyph.
static func shard() -> Texture2D:
	if _cache.has("shard"):
		return _cache["shard"]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var centre := Vector2(SIZE, SIZE) * 0.5
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5) - centre
			var r := HALF * (0.46 + 0.54 * pow(absf(cos(2.0 * p.angle())), 2.5))
			var a := clampf(r - p.length() + 0.5, 0.0, 1.0)
			var shade := 1.0 - 0.25 * clampf(p.length() / maxf(r, 1.0), 0.0, 1.0)
			img.set_pixel(x, y, Color(BASE.r * shade, BASE.g * shade, BASE.b * shade, a))
	var tex := ImageTexture.create_from_image(img)
	_cache["shard"] = tex
	return tex


## White rounded-square mask for the glass shader (it computes its own bevel from the UV).
static func glass_mask() -> Texture2D:
	if _cache.has("glass_mask"):
		return _cache["glass_mask"]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var d := _sdf(Vector2(x + 0.5, y + 0.5) - Vector2(SIZE, SIZE) * 0.5, HALF, GLASS_CORNER)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(0.5 - d, 0.0, 1.0)))
	var tex := ImageTexture.create_from_image(img)
	_cache["glass_mask"] = tex
	return tex


## Pre-baked placeholder sky for the backdrop: navy to violet/teal gradient with soft nebula blobs.
## One small texture, stretched over the screen by a single sprite. Generated once.
static func sky() -> Texture2D:
	if _cache.has("sky"):
		return _cache["sky"]
	var w := 108
	var h := 192
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var top := Color(0.03, 0.06, 0.20)
	var mid := Color(0.16, 0.10, 0.36)
	var low := Color(0.06, 0.26, 0.34)
	# [centre uv, radius (uv of width), colour, strength]
	var blobs := [
		[Vector2(0.25, 0.22), 0.34, Color(0.75, 0.30, 0.85), 0.55],
		[Vector2(0.78, 0.50), 0.40, Color(0.15, 0.75, 0.85), 0.5],
		[Vector2(0.35, 0.82), 0.36, Color(0.95, 0.55, 0.45), 0.4],
	]
	for y in h:
		var v := float(y) / float(h - 1)
		var base: Color = top.lerp(mid, clampf(v * 2.0, 0.0, 1.0)) if v < 0.5 else mid.lerp(low, (v - 0.5) * 2.0)
		for x in w:
			var u := float(x) / float(w - 1)
			var c := Vector3(base.r, base.g, base.b)
			for b in blobs:
				var dd := (Vector2(u, v * 1.78) - Vector2(b[0].x, b[0].y * 1.78)).length() / float(b[1])
				var a := exp(-dd * dd * 2.2) * float(b[3])
				var bc: Color = b[2]
				c += Vector3(bc.r, bc.g, bc.b) * a
			img.set_pixel(x, y, Color(minf(c.x, 1.0), minf(c.y, 1.0), minf(c.z, 1.0), 1.0))
	img.generate_mipmaps()  # the glass blurs the sky by sampling a lower mip level
	var tex := ImageTexture.create_from_image(img)
	_cache["sky"] = tex
	return tex


## Baked stars (transparent, 540x960, mipmapped). The backdrop draws it full screen and the glass
## samples it, so stars bend at a glass tile's rim.
static func stars() -> Texture2D:
	if _cache.has("stars"):
		return _cache["stars"]
	var w := 540
	var h := 960
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	for i in 110:
		var c := Vector2(rng.randf() * w, rng.randf() * h)
		var b := rng.randf_range(0.25, 0.9)
		var r := rng.randf_range(0.6, 1.6)
		for y in range(int(c.y - r - 1.0), int(c.y + r + 2.0)):
			for x in range(int(c.x - r - 1.0), int(c.x + r + 2.0)):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var a := clampf(r + 0.5 - Vector2(x + 0.5, y + 0.5).distance_to(c), 0.0, 1.0)
				if a > 0.0:
					img.set_pixel(x, y, Color(0.7 * b, 0.8 * b, b, a))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache["stars"] = tex
	return tex


static func shadow(corner: float = CORNER) -> Texture2D:
	var key := "shadow_%d" % int(corner)
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var d := _sdf(Vector2(x + 0.5, y + 0.5) - Vector2(SIZE, SIZE) * 0.5, HALF - 8.0, corner)
			var a := clampf(0.5 - d / 16.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(0, 0, 0, a * a * 0.6))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
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

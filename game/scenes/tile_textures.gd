extends RefCounted
## Procedural tile art: glass masks (rounded square or circle), the back-plane sticker star, a soft drop
## shadow, and the baked sky and stars that the backdrop draws and the glass samples. Generated
## once and cached. Placeholder until human art exists.

const SIZE := 128
const HALF := 61.0
const CORNER := 24.0  # default for shadow()
## Glass tiles are rounder (owner, 9 Oct). Keep in step with GLASS_CORNER in glass.gdshader.
const GLASS_CORNER := 38.0
const BASE := Color(0.94, 0.92, 0.84)

static var _cache: Dictionary = {}


## Back-plane debris (owner, 13 Oct 2026: "make the stars a bit more interesting"): a sticker
## star like the owner's sheet, a four-point sparkle with a dark ink outline and a white glint.
## The fill is near white so the tile view can tint it (self_modulate); the ink stays dark.
static func shard() -> Texture2D:
	if _cache.has("shard"):
		return _cache["shard"]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var centre := Vector2(SIZE, SIZE) * 0.5
	var ink := Color(0.04, 0.06, 0.18)
	var outline := 7.0
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5) - centre
			var r := HALF * (0.42 + 0.58 * pow(absf(cos(2.0 * p.angle())), 2.2))
			var d := p.length() - r  # rough signed distance to the star's edge
			var a := clampf(0.5 - d, 0.0, 1.0)
			if a <= 0.0:
				continue
			var fill_k := clampf(-d - outline + 0.5, 0.0, 1.0)
			var shade := 1.0 - 0.22 * clampf(p.length() / maxf(r, 1.0), 0.0, 1.0)
			var glint := clampf(1.0 - (p - Vector2(-7, -9)).length() / 7.0, 0.0, 1.0)
			var fill := Color(shade, shade, shade).lerp(Color.WHITE, glint)
			var c := ink.lerp(fill, fill_k)
			c.a = a
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache["shard"] = tex
	return tex


## White rounded-square mask for the glass shader (it computes its own bevel from the UV).
## corner = HALF gives a circle (the bubble look).
static func glass_mask(corner: float = GLASS_CORNER) -> Texture2D:
	var key := "glass_mask_%d" % int(corner)
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var d := _sdf(Vector2(x + 0.5, y + 0.5) - Vector2(SIZE, SIZE) * 0.5, HALF, corner)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(0.5 - d, 0.0, 1.0)))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Cartoon night sky (owner references, 13 Oct 2026): deep blue, a little lighter in the middle and
## darker toward the edges. One small texture, stretched over the screen by a single sprite; the
## glass tiles refract it. Generated once.
static func sky() -> Texture2D:
	if _cache.has("sky"):
		return _cache["sky"]
	var w := 135
	var h := 240
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var centre := Color("2d55a6")
	var mid := Color("19347a")
	var edge := Color("0c1a48")
	for y in h:
		var v := float(y) / float(h - 1)
		for x in w:
			var u := float(x) / float(w - 1)
			var d := Vector2((u - 0.5) * 1.0, (v - 0.42) * 1.78).length() / 0.95
			var c := centre.lerp(mid, smoothstep(0.0, 0.6, d)).lerp(edge, smoothstep(0.55, 1.15, d))
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	img.generate_mipmaps()  # the glass blurs the sky by sampling a lower mip level
	var tex := ImageTexture.create_from_image(img)
	_cache["sky"] = tex
	return tex


## Baked dots (transparent, 540x960, mipmapped): small white and pale blue stars, as in the owner's
## references. The backdrop draws it full screen and the glass samples it.
static func stars() -> Texture2D:
	if _cache.has("stars"):
		return _cache["stars"]
	var w := 540
	var h := 960
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var tints := [Color("ffffff"), Color("ffffff"), Color("ffffff"), Color("bfe6ff"), Color("8fd8ff")]
	for i in 220:
		var c := Vector2(rng.randf() * w, rng.randf() * h)
		var tint: Color = tints[rng.randi() % tints.size()]
		var r := rng.randf_range(0.8, 2.0)
		var b := rng.randf_range(0.55, 1.0)
		for y in range(int(c.y - r - 1.0), int(c.y + r + 2.0)):
			for x in range(int(c.x - r - 1.0), int(c.x + r + 2.0)):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var a := clampf(r + 0.5 - Vector2(x + 0.5, y + 0.5).distance_to(c), 0.0, 1.0) * b
				if a > img.get_pixel(x, y).a:
					img.set_pixel(x, y, Color(tint.r, tint.g, tint.b, a))
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

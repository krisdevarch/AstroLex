extends RefCounted
## Procedural tile art: glass masks (rounded square or circle), the back-plane shard, a soft drop
## shadow, and the baked sky and stars that the backdrop draws and the glass samples. Generated
## once and cached. Placeholder until human art exists.

const SIZE := 128
const HALF := 61.0
const CORNER := 24.0  # default for shadow()
## Glass tiles are rounder (owner, 9 Oct). Keep in step with GLASS_CORNER in glass.gdshader.
const GLASS_CORNER := 38.0
const BASE := Color(0.94, 0.92, 0.84)

static var _cache: Dictionary = {}


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


## Act I sky (Low Orbit, palette "Deep Space Blue" #062C43 #054569 #5591A9 #9CCDDC + coral): deep
## navy at the top, a faint teal band of the galaxy crossing the upper sky, a calm darker middle
## where the letters drift, and Earth's blue glow with a coral sunrise rising from the bottom right.
## One small texture, stretched over the screen by a single sprite. Generated once.
static func sky() -> Texture2D:
	if _cache.has("sky"):
		return _cache["sky"]
	var w := 135
	var h := 240
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var stops := [[0.0, Color("01040d")], [0.30, Color("041a33")], [0.62, Color("062843")], [0.84, Color("07385a")], [1.0, Color("0d5578")]]
	var band := Color("5591A9")
	var band_hi := Color("9CCDDC")
	var coral := Color("FF6B35")
	for y in h:
		var v := float(y) / float(h - 1)
		var base: Color = stops[0][1]
		for i in range(1, stops.size()):
			if v <= float(stops[i][0]):
				var t := (v - float(stops[i - 1][0])) / (float(stops[i][0]) - float(stops[i - 1][0]))
				base = (stops[i - 1][1] as Color).lerp(stops[i][1], smoothstep(0.0, 1.0, t))
				break
		for x in w:
			var u := float(x) / float(w - 1)
			var c := Vector3(base.r, base.g, base.b)
			# Galaxy band: a soft diagonal from the upper left down to the right, brightest high up.
			var d := (v * 1.78 - (0.12 + 0.62 * u)) / 0.2
			var k := exp(-d * d) * (0.6 - 0.46 * smoothstep(0.16, 0.55, v))
			var lane := exp(-pow(d * 3.2 - 0.6, 2.0)) * k * 0.55  # a darker dust lane inside it
			var bc := band.lerp(band_hi, exp(-d * d * 4.0))
			c += Vector3(bc.r, bc.g, bc.b) * k - Vector3(lane, lane, lane) * 0.6
			# Sunrise: coral warmth just above the limb at the lower right.
			var sd := Vector2((u - 0.92) * 1.0, (v - 0.86) * 1.78).length() / 0.42
			var sk := exp(-sd * sd * 1.6) * 0.55
			c += Vector3(coral.r, coral.g * 0.85, coral.b * 0.6) * sk
			# Teal wisps at the top right and a deep blue pool at the lower left frame the field.
			var t1 := Vector2((u - 0.95) * 1.0, (v - 0.12) * 1.78).length() / 0.45
			c += Vector3(0.20, 0.45, 0.55) * exp(-t1 * t1 * 1.8) * 0.6
			var t2 := Vector2((u - 0.0) * 1.0, (v - 0.72) * 1.78).length() / 0.5
			c += Vector3(0.02, 0.22, 0.38) * exp(-t2 * t2 * 1.8) * 0.9
			# Calm middle: a slightly darker oval behind the play field keeps the glyphs readable.
			var md := Vector2((u - 0.5) * 1.2, (v - 0.47) * 1.78).length() / 0.62
			c *= 1.0 - 0.2 * exp(-md * md)
			img.set_pixel(x, y, Color(clampf(c.x, 0.0, 1.0), clampf(c.y, 0.0, 1.0), clampf(c.z, 0.0, 1.0), 1.0))
	img.generate_mipmaps()  # the glass blurs the sky by sampling a lower mip level
	var tex := ImageTexture.create_from_image(img)
	_cache["sky"] = tex
	return tex


## Baked stars (transparent, 540x960, mipmapped): a scatter over the whole sky plus a dense dust of
## faint stars along the galaxy band. The backdrop draws it full screen and the glass samples it,
## so stars bend at a glass tile's rim.
static func stars() -> Texture2D:
	if _cache.has("stars"):
		return _cache["stars"]
	var w := 540
	var h := 960
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	for i in 640:
		var c: Vector2
		var b: float
		var r: float
		if i < 140:
			c = Vector2(rng.randf() * w, rng.randf() * h)
			b = rng.randf_range(0.3, 0.95)
			r = rng.randf_range(0.6, 1.7)
		else:
			# Along the band: x uniform, y on the band's centre line with a gaussian spread.
			var u := rng.randf()
			var off := rng.randfn(0.0, 0.07)
			c = Vector2(u * w, (0.12 + 0.62 * u + off) / 1.78 * h)
			var fade := 1.0 - 0.75 * smoothstep(0.2, 0.55, c.y / h)
			b = rng.randf_range(0.2, 0.7) * fade
			r = rng.randf_range(0.45, 1.1)
		var tint := Color(0.75, 0.85, 1.0) if rng.randf() < 0.8 else Color(1.0, 0.86, 0.7)
		for y in range(int(c.y - r - 1.0), int(c.y + r + 2.0)):
			for x in range(int(c.x - r - 1.0), int(c.x + r + 2.0)):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var a := clampf(r + 0.5 - Vector2(x + 0.5, y + 0.5).distance_to(c), 0.0, 1.0) * clampf(b * 1.3, 0.0, 1.0)
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

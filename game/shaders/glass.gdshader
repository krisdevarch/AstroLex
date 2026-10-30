shader_type canvas_item;
// Glass letter tile (design doc 10, owner decision O-22). Five layers in one pass:
// 1 refraction (blurred, brightened sky read from the screen texture, warped by the bevel normal),
// 2 frost core behind the glyph, 3 (the glyph is a Label drawn on top), 4 specular that slides
// with tilt_deg, 5 rim/bottom edge tint in an accent colour. Tilt vertex code is the same as tile.gdshader.
// The square glass samples the baked sky texture (the same one the backdrop draws, full screen) at the
// pixel's SCREEN_UV: a screen-texture copy plus mipmaps every frame came out black and slow on iPhone
// Safari. The bubble look (13 Oct 2026, owner: "the glass does not magnify the object behind") reads
// the live screen with no mipmaps, one copy per frame, so the planets show magnified through it;
// `live` off falls back to the baked sky.
// Chromatic edge fringe and fine grain follow the CC0 "Fluid Glass UI" shader by Binbun.

uniform sampler2D sky_tex : filter_linear_mipmap, repeat_disable;
uniform float chroma : hint_range(0.0, 1.0) = 0.35;  // colour fringe at the bevel
uniform float grain : hint_range(0.0, 1.0) = 0.05;
uniform sampler2D stars_tex : filter_linear_mipmap, repeat_disable;  // baked stars, same layout as the backdrop
uniform float milk : hint_range(0.0, 1.0) = 0.08;   // faint milky lift of the clear glass

uniform vec2 tilt_deg = vec2(0.0);
uniform float depth_px = 380.0;
uniform float max_tilt_deg = 20.0;
uniform vec3 unlit_gain = vec3(1.0);      // cancels the ambient CanvasModulate (tile is off the lamp)
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec3 flash_color : source_color = vec3(0.95, 0.15, 0.1);

uniform float blur : hint_range(0.0, 1.0) = 0.6;          // 0..1 of the max mip level
uniform float refract_px = 14.0;
uniform float frost : hint_range(0.0, 1.0) = 0.35;
uniform float specular : hint_range(0.0, 1.0) = 0.7;
uniform float edge_tint : hint_range(0.0, 1.0) = 0.6;
uniform vec3 accent : source_color = vec3(0.35, 0.85, 1.0);
uniform float max_lod = 3.0;  // the sky is 108x192, so three mip levels is already very soft
uniform bool shard = false;               // back plane: small frosted shard, no glyph

const float HALF = 61.0;
uniform float corner = 38.0;      // rounded square; corner = HALF (61) makes a circle (bubble)
uniform float lens_width = 26.0;  // width of the lens zone at the rim, in texture px
uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;  // live: what is drawn behind
uniform bool live = true;          // bubble look: refract the live screen (planets too), else the baked sky
uniform float magnify = 0.12;      // bubble look: lens magnification at the centre (0.12 = 12 % bigger)
uniform float rim_bend = 0.9;      // bubble look: extra magnification toward the rim, where the glass bends most
uniform float dark : hint_range(0.0, 1.0) = 0.0;   // bubble look: how much the inside darkens toward night navy (mock v3)
uniform float film : hint_range(0.0, 1.0) = 0.1;   // bubble look: strength of the iridescent rim
uniform float film_sat : hint_range(0.0, 1.0) = 0.6;  // bubble look: rainbow saturation of the rim
uniform float film_width = 13.0;  // bubble look: rim width in texture px
uniform float gloss : hint_range(0.0, 1.0) = 0.0;  // bubble look: the white highlight crescent and dot, top-left
uniform bool bubble = false;      // soap bubble: whole-ball lens, thin-film rainbow rim, highlight spot
uniform float bubble_phase = 0.0;  // per-tile offset of the rim drift (set once; WP-F.24: the drift runs on TIME)
uniform float bubble_drift = 0.4;  // radians per second the rim rainbow turns; 0 holds it still (reduced motion)

void vertex() {
	vec2 p = VERTEX;
	float ax = radians(tilt_deg.x);
	float ay = radians(tilt_deg.y);
	float x1 = p.x * cos(ay);
	float z1 = -p.x * sin(ay);
	float y2 = p.y * cos(ax) - z1 * sin(ax);
	float z2 = p.y * sin(ax) + z1 * cos(ax);
	float s = depth_px / (depth_px + z2);
	VERTEX = vec2(x1, y2) * s;
}

void fragment() {
	// Clear "Liquid Glass" (owner reference, 9 Oct): the middle shows the sky almost untouched, the rim
	// acts as a lens that bends what is behind it, a thin bright rim with a colour fringe outlines it.
	vec4 body = texture(TEXTURE, UV);
	vec2 p = (UV - vec2(0.5)) * 128.0;
	vec2 g;
	float d;
	float lens;
	if (shard) {
		g = normalize(p + vec2(0.001));
		float r = length(p) / HALF;
		lens = smoothstep(0.35, 1.0, r);
		d = -(1.0 - r) * 30.0;
	} else {
		vec2 q = abs(p) - vec2(HALF - corner);
		vec2 qm = max(q, vec2(0.0));
		d = length(qm) + min(max(q.x, q.y), 0.0) - corner;
		if (length(qm) > 0.0) {
			g = normalize(qm);
		} else if (q.x > q.y) {
			g = vec2(1.0, 0.0);
		} else {
			g = vec2(0.0, 1.0);
		}
		g *= sign(p + vec2(0.0001));
		float t = clamp(-d / lens_width, 0.0, 1.0);
		lens = pow(1.0 - t, 2.5);
	}
	// 1 refraction: near the rim the glass samples from further in, so the sky and stars bend.
	vec2 shift = -g * lens * refract_px * SCREEN_PIXEL_SIZE;
	vec2 uv = SCREEN_UV + shift;
	float lod = blur * max_lod + (shard ? 1.0 : 0.0);
	vec2 fringe = shift * chroma;
	vec3 col;
	if (bubble && !shard && live) {
		// Liquid glass (owner reference, 13 Oct 2026: the clear "+" disc): a convex lens over the live
		// screen. Each pixel samples a point nearer the centre, so what is behind (planets, stars)
		// shows magnified, most strongly in the rim band, with a slight colour split at the edge.
		// The pixel's offset from the centre in screen UV comes from the texture-to-screen
		// derivatives, so it holds at any size, scale or y direction.
		vec2 per_px = vec2(dFdx(UV.x), dFdy(UV.y)) * 128.0;  // texture px per screen px (signed)
		vec2 off = p / per_px * SCREEN_PIXEL_SIZE;            // this pixel's offset from the centre
		float rr = clamp(length(p) / HALF, 0.0, 1.0);
		float m = 1.0 + magnify + rim_bend * pow(rr, 5.0);
		float k = 1.0 - 1.0 / m;
		float split = chroma * 0.08 * rr * rr;
		col = vec3(texture(screen_tex, SCREEN_UV - off * (k + split)).r, texture(screen_tex, SCREEN_UV - off * k).g, texture(screen_tex, SCREEN_UV - off * (k - split)).b);
		col /= max(unlit_gain, vec3(0.01));  // the screen is already lit; undo the gain applied at the end
		col = mix(col, vec3(0.9, 0.94, 1.0), milk * 0.5 + 0.1 * pow(rr, 6.0));
		// Mock v3: a navy core that clears into a pale, see-through film band at the rim.
		float band = smoothstep(0.76, 0.97, rr);
		col = mix(col, vec3(0.05, 0.09, 0.2), dark * (1.0 - band));
		col = mix(col, vec3(0.86, 0.9, 1.0), 0.22 * band);
	} else {
		col = vec3(textureLod(sky_tex, uv + fringe, lod).r, textureLod(sky_tex, uv, lod).g, textureLod(sky_tex, uv - fringe, lod).b);
		vec4 st = textureLod(stars_tex, uv, lod * 0.5);
		col += st.rgb * st.a;
		col = mix(col, vec3(0.86, 0.9, 0.98), milk + 0.12 * lens);
	}
	float n = fract(sin(dot(floor(FRAGCOORD.xy), vec2(9.82131, 58.234))) * 45312.1324);
	col *= 1.0 + (n * 2.0 - 1.0) * grain;
	// 2 frost core (0 by default: the glass is clear).
	float core = shard ? 0.0 : smoothstep(1.05, 0.15, length(p) / HALF);
	col = mix(col, vec3(0.03, 0.06, 0.15), clamp(frost * 1.7 * core, 0.0, 0.85));
	// 4 specular: a soft glow inside the top edge plus a faint sheen that slides with tilt.
	float top_glow = smoothstep(0.0, -HALF, p.y) * smoothstep(-HALF, -HALF * 0.35, p.y) * (1.0 - lens);
	float u = dot(UV - vec2(0.5), vec2(0.7071, -0.7071));
	float pos = clamp(tilt_deg.y / max_tilt_deg, -1.0, 1.0) * 0.32 + clamp(tilt_deg.x / max_tilt_deg, -1.0, 1.0) * 0.1 - 0.12;
	float sheen = exp(-pow((u - pos) / 0.09, 2.0)) * (1.0 - lens);
	col += vec3(1.0) * (top_glow * 0.10 + sheen * 0.04) * specular;
	// 5 rim: a thin bright line, strongest top-left and bottom-right, cool on the left, warm on the right.
	float ring = smoothstep(2.4, 0.0, -d);
	float ring_soft = smoothstep(7.0, 0.0, -d);
	float diag = abs(dot(g, normalize(vec2(-1.0, -1.0))));
	vec3 rim_col = mix(vec3(0.75, 0.85, 1.0), vec3(1.0, 0.86, 0.7), clamp(g.x * 0.5 + 0.5, 0.0, 1.0));
	col += rim_col * (ring * (0.35 + 0.55 * diag) + ring_soft * 0.12) * (0.5 + specular * 0.7);
	col += accent * edge_tint * lens * 0.5;
	if (bubble && !shard) {
		// Soap-bubble rim (owner mock v3): a thin iridescent band that drifts slowly, a bright line
		// top-left and bottom-right, and a white highlight crescent with a dot, top-left.
		float ang = atan(g.y, g.x) + (TIME + bubble_phase) * bubble_drift;
		// Target mock (19 Oct 2026): a bold rainbow rim (pink, gold, green, cyan, violet) round the ball.
		vec3 irid = mix(0.5 + 0.5 * cos(vec3(0.0, 2.1, 4.2) + ang * 2.0), vec3(1.0), 1.0 - film_sat);
		float edge = smoothstep(film_width, 0.0, -d) * (0.55 + 0.45 * smoothstep(film_width, 3.0, -d));
		col = mix(col, irid * 1.05, clamp(edge * film * film_sat * 0.75, 0.0, 1.0));
		col += irid * edge * film * 0.35;
		float arc = smoothstep(3.0, 0.5, abs(-d - 2.0)) * pow(abs(dot(g, normalize(vec2(-1.0, -1.0)))), 2.0);
		col += vec3(1.0) * arc * 0.55 * specular;
		vec2 pn = p / HALF;
		float a2 = atan(pn.y, pn.x);
		float crescent = smoothstep(0.13, 0.0, abs(length(pn) - 0.72)) * smoothstep(0.8, 0.0, abs(a2 + 2.25));
		float dot_hl = smoothstep(0.1, 0.03, length(pn - vec2(-0.3, -0.62)));
		col += vec3(1.0) * (crescent * 0.6 + dot_hl * 0.85) * gloss;
	}
	col = mix(col, flash_color, flash * 0.75);
	COLOR = vec4(col * unlit_gain, body.a);
}

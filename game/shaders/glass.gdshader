shader_type canvas_item;
// Glass letter tile (design doc 10, owner decision O-22). Five layers in one pass:
// 1 refraction (blurred, brightened sky read from the screen texture, warped by the bevel normal),
// 2 frost core behind the glyph, 3 (the glyph is a Label drawn on top), 4 specular that slides
// with tilt_deg, 5 rim/bottom edge tint in an accent colour. Tilt vertex code is the same as tile.gdshader.
// The glass does NOT read the live screen: a screen-texture copy plus mipmaps every frame came out
// black and slow on iPhone Safari. It samples the baked sky texture (the same one the backdrop draws,
// full screen) at the pixel's SCREEN_UV, so it costs two plain texture fetches and works everywhere.
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
uniform bool bubble = false;      // soap bubble: whole-ball lens, thin-film rainbow rim, highlight spot
uniform float bubble_time = 0.0;

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
	vec3 col = vec3(textureLod(sky_tex, uv + fringe, lod).r, textureLod(sky_tex, uv, lod).g, textureLod(sky_tex, uv - fringe, lod).b);
	vec4 st = textureLod(stars_tex, uv, lod * 0.5);
	col += st.rgb * st.a;
	col = mix(col, vec3(0.86, 0.9, 0.98), milk + 0.12 * lens);
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
		// Thin-film rainbow on the rim that drifts slowly, and a bright window highlight up-left.
		float ang = atan(g.y, g.x) + bubble_time * 0.6;
		vec3 film = 0.5 + 0.5 * cos(vec3(0.0, 2.1, 4.2) + ang * 2.0 + length(p) * 0.05);
		col += film * smoothstep(12.0, 0.0, -d) * 0.22;
		vec2 hp = p - vec2(-HALF * 0.38, -HALF * 0.42);
		float spot = exp(-dot(hp, hp) / (HALF * HALF * 0.018));
		float arc = smoothstep(6.0, 2.0, abs(-d - 9.0)) * clamp(dot(g, normalize(vec2(1.0, 1.0))), 0.0, 1.0);
		col += vec3(1.0) * (spot * 0.75 + arc * 0.25) * specular;
	}
	col = mix(col, flash_color, flash * 0.75);
	COLOR = vec4(col * unlit_gain, body.a);
}

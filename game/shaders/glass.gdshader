shader_type canvas_item;
// Glass letter tile (design doc 10, owner decision O-22). Five layers in one pass:
// 1 refraction (blurred, brightened sky read from the screen texture, warped by the bevel normal),
// 2 frost core behind the glyph, 3 (the glyph is a Label drawn on top), 4 specular that slides
// with tilt_deg, 5 rim/bottom edge tint in an accent colour. Tilt vertex code is the same as tile.gdshader.
// Blur uses the screen texture's mip chain (textureLod); one fetch per pixel keeps it cheap on phones.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

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
uniform float max_lod = 5.0;
uniform bool shard = false;               // back plane: small frosted shard, no glyph

const float HALF = 61.0;
const float CORNER = 24.0;
const float BEVEL = 20.0;

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
	vec4 body = texture(TEXTURE, UV);
	vec2 p = (UV - vec2(0.5)) * 128.0;
	vec2 g;
	float d;
	float bevel_s;
	float core;
	if (shard) {
		g = normalize(p + vec2(0.001));
		float r = length(p) / HALF;
		bevel_s = smoothstep(0.35, 1.0, r);
		d = -(1.0 - r) * 30.0;
		core = 0.0;
	} else {
		vec2 q = abs(p) - vec2(HALF - CORNER);
		vec2 qm = max(q, vec2(0.0));
		d = length(qm) + min(max(q.x, q.y), 0.0) - CORNER;
		if (length(qm) > 0.0) {
			g = normalize(qm);
		} else if (q.x > q.y) {
			g = vec2(1.0, 0.0);
		} else {
			g = vec2(0.0, 1.0);
		}
		g *= sign(p + vec2(0.0001));
		float t = clamp(-d / BEVEL, 0.0, 1.0);
		bevel_s = (1.0 - t) * (1.0 - t);
		core = smoothstep(1.05, 0.15, length(p) / HALF);
	}
	// 1 refraction: sample the sky through the bevel, blurred by mip level.
	vec2 uv = SCREEN_UV + g * bevel_s * refract_px * SCREEN_PIXEL_SIZE;
	float lod = blur * max_lod + (shard ? 1.5 : 0.0);
	vec3 col = textureLod(screen_texture, uv, lod).rgb;
	col = col * 1.25 + vec3(0.04, 0.06, 0.09);
	// 2 frost core.
	col = mix(col, vec3(0.03, 0.06, 0.15), clamp(frost * 1.7 * core, 0.0, 0.85));
	if (shard) {
		col = mix(col, vec3(0.5, 0.65, 0.85), 0.25);
	}
	// 4 specular: a rim highlight toward the top-left plus a diagonal sheen that slides with tilt.
	vec2 L = normalize(vec2(-0.5, -0.8));
	float rim_spec = pow(clamp(dot(g, L), 0.0, 1.0), 3.0) * bevel_s;
	float u = dot(UV - vec2(0.5), vec2(0.7071, -0.7071));
	float pos = clamp(tilt_deg.y / max_tilt_deg, -1.0, 1.0) * 0.32 + clamp(tilt_deg.x / max_tilt_deg, -1.0, 1.0) * 0.1 - 0.12;
	float sheen = exp(-pow((u - pos) / 0.07, 2.0)) * (1.0 - bevel_s);
	col += vec3(1.0) * (rim_spec * 0.8 + sheen * 0.3) * specular;
	// 5 edge tint: accent on the rim, stronger toward the bottom.
	float bottom = clamp(g.y, 0.0, 1.0);
	col += accent * edge_tint * bevel_s * (0.5 + 0.7 * bottom);
	float ring = smoothstep(3.0, 0.0, -d);
	col += vec3(0.7, 0.9, 1.0) * ring * 0.3;
	col = mix(col, flash_color, flash * 0.75);
	COLOR = vec4(col * unlit_gain, body.a);
}

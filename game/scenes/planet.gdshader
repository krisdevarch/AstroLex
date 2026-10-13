shader_type canvas_item;
// A flat, cartoon planet drawn on a quad (owner reference, 13 Oct 2026): a disc with bands, craters,
// continents or swirls that turn slowly, a soft shaded crescent and a small highlight. `sat`
// drains the colour for the colour story, like the backdrop.

uniform vec4 base : source_color = vec4(0.95, 0.6, 0.25, 1.0);
uniform vec4 detail : source_color = vec4(1.0, 0.75, 0.35, 1.0);
uniform vec4 shade : source_color = vec4(0.75, 0.35, 0.2, 1.0);
uniform int kind = 0; // 0 bands, 1 craters, 2 continents and clouds, 3 swirls, 4 sun
uniform vec4 ink : source_color = vec4(0.06, 0.08, 0.22, 1.0);
uniform float spin = 0.02; // turns per second of the surface pattern
uniform float seed = 0.0;
uniform float sat = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float aa = fwidth(r) * 1.5;
	float mask = 1.0 - smoothstep(1.0 - aa, 1.0, r);
	float z = sqrt(max(0.0, 1.0 - r * r));
	// Surface coordinates on the sphere; x scrolls with time so the planet turns.
	vec2 s = vec2(asin(clamp(p.x / max(sqrt(1.0 - p.y * p.y), 0.001), -1.0, 1.0)) / 3.14159 + TIME * spin + seed, p.y);
	vec3 col = base.rgb;
	if (kind == 0) {
		float wob = sin(s.x * 9.0 + s.y * 5.0) * 0.08 + noise(vec2(s.x * 3.0, s.y * 2.0)) * 0.12;
		float b = sin((s.y + wob) * 13.0);
		col = mix(col, detail.rgb, smoothstep(0.25, 0.55, b));
		col = mix(col, shade.rgb, smoothstep(0.75, 0.95, -b) * 0.6);
	} else if (kind == 1) {
		for (int i = 0; i < 7; i++) {
			float fi = float(i) + seed * 13.0;
			vec2 c = vec2(hash(vec2(fi, 1.0)) * 2.0 - 1.0, hash(vec2(fi, 2.0)) * 1.6 - 0.8);
			float cr = 0.12 + 0.18 * hash(vec2(fi, 3.0));
			vec2 d = vec2(fract(s.x * 0.5 - c.x * 0.5 + 0.5) * 2.0 - 1.0, s.y - c.y);
			float k = 1.0 - smoothstep(cr - 0.02, cr, length(d * vec2(1.6, 1.0)));
			col = mix(col, detail.rgb, k);
		}
	} else if (kind == 2) {
		float land = noise(s * vec2(6.0, 2.6)) * 0.65 + noise(s * vec2(13.0, 5.5)) * 0.35;
		col = mix(col, detail.rgb, smoothstep(0.52, 0.56, land));
		col = mix(col, vec3(1.0), smoothstep(0.82, 0.9, abs(p.y)) * 0.8);
		float cloud = noise(vec2(s.x * 7.0 - TIME * spin * 3.0, s.y * 3.5) + 7.0);
		col = mix(col, vec3(0.97, 0.98, 1.0), smoothstep(0.66, 0.7, cloud) * 0.95);
	} else if (kind == 4) {
		float m = noise(p * 2.5 + vec2(TIME * 0.15, 0.0)) * 0.6 + noise(p * 5.0 - vec2(0.0, TIME * 0.1)) * 0.4;
		col = mix(base.rgb, detail.rgb, smoothstep(0.85, 0.05, r));
		col = mix(col, shade.rgb, smoothstep(0.5, 0.75, m) * 0.25 * smoothstep(0.2, 0.7, r));
	} else {
		float sw = sin(s.x * 14.0 + sin(s.y * 6.0 + s.x * 4.0) * 2.0 + s.y * 8.0);
		col = mix(col, detail.rgb, smoothstep(0.55, 0.8, sw));
	}
	if (kind != 4) {
		// Cartoon shading: a soft darker crescent at the lower right, a small highlight at the upper left.
		float dark = smoothstep(0.35, 1.05, length(p - vec2(-0.45, -0.45)));
		col = mix(col, shade.rgb * 0.75, dark * 0.5);
		col += vec3(1.0) * (1.0 - smoothstep(0.0, 0.45, length(p - vec2(-0.42, -0.42)))) * 0.12;
		col *= 0.85 + 0.15 * z;
	}
	// Ink outline, like a sticker.
	col = mix(col, ink.rgb, smoothstep(0.935 - aa, 0.935, r));
	float g = dot(col, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(g), col, sat), mask * COLOR.a);
}

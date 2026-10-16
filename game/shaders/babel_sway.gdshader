shader_type canvas_item;
// Babel's cape and lower body sway: a horizontal UV offset that grows toward the bottom of the
// sprite (nothing moves at the head), a sine over time. Off under reduced motion (no material).
uniform float amp : hint_range(0.0, 0.2) = 0.02;
uniform float speed = 2.2;
uniform float from_y : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	float k = smoothstep(from_y, 1.0, UV.y);
	vec2 uv = UV;
	uv.x += sin(TIME * speed + UV.y * 5.0) * amp * k;
	COLOR *= texture(TEXTURE, uv);  // keeps modulate (fades, tints)
}

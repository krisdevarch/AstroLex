shader_type canvas_item;
// 2.5D letter tile body (plan 8.2): perspective tilt in the vertex stage, flash and a gain that
// cancels the ambient dimming when the tile is excluded from the visor lamp (flat treatment).
// The normal-mapped lighting itself is Godot's own (CanvasTexture + PointLight2D).

uniform vec2 tilt_deg = vec2(0.0);       // x: tip about the horizontal axis, y: about the vertical axis
uniform float depth_px = 380.0;          // perspective distance in texture pixels
uniform vec3 unlit_gain = vec3(1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec3 flash_color : source_color = vec3(0.95, 0.15, 0.1);

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
	vec4 c = texture(TEXTURE, UV);
	c.rgb *= unlit_gain;
	c.rgb = mix(c.rgb, flash_color, flash * 0.75);
	COLOR = c;
}

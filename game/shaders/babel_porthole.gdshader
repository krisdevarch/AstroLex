shader_type canvas_item;
// Babel's porthole: the sprite is clipped to a circle (in the sprite's own local pixels, so the
// mask breathes with it; the ring that covers the edge hides the difference).
uniform float radius = 220.0;
varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	if (length(lp) > radius) {
		discard;
	}
	COLOR *= texture(TEXTURE, UV);  // keeps modulate (fades, tints)
}

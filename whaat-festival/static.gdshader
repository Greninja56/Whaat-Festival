shader_type canvas_item;

uniform float brightness : hint_range(0.0, 1.0) = 0.9;
uniform float pixel_size = 2.0;                              // smaller = finer grain
uniform float contrast : hint_range(0.0, 1.0) = 0.8;         // 1 = pure black/white
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.15;
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.15;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE / pixel_size;
	vec2 cell = floor(UV * res);

	// fresh noise ~30 times a second
	float n = hash(cell + floor(TIME * 30.0));

	// horizontal tearing: some rows get shifted noise
	float row = floor(UV.y * 40.0);
	float tear = step(0.93, hash(vec2(row, floor(TIME * 12.0))));
	float shift = hash(vec2(row, floor(TIME * 25.0))) * 200.0;
	n = mix(n, hash(vec2(cell.x + shift, cell.y) + floor(TIME * 30.0)), tear);

	// push toward pure black/white
	float bw = smoothstep(0.5 - (1.0 - contrast) * 0.5, 0.5 + (1.0 - contrast) * 0.5, n);

	// slow rolling dark bar
	float roll = smoothstep(0.0, 0.2, fract(UV.y - TIME * 0.2)) * 0.35 + 0.65;

	// scanlines
	float scan = 1.0 - scanline_strength * (0.5 + 0.5 * sin(UV.y * res.y * 3.14159));

	// whole-screen flicker
	float flick = 1.0 - flicker_strength * hash(vec2(floor(TIME * 20.0), 1.0));

	float v = bw * brightness * roll * scan * flick;
	COLOR = vec4(vec3(v), 1.0);
}
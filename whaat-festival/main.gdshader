shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float edge_size : hint_range(0.001, 0.6) = 0.03;

void fragment() {
	vec2 d = min(UV, vec2(1.0) - UV);
	float edge = min(d.x, d.y);
	float a = 1.0 - smoothstep(0.0, edge_size, edge);
	COLOR = vec4(tint.rgb, a * strength);
}
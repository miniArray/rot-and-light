// Flat ground in toon bands with a faint grid, so speed and distance are easy
// to read. main.gd sets the colours from look.tres. The grid is colour only:
// the ink pass reads depth and normals, so it draws no lines on the ground.
shader_type spatial;
render_mode ambient_light_disabled, specular_disabled;

#include "res://game/toon.gdshaderinc"

uniform vec3 base_colour : source_color;
uniform vec3 line_colour : source_color;
uniform float cell_size = 2.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 cell = world_position.xz / max(cell_size, 0.01);
	vec2 distance_to_line = abs(fract(cell - 0.5) - 0.5) / fwidth(cell);
	float line = 1.0 - min(min(distance_to_line.x, distance_to_line.y), 1.0);
	ALBEDO = mix(base_colour, line_colour, line);
	EMISSION = ALBEDO * shadow_tint;
}

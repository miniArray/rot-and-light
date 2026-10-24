// A solid thing in three tone bands: crates, lamp posts, the lord, minions,
// debris, rot caps. Look.material() makes and shares these materials.
shader_type spatial;
render_mode ambient_light_disabled, specular_disabled;

#include "res://game/toon.gdshaderinc"

uniform vec3 albedo : source_color;
// Light the thing gives off by itself, on top of the bands.
uniform vec3 glow : source_color;
uniform float glow_strength;
// The colour the per-instance flash blends to, such as a crate being hit.
uniform vec3 flash_colour : source_color;
instance uniform float flash = 0.0;

void fragment() {
	vec3 colour = mix(albedo, flash_colour, flash);
	ALBEDO = colour;
	EMISSION = colour * shadow_tint + glow * glow_strength + flash_colour * flash * 0.5;
}

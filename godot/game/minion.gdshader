// A minion's stalk or cap in three tone bands, with its health states.
// Shared materials (stalk, cap) serve the whole horde; each minion sets
// its own state through instance uniforms, so the horde still batches. The
// lord's crown uses it too. A cap glows faintly all over and brightly in a
// few spots on its dome.
//
// Burning: a flickering warm rim, a warm glow over the body, and a cap that
// turns from cold glow to hot. Withering: the colour fades toward ash and the
// cap glow dies. minion.gd adds the shapes: shake and embers for burning,
// droop and shrink for withering.
shader_type spatial;
render_mode ambient_light_disabled, specular_disabled;

#include "res://game/toon.gdshaderinc"

uniform vec3 albedo : source_color;
uniform vec3 glow : source_color;
uniform float glow_strength;
uniform vec3 burn_colour : source_color;
uniform float burn_rim;
uniform float burn_body;
uniform float burn_flicker_hz;
uniform vec3 wither_colour : source_color;
uniform float wither_fade;

// 0 to 1: how much the minion burns now. Eases in and out in minion.gd.
instance uniform float burn = 0.0;
// 0 to 1: how far the minion has withered.
instance uniform float wither = 0.0;
// A per-minion offset, so the horde does not flicker in step.
instance uniform float phase = 0.0;

// Glow of the cap outside its spots, as a fraction of the spot glow.
const float CAP_BASE_GLOW = 0.12;
// Spot centres on the dome, as directions in the mesh's own space.
const vec3 SPOTS[6] = vec3[6](
	vec3(0.0, 1.0, 0.0),
	vec3(0.72, 0.62, 0.3),
	vec3(-0.55, 0.6, 0.58),
	vec3(-0.4, 0.62, -0.68),
	vec3(0.3, 0.55, -0.78),
	vec3(-0.85, 0.5, -0.1)
);

varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float grey = dot(albedo, vec3(0.3, 0.55, 0.15));
	vec3 ash = mix(vec3(grey), wither_colour, 0.6);
	vec3 colour = mix(albedo, ash, wither * wither_fade);
	// Burning chars the colour.
	colour = mix(colour, colour * 0.45, burn);
	ALBEDO = colour;

	float t = TIME * burn_flicker_hz * 6.2832 + phase;
	float flicker = 0.6 + 0.4 * sin(t) * sin(t * 1.73 + 1.1);
	float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	rim = smoothstep(0.35, 0.75, rim);
	vec3 burning = burn_colour * (burn_rim * rim + burn_body) * flicker;

	// The dome is flatter than a half sphere; undo that before the spots.
	vec3 dome = normalize(local_position * vec3(1.0, 1.6, 1.0));
	float spot = 0.0;
	for (int i = 0; i < 6; i++) {
		spot = max(spot, smoothstep(0.955, 0.97, dot(dome, normalize(SPOTS[i]))));
	}
	vec3 cap_glow = glow * glow_strength * (CAP_BASE_GLOW + spot) * (1.0 - wither) * (1.0 - burn);
	EMISSION = colour * shadow_tint + cap_glow + burning * burn;
}

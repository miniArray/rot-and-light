// Toon lighting shared by every solid thing: three tone bands from the moon,
// and a hard-edged warm band from lamps. Look.apply_bands() sets the uniforms
// from look.tres. A shader that includes this file adds the shadow band
// itself, in fragment(): EMISSION += ALBEDO * shadow_tint.
//
// The engine's ambient light is off, so the shadow band is exactly
// shadow_tint and the look file owns every tone.

uniform float band_low;
uniform float band_high;
uniform float band_mid_level;
uniform float band_softness;
uniform vec3 shadow_tint : source_color;
uniform float lamp_back_level;

// Lamp light counts on a surface while its attenuation is above this.
// Godot's omni attenuation reaches zero at the light's range, so the band
// ends at the range: OmniLight3D.omni_range is the hard edge.
const float LAMP_CUTOFF = 0.0001;

// 0 in the shadow band, band_mid_level in the middle band, 1 in the lit band.
float toon_band(float lit) {
	float w = max(band_softness, 0.0001);
	float mid = smoothstep(band_low - w, band_low + w, lit);
	float top = smoothstep(band_high - w, band_high + w, lit);
	return band_mid_level * mid + (1.0 - band_mid_level) * top;
}

void light() {
	float n_dot_l = dot(NORMAL, LIGHT);
	if (LIGHT_IS_DIRECTIONAL) {
		// ATTENUATION holds the moon's shadow, so cast shadows band too.
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * toon_band(clamp(n_dot_l, 0.0, 1.0) * ATTENUATION);
	} else {
		float inside = step(LAMP_CUTOFF, ATTENUATION);
		float side = mix(lamp_back_level, 1.0, step(0.0, n_dot_l));
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * inside * side;
	}
}

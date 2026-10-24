// Rot on the ground where a lamp went out: a mottled carpet in two cold
// colours with a ragged, creeping edge, glowing spore specks that pulse,
// and a faint glowing seam along the edge. rot.gd draws it on a PlaneMesh
// centred on the patch and sets the colours from look.tres.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 deep : source_color;
uniform vec3 bloom : source_color;
uniform vec3 speck : source_color;
uniform float speck_strength;
uniform float radius = 5.0;
uniform float seed = 0.0;

varying vec2 local_xz;

void vertex() {
	local_xz = VERTEX.xz;
}

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 p = local_xz;
	float d = length(p);
	// The edge creeps out in lobes, so the patch is not a clean disc. Noise
	// on the unit circle has no seam where the angle wraps.
	vec2 direction = p / max(d, 0.0001);
	float lobes = noise(direction * 1.8 + seed) * 0.6 + noise(direction * 4.5 + seed + 3.0) * 0.4;
	float edge = radius * (0.9 + 0.14 * lobes);
	float soft = max(fwidth(d), 0.02);
	float inside = 1.0 - smoothstep(edge - soft, edge + soft, d);

	// Mottled carpet, cut into three flat tones like the toon bands.
	float n = noise(p * 0.7 + seed) * 0.65 + noise(p * 2.1 - seed) * 0.35;
	float tone = floor(n * 3.0) / 2.0;
	vec3 colour = mix(deep, bloom, tone * 0.85);

	// Spore specks: at most one per cell, and only in some cells.
	vec2 cell = floor(p * 1.4);
	vec2 centre = (cell + 0.2 + 0.6 * vec2(hash(cell + seed), hash(cell + seed + 7.0))) / 1.4;
	float lucky = step(0.55, hash(cell * 1.7 + seed));
	float dot_size = 0.05 + 0.04 * hash(cell + 3.0);
	float speck_on = lucky * (1.0 - smoothstep(dot_size, dot_size + soft, length(p - centre)));
	float pulse = 0.6 + 0.4 * sin(TIME * 1.7 + hash(cell) * 6.2832);

	// A thin seam that glows where the rot meets the ground.
	float seam = smoothstep(edge - 0.25, edge - 0.05, d) * inside;

	ALBEDO = colour + speck * speck_strength * (speck_on * pulse + seam * 0.35);
	ALPHA = inside * 0.94;
}

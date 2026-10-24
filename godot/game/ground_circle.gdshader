// A flat circle on the ground: a fill and an edge band, with a set softness.
// Lamp light uses a hard, bright edge; the spore cloud a soft one. Draw it on
// a PlaneMesh centred on the node, at least 2 * radius across.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 colour : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 edge_colour : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float radius = 5.0;
uniform float fill_alpha = 0.3;
uniform float edge_alpha = 0.9;
uniform float edge_width = 0.1;
// Half-width of the fade at the outer edge, metres. Never below one pixel.
uniform float softness = 0.02;

varying vec2 local_xz;

void vertex() {
	local_xz = VERTEX.xz;
}

void fragment() {
	float d = length(local_xz);
	float soft = max(softness, fwidth(d));
	float inside = 1.0 - smoothstep(radius - soft, radius + soft, d);
	float edge = inside * smoothstep(radius - edge_width - soft, radius - edge_width + soft, d);
	ALBEDO = mix(colour.rgb, edge_colour.rgb, edge);
	ALPHA = mix(colour.a * fill_alpha * inside, edge_colour.a * edge_alpha, edge);
}

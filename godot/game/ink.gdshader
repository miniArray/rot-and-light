// Ink outlines for the whole scene in one screen-space pass. ink.gd draws it
// on a quad that covers the screen, after everything else. Its cost depends
// on the screen size only, not on how many minions are on it.
//
// Depth lines (both renderers): with reverse Z, the raw depth of a flat
// surface changes linearly across the screen. A pixel whose depth sits in
// front of the line through its two neighbours, by more than
// depth_threshold of its own depth, is on the near side of an edge. Only the
// near side draws, so an edge gets one line, not two, and flat ground at any
// angle draws nothing.
//
// Crease lines (Forward+ only): a bend sharper than crease_cos between this
// pixel and its right or upper neighbour, on the same surface (no depth
// step), draws a line. The Mobile renderer has no normal-roughness buffer,
// so there it draws depth lines only.
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;
#if CURRENT_RENDERER == RENDERER_FORWARD_PLUS
uniform sampler2D normal_texture : hint_normal_roughness_texture, filter_nearest, repeat_disable;
#endif

uniform vec4 ink_colour : source_color;
// Line width in pixels on a 1080-pixel-high screen.
uniform float ink_width;
uniform float depth_threshold;
uniform float crease_cos;
uniform float fade_start;
uniform float fade_end;

void vertex() {
	// Cover the screen at the near plane, whatever the camera does.
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float depth_at(vec2 uv) {
	return texture(depth_texture, uv).r;
}

// How far this pixel stands in front of the line through a and b, as a
// fraction of its own depth. Positive on the near side of an edge.
float step_out(float centre, float a, float b) {
	return (2.0 * centre - a - b) / centre;
}

#if CURRENT_RENDERER == RENDERER_FORWARD_PLUS
vec3 normal_at(vec2 uv) {
	return normalize(texture(normal_texture, uv).xyz * 2.0 - 1.0);
}
#endif

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 offset = vec2(ink_width * VIEWPORT_SIZE.y / 1080.0) / VIEWPORT_SIZE;
	float centre = depth_at(uv);
	float line = 0.0;
	// Depth 0 is the sky: no line there.
	if (centre > 0.0) {
		float left = depth_at(uv - vec2(offset.x, 0.0));
		float right = depth_at(uv + vec2(offset.x, 0.0));
		float down = depth_at(uv - vec2(0.0, offset.y));
		float up = depth_at(uv + vec2(0.0, offset.y));
		float out_x = step_out(centre, left, right);
		float out_y = step_out(centre, down, up);
		line = smoothstep(depth_threshold, depth_threshold * 1.6, max(out_x, out_y));

#if CURRENT_RENDERER == RENDERER_FORWARD_PLUS
		vec3 n = normal_at(uv);
		// Same surface: the neighbour's depth is close to this pixel's.
		float same_r = step(abs(right - centre) / centre, depth_threshold);
		float same_u = step(abs(up - centre) / centre, depth_threshold);
		float bend_r = 1.0 - smoothstep(crease_cos - 0.05, crease_cos, dot(n, normal_at(uv + vec2(offset.x, 0.0))));
		float bend_u = 1.0 - smoothstep(crease_cos - 0.05, crease_cos, dot(n, normal_at(uv + vec2(0.0, offset.y))));
		line = max(line, max(bend_r * same_r, bend_u * same_u));
#endif

		vec4 view = INV_PROJECTION_MATRIX * vec4(uv * 2.0 - 1.0, centre, 1.0);
		float distance = -view.z / view.w;
		line *= 1.0 - smoothstep(fade_start, fade_end, distance);
	}
	ALBEDO = ink_colour.rgb;
	ALPHA = ink_colour.a * line;
}

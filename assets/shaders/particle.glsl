#ifdef VERTEX
	uniform vec3 u_position;
	uniform mat4 u_view, u_projection;

	vec4 position(mat4 mvp, vec4 v_position) {
		mat4 model = mat4(1.0);
		model[3][0] = u_position.x;
		model[3][1] = u_position.y;
		model[3][2] = u_position.z;

		mat4 mv = u_view * model;
		mv[0][0] = 1.0;
		mv[0][1] = 0.0;
		mv[0][2] = 0.0;

		// ignore this part for cylindrical objects
		mv[1][0] = 0.0;
		mv[1][1] = 1.0;
		mv[1][2] = 0.0;

		mv[2][0] = 0.0;
		mv[2][1] = 0.0;
		mv[2][2] = 1.0;

		return u_projection * mv * v_position;
	}
#endif

#ifdef PIXEL
uniform vec2 u_clips;
uniform vec3 u_fog_color;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
	float depth = 1.0 / gl_FragCoord.w;
	float scaled = (depth - u_clips.x) / (u_clips.y - u_clips.x);
	scaled = pow(scaled, 1.0);

	vec4 out_color = texture2D(texture, texture_coords) * color;

	return vec4(mix(out_color.rgb, u_fog_color.rgb, min(scaled, 1.0)), out_color.a);
}
#endif

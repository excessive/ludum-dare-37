varying vec3 f_normal;

#ifdef VERTEX
	uniform mat4 u_view, u_projection;

	vec4 position(mat4 mvp, vec4 v_position) {
		vec4 position = u_projection * u_view * v_position;
		position.z = 1.0;

		f_normal = normalize(v_position.xyz);

		return position;
	}
#endif

#ifdef PIXEL
	uniform vec3 u_light_direction = vec3(0.3, 0.0, 0.7);
	uniform vec3 u_fog_color;
	uniform vec2 u_clips;

	const vec4 sun_color = vec4(3.0, 2.6, 2.2, 1.0);

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
		if (dot(u_light_direction, normalize(f_normal)) > 0.9) {
			return sun_color;
		}

	//float depth = 1.0 / gl_FragCoord.w;
	float depth = 120.0;
	float scaled = (depth - u_clips.x) / (u_clips.y - u_clips.x);
	scaled = pow(scaled, 3.0);

	vec4 out_color = texture2D(texture, texture_coords) * color;

	return vec4(mix(out_color.rgb, u_fog_color.rgb, min(scaled, 1.0)), out_color.a);
	}
#endif

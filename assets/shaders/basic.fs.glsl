varying vec3 f_normal;
varying vec3 f_view_normal;
varying vec4 f_shadow_coords;

uniform vec3 u_light_direction;
uniform vec3 u_light_color;
uniform vec3 u_fog_color;

uniform vec2 u_clips;

uniform sampler2DShadow u_shadow_texture;

// http://prideout.net/blog/?p=22
float stepmix(float edge0, float edge1, float E, float x) {
	float T = clamp(0.5 * (x - edge0 + E) / E, 0.0, 1.0);
	return mix(edge0, edge1, T);
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
	vec3 light = normalize(u_light_direction);
	vec3 normal = normalize(f_normal);
	float df = max(dot(normal, light), 0.0);

	const float A = 0.125;
	const float B = 0.25;
	const float C = 0.75;
	const float D = 1.0;
	float E = fwidth(df);

	if      (df > A - E && df < A + E) df = stepmix(A, B, E, df);
	else if (df > B - E && df < B + E) df = stepmix(B, C, E, df);
	else if (df > C - E && df < C + E) df = stepmix(C, D, E, df);
	else if (df < A) df = 0.0;
	else if (df < B) df = B;
	else if (df < C) df = C;
	else df = D;

	float shade = df + pow(dot(vec3(0.0, 0.0, -1.0), normalize(f_view_normal)) * 0.5 + 0.5, 2.0);
	shade = shade * 0.5 + 0.5;
	shade = pow(shade, 3.0);

	float illuminated = shadow2DProj(u_shadow_texture, f_shadow_coords).z;
	// diff *= illuminated;
	// spec *= illuminated;
	shade *= illuminated;

	vec4 ambient;
	vec3 top = vec3(0.0, 0.2, 1.0);
	vec3 bottom = vec3(0.0, 0.0, 0.0);
	ambient.rgb = mix(top, bottom, dot(f_normal, vec3(0.0, 0.0, -1.0)) * 0.5 + 0.5);
	ambient.rgb *= 0.05;
	ambient.a = 0.0;
	vec4 diffuse = Texel(tex, uv) * color * vec4(vec3(shade), 1.0);
	diffuse.rgb *= u_light_color;

	float depth = 1.0 / gl_FragCoord.w;
	float scaled = (depth - u_clips.x) / (u_clips.y - u_clips.x);
	scaled = pow(scaled, 1.6);

	vec4 out_color = diffuse + ambient;

	return vec4(mix(out_color.rgb, u_fog_color.rgb, min(scaled, 1.0)), out_color.a);
}

attribute vec3 VertexNormal;

varying vec3 f_normal;
varying vec3 f_view_normal;
varying vec4 f_shadow_coords;

uniform mat4 u_model, u_view, u_projection;
uniform mat4 u_shadow_vp;

vec4 position(mat4 _, vec4 vertex) {
	f_normal = mat3(u_model) * VertexNormal;
	f_view_normal = mat3(u_view * u_model) * VertexNormal;
	f_shadow_coords = u_shadow_vp * u_model * vertex;

	return u_projection * u_view * u_model * vertex;
}

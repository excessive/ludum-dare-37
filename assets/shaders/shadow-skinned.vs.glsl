#ifdef VERTEX // DO NOT REMOVE
varying vec4 VaryingColor;
varying vec4 VaryingTexCoord;

attribute vec4 VertexPosition;
attribute vec4 VertexWeight;
attribute vec4 VertexBone;

uniform mat4 u_view, u_model, u_projection;
uniform mat4 u_pose[100];

mat4 getDeformMatrix() {
	// *255 because byte data is normalized against our will.
	return
		u_pose[int(VertexBone.x*255.0)] * VertexWeight.x +
		u_pose[int(VertexBone.y*255.0)] * VertexWeight.y +
		u_pose[int(VertexBone.z*255.0)] * VertexWeight.z +
		u_pose[int(VertexBone.w*255.0)] * VertexWeight.w;
}

void main() {
	VaryingColor    = vec4(1.0);
	VaryingTexCoord = vec4(0.0);
	gl_Position = u_projection * u_view * u_model * getDeformMatrix() * VertexPosition;
}
#endif

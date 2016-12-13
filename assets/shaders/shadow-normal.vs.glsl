#ifdef VERTEX // DO NOT REMOVE
varying vec4 VaryingColor;
varying vec4 VaryingTexCoord;

attribute vec4 VertexPosition;
attribute vec4 VertexWeight;
attribute vec4 VertexBone;

uniform mat4 u_view, u_model, u_projection;

void main() {
	VaryingColor    = vec4(1.0);
	VaryingTexCoord = vec4(0.0);
	gl_Position = u_projection * u_view * u_model * VertexPosition;
}
#endif

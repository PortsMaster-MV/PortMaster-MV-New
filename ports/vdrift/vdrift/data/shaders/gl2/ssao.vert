#if __VERSION__ > 120
#define attribute in
#define varying out
#endif

uniform mat4 ModelViewProjMatrix;
uniform vec3 frustum_corner_bl;
uniform vec3 frustum_corner_br_delta;
uniform vec3 frustum_corner_tl_delta;
uniform float znear;

attribute vec3 VertexPosition;
attribute vec2 VertexTexCoord;

varying vec3 eyespace_view_direction;
varying float q;  // equivalent to ProjectionMatrix[2].z
varying float qn; // equivalent to ProjectionMatrix[3].z

void main()
{
	gl_Position = ModelViewProjMatrix * vec4(VertexPosition, 1.0);

	vec3 viewdir = frustum_corner_bl
		+ frustum_corner_br_delta * VertexTexCoord.x
		+ frustum_corner_tl_delta * VertexTexCoord.y;

	eyespace_view_direction = viewdir;

	float zfar = -viewdir.z;
	float depth = zfar - znear;
	q = -(zfar + znear) / depth;
	qn = -2.0 * (zfar * znear) / depth;
}

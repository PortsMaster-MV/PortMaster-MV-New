#if __VERSION__ > 120
#define attribute in
#define varying out
#endif

uniform mat4 ModelViewProjMatrix;
uniform mat4 ModelViewMatrix;
#ifdef _INITIAL_
uniform vec3 frustum_corner_bl;
uniform vec3 frustum_corner_br_delta;
uniform vec3 frustum_corner_tl_delta;
#endif

attribute vec3 VertexPosition;
attribute vec2 VertexTexCoord;

varying vec2 texcoord;
varying vec3 eyespace_view_direction;

void main()
{
	#ifdef _INITIAL_
	vec3 viewdir = frustum_corner_bl
		+ frustum_corner_br_delta * VertexTexCoord.x
		+ frustum_corner_tl_delta * VertexTexCoord.y;
	eyespace_view_direction = viewdir;
	#else
	eyespace_view_direction = vec3(ModelViewMatrix * vec4(VertexPosition, 1.0));
	#endif

	texcoord = VertexTexCoord;

	gl_Position = ModelViewProjMatrix * vec4(VertexPosition, 1.0);
}

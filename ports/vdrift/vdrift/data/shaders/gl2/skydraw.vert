#if __VERSION__ > 120
#define attribute in
#define varying out
#endif

uniform mat4 ModelViewProjMatrix;

attribute vec3 VertexPosition;
attribute vec3 VertexTangent;

varying vec3 view_direction;

void main(void)
{
	gl_Position = ModelViewProjMatrix * vec4(VertexPosition, 1.0);

	view_direction = VertexTangent;
}

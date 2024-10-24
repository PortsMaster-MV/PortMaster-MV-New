#if __VERSION__ > 120
#define attribute in
#define varying out
#endif

uniform mat4 ModelViewProjMatrix;
uniform mat4 ModelViewMatrix;

attribute vec3 VertexPosition;
attribute vec3 VertexNormal;
attribute vec2 VertexTexCoord;

varying vec2 texcoord;
varying vec3 ecposition;
varying vec3 normal_eye;

void main()
{
	gl_Position = ModelViewProjMatrix * vec4(VertexPosition, 1.0);

	normal_eye = vec3(ModelViewMatrix * vec4(VertexNormal, 0.0));

	ecposition = VertexPosition;

	texcoord = VertexTexCoord;
}

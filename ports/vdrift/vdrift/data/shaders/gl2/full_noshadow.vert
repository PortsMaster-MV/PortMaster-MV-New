#if __VERSION__ > 120
#define attribute in
#define varying out
#endif

uniform mat4 ModelViewProjMatrix;
uniform mat4 ModelViewMatrix;

attribute vec3 VertexPosition;
attribute vec3 VertexNormal;
attribute vec2 VertexTexCoord;

varying vec2 texcoord_2d;
varying vec3 normal_eye;
varying vec3 viewdir;

void main()
{
	//set the texture coordinates
	texcoord_2d = VertexTexCoord;
	
	//compute the eyespace normal (assuming no non-uniform scale)
	normal_eye = vec3(ModelViewMatrix * vec4(VertexNormal, 0.0));
	
	//compute the eyespace position
	vec4 ecposition = ModelViewMatrix * vec4(VertexPosition, 1.0);
	
	//compute the eyespace view direction
	viewdir = vec3(ecposition) / ecposition.w;
	
	//transform the vertex
	gl_Position = ModelViewProjMatrix * vec4(VertexPosition, 1.0);
}

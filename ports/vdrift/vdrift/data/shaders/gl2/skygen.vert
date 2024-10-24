#if __VERSION__ > 120
#define attribute in
#define varying out
#endif

attribute vec3 VertexPosition;
attribute vec3 VertexTexCoord;

varying vec3 vViewDirection;

void main(void)
{
	gl_Position = vec4(VertexPosition, 1.0);

   	vViewDirection = VertexTexCoord;
}

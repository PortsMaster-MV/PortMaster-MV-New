#if __VERSION__ > 120
#define texture2D texture
#define texture2DRect texture
#define textureCube texture
#define varying in
#define OUT(x) out x;
#else
#define FragColor gl_FragColor
#define FragData0 gl_FragData[0]
#define FragData1 gl_FragData[1]
#define FragData2 gl_FragData[2]
#define OUT(x)
#endif

uniform sampler2D tu0_2D;
//uniform float depthoffset;

varying vec2 texcoord;
varying vec3 eyespacenormal;
//varying float lightdotnorm;

OUT(vec4 FragColor)

void main()
{
	//float depthoffset = mix(0.01,0.0001,eyespacenormal.z*eyespacenormal.z);
	//float depthoffset = mix(0.005,0.001,eyespacenormal.z);
	
	gl_FragDepth = gl_FragCoord.z;
	vec4 tu0color = texture2D(tu0_2D, texcoord);
	FragColor = tu0color;
	
	//gl_FragDepth = gl_FragCoord.z + mix(0.007,0.0009,lightdotnorm);
	//gl_FragDepth = gl_FragCoord.z + mix(0.0009,0.007,lightdotnorm);
}

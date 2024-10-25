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

//varying float lightdotnorm;
varying vec2 texcoord;
varying vec3 eyespacenormal;

OUT(vec4 FragColor)

void main()
{
	//float depthoffset = mix(0.01,0.0001,eyespacenormal.z*eyespacenormal.z);
	//float depthoffset = mix(0.005,0.001,eyespacenormal.z);
	
#ifdef _SHADOWSLOW_
	//float depthoffset = mix(0.01,0.002,eyespacenormal.z);
	float depthoffset = mix(0.005,0.001,eyespacenormal.z);
#else
#ifdef _SHADOWSMEDIUM_
	float depthoffset = mix(0.00375,0.00075,eyespacenormal.z);
#else
	float depthoffset = mix(0.0025,0.0005,eyespacenormal.z);
#endif
#endif
	//depthoffset = 0.005;
	//FragColor = vec4(1);
	vec4 tu0color = texture2D(tu0_2D, texcoord);
	#ifdef _ALPHATEST_
	if (tu0color.a < 0.5)
		discard; //emulate alpha testing
	#endif
	gl_FragDepth = gl_FragCoord.z+depthoffset;
	FragColor = vec4(1,1,1,1);
	
	//gl_FragDepth = gl_FragCoord.z + mix(0.007,0.0009,lightdotnorm);
	//gl_FragDepth = gl_FragCoord.z + mix(0.0009,0.007,lightdotnorm);
}

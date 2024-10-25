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

//uniform float depthoffset;
//uniform sampler2D tu0_2D;

//varying float lightdotnorm;

OUT(vec4 FragColor)

vec4 packFloatToVec4i(const float value)
{
	vec4 bitSh = vec4(256.0 * 256.0 * 256.0, 256.0 * 256.0, 256.0, 1.0);
	vec4 bitMsk = vec4(0.0, 1.0 / 256.0, 1.0 / 256.0, 1.0 / 256.0);
	vec4 res = fract(value * bitSh);
	res -= res.xxyz * bitMsk;
	return res;
}

vec3 packFloatToVec3i(const float value)
{
	vec3 bitSh = vec3(256.0*256.0, 256.0, 1.0);
	vec3 res = fract(value * bitSh);
	vec3 bitMsk = vec3(0.0, 1.0/256.0, 1.0/256.0);
	return res - res.xxy * bitMsk;
	//return res;
}

/*vec4 packFloatToVec4i(const float value)
{
	vec4 bitSh = vec4(256.0 * 256.0 * 256.0, 256.0 * 256.0, 256.0, 1.0);
	return value * bitSh;
}*/

/*vec2 packFloatToVec2i(const float value)
{
	vec2 bitSh = vec2(256.0, 1.0);
	vec2 bitMsk = vec2(0.0, 1.0/256.0);
	vec2 res = fract(value * bitSh);
	res -= res.xx * bitMsk;
	return res;
}*/

vec2 packFloatToVec2i(const float value)
{
	/*float val256 = value*256.0;
	float bigpart = floor(val256);
	float smallpart = floor(fract(val256-bigpart)*256.0);
	return vec2(smallpart/256.0,bigpart/256.0);*/
	
	float val = clamp(value,0.0,1.0);
	float smallpart = mod(val,1.0/256.0);
	return vec2(smallpart*256.0,val-smallpart);
}

void main()
{
	//float depthoffset = mix(0.01,0.0001,eyespacenormal.z*eyespacenormal.z);
	//float depthoffset = mix(0.005,0.001,eyespacenormal.z);
	//float depthoffset = mix(0.0025,0.0005,eyespacenormal.z);
	float depthoffset = 0.0025;
	
#ifdef _SHADOWSULTRA_
	//FragColor = packFloatToVec4i(gl_FragCoord.z+depthoffset);
	//FragColor = vec4(packFloatToVec3i(gl_FragCoord.z+depthoffset),1.0);
	float valtopack = gl_FragCoord.z+depthoffset;
	if (valtopack < 0.5+1.5/256.0) valtopack -= 1.0/256.0; //fix for bug on my nvidia 7900GT
	FragColor = vec4(packFloatToVec3i(valtopack),1.0);
	//FragColor = vec4(vec3(gl_FragCoord.z+depthoffset),1.0);
	//FragColor = vec4(packFloatToVec2i(gl_FragCoord.z),0.0,1.0);
#else
	gl_FragDepth = gl_FragCoord.z+depthoffset;
	//vec4 tu0color = texture2D(tu0_2D, texcoord);
	//FragColor = tu0color;
#endif
	
	//gl_FragDepth = gl_FragCoord.z + mix(0.007,0.0009,lightdotnorm);
	//gl_FragDepth = gl_FragCoord.z + mix(0.0009,0.007,lightdotnorm);
}

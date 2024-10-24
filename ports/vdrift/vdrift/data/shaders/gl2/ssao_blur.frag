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
varying vec2 texcoord;

OUT(vec4 FragColor)

//#define RESOLUTION 512.0

void main()
{
	const vec2 pixelsize = vec2(1.0/SCREENRESX,1.0/SCREENRESY);
	
	vec2 tc = texcoord;
	
	vec3 final = vec3(0.0, 0.0, 0.0);
	
	vec2 offsets[4];
	offsets[0] = vec2(0.0,0.0);
	offsets[1] = vec2(0.0,1.0);
	offsets[2] = vec2(1.0,0.0);
	offsets[3] = vec2(1.0,1.0);
	
	for (int i = 0; i < 4; i++)
		final += texture2D(tu0_2D, tc + offsets[i]*pixelsize).rgb;
	final *= 0.25;
	
	FragColor = vec4(final,1.0);
	
	//FragColor = texture2D(tu0_2D,tc);
}

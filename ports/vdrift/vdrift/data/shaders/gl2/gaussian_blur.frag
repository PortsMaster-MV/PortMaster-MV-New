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
	vec2 res = vec2(SCREENRESX,SCREENRESY);
	
	vec2 tc = texcoord;
	
	vec3 final = vec3(0.0, 0.0, 0.0);
	
	vec2 direction = vec2(1.,0.);
	float pixelsize = 1.0/res.x;
	
#ifdef _VERTICAL_
	direction = vec2(0.,1.);
	pixelsize = 1.0/res.y;
#endif
	
	/*//big kernel box filter
	const int num_samples = 9;
	for (int i = 0; i < num_samples; i++)
		final += texture2D(tu0_2D, tc + direction*(float(i*2)-float(num_samples)+1.5)*pixelsize ).rgb;
	final /= float(num_samples);*/
	
	float weights[5];
	weights[0] = 0.08167442;
	weights[1] = 0.10164545;
	weights[2] = 0.11883558;
	weights[3] = 0.13051535;
	weights[4] = 0.13465835;
	
	for (int i = 0; i < 5; i++)
		final += weights[i] * texture2D(tu0_2D, tc + direction*float(i-4)*pixelsize ).rgb; //pixels -4 to 0
	
	for (int i = 3; i >= 0; i--)
		final += weights[i] * texture2D(tu0_2D, tc + direction*float(3-i+1)*pixelsize ).rgb; //pixels +1 to +4
	
	FragColor = vec4(final,1.0);
	
	//FragColor = texture2D(tu0_2D,tc);
}

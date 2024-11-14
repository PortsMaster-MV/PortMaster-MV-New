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
uniform vec4 color_tint;

varying vec2 texcoord;

OUT(vec4 FragColor)

void main()
{
	vec4 texcolor = texture2D(tu0_2D, texcoord);
	texcolor.rgb *= color_tint.rgb;
	float distanceFactor = texcolor.a;
	
	//anti-aliasing
	float width = dFdx(texcoord.x) * 70.0;
	texcolor.a = smoothstep(0.5-width, 0.5+width, texcolor.a);
	
	/*//outline calculation
	const vec4 outlineColour = vec4(0, 0, 1, 1);
	const float OUTLINE_MIN_0 = 0.4;
	const float OUTLINE_MIN_1 = OUTLINE_MIN_0 + width * 2.0;
	const float OUTLINE_MAX_0 = 0.5;
	const float OUTLINE_MAX_1 = OUTLINE_MAX_0 + width * 2.0;
	if (distanceFactor > OUTLINE_MIN_0 && distanceFactor < OUTLINE_MAX_1)
	{
		float outlineAlpha;
		if (distanceFactor < OUTLINE_MIN_1)
			outlineAlpha = smoothstep(OUTLINE_MIN_0, OUTLINE_MIN_1, distanceFactor);
		else
			outlineAlpha = smoothstep(OUTLINE_MAX_1, OUTLINE_MAX_0, distanceFactor);
			
		texcolor = mix(texcolor, outlineColour, outlineAlpha);
	}*/
	
	/*//shadow / glow calculation
	const vec2 GLOW_UV_OFFSET = vec2(-0.004, -0.004);
	const vec3 glowColour = vec3(0, 0, 0);
	float glowDistance = texture2D(tu0_2D, texcoord + GLOW_UV_OFFSET).a;
	float glowFactor = smoothstep(0.3, 0.5, glowDistance);
	texcolor = mix(vec4(glowColour, glowFactor), texcolor, texcolor.a);*/
	
	float glowFactor = smoothstep(0.0, 1.0, distanceFactor);
	texcolor = mix(vec4(0.0, 0.0, 0.0, glowFactor), texcolor, texcolor.a);
	
	texcolor.a *= color_tint.a;
	
	FragColor = vec4(texcolor.rgb,texcolor.a);
    //FragColor = vec4(texcolor.rgb*color_tint.a,texcolor.a);
    //FragColor = vec4(texcolor.rgb*texcolor.a,texcolor.a);
	
	//FragColor = texture2D(tu0_2D, texcoord);
	
	//FragColor.rg = texcoord*0.5+0.5;
	//FragColor.ba = vec2(1.0);
}

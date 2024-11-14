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

uniform samplerCube tu0_cube;
uniform vec4 color_tint;

varying vec3 texcoord;

OUT(vec4 FragColor)

void main()
{
	// Setting Each Pixel To Red
	//FragColor = vec4(1.0, 0.0, 0.0, 1.0);
	
	//vec4 incol = texture2D(tu0_2D, texcoord);
	//vec4 outcol = 1.0/(1.0+pow(2.718,-(incol*6.0-3.0)));
	
	vec4 outcol = textureCube(tu0_cube, texcoord);
	
    FragColor = vec4(outcol.rgb*color_tint.rgb,outcol.a*color_tint.a);
	//FragColor = vec4(outcol.rgb*color_tint.rgb*outcol.a*color_tint.a,outcol.a*color_tint.a);
    //FragColor = vec4(outcol.rgb*color_tint.rgb*color_tint.a,outcol.a*color_tint.a);
	//FragColor = bicubic_filter(tu0_2D, texcoord)*color_tint;
	
	//FragColor.rg = texcoord*0.5+0.5;
	//FragColor.ba = vec2(1.0);
	
	//FragColor = vec4(texcoord.r, texcoord.g, texcoord.b, 1);
}

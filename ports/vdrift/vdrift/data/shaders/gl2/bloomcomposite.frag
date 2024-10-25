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

#extension GL_ARB_texture_rectangle : enable

uniform sampler2DRect tu0_2DRect;
uniform sampler2D tu1_2D;

varying vec2 texcoord;

OUT(vec4 FragColor)

void main()
{
	vec4 tu0_2D_val = texture2DRect(tu0_2DRect, gl_FragCoord.xy);
	vec4 tu1_2D_val = texture2D(tu1_2D, texcoord);
	
	vec3 orig = tu0_2D_val.rgb;
	vec3 blurred = tu1_2D_val.rgb;
	
	vec3 final = orig + blurred*0.25;
	//vec3 final = pow(orig + blurred,vec3(2.0));
	//vec3 final = blurred;
	//vec3 final = mix(orig,orig*blurred,0.25)*1.0;
	//vec3 final = max(blurred,orig);
	
	/*const float onethird = 1./3.;
	float orig_luminance = dot(vec3(onethird),orig);
	vec3 final = orig + mix(blurred, vec3(0.), orig_luminance);*/
	
	//vec3 final = orig * blurred;
	/*float blurred_grey = (blurred.r*0.25+blurred.g*0.5+blurred.b*0.25)*0.8+0.2;
	blurred = vec3(blurred_grey,blurred_grey,blurred_grey);
	vec3 final = orig*(orig + 2.0*blurred*(1.0-orig)); //"OVERLAY"*/
	//vec3 final = blurred;
	//vec3 final = orig*(orig + 2.0*blurred*(1.0-orig));
	
	FragColor = vec4(final,1.);
	//FragColor = texture2DRect(tu0_2DRect, gl_FragCoord.xy);
}

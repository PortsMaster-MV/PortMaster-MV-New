#if __VERSION__ > 120
#define shadow2D texture
#define texture2D texture
#define texture2DRect texture
#define textureCube texture
#define varying in
#define OUT(x) out x;
#else
#define shadow2D(s, t) shadow2D(s, t).r
#define FragColor gl_FragColor
#define FragData0 gl_FragData[0]
#define FragData1 gl_FragData[1]
#define FragData2 gl_FragData[2]
#define OUT(x)
#endif

uniform sampler2D tu0_2D;
uniform vec3 light_direction;
uniform vec4 color_tint;
uniform float contrast;

#ifdef _EDGECONTRASTENHANCEMENT_
uniform sampler2DShadow tu9_2D; //edge contrast enhancement depth map
#endif

varying vec3 ecposition;
varying vec2 texcoord;
varying vec3 normal_eye;

OUT(vec4 FragColor)

/*float w0(float a)
{
	return (1.0/6.0)*(-a*a*a+3.0*a*a-3.0*a+1.0);
}

float w1(float a)
{
	return (1.0/6.0)*(3.0*a*a*a-6.0*a*a+4.0);
}

float w2(float a)
{
	return (1.0/6.0)*(-3.0*a*a*a+3.0*a*a+3.0*a+1.0);
}

float w3(float a)
{
	return (1.0/6.0)*(a*a*a);
}

vec4 hglookup(float x)
{
	float g0 = w0(x) + w1(x);
	float g1 = w2(x) + w3(x);
	float h0 = 1.0 - w1(x)/(w0(x)+w1(x))+x;
	float h1 = 1.0 + w3(x)/(w2(x)+w3(x))-x;
	
	return vec4(h0,h1,g0,g1);
}

vec4 bicubic_filter(sampler2D tex_source, vec2 coord_source)
{
	//texel sizes
	vec2 e_x = vec2(dFdx(coord_source.x),0.0);
	vec2 e_y = vec2(0.0,dFdy(coord_source.y));
	
	//vec2 coord_hg = coord_source*256.0 - vec2(0.5,0.5);
	vec2 coord_hg = coord_source;
	
	//fetch offsets and weights
	vec3 hg_x = hglookup(coord_hg.x).rgb;
	vec3 hg_y = hglookup(coord_hg.y).rgb;
	
	//determine sampling coordinates
	vec2 coord_source10 = coord_source + hg_x.x*e_x;
	vec2 coord_source00 = coord_source - hg_x.y*e_x;
	vec2 coord_source11 = coord_source10 + hg_y.x*e_y;
	vec2 coord_source01 = coord_source00 + hg_y.x*e_y;
	coord_source10 = coord_source10 - hg_y.y*e_y;
	coord_source00 = coord_source00 - hg_y.y*e_y;
	
	//fetch four linearly interpolated inputs
	vec4 tex_source00 = texture2D(tex_source, coord_source00);
	vec4 tex_source10 = texture2D(tex_source, coord_source10);
	vec4 tex_source01 = texture2D(tex_source, coord_source01);
	vec4 tex_source11 = texture2D(tex_source, coord_source11);
	
	//weight along y direction
	tex_source00 = mix(tex_source00, tex_source01, hg_y.z);
	tex_source10 = mix(tex_source10, tex_source11, hg_y.z);
	
	//weight along x direction
	tex_source00 = mix(tex_source00, tex_source10, hg_x.z);
	
	return tex_source00;
}*/

#ifdef _EDGECONTRASTENHANCEMENT_
float GetEdgeContrastEnhancementFactor(in sampler2DShadow tu, in vec3 coords)
{
	vec2 poissonDisk[16];
	poissonDisk[0] = vec2( -0.94201624, -0.39906216 );
	poissonDisk[1] = vec2( 0.94558609, -0.76890725 );
	poissonDisk[2] = vec2( -0.094184101, -0.92938870 );
	poissonDisk[3] = vec2( 0.34495938, 0.29387760 );
	poissonDisk[4] = vec2( -0.91588581, 0.45771432 );
	poissonDisk[5] = vec2( -0.81544232, -0.87912464 );
	poissonDisk[6] = vec2( -0.38277543, 0.27676845 );
	poissonDisk[7] = vec2( 0.97484398, 0.75648379 );
	poissonDisk[8] = vec2( 0.44323325, -0.97511554 );
	poissonDisk[9] = vec2( 0.53742981, -0.47373420 );
	poissonDisk[10] = vec2( -0.26496911, -0.41893023 );
	poissonDisk[11] = vec2( 0.79197514, 0.19090188 );
	poissonDisk[12] = vec2( -0.24188840, 0.99706507 );
	poissonDisk[13] = vec2( -0.81409955, 0.91437590 );
	poissonDisk[14] = vec2( 0.19984126, 0.78641367 );
	poissonDisk[15] = vec2( 0.14383161, -0.14100790 );
	
	float factor = 0.0;
	float radius = 3.0/1024.0;
	for (int i = 0; i < 8; i++)
		factor += shadow2D(tu,coords + radius*vec3(poissonDisk[i],0.0));
	factor *= 1.0/8.0;
	return factor;
}
#endif

//post-processing functions
vec3 ContrastSaturationBrightness(vec3 color, float con, float sat, float brt)
{
	// Increase or decrease theese values to adjust r, g and b color channels seperately
	const float AvgLumR = 0.5;
	const float AvgLumG = 0.5;
	const float AvgLumB = 0.5;
	
	const vec3 LumCoeff = vec3(0.2125, 0.7154, 0.0721);
	
	vec3 AvgLumin = vec3(AvgLumR, AvgLumG, AvgLumB);
	vec3 brtColor = color * brt;
	vec3 intensity = vec3(dot(brtColor, LumCoeff));
	vec3 satColor = mix(intensity, brtColor, sat);
	vec3 conColor = mix(AvgLumin, satColor, con);
	return conColor;
}
#define BlendScreenf(base, blend) 		(1.0 - ((1.0 - base) * (1.0 - blend)))
#define BlendSoftLightf(base, blend) 	((blend < 0.5) ? (2.0 * base * blend + base * base * (1.0 - 2.0 * blend)) : (sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend)))
#define BlendOverlayf(base, blend) 	(base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)))
#define Blend(base, blend, funcf) 		vec3(funcf(base.r, blend.r), funcf(base.g, blend.g), funcf(base.b, blend.b))
#define BlendOverlay(base, blend) 		Blend(base, blend, BlendOverlayf)
#define BlendSoftLight(base, blend) 	Blend(base, blend, BlendSoftLightf)
#define BlendScreen(base, blend) 		Blend(base, blend, BlendScreenf)
#define GammaCorrection(color, gamma)								pow(color, 1.0 / gamma)
#define LevelsControlInputRange(color, minInput, maxInput)				min(max(color - vec3(minInput), vec3(0.0)) / (vec3(maxInput) - vec3(minInput)), vec3(1.0))
#define LevelsControlInput(color, minInput, gamma, maxInput)				GammaCorrection(LevelsControlInputRange(color, minInput, maxInput), gamma)

float ColorCorrectfloat(in float x)
{
	return pow(x,5.0)*5.23878+pow(x,4.0)*-14.45564+pow(x,3.0)*12.6883+pow(x,2.0)*-3.78462+x*1.31897-.01041;
}

vec3 ColorCorrect(in vec3 val)
{
	return vec3(ColorCorrectfloat(val.r),ColorCorrectfloat(val.g),ColorCorrectfloat(val.b));
}

void main()
{
	// Setting Each Pixel To Red
	//FragColor = vec4(1.0, 0.0, 0.0, 1.0);
	
	//vec4 incol = texture2D(tu0_2D, texcoord);
	//vec4 outcol = 1.0/(1.0+pow(2.718,-(incol*6.0-3.0)));
	
	vec4 outcol = texture2D(tu0_2D, texcoord);
	vec3 finalcolor = outcol.rgb;
	
	//do post-processing
	/*finalcolor = clamp(finalcolor,0.0,1.0);
	finalcolor = ((finalcolor-0.5)*1.2)+0.5;*/
	
	/*finalcolor = clamp(finalcolor,0.0,1.0);
	finalcolor = mix(finalcolor,3.0*finalcolor*finalcolor-2.0*finalcolor*finalcolor*finalcolor,0.5);
	finalcolor = ContrastSaturationBrightness(finalcolor, 1.0, 0.65, 1.0);*/
	finalcolor = ColorCorrect(finalcolor);
	finalcolor = ContrastSaturationBrightness(finalcolor, contrast, 1.0/contrast, (contrast-1.0)*0.5+1.0);
	finalcolor = clamp(finalcolor,0.0,1.0);
	
#ifdef _EDGECONTRASTENHANCEMENT_
	vec3 shadowcoords = vec3(gl_FragCoord.x/SCREENRESX, gl_FragCoord.y/SCREENRESY, gl_FragCoord.z-0.001);
	float edgefactor = GetEdgeContrastEnhancementFactor(tu9_2D, shadowcoords);
	finalcolor *= edgefactor*0.5+0.5;
#endif
	
    //outcol.a *= color_tint.a;
    FragColor = vec4(finalcolor,outcol.a);
    //FragColor = vec4(finalcolor*color_tint.a*outcol.a,outcol.a);
	//FragColor = vec4(finalcolor*outcol.a,outcol.a);
	//FragColor = bicubic_filter(tu0_2D, texcoord)*color_tint;
	
	//FragColor.rg = texcoord*0.5+0.5;
	//FragColor.ba = vec2(1.0);
	
	
	//sky color generation shader; fun to fiddle with.
	/*const vec3 SunPos = vec3(-2.0,1.0,1.0);
	float Exposure = 0.0;

	float sunsize = 1.0;

	const vec4 Zenith  = vec4( 0.00, 0.44, 0.81, 0.00 );
	const vec4 Horizon = vec4( 1.00, 1.00, 1.00, 0.00 );

	//Normalise current vertex position
	vec3 norm = -normalize(ecposition).xyz;


	//Normalise sun position
	//vec3 Sun = -normalize(vec3(0.1, SunPos.x, 1.0));
	vec3 Sun = -normalize(vec3(0.1, 1.0, SunPos.x));

	float ScatterDirection = dot(Sun, norm);
	//Curve based on position of sun
	float Curve = pow(5.0 + abs(SunPos.x), length(norm.xy)) * 0.05;

	//Mix colours based on curve
	vec4 sky = mix(Zenith, Horizon, Curve);
	//Apply scatter from direction of sun only
	sky = mix(sky, Zenith, ScatterDirection);

	//Sun
	vec4 light = vec4(pow( max(0.0, dot(-Sun, norm)), 360.0 ));
	//vec4 light = vec4(pow( max(0.0, dot(-Sun, norm)), 4.0 ));


	//Adjust exposure based on height of sun in sky
	Exposure += 1.0-abs(SunPos.x*0.033);

	//Fake HDR Output
	FragColor = (Exposure * sky) + sunsize*light;
	//FragColor = sunsize*light;
	FragColor.a = 1.0;*/
}

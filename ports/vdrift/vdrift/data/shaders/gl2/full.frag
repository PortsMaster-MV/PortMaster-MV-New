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

uniform sampler2D tu0_2D; //diffuse map
uniform sampler2D tu1_2D; //misc map (includes gloss on R channel, metallic on G channel, ...
uniform samplerCube tu3_cube; //ambient light cube map
uniform float contrast;

#ifdef _SHADOWS_
#ifdef _SHADOWSULTRA_
uniform sampler2D tu4_2D; //close shadow map
#else
uniform sampler2DShadow tu4_2D; //close shadow map
#endif
#ifdef _CSM2_
uniform sampler2DShadow tu5_2D; //far shadow map
#endif
#ifdef _CSM3_
uniform sampler2DShadow tu6_2D; //far far shadow map
#endif
#endif

//#define _FANCIERSHADOWBLENDING_

#ifndef _REFLECTIONDISABLED_
uniform samplerCube tu2_cube; //reflection map
#endif

#ifdef _EDGECONTRASTENHANCEMENT_
uniform sampler2DShadow tu9_2D; //edge contrast enhancement depth map
#endif

uniform vec3 light_direction;
uniform vec4 color_tint;

varying vec2 texcoord_2d;
varying vec3 V, N;
varying vec3 refmapdir, ambientmapdir;

#ifdef _SHADOWS_
varying vec4 projshadow_0;
#ifdef _CSM2_
varying vec4 projshadow_1;
#endif
#ifdef _CSM3_
varying vec4 projshadow_2;
#endif
#endif

OUT(vec4 FragColor)

const float PI = 3.141593;
const float ONE_OVER_PI = 1.0 / PI;

#if ( defined (_SHADOWS_) && ( defined (_SHADOWSULTRA_) || defined (_SHADOWSVHIGH_) ) ) || defined (_EDGECONTRASTENHANCEMENT_)
vec2 poissonDisk[16];
#endif

#ifdef _SHADOWSULTRA_
#define    BLOCKER_SEARCH_NUM_SAMPLES 16
#define    PCF_NUM_SAMPLES 16
#define    NEAR_PLANE 9.5
#define    LIGHT_WORLD_SIZE .05
#define    LIGHT_FRUSTUM_WIDTH 3.75
// Assuming that LIGHT_FRUSTUM_WIDTH == LIGHT_FRUSTUM_HEIGHT
#define LIGHT_SIZE_UV (LIGHT_WORLD_SIZE / LIGHT_FRUSTUM_WIDTH)

float unpackFloatFromVec4i(const vec4 value)
{
	const vec4 bitSh = vec4(1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
	return(dot(value, bitSh));
}

float unpackFloatFromVec3i(const vec3 value)
{
	const vec3 bitSh = vec3(1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
	return(dot(value, bitSh));
}

float unpackFloatFromVec2i(const vec2 value)
{
	const vec2 unpack_constants = vec2(1.0/256.0, 1.0);
	return dot(unpack_constants,value);
}

float shadow_comparison(sampler2D tu, vec2 uv, float comparison)
{
	float lookupvalue = unpackFloatFromVec3i(texture2D(tu, uv).rgb);
	return lookupvalue > comparison ? 1.0 : 0.0;
}

float PenumbraSize(float zReceiver, float zBlocker) //Parallel plane estimation
{
	return (zReceiver - zBlocker) / zBlocker;
}

void FindBlocker(in vec2 poissonDisk[16], in sampler2D tu,
		 out float avgBlockerDepth,
		 out float numBlockers,
		 vec2 uv, float zReceiver )
{
	//This uses similar triangles to compute what
	//area of the shadow map we should search
	//float searchWidth = LIGHT_SIZE_UV * (zReceiver - NEAR_PLANE) / zReceiver;
	float searchWidth = 10.0/2048.0;
	//float searchWidth = LIGHT_SIZE_UV;
	float blockerSum = 0;
	numBlockers = 0;
	for( int i = 0; i < BLOCKER_SEARCH_NUM_SAMPLES; ++i )
	{
		//float shadowMapDepth = tDepthMap.SampleLevel(PointSampler,uv + poissonDisk[i] * searchWidth,0);
		float shadowMapDepth = unpackFloatFromVec3i(texture2D(tu, uv + poissonDisk[i] * searchWidth).rgb);
		if ( shadowMapDepth < zReceiver ) {
			blockerSum += shadowMapDepth;
			numBlockers++;
		}
	}
	avgBlockerDepth = blockerSum / numBlockers;
}

float PCF_Filter( in vec2 poissonDisk[16], in sampler2D tu, in vec2 uv, in float zReceiver, in float filterRadiusUV )
{
	float sum = 0.0f;
	for ( int i = 0; i < PCF_NUM_SAMPLES; ++i )
	{
		vec2 offset = poissonDisk[i] * filterRadiusUV;
		sum += shadow_comparison(tu, uv + offset, zReceiver);
	}
	return sum / PCF_NUM_SAMPLES;
	//vec2 offset = vec2(1.0/2048.0,1.0/2048.0);
	//vec2 offset = vec2(0.0,0.0);
	//return unpackFloatFromVec4i(texture2D(tu, uv + offset)) >= zReceiver ? 1.0 : 0.0;
	//return unpackFloatFromVec3i(texture2D(tu, uv + offset).rgb) > zReceiver + 1.0/(256.0*256.0) ? 1.0 : 0.0;
	//return unpackFloatFromVec3i(texture2D(tu, uv + offset).rgb) > zReceiver + 1.0/(256.0*4.0) ? 1.0 : 0.0;
	//return unpackFloatFromVec2i(texture2D(tu, uv + offset).rg) >= zReceiver ? 1.0 : 0.0;
}

float PCSS ( in vec2 poissonDisk[16], in sampler2D tu, vec3 coords )
{
	vec2 uv = coords.xy;
	float zReceiver = coords.z; // Assumed to be eye-space z in this code
	// STEP 1: blocker search
	float avgBlockerDepth = 0;
	float numBlockers = 0;
	FindBlocker( poissonDisk, tu, avgBlockerDepth, numBlockers, uv, zReceiver );
	if( numBlockers < 1 )
		//There are no occluders so early out (this saves filtering)
		return 1.0f;
	// STEP 2: penumbra size
	float penumbraRatio = PenumbraSize(zReceiver, avgBlockerDepth);
	//float filterRadiusUV = penumbraRatio * LIGHT_SIZE_UV * NEAR_PLANE / coords.z;
	float filterRadiusUV = clamp(penumbraRatio*0.05,0,20.0/2048.0);
	//float filterRadiusUV = penumbraRatio*(256.0/2048.0);
	// STEP 3: filtering
	return PCF_Filter( poissonDisk, tu, uv, zReceiver, filterRadiusUV );
}

float shadow_lookup(sampler2D tu, vec3 coords)
#else
float shadow_lookup(sampler2DShadow tu, vec3 coords)
#endif
{
	#ifdef _SHADOWSULTRA_
	float notshadowfinal = PCSS(poissonDisk, tu, coords);
	#else
	#ifdef _SHADOWSVHIGH_
	float notshadowfinal = 0.0;
	float radius = 3.0/2048.0;
	for (int i = 0; i < 16; i++)
		notshadowfinal += shadow2D(tu,coords + radius*vec3(poissonDisk[i],0.0));
	notshadowfinal *= 1.0/16.0;
	#else
	//no PCF
	float notshadowfinal = shadow2D(tu, coords);
	#endif
	#endif
	
	return notshadowfinal;
}

#ifdef _EDGECONTRASTENHANCEMENT_
float GetEdgeContrastEnhancementFactor(in sampler2DShadow tu, in vec3 coords)
{
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
    
    //vec3 AvgLumin = vec3(0.5,0.5,0.5);
    //return mix(AvgLumin, color, con);
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

float GetShadows()
{
	#if ( defined (_SHADOWS_) && ( defined (_SHADOWSULTRA_) || defined (_SHADOWSVHIGH_) ) ) || defined (_EDGECONTRASTENHANCEMENT_)
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
	#endif
	
	#ifdef _SHADOWS_
	
	#ifdef _CSM3_
	const int numcsm = 3;
	#else
	#ifdef _CSM2_
	const int numcsm = 2;
	#else
	const int numcsm = 1;
	#endif
	#endif
	
	vec3 shadowcoords[numcsm];
	
	shadowcoords[0] = projshadow_0.xyz;
	#ifdef _CSM2_
	shadowcoords[1] = projshadow_1.xyz;
	#endif
	#ifdef _CSM3_
	shadowcoords[2] = projshadow_2.xyz;
	#endif
	
	#ifndef _FANCIERSHADOWBLENDING_
	const float boundmargin = 0.1;
	const float boundmax = 1.0 - boundmargin;
	const float boundmin = 0.0 + boundmargin;
	
	bool effect[numcsm];
	
	for (int i = 0; i < numcsm; i++)
	{
		effect[i] = (shadowcoords[i].x < boundmin || shadowcoords[i].x > boundmax) ||
		(shadowcoords[i].y < boundmin || shadowcoords[i].y > boundmax) ||
		(shadowcoords[i].z < boundmin || shadowcoords[i].z > boundmax);
	}
	#endif //no fancier shadow blending
	
	//shadow lookup that works better with ATI cards:  no early out
	float notshadow[numcsm];
	notshadow[0] = shadow_lookup(tu4_2D, shadowcoords[0]);
	#ifdef _CSM2_
	notshadow[1] = shadow_lookup(tu5_2D, shadowcoords[1]);
	#endif
	#ifdef _CSM3_
	notshadow[2] = shadow_lookup(tu6_2D, shadowcoords[2]);
	#endif
	
	//simple shadow mixing, no shadow fade-in
	#ifndef _FANCIERSHADOWBLENDING_
	//float notshadowfinal = notshadow[0];
	float notshadowfinal = max(notshadow[0],float(effect[0]));
	#ifdef _CSM3_
	notshadowfinal = mix(notshadowfinal,mix(notshadow[1],notshadow[2],float(effect[1])),float(effect[0]));
	notshadowfinal = max(notshadowfinal,float(effect[2]));
	#else
	#ifdef _CSM2_
	notshadowfinal = mix(notshadowfinal,notshadow[1],float(effect[0]));
	notshadowfinal = max(notshadowfinal,float(effect[1]));
	#endif
	#endif
	#endif //no fancier shadow blending
	
	//fancy shadow mixing, gives shadow fade-in
	#ifdef _FANCIERSHADOWBLENDING_
	const float bound = 1.0;
	const float fade = 10.0;
	float effect[numcsm];
	
	for (int i = 0; i < numcsm; ++i)
	//for (int i = 3; i < 4; ++i)
	{
		shadowcoords[i] = clamp(shadowcoords[i], 0.0, bound);
		float xf1 = 1.0-min(1.0,shadowcoords[i].x*fade);
		float xf2 = max(0.0,shadowcoords[i].x*fade-(fade-1.0));
		float yf1 = 1.0-min(1.0,shadowcoords[i].y*fade);
		float yf2 = max(0.0,shadowcoords[i].y*fade-(fade-1.0));
		float zf1 = 1.0-min(1.0,shadowcoords[i].z*fade);
		float zf2 = max(0.0,shadowcoords[i].z*fade-(fade-1.0));
		effect[i] = max(xf1,max(xf2,max(yf1,max(yf2,max(zf1,zf2)))));
		//notshadow[i] = max(notshadow[i],effect[i]);
	}
	
	float notshadowfinal = notshadow[0];
	#ifdef _CSM3_
	notshadowfinal = mix(notshadowfinal,mix(notshadow[1],notshadow[2],effect[1]),effect[0]);
	notshadowfinal = max(notshadowfinal,effect[2]);
	#else
	#ifdef _CSM2_
	notshadowfinal = mix(notshadowfinal,notshadow[1],effect[0]);
	notshadowfinal = max(notshadowfinal,effect[1]);
	#else
	notshadowfinal = max(notshadowfinal,effect[0]);
	#endif
	#endif
	#endif //fancier shadow blending
	
	#else //no SHADOWS
	float notshadowfinal = 1.0;
	#endif

	return notshadowfinal;
	//return notshadow[2];
	//return max(shadow_lookup(tu6_2D, shadowcoords[2]),float(effect[2]));
	//return float(effect[0])*0.25+float(effect[1])*0.25+float(effect[2])*0.25;
	//return float(effect[0]);
}

float EffectStrength(float val, float coeff)
{
	return val*coeff+1.0-coeff;
}

vec3 EffectStrength(vec3 val, float coeff)
{
	return val*coeff+vec3(1.0-coeff);
}

float ColorCorrectfloat(in float x)
{
	//return pow(x,5.0)*5.23878+pow(x,4.0)*-14.45564+pow(x,3.0)*12.6883+pow(x,2.0)*-3.78462+x*1.31897-.01041;
    return (1.-pow(1.-clamp(x,0.,1.),1.5))*1.2-0.2;
    //return x;
}

vec3 ColorCorrect(in vec3 val)
{
	return vec3(ColorCorrectfloat(val.r),ColorCorrectfloat(val.g),ColorCorrectfloat(val.b));
}

vec3 Expose(vec3 light, float exposure)
{
    return vec3(1.)-exp(-light*exposure);
}

float BRDF_Ward(vec3 N, vec3 L, vec3 H, vec3 R, vec3 T, vec3 B, vec2 P, vec2 A, vec3 scale)
{
    float e1 = dot(H, T) / A.x;
    float e2 = dot(H, B) / A.y;
    float E = -2.0 * ((e1 * e1 + e2 * e2) / (1.0 + dot(H,N)));
    float cosThetaI = dot(N, L);
    float cosThetaR = dot(N, R);
    float brdf = P.x * ONE_OVER_PI +
                 P.y * (1.0 / sqrt(cosThetaI * cosThetaR)) *
                 (1.0 / (4.0 * PI * A.x * A.y)) * exp(E);
    return scale.x * P.x * ONE_OVER_PI +
                      scale.y * P.y * cosThetaI * brdf +
                      scale.z * dot(H,N) * P.y;
}

float BRDF_OrenNayar(vec3 V, vec3 N, vec3 L, float roughness)
{
    float S2 = roughness * roughness;
    float dotVN = dot(V,N);
    float dotLN = dot(L,N);
    float thetai = acos(dotVN);
    float thetar = acos(dotLN);
    float alpha = max(thetai,thetar);
    float beta = min(thetai, thetar);
    
    float gamma = dot(V - N * dotVN, L - N*dotLN);
    
    float C1 = 1.-0.5*(S2/(S2+0.33));
    float C2 = 0.45*(S2/(S2+0.09));
    
    if (gamma >= 0.)
    {
        C2 *= sin(alpha);
    }
    else
    {
        C2 *= (sin(alpha)-pow((2.*beta)*ONE_OVER_PI,3.));
    }
    
    float C3 = 0.125 * (S2/(S2+0.09)) * pow((4.*alpha*beta)*ONE_OVER_PI*ONE_OVER_PI,2.);
    
    float A = gamma * C2 * tan(beta);
    float B = (1.-abs(gamma)) * C3 * tan((alpha+beta)*0.5);
    
    return max(0.,dotLN)*(C1+A+B);
}

float BRDF_CookTorrance(vec3 V, vec3 N, vec3 L, vec3 H, float roughness, float fresnel)
{
    float R2 = roughness * 3.0;
    R2 *= R2;
    float NdotH = dot(N, H);
    float VdotH = dot(V, H);
    float NdotV = dot(N, V);
    float NdotL = max(0.,dot(N, L));
    float OneOverVdotH = 1. / max(VdotH,0.001);
    
    //geometric term
    float G1 = (2.*NdotH*NdotV) * OneOverVdotH;
    float G2 = (2.*NdotH*NdotL) * OneOverVdotH;
    float G = min(1.,max(0.,min(G1,G2)));
    
    //fresnel term
    float F = fresnel + (1.-fresnel)*pow(1.-NdotV,5.);
    
    //roughness term
    float NdotH2  = NdotH*NdotH;
    float A = 1./(4.*R2*NdotH2*NdotH2);
    float B = exp(-(1.-NdotH2)/(R2*NdotH2));
    float R0 = A * B;
    
    //final term
    return max(0.,(G*F*R0)/(NdotL*NdotV));
}

float BRDF_Lambert(vec3 N, vec3 L)
{
    return max(0.,dot(L,N));
}

void main()
{
	float notshadowfinal = GetShadows();
  
    vec4 tu0_2D_val = texture2D(tu0_2D, texcoord_2d);
    vec3 surfacecolor = mix(color_tint.rgb, tu0_2D_val.rgb, tu0_2D_val.a); // surfacecolor is mixed from diffuse and object color
    vec3 ambient_light = textureCube(tu3_cube, ambientmapdir).rgb;
    vec4 tu1_2D_val = texture2D(tu1_2D, texcoord_2d);
    float gloss = tu1_2D_val.r;
    float metallic = tu1_2D_val.g;
	float ambient = 1.0;//tu1_2D_val.a;
    vec3 L = light_direction;
    vec3 Nn = normalize(N);
    vec3 Vn = normalize(V);
    vec3 H = normalize(light_direction+V);
    
    vec3 diffuse = surfacecolor * ambient * (BRDF_Lambert(N,L) * notshadowfinal + ambient_light) * 0.5;
    
    vec3 specular = vec3(0.);
    if (gloss > 0. || metallic > 0.)
    {
        #ifndef _REFLECTIONDISABLED_
			#ifdef _REFLECTIONDYNAMIC_
				vec3 fixrefmapdir = vec3(-refmapdir.z, refmapdir.x, -refmapdir.y);
				vec3 specular_environment = textureCube(tu2_cube, fixrefmapdir).rgb;
			#else
				vec3 specular_environment = textureCube(tu2_cube, refmapdir).rgb;
			#endif
        #else
        vec3 specular_environment = vec3(1.);
        #endif
        
        float specval = max(dot(reflect(-Vn,Nn),L),0.0);
        float spec_add_highlight = metallic*2.0*max((pow(specval,512.0)-0.5)*2.0,0.0);
        float brdf_gloss = clamp(BRDF_CookTorrance(Vn, Nn, L, H, 0.1, 0.05)*gloss,0.,1.);
        float brdf_metal = clamp(BRDF_CookTorrance(Vn, Nn, L, H, 0.3, 0.15)*metallic,0.,1.);
        //float brdf = brdf_gloss+brdf_metal;
        specular = (notshadowfinal*0.5+0.5)*(brdf_gloss*vec3(1.)+brdf_metal*specular_environment) + vec3(1.)*spec_add_highlight*notshadowfinal;
        diffuse *= 1.0-(brdf_gloss+brdf_metal)*0.5;
    }
    
    vec3 finalcolor = diffuse + specular;
    
    //finalcolor = surfacecolor*vec3((BRDF_Lambert(N,L)*notshadowfinal+ambient_light)*0.5);
    //finalcolor = 1.156*(vec3(1.)-exp(-pow(finalcolor,vec3(1.3))*2.));
    finalcolor = 1.58*(vec3(1.)-exp(-finalcolor*1.));
    //finalcolor = (finalcolor+0.05)*1.1;
    //finalcolor = ColorCorrect(finalcolor);
	//vec3 fixrefmapdir = vec3(-refmapdir.z, refmapdir.x, -refmapdir.y);
    //finalcolor = textureCube(tu2_cube, fixrefmapdir).rgb;
	
    finalcolor = ContrastSaturationBrightness(finalcolor, contrast, 1.0/contrast, (contrast-1.0)*0.5+1.0);
    //finalcolor = Expose(finalcolor, contrast*3.0-2.0)*1.15;//(1./(1.-exp(-(contrast*3.-2.))));
    finalcolor = clamp(finalcolor,0.0,1.0);
	
#ifdef _EDGECONTRASTENHANCEMENT_
	vec3 depthcoords = vec3(gl_FragCoord.x/SCREENRESX, gl_FragCoord.y/SCREENRESY, gl_FragCoord.z-0.001);
	float edgefactor = GetEdgeContrastEnhancementFactor(tu9_2D, depthcoords);
	finalcolor *= edgefactor*0.5+0.5;
#endif
	
#ifdef _ALPHATEST_
	//float width = clamp(dFdx(texcoord_2d.x) * diffuse_texture_width * 0.5,0.0,0.5);
	float width = clamp(dFdx(texcoord_2d.x) * 512.0 * 0.5,0.0,0.5);
	float alpha = smoothstep(0.5-width, 0.5+width, tu0_2D_val.a);
#else
	float alpha = tu0_2D_val.a;
#endif
	// color_tint alpha determines surface transparency, 0.0 fully transparent, 0.5 texture alpha, 1.0 opaque
	FragColor.a = alpha;// + 2 * color_tint.a - 1;
    
	FragColor.rgb = finalcolor;
}

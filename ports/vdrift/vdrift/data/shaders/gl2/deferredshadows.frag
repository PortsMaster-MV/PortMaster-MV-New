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

varying vec3 eyespace_view_direction;
varying float q; //equivalent to ProjectionMatrix[2].z
varying float qn; //equivalent to ProjectionMatrix[3].z

#ifdef _SHADOWS_
#ifdef _CSM3_
uniform mat4 ShadowMatrix[3];
#else
#ifdef _CSM2_
uniform mat4 ShadowMatrix[2];
#else
uniform mat4 ShadowMatrix[1];
#endif
#endif
#endif

uniform sampler2D tu0_2D; //full scene depth
#ifdef _SHADOWS_
uniform sampler2DShadow tu1_2D; //close shadow map
#ifdef _CSM2_
uniform sampler2DShadow tu2_2D; //far shadow map
#endif
#ifdef _CSM3_
uniform sampler2DShadow tu3_2D; //far far shadow map
#endif
#endif

OUT(vec4 FragColor)

float shadow_lookup(sampler2DShadow tu, vec3 coords)
{
	float notshadowfinal = shadow2D(tu, coords);
	
	return notshadowfinal;
}

float GetShadows(vec4 eyespace_pos)
{
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
	vec4 sc0 = ShadowMatrix[0] * eyespace_pos;
	shadowcoords[0] = sc0.xyz;
	#ifdef _CSM2_
	vec4 sc1 = ShadowMatrix[1] * eyespace_pos;
	shadowcoords[1] = sc1.xyz;
	#endif
	#ifdef _CSM3_
	vec4 sc2 = ShadowMatrix[2] * eyespace_pos;
	shadowcoords[2] = sc2.xyz;
	#endif
	
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
	
	//shadow lookup that works better with ATI cards:  no early out
	float notshadow[numcsm];
	notshadow[0] = shadow_lookup(tu1_2D, shadowcoords[0]);
	#ifdef _CSM2_
	notshadow[1] = shadow_lookup(tu2_2D, shadowcoords[1]);
	#endif
	#ifdef _CSM3_
	notshadow[2] = shadow_lookup(tu3_2D, shadowcoords[2]);
	#endif
	
	//simple shadow mixing, no shadow fade-in
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
	
	#else //no SHADOWS
	float notshadowfinal = 1.0;
	#endif

	return notshadowfinal;
}

void main()
{
	vec2 screen = vec2(SCREENRESX,SCREENRESY);
	vec2 screencoord = gl_FragCoord.xy/screen;
	
	// retrieve g-buffer
	float gbuf_depth = texture2D(tu0_2D, screencoord).r;
	
	// early discard
	if (gbuf_depth == 1) discard;
	
	float eyespace_z = qn / (gbuf_depth * -2.0 + 1.0 - q); //http://www.opengl.org/discussion_boards/ubbthreads.php?ubb=showflat&Number=277938
	vec3 gbuf_eyespace_pos = vec3(eyespace_view_direction.xy/eyespace_view_direction.z*eyespace_z,eyespace_z); //http://lumina.sourceforge.net/Tutorials/Deferred_shading/Point_light.html
	
	float notshadow = GetShadows(vec4(gbuf_eyespace_pos,1.0));
	
	vec4 final = vec4(1.0,1.0,1.0,1.0)*notshadow;
	
	FragColor = final;
}

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

uniform mat3 ReflectionMatrix;

uniform sampler2D tu0_2D; // diffuse map
uniform sampler2D tu1_2D; // misc map (includes gloss on R channel, ...

#ifndef _REFLECTIONDISABLED_
uniform samplerCube tu2_cube; // reflection map
#endif

uniform vec3 light_direction;
uniform vec4 color_tint;

varying vec2 texcoord_2d;
varying vec3 normal_eye;
varying vec3 viewdir;

OUT(vec4 FragColor)

void main()
{
	float notshadowfinal = 1.0;
	
	vec3 normnormal = normalize(normal_eye);
	vec3 normviewdir = normalize(viewdir);
	vec3 normlight_direction = normalize(light_direction);
	
	vec4 tu0_2D_val = texture2D(tu0_2D, texcoord_2d);
	vec4 tu1_2D_val = texture2D(tu1_2D, texcoord_2d);
	vec4 tu6_2D_val = texture2D(tu6_2D, texcoord_2d);
	
	vec3 texcolor = tu0_2D_val.rgb;
	float gloss = tu1_2D_val.r;
	float metallic = tu1_2D_val.g;
	
	float difdot = dot(normnormal,normlight_direction);
	
	vec3 diffuse = texcolor*max(difdot,0.0)*notshadowfinal;
	
	vec3 ambient = texcolor;//*(1.0+min(difdot,0.0));
	
	float specval = max(dot(reflect(normviewdir,normnormal),normlight_direction),0.0);
	
	float env_factor = min(pow(1.0-max(0.0,dot(-normviewdir,normnormal)),3.0),0.6)*0.75+0.2;
	
	float spec = ((max((pow(specval,512.0)-0.5)*2.0,0.0))*metallic+pow(specval,12.0)*(0.4+(1.0-metallic)*0.8))*gloss;

	
	#ifndef _REFLECTIONDISABLED_
	vec3 refmapdir = reflect(normviewdir,normnormal);
	refmapdir = ReflectionMatrix * refmapdir;
	vec3 specular_environment = textureCube(tu2_cube, refmapdir).rgb*metallic*env_factor;
	#else
	vec3 specular_environment = vec3(0,0,0);
	#endif
	float inv_environment = 1.0 - (env_factor*metallic);
	
	float invgloss = (1.0-gloss);
	
	vec3 finalcolor = (ambient*0.5 + diffuse*0.8*max(0.7,invgloss))*(inv_environment*0.5+0.5) + vec3(spec)*notshadowfinal + specular_environment*max(0.5,notshadowfinal);
	
	//do post-processing
	finalcolor = clamp(finalcolor,0.0,1.0);
	finalcolor = ((finalcolor-0.5)*1.2)+0.5;
	
	FragColor = vec4(finalcolor, tu0_2D_val.a * color_tint.a);
}

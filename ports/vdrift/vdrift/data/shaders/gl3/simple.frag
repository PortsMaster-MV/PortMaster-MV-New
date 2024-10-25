#version 330

#ifndef NOTEXTURE
uniform sampler2D diffuseSampler;
#endif
uniform vec4 colorTint;

#ifdef VCOLOR
in vec4 vcolor;
#endif

in vec3 normal;
in vec3 uv;
in vec3 eyespacePosition;

out vec4 outputColor;

// doesn't include pow(x,1/2.2)
vec3 hableTonemap(vec3 x)
{
	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;
	
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

const vec3 scatterBeta = vec3(7.87e-6,1.573e-5,3.63e-5);
const float scatterDensity = 1.0;
vec3 inscatter(float worldDepth)
{
    return 1-exp(-worldDepth*scatterBeta*scatterDensity);
}
vec3 extinction(float worldDepth)
{
    return exp(-worldDepth*scatterBeta*scatterDensity);
}

void main(void)
{
    #ifdef NOTEXTURE
	vec4 diffuseTexture = vec4(1,1,1,1);
    #else
	vec4 diffuseTexture = texture(diffuseSampler, uv.xy);
    #endif
	
	vec4 albedo;
	
	#ifdef CARPAINT
	albedo.rgb = mix(colorTint.rgb, diffuseTexture.rgb, diffuseTexture.a); // albedo is mixed from diffuse and object color
	albedo.a = 1;
	#else
	#ifdef VCOLOR
	albedo = diffuseTexture * vcolor;
	#else
	albedo = diffuseTexture * colorTint;
	#endif
	#endif
	
	#ifdef ALPHATEST
	if (diffuseTexture.a < 0.5)
		discard;
	#endif

    #ifdef FOG
    float depth = length(eyespacePosition);
    albedo.rgb = albedo.rgb*extinction(depth) + inscatter(depth);
    #endif

    #ifdef TONEMAP
	float exposureBias = 10.0;
	//albedo.rgb = hableTonemap(exposureBias*albedo.rgb);
    #endif

	outputColor.rgba = albedo;
}

#version 330

uniform sampler2D diffuseAlbedoSampler;
uniform sampler2D depthSampler;
uniform sampler2D normalSampler;
uniform sampler2D materialSampler;
uniform sampler2D emissiveSampler;
uniform samplerCube reflectionCubeSampler;
uniform vec2 viewportSize;
uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform vec4 colorTint;
uniform vec4 directionalLightColor;
uniform vec4 ambientLightColor;
uniform vec3 eyespaceLightDirection;
uniform mat4 invProjectionMatrix;
uniform mat4 invViewMatrix;
uniform mat4 defaultViewMatrix;
uniform mat4 defaultProjectionMatrix;
uniform vec4 reflectedLightColor;

#ifdef SHADOWS

#ifdef DIRECTIONAL
uniform sampler2D shadowSampler;
#endif

#ifdef AMBIENT
uniform sampler2D aoSampler;
#endif

#endif

in vec3 eyespacePosition;
in vec3 uv;

out vec4 outputColor;

float unpackFloatFromVec2i(const vec2 value)
{
	const vec2 unpack_constants = vec2(1.0/256.0, 1.0);
	return dot(unpack_constants,value);
}

vec3 sphericalToXYZ(const vec2 spherical)
{
	vec3 xyz;
	float theta = spherical.x*3.14159265358979323846;
	vec2 sincosTheta = vec2(sin(theta),cos(theta));
	vec2 sincosPhi = vec2(sqrt(1.0-spherical.y*spherical.y), spherical.y);
	xyz.x = sincosTheta.y*sincosPhi.x;
	xyz.y = sincosTheta.x*sincosPhi.x;
	xyz.z = spherical.y;
	return xyz;
}

float cos_clamped(const vec3 V1, const vec3 V2)
{
	return max(0.0,dot(V1,V2));
}

vec3 CommonBRDF(const vec3 brdf, const vec3 E_l, const float omega_i)
{
	return brdf * E_l * omega_i;
}

vec3 FresnelEquation(const vec3 Rf0, const float omega_i)
{
	//return Rf0 + (vec3(1.,1.,1.)-Rf0)*pow(1.0-omega_i,5.0);
	return Rf0 + (vec3(1.,1.,1.)-Rf0)*pow(1.0-omega_i,3.0);
}

// equation 7.49, Real-Time Rendering (third edition) by Akenine-Moller, Haines, Hoffman
vec3 RealTimeRenderingBRDF(const vec3 cdiff, const float m, const vec3 Rf0, const float alpha_h, const float omega_h)
{
	return cdiff + (m/8.0)*FresnelEquation(Rf0,alpha_h)*pow(omega_h,m);
}

// 9-coefficient spherical harmonics; see
// http://graphics.stanford.edu/papers/envmap/
// I generated these coefficients from a vdrift screenshot cubemap
vec3 genericAmbient(vec3 n)
{
	const vec3 L00 = vec3(0.127828, 0.134996, 0.143064);
	const vec3 L1_1 = vec3(0.0782191, 0.0846895, 0.0914452);
	const vec3 L10 = vec3(0.00262751, 0.00178929, 0.00131505);
	const vec3 L11 = vec3(-0.00115066, 0.00039037, 0.0013798);
	const vec3 L2_2 = vec3(-0.00269112, -0.000918181, 0.000237999);
	const vec3 L2_1 = vec3(0.00206233, 0.000806966, 0.000123036);
	const vec3 L20 = vec3(-0.0067301, -0.00879927, -0.0111885);
	const vec3 L21 = vec3(-0.00129254, -0.000877234, -0.0001961);
	const vec3 L22 = vec3(-0.00720356, -0.00989728, -0.0131989);
	
	const float c1 = 0.429043 ;
	const float c2 = 0.511664 ;
	const float c3 = 0.743125 ;
	const float c4 = 0.886227 ;
	const float c5 = 0.247708 ;

	float x = n[0];
	float y = n[1];
	float z = n[2];

	float x2 = x*x;
	float y2 = y*y;
	float z2 = z*z;
	float xy = x*y;
	float yz = y*z;
	float xz = x*z;

	return (c1*L22*(x2-y2) + c3*L20*z2 + c4*L00 - c5*L20 
		+ 2*c1*(L2_2*xy + L21*xz + L2_1*yz) 
		+ 2*c2*(L11*x+L1_1*y+L10*z))/0.143;
}

#ifdef AMBIENT
	#define SCREENSPACE
#endif

#ifdef DIRECTIONAL
	#define SCREENSPACE
#endif

vec3 getNDC(vec2 screencoord, float gbuf_depth)
{
		return vec3(screencoord.x, screencoord.y, gbuf_depth)*2.0-vec3(1.0);
}
		
vec3 NDCtoEyespace(vec3 normalizedDevicePosition)
{
		// transform from NDCs to eyespace
		vec4 reconstructedEyespacePosition = invProjectionMatrix * 
			vec4(normalizedDevicePosition.x,
				normalizedDevicePosition.y,
				normalizedDevicePosition.z,
				1.0);
		reconstructedEyespacePosition.xyz /= reconstructedEyespacePosition.w;
        return reconstructedEyespacePosition.xyz;
}

vec3 screenToEyespace(vec2 screencoord, float gbuf_depth)
{
    return NDCtoEyespace(getNDC(screencoord, gbuf_depth));
}

vec3 eyespaceToNDC(vec3 eyespacePosition)
{
    vec4 projectedpos = defaultProjectionMatrix*(vec4(eyespacePosition, 1.0));
    return projectedpos.xyz/projectedpos.w;
}

vec3 NDCtoScreen(vec3 ndc)
{
    return (ndc+vec3(1.0))*0.5;
}

vec3 eyespaceToScreen(vec3 eyespacePosition)
{
    return NDCtoScreen(eyespaceToNDC(eyespacePosition));
}

// returns true if we're done
bool findReflectionDistanceStep(float curDistance, inout float lastDistance, inout float lastDepth, vec3 screenspacePosition, vec3 reconstructedEyespacePosition, vec3 eyespaceReflectionDirection)
{
    vec3 reflectionSampleEyespace = reconstructedEyespacePosition + eyespaceReflectionDirection*curDistance;
    vec3 reflectionSampleScreen = eyespaceToScreen(reflectionSampleEyespace);

    float gbuf_depth = texture(depthSampler, reflectionSampleScreen.xy).r;
    vec3 sampleNDC = getNDC(reflectionSampleScreen.xy, gbuf_depth);

    //if (gbuf_depth <= reflectionSampleScreen.z && gbuf_depth > screenspacePosition.z)
    if (gbuf_depth <= reflectionSampleScreen.z && gbuf_depth >= lastDepth - (reflectionSampleScreen.z-lastDepth))
    //if (gbuf_depth <= reflectionSampleScreen.z && gbuf_depth >= lastDepth - 0.001)
    //if (gbuf_depth <= reflectionSampleScreen.z && gbuf_depth >= lastDepth)
    //if (gbuf_depth <= reflectionSampleScreen.z)
        return true;

    lastDistance = curDistance;
    lastDepth = reflectionSampleScreen.z;

    return false;
}

float findReflectionDistance(vec3 screenspacePosition, vec3 reconstructedEyespacePosition, vec3 eyespaceReflectionDirection)
{
    const int numDistances = 16;
    const float stepDistance = 0.25/numDistances;

    float lastDistance = 0;
    float curDistance = 0;
    float lastDepth = screenspacePosition.z;

    float distanceCoeff = max(1.0,length(reconstructedEyespacePosition));

    bool foundHit = false;

    for (int i = 0; i < numDistances; i++)
    {
        curDistance = (i+1)*distanceCoeff*stepDistance;

        foundHit = findReflectionDistanceStep(curDistance, lastDistance, lastDepth, screenspacePosition, reconstructedEyespacePosition, eyespaceReflectionDirection);
        if (foundHit)
        {
            return curDistance;
        }
    }
    
    return 1000.0;
}

// zero at min, 1 at max
float fade(float val, float min, float max)
{
    float t = clamp((val-min)/(max-min), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

float screenFade(vec3 screenPos)
{
    const float screenFadeStart = 0.75;
    return fade(screenPos.x, 0, 1-screenFadeStart)
        * fade(screenPos.x, 1, screenFadeStart)
        * fade(screenPos.y, 0, 1-screenFadeStart)
        * fade(screenPos.y, 1, screenFadeStart)
        * (screenPos.z > 1.0 ? 0.0 : 1.0) 
        ;
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
	#ifdef SCREENSPACE
		vec2 screencoord = uv.xy;
	#else
		vec2 screencoord = gl_FragCoord.xy/viewportSize;
	#endif
	
	// retrieve g-buffer
	float gbuf_depth = texture(depthSampler, screencoord).r;
	
	// early discard
	#ifndef EMISSIVE
		if (gbuf_depth == 1) discard;
	#endif
	
	vec4 gbuf_material_properties = texture(materialSampler, screencoord);
	vec4 gbuf_normal_xy = texture(normalSampler, screencoord);
	vec4 gbuf_diffuse_albedo = texture(diffuseAlbedoSampler, screencoord);
	
	// decode g-buffer
	vec3 cdiff = gbuf_diffuse_albedo.rgb; //diffuse reflectance
	float carpaintMask = gbuf_diffuse_albedo.a; // 1 means this is carpaint
	vec3 Rf0 = gbuf_material_properties.rgb; //fresnel reflectance value at zero degrees
	float mpercent = clamp(gbuf_material_properties.a,0.001,0.999);
	float m = mpercent*mpercent*256.0; //micro-scale roughness
	//m = max(2.*dot(vec3(0.299,0.587,0.114),cdiff),m);
	//Rf0 = max(vec3(0.06),Rf0);
	vec2 normal_spherical = vec2(unpackFloatFromVec2i(gbuf_normal_xy.xy),unpackFloatFromVec2i(gbuf_normal_xy.zw))*2.0-vec2(1.0,1.0);
	vec3 normal = sphericalToXYZ(normal_spherical);
    #ifdef SIMPLE_NORMAL_ENCODING
    normal = gbuf_normal_xy.xyz*2.0-vec3(1,1,1);
    #endif
	
	// flip back-pointing face normals to point out the other direction
	//normal *= -sign(dot(V,normal));
	//normal.z = abs(normal.z);
	//normal.z = -normal.z;
	
	vec3 final = vec3(0,0,0);
	
	#ifdef AMBIENT
		#ifdef SHADOWS
			float notAO = texture(aoSampler, screencoord).r;
		#else
			float notAO = 1.0;
		#endif
		vec3 light_direction = normalize(eyespaceLightDirection);
		float omega_i = cos_clamped(light_direction,normal); //clamped cosine of angle between incoming light direction and surface normal
        //notAO *= omega_i;
        //notAO = max(0.2,notAO);
        notAO = notAO * 0.8+0.2;
        //notAO = 1;

		vec3 ambientDiffuse = cdiff*genericAmbient(normal)*ambientLightColor.rgb*notAO;

        vec3 reconstructedEyespacePosition = screenToEyespace(screencoord, gbuf_depth);

		vec3 V = normalize(reconstructedEyespacePosition.xyz);
		
		// compute the reflection direction
		vec3 eyespaceReflectionDirection = reflect(V, normal);
        mat3 invViewMatrix3 = mat3(invViewMatrix);
		vec3 worldspaceReflectionDirection = (invViewMatrix3*eyespaceReflectionDirection).xyz;

		vec3 reflectedLight = pow(textureLod(reflectionCubeSampler, worldspaceReflectionDirection.xzy*vec3(1,1,1), (1-mpercent)*7).rgb,vec3(2.2))*reflectedLightColor.rgb;

        #ifdef REFLECTIONS_HIGH
        vec3 screenSpaceReflectedLight = vec3(0);
        float reflectionDistance = findReflectionDistance(vec3(screencoord, gbuf_depth), reconstructedEyespacePosition, eyespaceReflectionDirection);
        vec3 reflectionSampleEyespace = reconstructedEyespacePosition + eyespaceReflectionDirection*reflectionDistance;
        vec3 reflectionSampleScreen = eyespaceToScreen(reflectionSampleEyespace);
        vec4 reflectedDiffuse = texture(diffuseAlbedoSampler, reflectionSampleScreen.xy);
        float screenSpaceReflectionAmount = screenFade(vec3(reflectionSampleScreen.xy,reflectionSampleEyespace.z));
        const vec3 reflectionTint = vec3(0.127828, 0.134996, 0.143064);
        screenSpaceReflectedLight = reflectedDiffuse.xyz*reflectionTint;
        reflectedLight = mix(reflectedLight,screenSpaceReflectedLight,screenSpaceReflectionAmount);
        #endif
		
		float alpha_h = clamp(dot(-V,normal),-1.0,1.0);
		reflectedLight *= FresnelEquation(Rf0*0.2,alpha_h)*mpercent;
		
		if (carpaintMask > 0.5)
        {
			ambientDiffuse *= (alpha_h*alpha_h*0.25+0.05);
        }
		else
			reflectedLight *= max(0,mpercent-0.5)*2.0;

        // fog!
        float worldDepth = length(reconstructedEyespacePosition);
        vec3 inscatterLight = inscatter(worldDepth);
		
		//final = ambientDiffuse + reflectedLight;//(0.25+cos_clamped(V,normal)*0.25);
		//final = texture(reflectionCubeSampler, (invViewMatrix*vec4(normal,0.0)).xzy).rgb;
		//final = abs(vec3(invProjectionMatrix[3].xyz));
		final = extinction(worldDepth)*(ambientDiffuse+reflectedLight*notAO)+inscatterLight;
        //final = vec3(notAO);
        //final = genericAmbient(normal)*ambientLightColor.rgb;
        //final = abs(reflect(invViewMatrix3*V,vec3(0,1,0)));
        //final = reflectedLight*100;
        //final = abs(invViewMatrix3*normal);
        //final = normal;
	#endif
	
	#ifdef DIRECTIONAL
		vec3 normalizedDevicePosition = vec3(screencoord.x, screencoord.y, gbuf_depth)*2.0-vec3(1.0);
		
		// transform from NDCs to eyespace
		vec4 reconstructedEyespacePosition = invProjectionMatrix * 
			vec4(normalizedDevicePosition.x,
				normalizedDevicePosition.y,
				normalizedDevicePosition.z,
				1.0);
		reconstructedEyespacePosition.xyz /= reconstructedEyespacePosition.w;
		vec3 V = -normalize(reconstructedEyespacePosition.xyz);
		
		#ifdef SHADOWS
			float notShadow = texture(shadowSampler, screencoord).r;
		#else
			float notShadow = 1.0;
		#endif
		
		// the direct light itself
		vec3 E_l = directionalLightColor.rgb;
		vec3 light_direction = normalize(eyespaceLightDirection);
		float omega_i = cos_clamped(light_direction,normal); //clamped cosine of angle between incoming light direction and surface normal
		vec3 H = normalize(V+light_direction);
		float alpha_h = clamp(dot(V,H),-1.0,1.0); //cosine of angle between half vector and view direction
		float omega_h = cos_clamped(H,normal); //clamped cosine of angle between half vector and normal
		if (carpaintMask > 0.5)
		//if (false)
		{
			final += CommonBRDF(RealTimeRenderingBRDF(cdiff*0.5, m, cdiff, alpha_h, omega_h),E_l,omega_i)*0.25;
			final += CommonBRDF(RealTimeRenderingBRDF(cdiff*0, m*4, Rf0, alpha_h, omega_h),E_l,omega_i)*0.001;
			
			/*const float mmult = 256*2;
			const float specmult = 1.0;
			final = CommonBRDF(RealTimeRenderingBRDF(vec3(.0079,.023,.1), 0, vec3(0), alpha_h, omega_h),E_l,omega_i);
			final += CommonBRDF(RealTimeRenderingBRDF(vec3(0), .15*mmult, vec3(.0011,.0015,.0019)*specmult, alpha_h, omega_h),E_l,omega_i);
			final += CommonBRDF(RealTimeRenderingBRDF(vec3(0), .043*mmult, vec3(.025,.03,.043)*specmult, alpha_h, omega_h),E_l,omega_i);
			final += CommonBRDF(RealTimeRenderingBRDF(vec3(0), .02*mmult, vec3(.059,.074,.082)*specmult, alpha_h, omega_h),E_l,omega_i);*/
		}
		else
		{
			final = CommonBRDF(RealTimeRenderingBRDF(cdiff, m, Rf0, alpha_h, omega_h),E_l,omega_i);
		}
		final *= notShadow;
        final *= extinction(length(reconstructedEyespacePosition));
		
		//final = vec3(reconstructedEyespacePosition);
		//final = normalize(V);
		//final = normalize(normalizedDevicePosition);
		//final = vec3(gbuf_depth*2-1);
		//final = vec3(V.y*.1);
		//final = vec3(abs(normalize(eyespacePosition).z));
		//final = vec3(notShadow);
		//final = vec3(shadowMap1.x,shadowMap1.y,0);
		//final = vec3(shadowLinearz1-shadowMap1.x,shadowMap1.x-shadowLinearz1,0);
		//final = shadowMatrix1[0].xyz;
		//final = vec3((shadowClipspacePosition.xy+vec2(1,1))*0.5*vec2(1,1),0);
		//final = vec3(shadowClipspacePosition.xy,0);
		//final = vec3(shadowLinearz1);
		//final = shadowClipspacePosition.xyz;
		
		// throw the specular map lookup into this block since we've already calculated V
		//final = texture(reflectionCubeSampler, (mat3(invViewMatrix)*normal.xyz).xzy).rgb;
		//final = texture(reflectionCubeSampler, normal).rgb;
	#endif
	
	#ifdef OMNI
		float eyespace_z = projectionMatrix[3].z / (gbuf_depth * -2.0 + 1.0 - projectionMatrix[2].z); //http://www.opengl.org/discussion_boards/ubbthreads.php?ubb=showflat&Number=277938
		vec3 gbuf_eyespace_pos = vec3(eyespacePosition.xy/eyespacePosition.z*eyespace_z,eyespace_z); //http://lumina.sourceforge.net/Tutorials/Deferred_shading/Point_light.html
		vec3 V = gbuf_eyespace_pos;
		vec3 light_center = (viewMatrix*modelMatrix[3]).xyz;
		float light_scale = length(modelMatrix[0].xyz);
		float attenuation_radius = light_scale*.707;
		float falloff_radius = attenuation_radius;
		//attenuation_radius = 1;
		//falloff_radius = 1;
		float dist = max(0.1*light_scale,distance(gbuf_eyespace_pos,light_center));
		float attenuation = max(0.0,(-dist/falloff_radius+1.0)*attenuation_radius/dist);
		//float attenuation = max(0.0,(-dist/falloff_radius+1.0));
		vec3 E_l = colorTint.rgb*attenuation;
		vec3 light_direction = -normalize(gbuf_eyespace_pos - light_center);
		
		//light_direction=normalize(vec3(0,0,1));
		//E_l = vec3(1,1,1);
		
		float omega_i = cos_clamped(light_direction,normal); //clamped cosine of angle between incoming light direction and surface normal
		vec3 H = normalize(V+light_direction);
		float alpha_h = clamp(dot(V,H),-1.0,1.0); //cosine of angle between half vector and view direction
		float omega_h = cos_clamped(H,normal); //clamped cosine of angle between half vector and normal
		final = CommonBRDF(RealTimeRenderingBRDF(cdiff, m, Rf0, alpha_h, omega_h),E_l,omega_i);
		//final = V;
	#endif
	
	#ifdef EMISSIVE
		final = texture(emissiveSampler, uv.xy).rgb*colorTint.rgb;
	#endif
	
	#ifndef DIRECTIONAL
		//final *= 0;
	#endif
	
	// add source light
	outputColor.a = 1;
	outputColor.rgb = final;
}

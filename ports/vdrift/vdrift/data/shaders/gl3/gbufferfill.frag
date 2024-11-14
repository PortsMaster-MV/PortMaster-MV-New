#version 330

uniform sampler2D diffuseSampler;
uniform sampler2D materialPropertiesSampler;
#ifdef NORMALMAPS
uniform sampler2D normalMapSampler;
#endif
uniform vec4 colorTint;
uniform float depthOffset;

in vec3 normal;
#ifdef TANGENTSPACE
in vec4 tangent;
#endif

in vec3 uv;
in vec3 eyespacePosition;

out vec4 materialProperties;
out vec4 normalXY;
out vec4 diffuseAlbedo;

vec2 packFloatToVec2i(const float val)
{
	float value = clamp(val,0.0,0.9999);
	vec2 bitSh = vec2(256.0, 1.0);
	vec2 bitMsk = vec2(0.0, 1.0/256.0);
	vec2 res = fract(value * bitSh);
	res -= res.xx * bitMsk;
	return res;
}

vec2 TweakTextureCoordinates(vec2 incoord, float texsize)
{
	vec2 t = incoord * texsize - .5;
	vec2 frc = fract(t);
	vec2 flr = t - frc;
	frc = frc*frc*(3.-2.*frc);//frc*frc*frc*(10+frc*(6*frc-15));
	return (flr + frc + .5)*(1./texsize);
}

mat3 MatrixInverse(mat3 inMatrix)
{  
	float det = dot(cross(inMatrix[0], inMatrix[1]), inMatrix[2]);
	mat3 T = transpose(inMatrix);
	return mat3(cross(T[1], T[2]),
		cross(T[2], T[0]),
		cross(T[0], T[1])) / det;
}

// viewdir and normal MUST BE UNIT LENGTH
//http://www.gamedev.net/community/forums/topic.asp?topic_id=521915
mat3 GetTangentBasis(vec3 normal, vec3 viewdir, vec2 tucoord)
{
	// get edge vectors of the pixel triangle
	vec3 dp1  = dFdx(viewdir);
	vec3 dp2  = dFdy(viewdir);   
	vec2 duv1 = dFdx(tucoord);
	vec2 duv2 = dFdy(tucoord);  

	// solve the linear system
	mat3 M = mat3(dp1, dp2, cross(dp1, dp2));
	mat3 inverseM = MatrixInverse(M);
	vec3 T = inverseM * vec3(duv1.x, duv2.x, 0.0);
	vec3 B = inverseM * vec3(duv1.y, duv2.y, 0.0);

	// construct tangent frame
	float maxLength = max(length(T), length(B));
	T = T / maxLength;
	B = B / maxLength;

	//vec3 tangent = normalize(T);
	//vec3 binormal = normalize(B);  

	return mat3(T, B, normal);
}

mat3 GetTangentBasis2(vec3 normal, vec3 viewdir, vec2 tucoord)
{
	// get edge vectors of the pixel triangle
	vec3 dp1  = dFdx(viewdir);
	vec3 dp2  = dFdy(viewdir);
	vec2 duv1 = dFdx(tucoord);
	vec2 duv2 = dFdy(tucoord);
	
	vec3 v1 = vec3(0,0,0);
	vec3 v2 = dp1;
	vec3 v3 = dp2;

	vec2 w1 = vec2(0,0);
	vec2 w2 = duv1;
	vec2 w3 = duv2;

	float x1 = v2.x - v1.x;
	float x2 = v3.x - v1.x;
	float y1 = v2.y - v1.y;
	float y2 = v3.y - v1.y;
	float z1 = v2.z - v1.z;
	float z2 = v3.z - v1.z;

	float s1 = w2.x - w1.x;
	float s2 = w3.x - w1.x;
	float t1 = w2.y - w1.y;
	float t2 = w3.y - w1.y;

	float r = 1.0F / (s1 * t2 - s2 * t1);
	vec3 T = vec3((t2 * x1 - t1 * x2) * r,
				  (t2 * y1 - t1 * y2) * r,
				  (t2 * z1 - t1 * z2) * r);
	vec3 B = vec3((s1 * x2 - s2 * x1) * r, 
				  (s1 * y2 - s2 * y1) * r,
				  (s1 * z2 - s2 * z1) * r);
	
	return mat3(normalize(T), normalize(B), normal);
}

void main()
{
	vec4 albedo = texture(diffuseSampler, uv.xy);
	
	#ifdef CARPAINT
	albedo.rgb = mix(colorTint.rgb, albedo.rgb, albedo.a); // albedo is mixed from diffuse and object color
	#else
	// emulate alpha testing
	if (albedo.a < 0.5)
		discard;
	#endif
	
	vec4 materialPropertyMap = texture(materialPropertiesSampler, uv.xy);
	
	vec3 eyeSpaceNormal = normalize(normal);
	
	#ifdef NORMALMAPS
	vec4 normalMap = texture(normalMapSampler, uv.xy);
	//vec4 normalMap = textureLod(normalMapSampler, uv.xy, 0);
	
	//albedo.xyz = eyeSpaceNormal.xyz;
	
	if (length(normalMap.xyz) > 0.25)
	{
		vec3 bumpNormal = normalMap.xyz*2.0-vec3(1,1,1);
		//bumpNormal.xy *= 0.1;
		bumpNormal = normalize(bumpNormal);
		//mat3 tangentBasis = GetTangentBasis(normal, normalize(-eyespacePosition), uv.xy);
		mat3 tangentBasis = GetTangentBasis2(normal, eyespacePosition, uv.xy);
		//eyeSpaceNormal = bumpNormal.x*tangentBasis[0] + bumpNormal.y*tangentBasis[1] + bumpNormal.z*tangentBasis[2]; 
		eyeSpaceNormal = tangentBasis*bumpNormal;
		
		//albedo.xyz = abs(cross(tangentBasis[0],tangentBasis[1]));
		//albedo.xyz = eyeSpaceNormal.xyz;
		//albedo.xyz = vec3(abs(bumpNormal));
	}
	//eyeSpaceNormal = vec3(0,0,-1);
	#endif // NORMALMAPS
	
	vec2 normalToPack = vec2(atan(eyeSpaceNormal.y,eyeSpaceNormal.x)/3.14159265358979323846, eyeSpaceNormal.z)*0.5+vec2(0.5,0.5);
    #ifdef SIMPLE_NORMAL_ENCODING
    vec3 normalXYZ = eyeSpaceNormal.xyz*0.5+vec3(0.5,0.5,0.5);
    #endif
	vec2 normalX = packFloatToVec2i(normalToPack.x);
	vec2 normalY = packFloatToVec2i(normalToPack.y);
	
	float m = materialPropertyMap.a;
	vec3 Rf0 = materialPropertyMap.rgb;
	//m = 1.0;
	//Rf0 = vec3(1,1,1);
	
	#ifdef CARPAINT
	float carpaintMask = 1.0;//-albedo.a; car paint mask should not affect reflectivity
	#else
	float carpaintMask = 0.0;
	#endif
	
	materialProperties = vec4(Rf0, m);
	normalXY = vec4(normalX, normalY);
    #ifdef SIMPLE_NORMAL_ENCODING
	normalXY = vec4(normalXYZ, 0);
    #endif
	diffuseAlbedo = vec4(albedo.rgb, carpaintMask);
	
	gl_FragDepth = gl_FragCoord.z + depthOffset;
}

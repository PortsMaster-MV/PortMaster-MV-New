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

uniform sampler2D tu0_2D; // diffuse
uniform sampler2D tu1_2D; // misc map 1 (specular color in RGB, specular power in A)
uniform sampler2D tu2_2D; // misc map 2 (RGB is normal map)
uniform vec4 color_tint;

varying vec2 texcoord;
varying vec3 N;
varying vec3 V;

OUT(vec4 FragData0)
OUT(vec4 FragData1)
OUT(vec4 FragData2)

vec2 packFloatToVec2i(const float val)
{
	float value = clamp(val,0.0,0.9999);
	vec2 bitSh = vec2(256.0, 1.0);
	vec2 bitMsk = vec2(0.0, 1.0/256.0);
	vec2 res = fract(value * bitSh);
	res -= res.xx * bitMsk;
	return res;
}

vec2 TweakTextureCoordinates(vec2 incoord, float textureSize)
{
	vec2 t = incoord * textureSize - .5;
	vec2 frc = fract(t);
	vec2 flr = t - frc;
	frc = frc*frc*(3.-2.*frc);//frc*frc*frc*(10+frc*(6*frc-15));
	return (flr + frc + .5)*(1./textureSize);
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

void main()
{
	vec4 albedo = texture2D(tu0_2D, texcoord);
	
	#ifdef _CARPAINT_
	albedo.rgb = mix(color_tint.rgb, albedo.rgb, albedo.a); // albedo is mixed from diffuse and object color
	#else
	// emulate alpha testing
	if (albedo.a < 0.5)
		discard;
	#endif
	
	vec4 miscmap1 = texture2D(tu1_2D, texcoord);
	//vec4 miscmap2 = texture2D(tu2_2D, TweakTextureCoordinates(texcoord, 512.0));
	vec4 miscmap2 = texture2D(tu2_2D, texcoord);
	float notshadow = 1.0;
	
	vec3 normal = normalize(N);
	#ifdef _NORMALMAPS_
	if (length(miscmap2.xyz) > 0.25)
	{
		vec3 bumpnormal = miscmap2.xyz*2.0-1.0;
		mat3 tangentBasis = GetTangentBasis(normal, normalize(-V), texcoord);
		normal = tangentBasis*bumpnormal;
	}
	#endif
	vec2 normal_topack = vec2(atan(normal.y,normal.x)/3.14159265358979323846, normal.z)*0.5+vec2(0.5,0.5);
	vec2 normal_x = packFloatToVec2i(normal_topack.x);
	vec2 normal_y = packFloatToVec2i(normal_topack.y);
	
	FragData0 = miscmap1;
	FragData1 = vec4(normal_x.x, normal_x.y, normal_y.x, normal_y.y);
	FragData2 = vec4(albedo.rgb,notshadow);

	//FragData2.a = -normal.z*4.0;//;sqrt(1.0-normal.x*normal.x-normal.y*normal.y)*4.0;
	//FragData2.a = dot(normal,normalize(-V));
	//FragData2.a = normal.z*normalize(-V).z*0.5+0.5;
	//FragData2.a = normal.z*0.5+0.5;
	//FragData2.rgb = normalize(-V);

	/*vec3 Vv = normalize(V);
	//Vv.b = -Vv.b;
	FragData2 = vec4(Vv,1);*/
}

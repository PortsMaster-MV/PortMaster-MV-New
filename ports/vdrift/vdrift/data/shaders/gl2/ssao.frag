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

uniform sampler2D tu0_2D; // full scene depth
uniform sampler2D tu1_2D; // normal XY components

uniform vec3 frustum_corner_bl;
uniform vec3 frustum_corner_br_delta;
uniform vec3 frustum_corner_tl_delta;

varying vec3 eyespace_view_direction;
varying float q;  // equivalent to ProjectionMatrix[2].z
varying float qn; // equivalent to ProjectionMatrix[3].z

OUT(vec4 FragColor)

const float scale = 4.0;
const float bias = 0.05;
const float sample_radius = 0.1;
const float intensity = 3.0;
const float self_occlusion = 0.0;

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

vec3 GetNormalFromScreenspace(vec2 screenspace_uv)
{
	vec4 gbuf_normal_xy = texture2D(tu1_2D, screenspace_uv);
	vec2 normal_spherical = vec2(unpackFloatFromVec2i(gbuf_normal_xy.xy),unpackFloatFromVec2i(gbuf_normal_xy.zw))*2.0-vec2(1.0,1.0);
	return sphericalToXYZ(normal_spherical);
}

vec3 GetEyespacePositionFromScreenspaceAndDepth(vec2 screenspace_uv, float gbuf_depth)
{
	vec3 viewdir = frustum_corner_bl + frustum_corner_br_delta*screenspace_uv.x + frustum_corner_tl_delta*screenspace_uv.y;
	
	float eyespace_z = qn / (gbuf_depth * -2.0 + 1.0 - q); //http://www.opengl.org/discussion_boards/ubbthreads.php?ubb=showflat&Number=277938
	return vec3(viewdir.xy/viewdir.z*eyespace_z,eyespace_z); //http://lumina.sourceforge.net/Tutorials/Deferred_shading/Point_light.html
}

vec3 GetEyespacePositionFromScreenspace(vec2 screenspace_uv)
{
	// retrieve g-buffer
	float gbuf_depth = texture2D(tu0_2D, screenspace_uv).r;
	return GetEyespacePositionFromScreenspaceAndDepth(screenspace_uv, gbuf_depth);
}

float AmbientOcclusion(vec2 tcoord, vec2 uv, vec3 p, vec3 cnorm)
{
	vec3 diff = GetEyespacePositionFromScreenspace(tcoord + uv) - p;
	vec3 v = normalize(diff);
	float d = length(diff)*scale;
	return max(0.0-self_occlusion,dot(cnorm,v)-bias)*(1.0/(1.0+d*d))*intensity;
}

float GetRandom(in vec2 screencoord)
{
	const vec2 screen = vec2(SCREENRESX,SCREENRESY);
	vec2 coord = fract(screencoord*screen*0.5);
	float top = mix(1.0,0.75,coord.x);
	float bottom = mix(0.5,0.25,coord.x);
	return mix(bottom,top,coord.y);
}

vec2 RandomNoise(in vec2 coord)
{
	float noiseX = (fract(sin(dot(coord,vec2(12.9898,78.233))) * 43758.5453));
	float noiseY = (fract(sin(dot(coord,vec2(12.9898,78.233)*2.0)) * 43758.5453));
	return vec2(noiseX,noiseY);
}

void main()
{
	vec2 screen = vec2(SCREENRESX,SCREENRESY);
	vec2 screencoord = gl_FragCoord.xy/screen;
	
	// retrieve g-buffer
	float gbuf_depth = texture2D(tu0_2D, screencoord).r;
	
	// early discard
	if (gbuf_depth == 1) discard;
	
	vec2 vec[4];
	vec[0] = vec2(1.,0.);
	vec[1] = vec2(-1.,0.);
	vec[2] = vec2(0.,1.);
	vec[3] = vec2(0.,-1.);

	vec3 p = GetEyespacePositionFromScreenspaceAndDepth(screencoord, gbuf_depth);
	vec3 n = GetNormalFromScreenspace(screencoord);
	float ao = 0.0;
	float rad = sample_radius/max(-10.,p.z);
	
	vec2 rand = RandomNoise(screencoord);
	float rand1 = GetRandom(screencoord);
	int iterations = 4;
	for (int i = 0; i < iterations; i++)
	{
		//vec2 coord1 = reflect(vec[i],rand)*rad;
		vec2 coord1 = vec[i]*rad*rand1;
		//vec2 coord1 = vec[i]*rad;
		vec2 coord2 = vec2(coord1.x*0.707 - coord1.y*0.707, coord1.x*0.707 + coord1.y*0.707);

		#ifdef _SSAO_HIGH_
		ao += AmbientOcclusion(screencoord, coord1*0.25, p, n);
		ao += AmbientOcclusion(screencoord, coord2*0.5, p, n);
		#endif
		ao += AmbientOcclusion(screencoord, coord1*0.75, p, n);
		ao += AmbientOcclusion(screencoord, coord2, p, n);
	}
	#ifdef _SSAO_HIGH_
	ao/=float(iterations)*4.0;
	#else
	ao/=float(iterations)*2.0;
	#endif
	ao += self_occlusion;
	
	//vec4 final = vec4(0.0,0.0,0.0,ao);
	vec4 final = vec4(1.,1.,1.,1.)*ao;
	final.a = 1.;
	
	FragColor = final;
}

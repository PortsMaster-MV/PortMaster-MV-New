#version 330

uniform sampler2D diffuseSampler;
uniform mat4 projectionMatrix;

in vec3 normal;
in vec3 uv;
in vec3 eyespacePosition;

out vec4 outputDepth;

vec2 computeMoments(float Depth)  
{
	vec2 Moments;
	
	// First moment is the depth itself.  
	Moments.x = Depth;
	
	// Compute partial derivatives of depth.  
	float dx = dFdx(Depth);
	float dy = dFdy(Depth);
	
	// Compute second moment over the pixel extents.  
	//Moments.y = Depth*Depth + 0.25*(dx*dx + dy*dy);
	Moments.y = Depth*Depth;
	return Moments;
}

void main(void)
{
	vec4 diffuseTexture = texture(diffuseSampler, uv.xy);
	
	vec4 albedo;
	
	float linearz = clamp(gl_FragCoord.z*gl_FragCoord.w,0,1);
	
	// standard VSM
	//albedo = vec4(computeMoments(linearz),0,1);
	
	// exponentially-warped VSM
	const float exponentialWarpConstant = 42;
	float warpedz = exp(linearz*exponentialWarpConstant);
	albedo = vec4(computeMoments(warpedz),0,1);
	
	outputDepth.rgba = albedo;
}

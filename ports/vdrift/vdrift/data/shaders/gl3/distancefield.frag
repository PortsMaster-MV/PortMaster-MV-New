#version 330

uniform sampler2D diffuseSampler;
uniform vec4 colorTint;

in vec3 normal;
in vec3 uv;
out vec4 outputColor;

void main()
{
	vec4 texcolor = texture(diffuseSampler, uv.xy);
	texcolor.rgb *= colorTint.rgb;
	float distanceFactor = texcolor.a;
	
	//anti-aliasing
	float width = dFdx(uv.x) * 70.0;
	texcolor.a = smoothstep(0.5-width, 0.5+width, texcolor.a);
	
	float glowFactor = smoothstep(0.0, 1.0, distanceFactor);
	texcolor = mix(vec4(0.0, 0.0, 0.0, glowFactor), texcolor, texcolor.a);
	
	texcolor.a *= colorTint.a;
	
	outputColor = texcolor;
}

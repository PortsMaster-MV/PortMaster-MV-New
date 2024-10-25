#version 330

uniform sampler2D depthSampler;
uniform vec2 viewportSize;

void main(void)
{
	gl_FragDepth = texture(depthSampler, gl_FragCoord.xy/viewportSize).r;
}

#version 330

uniform sampler2D diffuseSampler;
uniform vec2 invViewportSize;

in vec3 uv;

out vec4 outputColor;

// construct a vec2 offset from a float offset depending on whether or not this is a horizontal or vertical blur
vec2 getOffset2(float offset)
{
	#ifdef HORIZONTAL
		return vec2(offset, 0);
	#else
		return vec2(0, offset);
	#endif
}

vec4 sample(vec2 uv, vec2 invViewportSize, float weight, float offset)
{
	vec2 offset2 = getOffset2(offset);
	return weight*texture(diffuseSampler, uv.xy+offset2*invViewportSize);
}

//#define BOX
//#define DISABLE
//#undef BOX

void main(void)
{
	vec4 final = vec4(0,0,0,0);
	
	#ifndef DISABLE
		#ifdef BOX
		{
			const int taps = 7; // we get the effect of twice this due to linear texture filtering
			
			// sample in first direction (right/down)
			for (int i = 0; i < taps/2+1; i++)
			{
				float offset = float(i*2)+0.5;
				
				vec2 offset2 = getOffset2(offset);
				
				final += texture(diffuseSampler, uv.xy+offset2*invViewportSize);
			}
			
			// sample in second direction (left/up)
			for (int i = 1; i < taps/2+1; i++)
			{
				float offset = float(-i*2)+0.5;
				
				vec2 offset2 = getOffset2(offset);
				
				final += texture(diffuseSampler, uv.xy+offset2*invViewportSize);
			}
			
			final = final / taps;
		}
		#else
		{
			// gaussian-like 5-tap (http://assassinationscience.com/johncostella/magic/)
			final += sample(uv.xy, invViewportSize, 0.3, -1.16666667);
			final += sample(uv.xy, invViewportSize, 0.4, 0.);
			final += sample(uv.xy, invViewportSize, 0.3, 1.16666667);
		}
		#endif
	#else
		final = texture(diffuseSampler, uv.xy);
	#endif
	
	outputColor.rgba = final;
}

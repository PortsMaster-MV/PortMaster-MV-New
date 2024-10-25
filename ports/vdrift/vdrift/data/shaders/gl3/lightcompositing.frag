#version 330

uniform sampler2D lightBufferSampler;

in vec3 uv;

out vec4 outputColor;

vec3 linearTonemap(vec3 color)
{
	return color;
}

vec3 reinhardTonemap(vec3 color)
{
	return color/(vec3(1,1,1)+color);
}

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

// includes pow(x,1/2.2)
vec3 hejlTonemap(vec3 linearColor)
{
	vec3 x = max(vec3(0), linearColor-vec3(0.004));
	return (x*(6.2*x+vec3(0.5)))/(x*(6.2*x+vec3(1.7))+vec3(0.06));
}

float GetColorLuminance( vec3 color )
{
	return dot( color, vec3( 0.2126f, 0.7152f, 0.0722f ) );
}

vec3 adjustSaturation(vec3 val)
{
    val = mix(vec3(GetColorLuminance(val)), val, 0.0);
    return val;
}

float vignette(vec2 uvCoord)
{
    return 1.0f-length(vec2(0.5,0.5) - uvCoord.xy);
}

void main(void)
{
	vec4 lightBuffer = texture(lightBufferSampler, uv.xy);
	//lightBuffer.rgb = pow(lightBuffer.rgb,vec3(2.2));

    // vignette
    //lightBuffer *= vignette(uv.xy);
	
	vec4 final = vec4(0,0,0,1);
	
	//final.rgb = linearTonemap(lightBuffer.rgb);
	
	float exposureBias = 10.0;
	//float exposureBias = 4.0;
	vec3 curr = pow(hableTonemap(exposureBias*lightBuffer.rgb),vec3(1/2.2));
	//vec3 curr = hejlTonemap(exposureBias*lightBuffer.rgb);
	//vec3 curr = pow(reinhardTonemap(exposureBias*lightBuffer.rgb*0.5),vec3(1/2.2));
	
	/*vec3 curr = hableTonemap(exposureBias*lightBuffer.rgb);
	const float W = 11.2;
	vec3 whiteScale = 1.0/hableTonemap(vec3(W));
	final.rgb = pow(curr*whiteScale,vec3(1/2.2));*/
	final.rgb = curr;
	
	outputColor.rgba = final;
}

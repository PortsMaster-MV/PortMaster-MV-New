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

uniform sampler2D tu0_2D;

OUT(vec4 FragColor)

float GetColorLuminance( vec3 color )
{
	return dot( color, vec3( 0.2126f, 0.7152f, 0.0722f ) );
}

void main()
{
	//vec2 screen = vec2(SCREENRESX,SCREENRESY);
	//vec4 outcol = texture2D(tu0_2D, gl_FragCoord.xy/screen);
	vec2 pixelViewport = vec2(1.0/SCREENRESX, 1.0/SCREENRESY);
	vec2 uv = gl_FragCoord.xy*pixelViewport;
	
	const float filterStrengthNormalScale = 3.0;
	const float filterStrengthBlurScale = 3.0;
	const vec2 maxNormal = vec2(0.8,0.8);
	
	// Normal, scale it up 3x for a better coverage area
	vec2 upOffset = vec2( 0.0, pixelViewport.y ) * filterStrengthNormalScale;
	vec2 rightOffset = vec2( pixelViewport.x, 0.0 ) * filterStrengthNormalScale;

	float topHeight = GetColorLuminance( texture2D( tu0_2D, uv.xy+upOffset).rgb );
	float bottomHeight = GetColorLuminance( texture2D( tu0_2D, uv.xy-upOffset).rgb );
	float rightHeight = GetColorLuminance( texture2D( tu0_2D, uv.xy+rightOffset).rgb );
	float leftHeight = GetColorLuminance( texture2D( tu0_2D, uv.xy-rightOffset).rgb );
	float leftTopHeight = GetColorLuminance( texture2D( tu0_2D, uv.xy-rightOffset+upOffset).rgb );
	float leftBottomHeight = GetColorLuminance( texture2D( tu0_2D, uv.xy-rightOffset-upOffset).rgb );
	float rightBottomHeight = GetColorLuminance( texture2D( tu0_2D, uv.xy+rightOffset-upOffset).rgb );
	float rightTopHeight = GetColorLuminance( texture2D( tu0_2D, uv.xy+rightOffset+upOffset).rgb );
	
	// Normal map creation
	/*float sum0 = rightTopHeight+ topHeight + rightBottomHeight;
	float sum1 = leftTopHeight + bottomHeight + leftBottomHeight;*/
	float sum0 = rightTopHeight+ topHeight + leftTopHeight;
	float sum1 = leftBottomHeight + bottomHeight + rightBottomHeight;
	float sum2 = leftTopHeight + leftHeight + leftBottomHeight;
	float sum3 = rightBottomHeight + rightHeight + rightTopHeight ;

	// Then for the final vectors, just subtract the opposite sample set.
	// The amount of "antialiasing" is directly related to "filterStrength".
	// Higher gives better AA, but too high causes artifacts.
	float v1 = (sum1 - sum0);
	float v2 = (sum2 - sum3);

	// Put them together and multiply them by the offset scale for the final result.
	vec2 Normal = vec2(v1, v2)*filterStrengthBlurScale;
	/*float normLength = max(maxNormal.x,Normal.length());
	Normal /= normLength;
	Normal *= maxNormal.y;*/
	Normal = clamp(Normal, -vec2(1.,1.)*maxNormal.x, vec2(1.,1.)*maxNormal.y);
	
	// Color
	Normal.xy *= pixelViewport;
	vec4 Scene0 = texture2D( tu0_2D, uv.xy );
	vec4 Scene1 = texture2D( tu0_2D, uv.xy + Normal.xy );
	vec4 Scene2 = texture2D( tu0_2D, uv.xy - Normal.xy );
	vec4 Scene3 = texture2D( tu0_2D, uv.xy + vec2(Normal.x, -Normal.y) );
	vec4 Scene4 = texture2D( tu0_2D, uv.xy - vec2(Normal.x, -Normal.y) );

	// Final color
	FragColor.rgb = ((Scene0 + Scene1 + Scene2 + Scene3 + Scene4) * 0.2).rgb;
	FragColor.a = 1.0;
}

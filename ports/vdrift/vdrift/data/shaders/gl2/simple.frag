#version 120

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
uniform vec4 color_tint;

#ifdef _LIGHTING_
uniform vec3 light_direction;
varying vec3 normal;
#endif

varying vec2 texcoord;

OUT(vec4 FragColor)

#ifdef _GAMMA_
#define GAMMA 2.2
vec3 UnGammaCorrect(vec3 color)
{
    return pow(color, vec3(1.0/GAMMA,1.0/GAMMA,1.0/GAMMA));
}
vec3 GammaCorrect(vec3 color)
{
    return pow(color, vec3(GAMMA,GAMMA,GAMMA));
}
#undef GAMMA
#endif

void main()
{
    vec4 color = texture2D(tu0_2D, texcoord);

    #ifdef _ALPHATEST_
    if (color.a < 0.5)
        discard;
    #endif

    #ifdef _GAMMA_
    color.rgb = GammaCorrect(color.rgb);
    #endif

    #ifdef _CARPAINT_
    // albedo mixed from diffuse and object color
    color.rgb = mix(color_tint.rgb, color.rgb, color.a); 
    color.a = 1.0;  // Make sure we use float literal
    #else
    // albedo modulated by object color
    color *= color_tint;
    #endif

    #ifdef _LIGHTING_
    // lambert diffuse + const ambient
    float nl = max(dot(normalize(normal), light_direction), 0.0);
    color.rgb = color.rgb * nl + color.rgb * vec3(0.46, 0.46, 0.5);
    #endif

    #ifdef _PREMULTIPLY_ALPHA_
    color.rgb *= color.a;  // This is the line that was causing issues
    #endif

    FragColor = color;
}
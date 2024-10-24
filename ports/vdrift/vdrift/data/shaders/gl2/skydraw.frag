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

uniform samplerCube sky_sampler;

varying vec3 view_direction;

OUT(vec4 FragColor)

void main()
{
    FragColor = textureCube(sky_sampler, view_direction);
}

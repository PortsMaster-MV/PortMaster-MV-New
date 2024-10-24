#version 120

#if __VERSION__ > 120
#define attribute in
#define varying out
#endif

uniform mat4 ModelViewProjMatrix;
uniform mat4 ModelViewMatrix;

attribute vec3 VertexPosition;
attribute vec3 VertexNormal;
attribute vec2 VertexTexCoord;
attribute vec4 VertexColor;

varying vec2 texcoord;

#ifdef _LIGHTING_
varying vec3 normal;
#endif

#ifdef _VCOLOR_
varying vec4 vcolor;
#endif

void main()
{
    gl_Position = ModelViewProjMatrix * vec4(VertexPosition, 1.0);
    texcoord = VertexTexCoord;
    
    #ifdef _LIGHTING_
    normal = normalize(vec3(ModelViewMatrix * vec4(VertexNormal, 0.0)));
    #endif
    
    #ifdef _VCOLOR_
    vcolor = VertexColor;
    #endif
}
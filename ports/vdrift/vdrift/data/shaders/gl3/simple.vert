#version 330

invariant gl_Position;

uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;

in vec3 vertexPosition;
in vec3 vertexNormal;
in vec4 vertexTangent;
in vec3 vertexTexCoord;
in vec4 vertexColor;

out vec3 normal;
#ifdef TANGENTSPACE
out vec4 tangent;
#endif
out vec4 vcolor;
out vec3 uv;
out vec3 eyespacePosition;

void main(void)
{
	// compute the model view matrix
	mat4 modelViewMatrix = viewMatrix*modelMatrix;
	mat3 modelViewMatrix3 = mat3(modelViewMatrix);
	
	// transform the normal into eye space
	normal = modelViewMatrix3*vertexNormal;
	
	// transform the tangent eye space
	#ifdef TANGENTSPACE
	tangent = vec4(modelViewMatrix3*vertexTangent.xyz, vertexTangent.w);
	#endif
	
	// pass along the uv unmodified
	uv = vertexTexCoord;
	
	// pass along the color
	vcolor = vertexColor;
	
	// transform the position into eye space
	eyespacePosition = (modelViewMatrix*vec4(vertexPosition, 1.0)).xyz;
	
	// transform the position into screen space
	vec4 position = projectionMatrix*vec4(eyespacePosition, 1.0);
	#ifndef SKYBOX
	gl_Position = position;
	#else
	gl_Position = vec4(position.xy, position.w*0.999999, position.w);
	#endif
}

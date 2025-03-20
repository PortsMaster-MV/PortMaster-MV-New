#version 100
precision highp float;

uniform vec2 textureSize0;
uniform vec2 textureSize1;
uniform vec2 textureSize2;
uniform vec2 textureSize3;
uniform vec2 screenSize;
uniform mat3 vertexTransform;
uniform vec2 lightMapSize;
uniform vec2 lightMapScale;
uniform vec2 lightMapOffset;

attribute vec2 vertexPosition;
attribute vec2 vertexTextureCoordinate;
attribute vec4 vertexColor;
attribute float vertexData; // textureIndex (bits 0-1), lightMapMultiplier (bit 2)

varying highp vec2 fragmentTextureCoordinate;
varying float fragmentTextureIndex;
varying mediump vec4 fragmentColor;
varying float fragmentLightMapMultiplier; 
varying mediump vec2 fragmentLightMapCoordinate;

void main() {
  // Unpack data
  float textureIndex = mod(vertexData, 4.0); // Bits 0-1
  float lightMapMultiplier = step(4.0, vertexData); // Bit 2
  
  vec3 transformed = vertexTransform * vec3(vertexPosition, 1.0);
  vec2 screenPosition = transformed.xy;
  
  fragmentTextureIndex = textureIndex;
  fragmentLightMapMultiplier = lightMapMultiplier;
  // Apply 2x scale factor for half-sized lightmap textures
  fragmentLightMapCoordinate = (screenPosition / (lightMapScale * 2.0)) - lightMapOffset * lightMapSize / screenSize;
  
  // More efficient texture coordinate calculation
  vec2 invSize;
  if (textureIndex < 0.5) {
    invSize = 1.0 / textureSize0;
  } else if (textureIndex < 1.5) {
    invSize = 1.0 / textureSize1;
  } else if (textureIndex < 2.5) {
    invSize = 1.0 / textureSize2;
  } else {
    invSize = 1.0 / textureSize3;
  }
  fragmentTextureCoordinate = vertexTextureCoordinate * invSize;
  
  fragmentColor = vertexColor;
  gl_Position = vec4((screenPosition / screenSize) * 2.0 - 1.0, 0.0, 1.0);
}

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 textureSize0;
uniform vec2 textureSize1;
uniform vec2 textureSize2;
uniform vec2 textureSize3;
uniform vec2 screenSize;
uniform mat3 vertexTransform;

attribute vec2 vertexPosition;
attribute vec2 vertexTextureCoordinate;
attribute vec4 vertexColor;
attribute float vertexData;

varying vec2 fragmentTextureCoordinate;
varying float fragmentTextureIndex;
varying vec4 fragmentColor;

void main() {
  // Transform the vertex position.
  vec2 screenPosition = (vertexTransform * vec3(vertexPosition, 1.0)).xy;
  gl_Position = vec4(screenPosition / screenSize * 2.0 - 1.0, 0.0, 1.0);
  float vertexTextureIndex = mod(vertexData, 4.0);
  
  // Choose texture coordinate scaling based on the texture index.
  if (vertexTextureIndex > 2.9) {
    fragmentTextureCoordinate = vertexTextureCoordinate / textureSize3;
  } else if (vertexTextureIndex > 1.9) {
    fragmentTextureCoordinate = vertexTextureCoordinate / textureSize2;
  } else if (vertexTextureIndex > 0.9) {
    fragmentTextureCoordinate = vertexTextureCoordinate / textureSize1;
  } else {
    fragmentTextureCoordinate = vertexTextureCoordinate / textureSize0;
  }
  
  fragmentTextureIndex = vertexTextureIndex;
  fragmentColor = vertexColor;
}

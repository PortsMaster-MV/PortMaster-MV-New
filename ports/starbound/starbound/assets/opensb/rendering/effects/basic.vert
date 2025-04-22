#ifdef GL_ES
precision mediump float;
#endif

attribute vec2 vertexPosition;

void main() {
  gl_Position = vec4(vertexPosition, 0.0, 1.0);
}

#version 100
precision highp float;

uniform sampler2D texture0;
uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D texture3;
uniform float lightMapEnabled;  // Changed from bool to float
uniform vec2 lightMapSize;
uniform sampler2D lightMap;
uniform float lightMapMultiplier;

varying highp vec2 fragmentTextureCoordinate;
varying float fragmentTextureIndex;  // Changed from flat in int
varying mediump vec4 fragmentColor;
varying float fragmentLightMapMultiplier;
varying mediump vec2 fragmentLightMapCoordinate;

// Fast approximate bicubic filtering using four bilinear samples.
// Assumes texcoord is in pixel coordinates and that texscale is 1/textureSize.
vec4 fastBicubic(sampler2D tex, vec2 texcoord, vec2 texscale) {
    // Shift so that integer pixel centers are at 0.5, 1.5, 2.5, etc.
    vec2 pixelCoord = texcoord - 0.5;
    // f: fractional part (0...1), iCoord: integer part in pixels.
    vec2 f = fract(pixelCoord);
    vec2 iCoord = floor(pixelCoord);
    
    // Compute smooth weights (same as 3f² - 2f³)
    vec2 w = f * f * (3.0 - 2.0 * f);
    
    // Fetch four neighboring texels (hardware bilinear filtering is still applied).
    vec4 s0 = texture2D(tex, (iCoord + vec2(0.5, 0.5)) * texscale);
    vec4 s1 = texture2D(tex, (iCoord + vec2(1.5, 0.5)) * texscale);
    vec4 s2 = texture2D(tex, (iCoord + vec2(0.5, 1.5)) * texscale);
    vec4 s3 = texture2D(tex, (iCoord + vec2(1.5, 1.5)) * texscale);
    
    // Do bilinear blending with the computed weights.
    return mix(mix(s0, s1, w.x), mix(s2, s3, w.x), w.y);
}

// Use the fast bicubic approximation to sample the light map.
vec3 sampleLight(vec2 coord, vec2 scale) {
  // Here coord is assumed to be in pixel space; scale should be 1.0/textureSize.
  vec3 rgb = fastBicubic(lightMap, coord, scale).rgb;
  
  // Fast path: if no overbright areas, simply return rgb.
  if (rgb.r <= 1.0 && rgb.g <= 1.0 && rgb.b <= 1.0) 
    return rgb;
  
  // Else apply component‑wise tone mapping.
  return vec3(
    rgb.r > 1.0 ? 1.0 + (rgb.r - 1.0)/(1.0 + (rgb.r - 1.0)) : rgb.r,
    rgb.g > 1.0 ? 1.0 + (rgb.g - 1.0)/(1.0 + (rgb.g - 1.0)) : rgb.g,
    rgb.b > 1.0 ? 1.0 + (rgb.b - 1.0)/(1.0 + (rgb.b - 1.0)) : rgb.b
  );
}

void main() {
  vec4 texColor;
  float texIdx = fragmentTextureIndex;
  
  // Choose the correct texture based on index.
  if (texIdx < 0.5) {
    texColor = texture2D(texture0, fragmentTextureCoordinate);
  } else if (texIdx < 1.5) {
    texColor = texture2D(texture1, fragmentTextureCoordinate);
  } else if (texIdx < 2.5) {
    texColor = texture2D(texture2, fragmentTextureCoordinate);
  } else {
    texColor = texture2D(texture3, fragmentTextureCoordinate);
  }
  
  // Discard fully transparent pixels early.
  if (texColor.a <= 0.0) discard;
  
  vec4 finalColor = texColor * fragmentColor;
  float finalLightMapMultiplier = fragmentLightMapMultiplier * lightMapMultiplier;
  
  // Use an efficient alpha test, then apply light map modulation if enabled.
  if (abs(texColor.a - 0.996) < 0.001) {
    finalColor.a = fragmentColor.a;
  } else if (lightMapEnabled > 0.5 && finalLightMapMultiplier > 0.0) {
    // Here we pass the light map coordinate in pixel space and use (1.0/lightMapSize)
    // to convert back to normalized coordinates inside fastBicubic.
    finalColor.rgb *= sampleLight(fragmentLightMapCoordinate, 1.0 / lightMapSize) * finalLightMapMultiplier;
  }

  gl_FragColor = finalColor;
}


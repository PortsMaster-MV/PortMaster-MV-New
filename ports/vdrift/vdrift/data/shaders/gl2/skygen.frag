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

uniform vec3 uLightDirection;

varying vec3 vViewDirection;

OUT(vec4 FragColor)

// henyey-greenstein parameter, aerosol scattering (sun disk size)
//uniform float g;
const float g = -0.990;

// air, aerosol density scale (turbidity)
//uniform vec2 RayleighMieScaleHeight;// = {0.25, 0.1};
//const vec2 RayleighMieScaleHeight = vec2(0.25, 0.1);
const float ScaleHeight = 0.25; // rayleigh scale height

// rgb wavelength(rayleigh and mie)
//const vec3 WaveLength = vec3(0.65, 0.57, 0.475);
const vec3 InvWavelength = vec3(5.602, 9.473, 19.644); // pow(WaveLength, -4.0);
const vec3 WavelengthMie = vec3(1.435, 1.603, 1.869); // pow(WaveLength, -0.84);

const float InnerRadius = 6356.7523142;
const float OuterRadius = 6356.7523142 * 1.0157313;
const float Scale = 1.0 / (6356.7523142 * 1.0157313 - 6356.7523142);

//const float PI = 3.14159265;
//const float ESun = 20.0;
//const float Kr = 0.0025;
//const float Km = 0.0010;
const float KrESun = 0.0025 * 15.0;
const float KmESun = 0.0015 * 15.0;
const float Kr4PI = 0.0025 * 4.0 * 3.1415159;
const float Km4PI = 0.0015 * 4.0 * 3.1415159;

#define NumSamples 4

float MiePhase(float ViewSunCos, float ViewSunCos2)
{
   vec3 HG = vec3(1.5 * ((1.0 - g * g) / (2.0 + g * g)), 1.0 + g * g, 2.0 * g);
   return HG.x * (1.0 + ViewSunCos2) / pow(HG.y - HG.z * ViewSunCos, 1.5);
}

float RayleighPhase(float ViewSunCos2)
{
   return 0.75 * (1.0 + ViewSunCos2);
}

float HitOuterSphere(vec3 Pos, vec3 Dir) 
{
   vec3 L = -Pos;
   float B = dot(L, Dir);
   float C = dot(L, L);
   float D = C - B * B; 
   float q = sqrt(OuterRadius * OuterRadius - D);
   float t = B;
   return t + q;
}

// Sean O'Neil 2004
float ScaleDepth(float ViewSunCos)
{
   float x = 1.0 - ViewSunCos;
   return ScaleHeight * exp(-0.00287 + x * (0.459 + x * (3.83 + x * (-6.80 + x * 5.25))));
}

vec3 Scatter(vec3 ViewPos, vec3 ViewDir, vec3 SunDir)
{
   float Height0 = length(ViewPos);
   float Altitude0 = (Height0 - InnerRadius) * Scale;
   float Depth0 = exp(-Altitude0 / ScaleHeight);
   float ViewAngle0 = dot(ViewDir, ViewPos) / Height0;
   float DepthOffset = Depth0 * ScaleDepth(ViewAngle0);

   float ViewLength = HitOuterSphere(ViewPos , ViewDir);
   float SampleLength = ViewLength / NumSamples;
   float ScaledLength = SampleLength * Scale;
   vec3 SampleRay = ViewDir * SampleLength;
   vec3 SamplePos = ViewPos + SampleRay * 0.5;

   vec3 Color = vec3(0.0, 0.0, 0.0);
   for(int i = 0; i < NumSamples; i++)
   {
      float Height = length(SamplePos);
      float Altitude = (Height - InnerRadius) * Scale;
      float Depth = exp(-Altitude / ScaleHeight);
      float LightAngle = dot(SunDir, SamplePos) / Height;
      float ViewAngle = dot(ViewDir, SamplePos) / Height;
      float OpticalDepth = DepthOffset + Depth * (ScaleDepth(LightAngle) - ScaleDepth(ViewAngle));
      vec3 Attenuate = exp(-OpticalDepth * (InvWavelength * Kr4PI + Km4PI));
      Color += Attenuate * (Depth * ScaledLength);
      SamplePos += SampleRay;
   }
   
   vec3 Ray = Color * KrESun * InvWavelength;
   vec3 Mie = Color * KmESun * WavelengthMie;
   float ViewSunCos = -dot(ViewDir, SunDir);
   float ViewSunCos2 = ViewSunCos * ViewSunCos;
 
   return Ray * RayleighPhase(ViewSunCos2) + Mie * MiePhase(ViewSunCos, ViewSunCos2);
}

void main(void)
{
   vec3 ViewPos = vec3(0, 0, InnerRadius + 0.5);
   vec3 ViewDir = normalize(vViewDirection);
   vec3 SunDir = normalize(uLightDirection);
   vec3 Color = Scatter(ViewPos, ViewDir, SunDir);
   vec3 HDR = 1.0 - exp(Color * -2.0);
   FragColor = vec4(HDR, 1.0f);
}

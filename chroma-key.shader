uniform float3 key_color <
  string label = "Key Color";
  string widget_type = "color";
  string group = "Chroma Key";
> = {0.0, 1.0, 0.0};

uniform float3 secondary_color <
  string label = "Secondary Color";
  string widget_type = "color";
  string group = "Chroma Key";
> = {0.0, 1.0, 0.0};

uniform float black_point <
  string label = "Black Point";
  string widget_type = "slider";
  string group = "Chroma Key";
  float minimum = 0.0;
  float maximum = 1.0;
  float step = 0.001;
> = 0.0;

uniform float white_point <
  string label = "White Point";
  string widget_type = "slider";
  string group = "Chroma Key";
  float minimum = 0.001;
  float maximum = 1.0;
  float step = 0.001;
> = 1.0;

uniform float sharpness <
  string label = "Sharpness";
  string widget_type = "slider";
  string group = "Chroma Key";
  float minimum = 0.001;
  float maximum = 3.0;
  float step = 0.001;
> = 1.0;

uniform float denoise <
  string label = "Denoise";
  string widget_type = "slider";
  string group = "Chroma Key";
  float minimum = 0.0;
  float maximum = 1.0;
  float step = 0.001;
> = 0.0;

uniform bool output_alpha <
  string label = "Output Alpha";
  string group = "Chroma Key";
> = false;

uniform float spill <
  string label = "Amount";
  string widget_type = "slider";
  string group = "Spill Reduction";
  float minimum = 0;
  float maximum = 1.0;
  float step = 0.001;
> = 0.666;

uniform int spill_type <
  string label = "Type";
  string widget_type = "select";
  string group = "Spill Reduction";
  int option_0_value = 0;
  string option_0_label = "Average";
  int option_1_value = 1;
  string option_1_label = "Maximum";
  int option_2_value = 2;
  string option_2_label = "Minimum";
> = 0;

uniform float spill_hue <
  string label = "Hue Shift";
  string widget_type = "slider";
  string group = "Spill Reduction";
  float minimum = -0.333;
  float maximum = 0.333;
  float step = 0.001;
> = 0.0;

uniform float luminance_correction <
  string label = "Luminance Correction";
  string widget_type = "slider";
  string group = "Spill Reduction";
  float minimum = 0.0;
  float maximum = 1.0;
  float step = 0.001;
> = 0.666;

uniform float luminance_tint <
  string label = "Luminance Tint";
  string widget_type = "slider";
  string group = "Spill Reduction";
  float minimum = 0.0;
  float maximum = 1.0;
  float step = 0.001;
> = 1.0;


float normpdf(float x, float sigma)
{
	return 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;
}

float normpdf3(float3 v, float sigma)
{
	return 0.39894*exp(-0.5*dot(v,v)/(sigma*sigma))/sigma;
}

float2 MirrorCoords(float2 coords)
{
  coords[0] = coords[0] >= 0.0 && coords[0] <= 1.0 ? coords[0] : 
              coords[0] < 0.0 ? -coords[0] : 1.0 - coords[0];

  coords[1] = coords[1] >= 0.0 && coords[1] <= 1.0 ? coords[1] : 
              coords[1] < 0.0 ? -coords[1] : 1.0 - coords[1];

  return coords;
}

// Adapted from: https://www.shadertoy.com/view/4dfGDH
float4 BilateralFilterRGB(float4 rgba, float2 uv)
{   
  if (denoise == 0.0) return rgba;

  float kernel[15] = {0.031225216, 0.033322271, 0.035206333, 0.036826804, 0.038138565, 
                      0.039104044, 0.039695028, 0.039894000, 0.039695028, 0.039104044, 
                      0.038138565, 0.036826804, 0.035206333, 0.033322271, 0.031225216};

  const int kSize = 7;
  float3 final_colour = float3(0.0, 0.0, 0.0);
  float Z = 0.0;
  float3 cc;
  float factor;
  float bZ = 1.0 / normpdf(0.0, denoise);
  //read out the texels
  for (int i = -kSize; i <= kSize; ++i) {
    for (int j = -kSize; j <= kSize; ++j) {
        cc = image.Sample(textureSampler, MirrorCoords(uv + float2(i, j) / uv_size)).rgb;
        factor = normpdf3(cc-rgba.rgb, denoise) * bZ * kernel[kSize + j] * kernel[kSize + i];
        Z += factor;
        final_colour += factor * cc;
    }
  }
  if (Z == 0.0) return rgba;
  return float4(final_colour/Z, rgba.a);
}

// A blended complementary color between white and the complement
// e.g. green -> light magenta, blue -> light orange
float3 GetChannelComplement(int channel)
{
  return channel == 1 ? float3(1.0, 0.5, 1.0) : 
         channel == 2 ? float3(1.0, 1.0, 0.5) : 
                        float3(0.5, 1.0, 1.0);
}

float3 ApplyHue(float3 col, float hueAdjust)
{
  float3 sqrt3_3 = float3(0.57735, 0.57735, 0.57735);
  float normalizedHue = hueAdjust * 6.28318530718;
  float cosAngle = cos(normalizedHue);
  // Rodrigues' rotation formula: https://gist.github.com/mairod/a75e7b44f68110e1576d77419d608786
  return col * cosAngle + cross(sqrt3_3, col) * sin(normalizedHue) + sqrt3_3 * dot(sqrt3_3, col) * (1.0 - cosAngle);
}

float ChromaKeyR(float difference, float3 key)
{
  return 1.0 - difference / (key.r - key.g * 0.5 - key.b * 0.5);
}

float ChromaKeyG(float difference, float3 key)
{
  return 1.0 - difference / (key.g - key.r * 0.5 - key.b * 0.5);
}

float ChromaKeyB(float difference, float3 key)
{
  return 1.0 - difference / (key.b - key.r * 0.5 - key.g * 0.5);
}

// https://github.com/NatronGitHub/openfx-misc/blob/294ca3e2c1b18e5aaee0fa8d9c773acb70cee5b2/PIK/PIK.cpp#L1009
// (Ag-Ar*rw-Ab*gbw)<=0?1:clamp(1-(Ag-Ar*rw-Ab*gbw)/(Bg-Br*rw-Bb*gbw))
float ChromaKey(float4 rgba, int channel)
{ 
  float a;
  if (channel == 1) {
    float difference = rgba.g - rgba.r * 0.5 - rgba.b * 0.5;
    if (difference <= 0.0) {
      a = 1.0;
    } else {
      a = ChromaKeyG(difference, key_color) * ChromaKeyG(difference, secondary_color);
    }
  } else if (channel == 2) {
    float difference = rgba.b - rgba.r * 0.5 - rgba.g * 0.5;
    if (difference <= 0.0) {
      a = 1.0;
    } else {
      a = ChromaKeyB(difference, key_color) * ChromaKeyB(difference, secondary_color);
    }
  } else {
    float difference = rgba.r - rgba.g * 0.5 - rgba.b * 0.5;
    if (difference <= 0.0) {
      a = 1.0;
    } else {
      a = ChromaKeyR(difference, key_color) * ChromaKeyR(difference, secondary_color);
    }
  }

  // Make default masks 1.5x stronger since mixing two keys leads to
  // higher chance of transparency
  return pow(saturate(a * 1.5), sharpness);
}

int GetChannel(float3 col) {
  return col.g >= max(col.r, col.b) ? 1 : col.b > max(col.r, col.g) ? 2 : 0;
}

float4 mainImage(VertData v_in) : TARGET
{
  float4 rgba = image.Sample(textureSampler, v_in.uv);
  int channel = GetChannel(key_color);
  
  rgba.a = ChromaKey(BilateralFilterRGB(rgba, v_in.uv), channel);
  if (black_point > 0.0 || white_point < 1.0) {
    rgba.a = lerp(-black_point, 1 / white_point, rgba.a);
  }

  // Shift so the chroma hue (that we want to remove) is always red.
  // Multiply channel by 0.333 since red = 0deg, green = 120deg, blue = 240deg
  float hue = channel * 0.333 + spill_hue;
  float3 normalizedRGB = ApplyHue(rgba.rgb, -hue);

  float v;
  if (spill_type == 0) {
    // Average
    v = (normalizedRGB.g + normalizedRGB.b) * 0.5;
    if (normalizedRGB.r > v) normalizedRGB.r = v;
  } else if (spill_type == 1) {
    // Maximum
    v = max(normalizedRGB.g, normalizedRGB.b);
    if (normalizedRGB.r > v) normalizedRGB.r = v;
  } else {
    // Minimum
    v = min(normalizedRGB.g, normalizedRGB.b);
    if (normalizedRGB.r > v) normalizedRGB.r = v;
  }

  // Now shift the hue back, and interpolate based on the spill value.
  float3 rgb = lerp(rgba.rgb, ApplyHue(normalizedRGB, hue), spill);

  // Calculate luminance according to BT.709
  float luminance = luminance_correction * dot(abs(rgb - rgba.rgb), float3(0.2126, 0.7152, 0.0722));
  float3 luminance_complement = ApplyHue(GetChannelComplement(channel), spill_hue);
  float3 luminance_blend = lerp(float3(1.0, 1.0, 1.0), luminance_complement, luminance_tint);
  rgba.rgb = rgb + luminance * luminance_blend;

  if (output_alpha) {
    rgba.rgb = rgba.a;
  }
  return rgba;
}
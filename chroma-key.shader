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

uniform float detail <
  string label = "Detail";
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

// Since OBS's shader doesn't support longer arrays,
// unwrap array in if statement.
float BilateralKernel(int i)
{
    if (i == 0 || i == 14) return 0.031225216;
    if (i == 1 || i == 13) return 0.033322271;
    if (i == 2 || i == 12) return 0.035206333;
    if (i == 3 || i == 11) return 0.036826804;
    if (i == 4 || i == 10) return 0.038138565;
    if (i == 5 || i == 9) return 0.039104044;
    if (i == 6 || i == 8) return 0.039695028;
    if (i == 7) return 0.039894000;
    return 0.0;
}

float2 MirrorCoords(float2 coords)
{
  if (coords[0] < 0.0) {
    coords[0] = -coords[0];
  }
  if (coords[0] > 1.0) {
    coords[0] = 1.0 - coords[0];
  }
  if (coords[1] < 0.0) {
    coords[1] = -coords[1];
  }
  if (coords[1] > 1.0) {
    coords[1] = 1.0 - coords[1];
  }

  return coords;
}


float4 BilateralFilterRGB(float4 rgba, float2 uv)
{   
    const float SIGMA = 10.0;
    const float MSIZE = 15;

    if (denoise == 0.0) return rgba;
    
    const int kSize = (MSIZE - 1) / 2;
    float3 final_colour = float3(0.0, 0.0, 0.0);
    float Z = 0.0;
    float3 cc;
    float factor;
    float bZ = 1.0 / normpdf(0.0, denoise);
    //read out the texels
    for (int i = -kSize; i <= kSize; ++i) {
        for (int j = -kSize; j <= kSize; ++j) {
            cc = image.Sample(textureSampler, MirrorCoords(uv + float2(i, j) / uv_size)).rgb;
            factor = normpdf3(cc-rgba.rgb, denoise) * bZ * BilateralKernel(kSize + j) * BilateralKernel(kSize + i);
            Z += factor;
            final_colour += factor * cc;
        }
    }

   return float4(final_colour/Z, rgba.a);
}

float GetHueChannel(float3 col)
{
  if (col.g >= max(col.r, col.b)) {
    return 0.333;
  } else if (col.b > max(col.r, col.g)) {
    return 0.666;
  } else {
    return 0.0;
  }
}

float3 GetChannelComplement(float3 col)
{
  if (col.g >= max(col.r, col.b)) {
    return float3(1.0, 0.0, 1.0);
  } else if (col.b > max(col.r, col.g)) {
    return float3(1.0, 1.0, 0.0);
  } else {
    return float3(0.0, 1.0, 1.0);
  }
}

float3 ApplyHue(float3 col, float hueAdjust)
{
  float3 sqrt3_3 = float3(0.57735, 0.57735, 0.57735);
  float normalizedHue = hueAdjust * 6.28318530718;
  float cosAngle = cos(normalizedHue);
  // Rodrigues' rotation formula: https://gist.github.com/mairod/a75e7b44f68110e1576d77419d608786
  return col * cosAngle + cross(sqrt3_3, col) * sin(normalizedHue) + sqrt3_3 * dot(sqrt3_3, col) * (1.0 - cosAngle);
}

float ChromaKeyR(float4 rgba, float3 key)
{
  float difference = rgba.r - rgba.g * 0.5 - rgba.b * 0.5;
  return difference <= 0 ? 1 : 1 - difference / (key.r - key.g * 0.5 - key.b * 0.5);
}

// https://github.com/NatronGitHub/openfx-misc/blob/294ca3e2c1b18e5aaee0fa8d9c773acb70cee5b2/PIK/PIK.cpp#L1009
// (Ag-Ar*rw-Ab*gbw)<=0?1:clamp(1-(Ag-Ar*rw-Ab*gbw)/(Bg-Br*rw-Bb*gbw))
float ChromaKeyG(float4 rgba, float3 key)
{
  float difference = rgba.g - rgba.r * 0.5 - rgba.b * 0.5;
  return difference <= 0 ? 1 : 1 - difference / (key.g - key.r * 0.5 - key.b * 0.5);
}

float ChromaKeyB(float4 rgba, float3 key)
{
  float difference = rgba.b - rgba.r * 0.5 - rgba.g * 0.5;
  return difference <= 0 ? 1 : 1 - difference / (key.b - key.r * 0.5 - key.g * 0.5);
}

float ChromaKey(float4 rgba)
{ 
  float a;
  if (key_color.g >= max(key_color.r, key_color.b)) {
    a = ChromaKeyG(rgba, key_color) * ChromaKeyG(rgba, secondary_color);
  } else if (key_color.b > max(key_color.r, key_color.g)) {
    a = ChromaKeyB(rgba, key_color) * ChromaKeyB(rgba, secondary_color);
  } else {
    a = ChromaKeyR(rgba, key_color) * ChromaKeyR(rgba, secondary_color);
  }

  return pow(clamp(a * 1.5, 0.0, 1.0), detail);
}

float4 mainImage(VertData v_in) : TARGET
{
  float4 rgba = image.Sample(textureSampler, v_in.uv);
  rgba.a = ChromaKey(BilateralFilterRGB(rgba, v_in.uv));
  if (black_point > 0.0 || white_point < 1.0) {
    rgba.a = lerp(-black_point, 1 / white_point, rgba.a);
  }

  // Shift so the chroma hue (that we want to remove) is always red.
  float hue = GetHueChannel(key_color) + spill_hue;
  float3 normalizedRGB = ApplyHue(rgba.rgb, -hue);

  float v;
  if (spill_type == 1) {
    // Maximum
    v = max(normalizedRGB.g, normalizedRGB.b);
    if (normalizedRGB.r > v) normalizedRGB.r = v;
  } else if (spill_type == 2) {
    // Minimum
    v = min(normalizedRGB.g, normalizedRGB.b);
    if (normalizedRGB.r > v) normalizedRGB.r = v;
  } else {
    // Average
    v = (normalizedRGB.g + normalizedRGB.b) * 0.5;
    if (normalizedRGB.r > v) normalizedRGB.r = v;
  }

  // Now shift the hue back, and interpolate based on the spill value.
  float3 rgb = lerp(rgba.rgb, ApplyHue(normalizedRGB, hue), spill);

  float3 difference = abs(rgb - rgba.rgb);
  // Calculate luminance according to BT.709
  float luminance = luminance_correction * dot(difference, float3(0.2126, 0.7152, 0.0722));
  float3 luminance_complement = ApplyHue(GetChannelComplement(key_color), spill_hue);
  float3 luminance_blend = float3(1.0, 1.0, 1.0) * (1.0 - 0.5 * luminance_tint) + 0.5 * luminance_complement * (0.5 * luminance_tint);
  rgba.rgb = rgb + luminance * luminance_blend;

  if (output_alpha) {
    rgba.rgb = rgba.a;
  }
  return rgba;
}
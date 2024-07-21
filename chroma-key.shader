uniform float3 key_color <
  string label = "Key Color";
  string widget_type = "color";
  string group = "Chroma Key";
> = {0.0, 1.0, 0.0};

uniform float similarity <
  string label = "Similarity";
  string widget_type = "slider";
  string group = "Chroma Key";
  float minimum = 0.0;
  float maximum = 0.5;
  float step = 0.001;
> = 0.2;

uniform float smoothness <
  string label = "Smoothness";
  string widget_type = "slider";
  string group = "Chroma Key";
  float minimum = 0.0;
  float maximum = 1.0;
  float step = 0.001;
> = 0.1;

uniform float smoothness_power <
  string label = "Smoothness Power";
  string widget_type = "slider";
  string group = "Chroma Key";
  float minimum = 1.0;
  float maximum = 3.0;
  float step = 0.001;
> = 1.5;

uniform int edge_blur <
    string label = "Edge Blur";
    string widget_type = "slider";
    string group = "Chroma Key";
    int minimum = 0;
    int maximum = 10;
> = 1;

uniform bool output_alpha <
  string label = "Output Alpha";
  string group = "Chroma Key";
> = false;

uniform float black_point <
  string label = "Black Point";
  string widget_type = "slider";
  string group = "Refine Matte";
  float minimum = 0.0;
  float maximum = 1.0;
  float step = 0.001;
> = 0.0;

uniform float white_point <
  string label = "White Point";
  string widget_type = "slider";
  string group = "Refine Matte";
  float minimum = 0.001;
  float maximum = 1.0;
  float step = 0.001;
> = 1.0;

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

uniform float luminance_correction <
  string label = "Luminance Correction";
  string widget_type = "slider";
  string group = "Spill Reduction";
  float minimum = 0;
  float maximum = 1;
  float step = 0.001;
> = 0.666;

uniform float3 luminance_color <
  string label = "Luminance Color";
  string widget_type = "color";
  string group = "Spill Reduction";
> = {1.0, 0.5, 1.0};

float3 GetHue(float3 col)
{
  float minimum = min(min(col.r, col.g), col.b);
  float maximum = max(max(col.r, col.g), col.b);
  if (minimum == maximum) {
    return 0.0;
  }

  float hue;
  if (maximum == col.r) {
    hue = (col.g - col.b) / (maximum - minimum);
  } else if (maximum == col.g) {
    hue = 2.0 + (col.b - col.r) / (maximum - minimum);
  } else {
    hue = 4.0 + (col.r - col.g) / (maximum - minimum);
  }

  hue = hue * 0.1666666666666667;
  return hue;
}

float3 ApplyHue(float3 col, float hueAdjust)
{
  float3 sqrt3_3 = float3(0.57735, 0.57735, 0.57735);
  float normalizedHue = hueAdjust * 6.28318530718;
  float cosAngle = cos(normalizedHue);
  // Rodrigues' rotation formula: https://gist.github.com/mairod/a75e7b44f68110e1576d77419d608786
  return col * cosAngle + cross(sqrt3_3, col) * sin(normalizedHue) + sqrt3_3 * dot(sqrt3_3, col) * (1.0 - cosAngle);
}

float2 RGBtoUV(float3 rgb) 
{
  return float2(
    rgb.r * -0.169 + rgb.g * -0.331 + rgb.b *  0.5    + 0.5,
    rgb.r *  0.5   + rgb.g * -0.419 + rgb.b * -0.081  + 0.5
  );
}

float ChromaKey(float4 rgba)
{
  float chromaDist = distance(RGBtoUV(rgba.rgb), RGBtoUV(key_color));
  float baseMask = chromaDist - similarity;
  float fullMask = pow(clamp(baseMask / smoothness, 0.0, 1.0), smoothness_power);
  if (black_point > 0.0 || white_point < 1.0) {
    fullMask = lerp(-black_point, 1 / white_point, fullMask);
  }
  return fullMask;
}

float BlurChromaKey(float4 rgba, VertData v_in)
{
  if (edge_blur == 0.0) {
    return ChromaKey(rgba);
  }

  float Pi = 6.28318530718; // Pi*2
  float quality = 2.0;
  float directions = 8.0;

  float transparent = ChromaKey(rgba);
  int count = 1;

  [loop] for(float d = 0.0; d < Pi; d += Pi / directions) {
    [loop] for(float i = 1.0 / quality; i <= 1.0; i += 1.0 / quality) {
      float sc = ChromaKey(image.Sample(textureSampler, v_in.uv + float2(cos(d), sin(d)) * edge_blur * i / uv_size));
      transparent += sc;
      count++;
    }
  }

  return transparent / count;
}

float4 mainImage(VertData v_in) : TARGET
{
  float4 rgba = image.Sample(textureSampler, v_in.uv);
  rgba.a = BlurChromaKey(rgba, v_in);

  // Shift so the chroma hue (that we want to remove) is always red.
  float hue = GetHue(key_color);
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
  rgba.rgb = rgb + luminance * luminance_color;

  if (output_alpha) {
    rgba.rgb = rgba.a;
  }
  return rgba;
}
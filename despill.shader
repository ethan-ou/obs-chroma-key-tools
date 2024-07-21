uniform float3 spill_color <
  string label = "Spill Color";
  string widget_type = "color";
> = {0.0, 1.0, 0.0};

uniform float spill <
  string label = "Spill Reduction";
  string widget_type = "slider";
  float minimum = 0;
  float maximum = 1.0;
  float step = 0.001;
> = 0.666;

uniform int type <
  string label = "Type";
  string widget_type = "select";
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
  float minimum = 0;
  float maximum = 1;
  float step = 0.001;
> = 0.666;

uniform float3 luminance_color <
  string label = "Luminance Color";
  string widget_type = "color";
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
  // Rodrigues' rotation formula
  return col * cosAngle + cross(sqrt3_3, col) * sin(normalizedHue) + sqrt3_3 * dot(sqrt3_3, col) * (1.0 - cosAngle);
}

float4 mainImage(VertData v_in) : TARGET
{
  float4 rgba = image.Sample(textureSampler, v_in.uv);

  // Shift so the chroma hue (that we want to remove) is always red.
  float hue = GetHue(spill_color);
  float3 normalizedRGB = ApplyHue(rgba.rgb, -hue);

  float v;
  if (type == 1) {
    // Maximum
    v = max(normalizedRGB.g, normalizedRGB.b);
    if (normalizedRGB.r > v) normalizedRGB.r = v;
  } else if (type == 2) {
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

  return rgba;
}
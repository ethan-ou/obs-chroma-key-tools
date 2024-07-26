uniform float3 key_color <
  string label = "Key Color";
  string widget_type = "color";
  string group = "Chroma Key";
> = {0.0, 1.0, 0.0};

uniform float3 secondary_color <
  string label = "Secondary Color";
  string widget_type = "color";
  string group = "Chroma Key";
> = {0.0, 0.0, 0.0};

uniform float3 tertiary_color <
  string label = "Tertiary Color";
  string widget_type = "color";
  string group = "Chroma Key";
> = {0.0, 0.0, 0.0};

uniform bool original_image <
  string label = "View Original Image";
  string widget_type = "color";
  string group = "Chroma Key";
> = false;

uniform float black_point <
  string label = "Black Point";
  string widget_type = "slider";
  string group = "Chroma Key";
  float minimum = 0.0;
  float maximum = 2.0;
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

uniform float color_balance <
  string label = "Color Balance";
  string widget_type = "slider";
  string group = "Chroma Key";
  float minimum = 0.0;
  float maximum = 1.0;
  float step = 0.001;
> = 0.5;

uniform int denoise <
  string label = "Denoise";
  string widget_type = "slider";
  string group = "Chroma Key";
  int minimum = 0;
  int maximum = 100;
  int step = 1;
> = 0;

uniform bool max_saturation <
  string label = "Force Key Saturation (Details Mode)";
  string group = "Chroma Key";
> = false;

uniform bool output_alpha <
  string label = "Output Alpha";
  string group = "Chroma Key";
> = false;

uniform bool spill_enable <
  string label = "Enable";
  string group = "Spill Reduction";
> = true;

uniform float spill <
  string label = "Amount";
  string widget_type = "slider";
  string group = "Spill Reduction";
  float minimum = 0.0;
  float maximum = 1.0;
  float step = 0.001;
> = 1.0;

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
  float minimum = -1;
  float maximum = 1;
  float step = 0.001;
> = 0.0;

uniform float luminance_correction <
  string label = "Luminance Correction";
  string widget_type = "slider";
  string group = "Spill Reduction";
  float minimum = 0.0;
  float maximum = 1.0;
  float step = 0.001;
> = 1.0;

uniform float3 luminance_tint <
  string label = "Luminance Tint";
  string widget_type = "color";
  string group = "Spill Reduction";
> = {1.0, 1.0, 1.0};

float2 MirrorCoords(float2 coords)
{
  coords[0] = coords[0] >= 0.0 && coords[0] <= 1.0 ? coords[0] : 
              coords[0] < 0.0 ? -coords[0] : 1.0 - coords[0];

  coords[1] = coords[1] >= 0.0 && coords[1] <= 1.0 ? coords[1] : 
              coords[1] < 0.0 ? -coords[1] : 1.0 - coords[1];

  return coords;
}

// https://www.shadertoy.com/view/7d2SDD
float4 sirBirdDenoise(float4 rgba, float2 uv)
{
  if (denoise == 0) return rgba;

  float3 final_color = float3(0.0, 0.0, 0.0);
  float2 samplePixel = float2(1.0, 1.0) / uv_size; 
  float3 sampleCenter = image.Sample(textureSampler, uv).rgb;

  float influenceSum = 0.0;
  float brightnessSum = 0.0;

  float2 pixelRotated = float2(0.0, 1.0);

  for (float x = 0.0; x <= float(denoise); x++) {
    float x_pixel = pixelRotated.x;
    float y_pixel = pixelRotated.y;
    pixelRotated.x = x_pixel * -0.73736885799 + y_pixel * 0.67549031618;
    pixelRotated.y = x_pixel * -0.67549031618 + y_pixel * -0.73736885799;
    
    float2 pixelOffset = 1.0 * pixelRotated * sqrt(x) * samplePixel;
    float3 denoised_color = image.Sample(textureSampler, uv + pixelOffset).rgb;

    float pixelInfluence =   
      pow(saturate(0.5 + 0.5 * dot(normalize(sampleCenter), normalize(denoised_color))), 20.0) * 
      pow(saturate(1.0 - abs(length(denoised_color) - length(sampleCenter))), 8.0);
        
    influenceSum += pixelInfluence;
    final_color += denoised_color * pixelInfluence;
  }

  return saturate(float4(final_color / influenceSum, rgba.a));
}

float3 RGBToHSV(float3 c)
{
  float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
  float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSVToRGB(float3 c)
{
  float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float3 MaxSaturation(float3 c)
{
  float3 hsv = RGBToHSV(c);
  float3 force_saturation = float3(hsv.x, 1.0, hsv.y);
  return HSVToRGB(force_saturation);
}

int GetChannel(float3 col)
{
  return col.g >= max(col.r, col.b) ? 1 : col.b > max(col.r, col.g) ? 2 : 0;
}

// Calculate luminance according to BT.709
float Grayscale(float3 c)
{
  return dot(c, float3(0.2126, 0.7152, 0.0722));
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
  float3 hsv = RGBToHSV(col);
  hsv.x += hueAdjust;
  return HSVToRGB(hsv);
}

float ChromaKeyWeights(float primary, float secondary_1, float secondary_2)
{
  float weights = primary - secondary_1 * (1.0 - color_balance) - secondary_2 * color_balance;
  return weights <= 0.0 ? 0.0 : weights;
}

// https://github.com/NatronGitHub/openfx-misc/blob/294ca3e2c1b18e5aaee0fa8d9c773acb70cee5b2/PIK/PIK.cpp#L1009
// (Ag-Ar*rw-Ab*gbw)<=0?1:clamp(1-(Ag-Ar*rw-Ab*gbw)/(Bg-Br*rw-Bb*gbw))
float ChromaKey(float4 rgba, float3 key)
{
  float channel = GetChannel(key);
  float difference = channel == 1 ? ChromaKeyWeights(rgba.g, rgba.r, rgba.b) : 
                     channel == 2 : ChromaKeyWeights(rgba.b, rgba.r, rgba.g) : 
                                    ChromaKeyWeights(rgba.r, rgba.g, rgba.b);
  if (difference <= 0.0) return 1.0;

  float weights = channel == 1 ? ChromaKeyWeights(key.g, key.r, key.b):
                  channel == 2 ? ChromaKeyWeights(key.b, key.r, key.g):
                                 ChromaKeyWeights(key.r, key.g, key.b);
  if (weights == 0.0) return 1.0;
  return saturate(1.0 - difference / weights);
}

float4 mainImage(VertData v_in) : TARGET
{
  float4 rgba = image.Sample(textureSampler, v_in.uv);
  if (original_image) return rgba;

  int channel = GetChannel(key_color);

  float4 denoise = sirBirdDenoise(rgba, v_in.uv);
  rgba.a = min(
              min(ChromaKey(denoise, max_saturation ? MaxSaturation(key_color) : key_color), 
                  ChromaKey(denoise, max_saturation ? MaxSaturation(secondary_color) : secondary_color)),
                  ChromaKey(denoise, max_saturation ? MaxSaturation(tertiary_color) : tertiary_color));

  if (black_point > 0.0 || white_point < 1.0) {
    rgba.a = saturate(lerp(-black_point, 1 / white_point, rgba.a));
  }

  if (spill_enable) {
    // Shift so the chroma hue (that we want to remove) is always red.
    // Multiply channel by 0.333 since red = 0deg, green = 120deg, blue = 240deg
    float hue = channel * 0.333 + spill_hue * 0.1;
    float3 normalizedRGB = ApplyHue(rgba.rgb, -hue);

    float v = spill_type == 0 ? (normalizedRGB.g + normalizedRGB.b) * 0.5 : 
              spill_type == 1 ? max(normalizedRGB.g, normalizedRGB.b) : 
                                min(normalizedRGB.g, normalizedRGB.b);
    if (normalizedRGB.r > v) normalizedRGB.r = v;

    // Now shift the hue back, and interpolate based on the spill value.
    float3 rgb = lerp(rgba.rgb, ApplyHue(normalizedRGB, hue), spill);

    float luminance = luminance_correction * Grayscale(abs(rgb - rgba.rgb));
    float3 luminance_blend = luminance_tint * luminance;
    rgba.rgb = rgb + luminance_blend;
  }

  if (output_alpha) {
    rgba.rgb = rgba.a;
    rgba.a = 1.0;
  }
  
  return rgba;
}
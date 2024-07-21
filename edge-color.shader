uniform float3 edge_color <
    string label = "Edge Color";
    string widget_type = "color";
> = {1.0, 1.0, 1.0};

uniform float blur_strength <
    string label = "Blur Strength";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 50.0;
    float step = 1.0;
> = 2.0;

uniform float color_strength <
    string label = "Color Strength";
    string widget_type = "color";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 2.0;
    float step = 0.001;
> = 0.5;

float4 mainImage(VertData v_in) : TARGET
{
  float Pi = 6.28318530718; // Pi*2
  float Quality = 4.0;
  float Directions = 16.0;
  
  float4 c = image.Sample(textureSampler, v_in.uv);
  float transparent = c.a;
  int count = 1;

  [loop] for(float d = 0.0; d < Pi; d += Pi / Directions) {
    [loop] for(float i = 1.0 / Quality; i <= 1.0; i += 1.0 / Quality) {
      float sc = image.Sample(textureSampler, v_in.uv + float2(cos(d), sin(d)) * blur_strength  * i / uv_size).a;
      transparent += sc;
      count++;
    }
  }

  float alpha_difference = c.a - (transparent / count);
  if (alpha_difference > 0.0) {
    c.rgb = clamp(c.rgb + edge_color * alpha_difference * color_strength, 0.0, 1.0);  
  }

  return c;
}
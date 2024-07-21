uniform float Size<
    string label = "Size (8.0)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 100.0;
    float step = 1.0;
> = 2.0;

float4 mainImage(VertData v_in) : TARGET
{
  float Pi = 6.28318530718; // Pi*2
  float Quality = 4.0;
  float Directions = 16.0;
  
  float4 c = image.Sample(textureSampler, v_in.uv);
  float transparent = c.a;
  int count = 1;

  [loop] for (float d = 0.0; d < Pi; d += Pi / Directions) {
    [loop] for (float i = 1.0 / Quality; i <= 1.0; i += 1.0 / Quality) {
      float sc = image.Sample(textureSampler, v_in.uv + float2(cos(d), sin(d)) * Size * i / uv_size).a;
      transparent += sc;
      count++;
    }
  }

  c.a = transparent / count; 
  return c;
}
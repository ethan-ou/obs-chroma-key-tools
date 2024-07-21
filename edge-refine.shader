uniform int edge_shrink <
  string label = "Shrink Edges";
  string widget_type = "slider";
  int minimum = 0;
  int maximum = 20;
  int step = 1;
> = 5;

uniform int edge_sharpness <
  string label = "Shrink Sharpness";
  string widget_type = "slider";
  int minimum = 1;
  int maximum = 20;
  int step = 1;
> = 10;

float4 mainImage(VertData v_in) : TARGET
{
  float4 rgba = image.Sample(textureSampler, v_in.uv);

  // Edge Shrink and Sharpness
  if (edge_shrink > 0) {
    [loop] for (int x = -edge_shrink; x < edge_shrink; x++) {
      [loop] for (int y = -edge_shrink; y < edge_shrink; y++) {
        if (abs(x * x) + abs(y * y) < edge_shrink * edge_shrink) {
          float4 t = image.Sample(textureSampler, v_in.uv + float2(x * uv_pixel_interval.x, y * uv_pixel_interval.y));
          if (t.a < 1.0)
            rgba.a = max(rgba.a - (edge_sharpness * 0.005), 0);
        }
      }
    }
  }

  return rgba;
}

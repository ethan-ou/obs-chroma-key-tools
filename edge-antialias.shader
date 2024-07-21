uniform int type <
  string label = "Type";
  string widget_type = "select";
  int option_0_value = 0;
  string option_0_label = "Low Antialias";
  int option_1_value = 1;
  string option_1_label = "Mid Antialias";
  int option_2_value = 2;
  string option_2_label = "Strong Antialias";
> = 3;

float4 mainImage(VertData v_in) : TARGET
{
  float dx = 1 / uv_size.x;
	float dy = 1 / uv_size.y;

  float4 c0 = image.Sample(textureSampler, v_in.uv + float2(-dx, -dy));
  float4 c1 = image.Sample(textureSampler, v_in.uv + float2(0, -dy));
  float4 c2 = image.Sample(textureSampler, v_in.uv + float2(dx, -dy));
  float4 c3 = image.Sample(textureSampler, v_in.uv + float2(-dx, 0));
  float4 c4 = image.Sample(textureSampler, v_in.uv + float2(0, 0));
  float4 c5 = image.Sample(textureSampler, v_in.uv + float2(dx, 0));
  float4 c6 = image.Sample(textureSampler, v_in.uv + float2(-dx, dy));
  float4 c7 = image.Sample(textureSampler, v_in.uv + float2(0, dy));
  float4 c8 = image.Sample(textureSampler, v_in.uv + float2(dx, dy));

  float4 rgba;
  if (type == 0) {
    rgba = (c1 + c3 + 2*c4 + c5 + c7) / 6.0;
  }

  if (type == 1) {
    rgba = (c0 + 2*c1 + c2 + 2*c3 + 4*c4 + 2*c5 + c6 + 2*c7 + c8) / 16.0;
  }

  if (type == 2) {
    rgba = (c0 + c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8) / 9.0;
  }

  rgba.rgb = c4.rgb;
  
	return rgba;
}
float4 mainImage(VertData v_in) : TARGET
{
  float3 p1 = image.Sample(textureSampler, v_in.uv + float2(-1, -1) / uv_size).xyz;
  float3 p2 = image.Sample(textureSampler, v_in.uv + float2(-1, 0) / uv_size).xyz;
  float3 p3 = image.Sample(textureSampler, v_in.uv + float2(-1, 1) / uv_size).xyz;
  float3 p4 = image.Sample(textureSampler, v_in.uv + float2(0, -1) / uv_size).xyz;
  float3 p5 = image.Sample(textureSampler, v_in.uv).xyz;
  float3 p6 = image.Sample(textureSampler, v_in.uv + float2(0, 1) / uv_size).xyz;
  float3 p7 = image.Sample(textureSampler, v_in.uv + float2(1, -1) / uv_size).xyz;
  float3 p8 = image.Sample(textureSampler, v_in.uv + float2(1, 0) / uv_size).xyz;
  float3 p9 = image.Sample(textureSampler, v_in.uv + float2(1, 1) / uv_size).xyz;

  float3 op1 = min(p2, p3);
  float3 op2 = max(p2, p3);
  float3 op3 = min(p5, p6);
  float3 op4 = max(p5, p6);
  float3 op5 = min(p8, p9);
  float3 op6 = max(p8, p9);
  float3 op7 = min(p1, op1);
  float3 op8 = max(p1, op1);
  float3 op9 = min(p4, op3);
  float3 op10 = max(p4, op3);
  float3 op11 = min(p7, op5);
  float3 op12 = max(p7, op5);
  float3 op13 = min(op8, op2);
  float3 op14 = max(op8, op2);
  float3 op15 = min(op10, op4);
  float3 op16 = max(op10, op4);
  float3 op17 = min(op12, op6);
  float3 op18 = max(op12, op6);
  float3 op19 = max(op7, op9);
  float3 op20 = min(op15, op17);
  float3 op21 = max(op15, op17);
  float3 op22 = min(op16, op18);
  float3 op23 = max(op13, op20);
  float3 op24 = min(op23, op21);
  float3 op25 = min(op14, op22);
  float3 op26 = max(op19, op11);
  float3 op27 = min(op24, op25);
  float3 op28 = max(op24, op25);
  float3 op29 = max(op26, op27);
  float3 op30 = min(op29, op28);
  
  return float4(op30, 1.0);
}
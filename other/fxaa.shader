// Created by Reinder Nijhoff 2016
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/ls3GWS
//
//
// FXAA code from: http://www.geeks3d.com/20110405/fxaa-fast-approximate-anti-aliasing-demo-glsl-opengl-test-radeon-geforce/3/
float4 mainImage(VertData v_in) : TARGET
{  
  const float FXAA_SPAN_MAX = 8.0;
  const float FXAA_REDUCE_MUL = 1.0/FXAA_SPAN_MAX;
  const float FXAA_REDUCE_MIN = 1.0/128.0;
  const float FXAA_SUBPIX_SHIFT = 1.0/4.0;

  float3 rgbNW = image.Sample(textureSampler, v_in.uv + float2( 1, 1)/uv_size).rgb;
  float3 rgbNE = image.Sample(textureSampler, v_in.uv + float2( 1,-1)/uv_size).rgb;
  float3 rgbSW = image.Sample(textureSampler, v_in.uv + float2(-1, 1)/uv_size).rgb;
  float3 rgbSE = image.Sample(textureSampler, v_in.uv + float2(-1,-1)/uv_size).rgb;
  float3 rgbM  = image.Sample(textureSampler, v_in.uv).rgb;

  float3 luma = float3(0.299, 0.587, 0.114);
  float lumaNW = dot(rgbNW, luma);
  float lumaNE = dot(rgbNE, luma);
  float lumaSW = dot(rgbSW, luma);
  float lumaSE = dot(rgbSE, luma);
  float lumaM  = dot(rgbM,  luma);

  float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
  float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

  float2 dir;
  dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
  dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

  float dirReduce = max(
      (lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL),
      FXAA_REDUCE_MIN);
  float rcpDirMin = 1.0/(min(abs(dir.x), abs(dir.y)) + dirReduce);
  
  dir = min(float2( FXAA_SPAN_MAX,  FXAA_SPAN_MAX),
        max(float2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
        dir * rcpDirMin)) / uv_size;

  float3 rgbA = (1.0/2.0) * (
      image.Sample(textureSampler, v_in.uv + dir * (1.0/3.0 - 0.5)).rgb +
      image.Sample(textureSampler, v_in.uv + dir * (2.0/3.0 - 0.5)).rgb);
  float3 rgbB = rgbA * (1.0/2.0) + (1.0/4.0) * (
      image.Sample(textureSampler, v_in.uv + dir * (0.0/3.0 - 0.5)).rgb +
      image.Sample(textureSampler, v_in.uv + dir * (3.0/3.0 - 0.5)).rgb);
  
  float lumaB = dot(rgbB, luma);

  if((lumaB < lumaMin) || (lumaB > lumaMax)) return float4(rgbA, 1.0);
  
  return float4(rgbB, 1.0); 
}
float2 MirrorCoords(float2 coords)
{
  coords[0] = coords[0] >= 0.0 && coords[0] <= 1.0 ? coords[0] : 
              coords[0] < 0.0 ? -coords[0] : 1.0 - coords[0];

  coords[1] = coords[1] >= 0.0 && coords[1] <= 1.0 ? coords[1] : 
              coords[1] < 0.0 ? -coords[1] : 1.0 - coords[1];

  return coords;
}

float4 mainImage(VertData v_in) : TARGET
{  
  float4 rgba = image.Sample(textureSampler, v_in.uv) * 0.5;
  rgba += image.Sample(textureSampler, MirrorCoords(v_in.uv + float2( 0.5, 0.5) / uv_size)) * 0.125;
  rgba += image.Sample(textureSampler, MirrorCoords(v_in.uv + float2( 0.5,-0.5) / uv_size)) * 0.125;
  rgba += image.Sample(textureSampler, MirrorCoords(v_in.uv + float2(-0.5,-0.5) / uv_size)) * 0.125;
  rgba += image.Sample(textureSampler, MirrorCoords(v_in.uv + float2(-0.5, 0.5) / uv_size)) * 0.125;	

  return rgba;
}
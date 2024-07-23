

uniform float denoise <
  string label = "denoise";
  string widget_type = "slider";
  float minimum = 0.0;
  float maximum = 1.0;
  float step = 0.001;
> = 0.1;

float normpdf(float x, float sigma)
{
	return 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;
}

float normpdf3(float3 v, float sigma)
{
	return 0.39894*exp(-0.5*dot(v,v)/(sigma*sigma))/sigma;
}

float2 MirrorCoords(float2 coords)
{
  coords[0] = coords[0] >= 0.0 && coords[0] <= 1.0 ? coords[0] : 
              coords[0] < 0.0 ? -coords[0] : 1.0 - coords[0];

  coords[1] = coords[1] >= 0.0 && coords[1] <= 1.0 ? coords[1] : 
              coords[1] < 0.0 ? -coords[1] : 1.0 - coords[1];

  return coords;
}

// Adapted from: https://www.shadertoy.com/view/4dfGDH
float4 mainImage(VertData v_in) : TARGET
{   
    if (denoise == 0.0) return rgba;

    float kernel[15] = {0.031225216, 0.033322271, 0.035206333, 0.036826804, 0.038138565, 
                        0.039104044, 0.039695028, 0.039894000, 0.039695028, 0.039104044, 
                        0.038138565, 0.036826804, 0.035206333, 0.033322271, 0.031225216};

    const int kSize = 7;
    float3 final_colour = float3(0.0, 0.0, 0.0);
    float Z = 0.0;
    float3 cc;
    float factor;
    float bZ = 1.0 / normpdf(0.0, denoise);
    //read out the texels
    for (int i = -kSize; i <= kSize; ++i) {
      for (int j = -kSize; j <= kSize; ++j) {
          cc = image.Sample(textureSampler, MirrorCoords(uv + float2(i, j) / uv_size)).rgb;
          factor = normpdf3(cc-rgba.rgb, denoise) * bZ * kernel[kSize + j] * kernel[kSize + i];
          Z += factor;
          final_colour += factor * cc;
      }
    }

   return float4(final_colour/Z, rgba.a);
}
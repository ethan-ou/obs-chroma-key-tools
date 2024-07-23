

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

// Since OBS's shader doesn't support longer arrays,
// unwrap array in if statement.
float get_kernel(int i)
{
    if (i == 0 || i == 14) return 0.031225216;
    if (i == 1 || i == 13) return 0.033322271;
    if (i == 2 || i == 12) return 0.035206333;
    if (i == 3 || i == 11) return 0.036826804;
    if (i == 4 || i == 10) return 0.038138565;
    if (i == 5 || i == 9) return 0.039104044;
    if (i == 6 || i == 8) return 0.039695028;
    if (i == 7) return 0.039894000;
    return 0.0;
}

float2 MirrorCoords(float2 coords)
{
  if (coords[0] < 0.0) {
    coords[0] = -coords[0];
  }
  if (coords[0] > 1.0) {
    coords[0] = 1.0 - coords[0];
  }
  if (coords[1] < 0.0) {
    coords[1] = -coords[1];
  }
  if (coords[1] > 1.0) {
    coords[1] = 1.0 - coords[1];
  }

  return coords;
}


float4 mainImage(VertData v_in) : TARGET
{   
    float4 c = image.Sample(textureSampler, v_in.uv);

    const float SIGMA = 10.0;
    const float MSIZE = 15;

    if (denoise == 0.0) return c;
    
    const int kSize = (MSIZE - 1) / 2;
    float4 final_colour = float4(0.0, 0.0, 0.0, 0.0);
    float Z = 0.0;
    float4 cc;
    float factor;
    float bZ = 1.0 / normpdf(0.0, denoise);
    //read out the texels
    for (int i = -kSize; i <= kSize; ++i) {
        for (int j = -kSize; j <= kSize; ++j) {
            cc = image.Sample(textureSampler, MirrorCoords(v_in.uv + float2(i, j) / uv_size));
            factor = normpdf3(cc-c, denoise) * bZ * get_kernel(kSize + j) * get_kernel(kSize + i);
            Z += factor;
            final_colour += factor * cc;
        }
    }

   return final_colour/Z;
}


// void mainImage( float4 fragColor, float2 fragCoord )
// {
// 	float3 c = texture(iChannel0, float2(0.0, 1.0)-(fragCoord.xy / iResolution.xy)).rgb;

		
// 		//declare stuff
// 		const int kSize = (MSIZE-1)/2;
// 		float kernel[MSIZE];
// 		float3 final_colour = float3(0.0);
		
// 		//create the 1-D kernel
// 		float Z = 0.0;
// 		for (int j = 0; j <= kSize; ++j)
// 		{
// 			kernel[kSize+j] = kernel[kSize-j] = normpdf(float(j), SIGMA);
// 		}
		
		
// 		float3 cc;
// 		float factor;
// 		float bZ = 1.0 / normpdf(0.0, denoise);
// 		//read out the texels
// 		for (int i=-kSize; i <= kSize; ++i)
// 		{
// 			for (int j=-kSize; j <= kSize; ++j)
// 			{
// 				cc = texture(iChannel0, float2(0.0, 1.0)-(fragCoord.xy+float2(float(i),float(j))) / iResolution.xy).rgb;
// 				factor = normpdf3(cc-c, denoise)*bZ*kernel[kSize+j]*kernel[kSize+i];
// 				Z += factor;
// 				final_colour += factor*cc;

// 			}
// 		}
		
// 		return float4(final_colour/Z, 1.0);

// }
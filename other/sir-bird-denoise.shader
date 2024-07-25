// https://www.shadertoy.com/view/7d2SDD
float3 sirBirdDenoise(float2 uv) {
    int SAMPLES = 80; // HIGHER = NICER = SLOWER
    float DISTRIBUTION_BIAS = 0.0; // between 0. and 1.
    float PIXEL_MULTIPLIER = 3.0; // between 1. and 3. (keep low)
    float INVERSE_HUE_TOLERANCE = 20.0; // (2. - 30.)

    float GOLDEN_ANGLE = 2.3999632; //3PI-sqrt(5)PI

    float3 denoisedColor  = float3(0.0, 0.0, 0.0);
    
    const float sampleRadius = sqrt(float(SAMPLES));
    const float sampleTrueRadius = 0.5 / (sampleRadius*sampleRadius);
    float2 samplePixel = float2(1.0, 1.0) / uv_size; 
    float3 sampleCenter = image.Sample(textureSampler, uv).rgb;
    float3 sampleCenterNorm = normalize(sampleCenter);
    float sampleCenterSat  = length(sampleCenter);
    
    float  influenceSum = 0.0;
    float brightnessSum = 0.0;
    
    float2 pixelRotated = float2(0.0,1.0);
    
    for (float x = 0.0; x <= float(SAMPLES); x++) {
        float x_pixel = pixelRotated.x;
        float y_pixel = pixelRotated.y;
        pixelRotated.x = (x_pixel * cos(GOLDEN_ANGLE)) + (y_pixel * (sin(GOLDEN_ANGLE)));
        pixelRotated.y = (x_pixel * -sin(GOLDEN_ANGLE)) + (y_pixel * (cos(GOLDEN_ANGLE)));
        
        float2 pixelOffset = PIXEL_MULTIPLIER * pixelRotated * sqrt(x)*0.5;
        float pixelInfluence = 1.0-sampleTrueRadius*pow(max(dot(pixelOffset,pixelOffset), 0.0), DISTRIBUTION_BIAS);
        pixelOffset *= samplePixel;
            
        float3 thisDenoisedColor = image.Sample(textureSampler, uv + pixelOffset).rgb;

        pixelInfluence *= pixelInfluence*pixelInfluence;
        /*
            HUE + SATURATION FILTER
        */
        pixelInfluence *=   
            pow(max(0.5+0.5*dot(sampleCenterNorm, normalize(thisDenoisedColor)), 0.0), INVERSE_HUE_TOLERANCE)
            * pow(max(1.0 - abs(length(thisDenoisedColor)-length(sampleCenterSat)), 0.0), 8.0);
            
        influenceSum += pixelInfluence;
        denoisedColor += thisDenoisedColor*pixelInfluence;
    }
    
    return denoisedColor /influenceSum;
}

float4 mainImage(VertData v_in) : TARGET
{   
    
  return float4(sirBirdDenoise(v_in.uv), 1.0);
}
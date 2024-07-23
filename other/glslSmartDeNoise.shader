//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Copyright (c) 2018-2019 Michele Morrone
//  All rights reserved.
//
//  https://michelemorrone.eu - https://BrutPitt.com
//
//  me@michelemorrone.eu - brutpitt@gmail.com
//  twitter: @BrutPitt - github: BrutPitt
//  
//  https://github.com/BrutPitt/glslSmartDeNoise/
//
//  This software is distributed under the terms of the BSD 2-Clause license
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


//  smartDeNoise - parameters
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  sampler2D mainImage     - sampler image / texture
//  float2 uv           - actual fragment coord
//  float sigma  >  0 - sigma Standard Deviation
//  float kSigma >= 0 - sigma coefficient 
//      kSigma * sigma  -->  radius of the circular kernel
//  float threshold   - edge sharpening threshold 


//float4 smartDeNoise(sampler2D mainImage, float2 uv, float sigma, float kSigma, float threshold)

uniform float threshold <
//   string label = "Spill Reduction";
  string widget_type = "slider";
  float minimum = 0;
  float maximum = 3.0;
  float step = 0.001;
> = 1.0;

uniform float sigma <
//   string label = "Spill Reduction";
  string widget_type = "slider";
  float minimum = 0;
  float maximum = 10.0;
  float step = 0.001;
> = 1.0;

uniform float kSigma <
//   string label = "Spill Reduction";
  string widget_type = "slider";
  float minimum = 0;
  float maximum = 10.0;
  float step = 0.001;
> = 1.0;

float4 mainImage(VertData v_in) : TARGET
{
    float INV_SQRT_OF_2PI = 0.39894228040143267793994605993439;  // 1.0/SQRT_OF_2PI
    float INV_PI = 0.31830988618379067153776752674503;

    float radius = kSigma * sigma;
    float radQ = radius * radius;

    float invSigmaQx2 = 0.5 / (sigma * sigma);      // 1.0 / (sigma^2 * 2.0)
    float invSigmaQx2PI = INV_PI * invSigmaQx2;    // 1/(2 * PI * sigma^2)

    float invThresholdSqx2 = 0.5 / (threshold * threshold);     // 1.0 / (sigma^2 * 2.0)
    float invThresholdSqrt2PI = INV_SQRT_OF_2PI / threshold;   // 1.0 / (sqrt(2*PI) * sigma^2)

    float4 centrPx = image.Sample(textureSampler, v_in.uv);

    float zBuff = 0.0;
    float4 aBuff = {0.0,0.0,0.0,0.0};

    for (float x= -radius; x <= radius; x++) {
        float pt = sqrt(radQ - x*x);       // pt = yRadius: have circular trend
        for (float y = -pt; y <= pt; y++) {
            float2 d = float2(x, y);
            float blurFactor = exp(-dot(d, d) * invSigmaQx2) * invSigmaQx2PI;

            float4 walkPx = image.Sample(textureSampler, v_in.uv + (d / uv_size)); // texture(mainImage,uv+d/size);
            float4 dC = walkPx - centrPx;
            float deltaFactor = exp(-dot(dC, dC) * invThresholdSqx2) * invThresholdSqrt2PI * blurFactor;

            zBuff += deltaFactor;
            aBuff += deltaFactor*walkPx;
        }
    }
    return aBuff/zBuff;
}
// Erode alpha by Eki "Halsu" Halkka for obs-shaderfilter plugin 11/2020

uniform float Erode_alpha = -1000.0;
uniform bool Unpremultiply = true;

float4 mainImage(VertData v_in) : TARGET
{
	float Erode_alpha2 = 0.002 * (Erode_alpha + 1000);
	float dx = Erode_alpha2 / uv_size.x;
	float dy = Erode_alpha2 / uv_size.y;

	float4 c0 = image.Sample(textureSampler, v_in.uv);
	
	// Unpremultiply
	if (c0.a > 0.0)
	if (Unpremultiply == true)
	c0.rgb = saturate(c0.rgb / c0.a);
	
	
	if (c0.a > 0.0 || Erode_alpha > -1000.0)
	{
		float4 c1 = image.Sample(textureSampler, v_in.uv + float2(-dx, -dy));
		float4 c2 = image.Sample(textureSampler, v_in.uv + float2(0, -dy));
		float4 c3 = image.Sample(textureSampler, v_in.uv + float2(dx, -dy));
		float4 c4 = image.Sample(textureSampler, v_in.uv + float2(-dx, 0));
		float4 c5 = image.Sample(textureSampler, v_in.uv + float2(dx, 0));
		float4 c6 = image.Sample(textureSampler, v_in.uv + float2(-dx, dy));
		float4 c7 = image.Sample(textureSampler, v_in.uv + float2(0, dy));
		float4 c8 = image.Sample(textureSampler, v_in.uv + float2(dx, dy));
		
				c0.a = min(c0.a,c1.a);
				c0.a = min(c0.a,c2.a);
				c0.a = min(c0.a,c3.a);
				c0.a = min(c0.a,c4.a);
				c0.a = min(c0.a,c5.a);
				c0.a = min(c0.a,c6.a);
				c0.a = min(c0.a,c7.a);
				c0.a = min(c0.a,c8.a);
		
	}
	
	return c0;
}

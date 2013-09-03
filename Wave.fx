StructuredBuffer<float2> PointXY;
StructuredBuffer<float3> PointHSV;

int Count;
int2 Size;

float Attack = 0.5;
float Decay = 0.95;

struct WaveData
{
	float3 hsv;
	float3 pHsv;
};

RWStructuredBuffer<WaveData> Output : BACKBUFFER;

float3 SampleData(float2 xy, float2 offsetXY)
{
	float2 sampleXY = xy + offsetXY;
	sampleXY.x = max(0, min(sampleXY.x, Size.x - 1));
	sampleXY.y = max(0, min(sampleXY.y, Size.y - 1));
	
	return Output[sampleXY.x + sampleXY.y * Size.x].hsv;
}

float3 Hue(float H)
{
    float R = abs(H * 6 - 3) - 1;
    float G = 2 - abs(H * 6 - 2);
    float B = 2 - abs(H * 6 - 4);
    return saturate(float3(R,G,B));
}
 
float4 HSVtoRGB(in float3 HSV)
{
    return float4(((Hue(HSV.x) - 1) * HSV.y + 1) * HSV.z,1);
}
 
float4 RGBtoHSV(in float3 RGB)
{
    float3 HSV = 0;
    HSV.z = max(RGB.r, max(RGB.g, RGB.b));
    float M = min(RGB.r, min(RGB.g, RGB.b));
    float C = HSV.z - M;
    if (C != 0)
    {
        HSV.y = C / HSV.z;
        float3 Delta = (HSV.z - RGB) / C;
        Delta.rgb -= Delta.brg;
        Delta.rg += float2(2,4);
        if (RGB.r >= HSV.z)
            HSV.x = Delta.b;
        else if (RGB.g >= HSV.z)
            HSV.x = Delta.r;
        else
            HSV.x = Delta.g;
        HSV.x = frac(HSV.x / 6);
    }
    return float4(HSV,1);
}

[numthreads(64, 1, 1)]
void MainCS( uint3 DTid : SV_DispatchThreadID )
{	
	//Current pixel XY
	float x = DTid.x % Size.x;
	float y = floor(DTid.x / Size.x);
	
	float2 pixelPoint = float2(x,y);
	
	x /= (Size.x - 1);
	y /= (Size.y - 1);
	
	WaveData data = Output[DTid.x];
	
	float3 hsv = data.hsv;
	for (int i = 0; i < Count; i++)
	{
		float dist = distance(float2(x, y), PointXY[i]);
		
		//hsv = dist <= 0.01 ? PointHSV[i] : hsv * 0.999;
		if(dist <= 0.01)
		{
			hsv = PointHSV[i];
		}
		else
		{
			hsv = float3(hsv.x, hsv.y, hsv.z * 0.999);
		}
		
	}
	
	float3 a = SampleData(pixelPoint, float2(-1, 0));
	float3 b = SampleData(pixelPoint, float2(+1, 0));
	float3 c = SampleData(pixelPoint, float2(0, -1));
	float3 d = SampleData(pixelPoint, float2(0, +1));
	
	float3 average = a + b + c + d;
    average /= 4;
	
//	float2 vecA = float2(cos(radians(a.x * 360)), sin(radians(a.x * 360)));
//	float2 vecB = float2(cos(radians(b.x * 360)), sin(radians(b.x * 360)));
//	float2 vecC = float2(cos(radians(c.x * 360)), sin(radians(c.x * 360)));
//	float2 vecD = float2(cos(radians(d.x * 360)), sin(radians(d.x * 360)));
	
//	float2 summVec = vecA + vecB + vecC + vecD;
	
//	float averageAngle = (a.x + b.x + c.x + d.x)/4;
	
//	float averageAngle = degrees(atan2(summVec.y, summVec.x)) / 360;

	//float resultV = (hsv.z + Decay * (hsv.z - data.pHsv.z)) + Attack * (average.z - hsv.z);
	
	//p = p_lastframe + (v_lastframe + (attack * (p_left + p_right + p_top + p_bottom - 4*p_lastframe))) * slowdown
	float resultV = hsv.z + ((hsv.z - data.pHsv.z) + Attack * (a.z + b.z + c.z + d.z - 4 * hsv.z)) * Decay;
	if(Count == 0) resultV *= 0.999;
	
	float3 color = HSVtoRGB(hsv).xyz;
	float3 colorA = HSVtoRGB(a).xyz;
	float3 colorB = HSVtoRGB(b).xyz;
	float3 colorC = HSVtoRGB(c).xyz;
	float3 colorD = HSVtoRGB(d).xyz;
	
	float3 averageColor = (color * 2 + colorA + colorB + colorC + colorD) / 6;
	
	averageColor = RGBtoHSV(averageColor).xyz;
	
	Output[DTid.x].pHsv = Output[DTid.x].hsv;
	Output[DTid.x].hsv = float3(averageColor.x, averageColor.y, saturate(resultV));
}


technique11 Main
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, MainCS() ) );
	}
}
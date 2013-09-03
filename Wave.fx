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
		
		hsv = dist <= 0.1 ? PointHSV[i] : hsv;
	}
	
	float3 a = SampleData(pixelPoint, float2(-1, 0));
	float3 b = SampleData(pixelPoint, float2(+1, 0));
	float3 c = SampleData(pixelPoint, float2(0, -1));
	float3 d = SampleData(pixelPoint, float2(0, +1));
	
	float averageV = a.z + b.z + c.z + d.z;
    averageV /= 4;
	
	float2 vecA = float2(cos(radians(a.x * 360)), sin(radians(a.x * 360)));
	float2 vecB = float2(cos(radians(b.x * 360)), sin(radians(b.x * 360)));
	float2 vecC = float2(cos(radians(c.x * 360)), sin(radians(c.x * 360)));
	float2 vecD = float2(cos(radians(d.x * 360)), sin(radians(d.x * 360)));
	
	float2 summVec = vecA + vecB + vecC + vecD;
	
	float averageAngle = (a.x + b.x + c.x + d.x)/4;
	
	//float averageAngle = degrees(atan2(summVec.y, summVec.x)) / 360;
	
	float resultV = (hsv.z + Decay * (hsv.z - data.pHsv.z)) + Attack * (averageV - hsv.z);
	resultV -= 0.0001;
	
	float3 resultHSV = float3(hsv.x, hsv.y, resultV * 1);
		
	Output[DTid.x].pHsv = Output[DTid.x].hsv;
	Output[DTid.x].hsv = saturate(resultHSV);
}


technique11 Main
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, MainCS() ) );
	}
}
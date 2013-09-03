StructuredBuffer<float2> PointXY;
StructuredBuffer<float3> PointHSV;

int Count;
int2 Size;

struct WaveData
{
	float3 hsv;
	float3 pHsv;
};

RWStructuredBuffer<WaveData> Output : BACKBUFFER;

[numthreads(64, 1, 1)]
void MainCS( uint3 DTid : SV_DispatchThreadID )
{	
	//Current pixel XY
	float x = DTid.x % Size.x;
	float y = floor(DTid.x / Size.x);
	
	x /= (Size.x - 1);
	y /= (Size.y - 1);
	
	WaveData data = Output[DTid.x];
	float3 hsv = 0;
	
	for (int i = 0; i < Count; i++)
	{
		float dist = distance(float2(x, y), PointXY[0]);
		
		hsv = dist <= 0.1 ? PointHSV[0] : float3(0,0,0);
	}
	
	Output[DTid.x].pHsv = Output[DTid.x].hsv;
	Output[DTid.x].hsv = hsv;
}

technique11 Main
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, MainCS() ) );
	}
}
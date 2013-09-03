// a 2d Wave Simulation
// by Sebastian Gregor
// developed in 2005

// this shader is the one responsible for calculating the waves.
// it stores a floating point number (wave height at a certain pixel) in different
// color channels. thats why the output looks sort of technical / not right.
// there is another "show wave.fx" which is responsible for displaying the waves.

// -------------------------------------------------------------------------------------------------------------------------------------
// PARAMETERS:
// -------------------------------------------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (DX9)
float4x4 tP: PROJECTION;   //projection matrix as set via Renderer (DX9)
float4x4 tWVP: WORLDVIEWPROJECTION;

//texture
texture txWave1 <string uiname="Wave -1";>;  // a texture holding the output of the last frame
texture txWave2 <string uiname="Wave -2";>;  // the frame before the last frame

sampler samWave1 = sampler_state
{
    Texture   = (txWave1);
    MipFilter = NONE;
    MinFilter = POINT;
    MagFilter = POINT;
};

sampler samWave2 = sampler_state
{
    Texture   = (txWave2);
    MipFilter = NONE;
    MinFilter = POINT;
    MagFilter = POINT;
};

float Attack <String uiname="Attack";> = 0.5;
float _Decay <String uiname="1-Decay";> = 0.01;

float rx <String uiname="Pixel Diameter X";> = 1/1024;
float ry <String uiname="Pixel Diameter Y";> = 1/1024;

// -------------------------------------------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// -------------------------------------------------------------------------------------------------------------------------------------

struct VS_OUTPUT
{
    float4 Pos  : POSITION;
    float2 TexC : TEXCOORD0;
};

VS_OUTPUT VS(
    float4 Pos  : POSITION,
    float2 TexC : TEXCOORD)
{
    //inititalize all fields of output struct with 0
    VS_OUTPUT Out = (VS_OUTPUT)0;

    //transform position
    Pos = mul(Pos, tWVP);
    
    Out.Pos  = Pos;
    Out.TexC = TexC;

    return Out;
}


float4 toColor_01(float s)
{
    float4 c;

    c.r = saturate(sign(s)*128+128);
    s = s * sign(s);

    float sf = floor(s);

    c.g = saturate(sf / 255);
    c.b = saturate(s - sf);
    c.a = 1;

    return c;
}

float toScalar_01(float4 c)
{
    return round(c.r*2 - 1) * (c.g * 255 + c.b);
}


// this second version is much easier. we just use a 16bit texture.
// so encoding and decoding of wave heights <-> colors is not necessary anymore.

float4 toColor_02(float s)
{
    return float4(s, s, s, 1);
}

float toScalar_02(float4 c)
{
    return c.r;
}


// -------------------------------------------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// -------------------------------------------------------------------------------------------------------------------------------------

float4 PS(float2 TexC: TEXCOORD0): COLOR
{
    float p_1 = toScalar_02( tex2D(samWave1, TexC));
    float p_2 = toScalar_02( tex2D(samWave2, TexC));
    
    float p_1n = toScalar_02( tex2D(samWave1, float2(TexC.x-rx, TexC.y)));
    p_1n = p_1n + toScalar_02( tex2D(samWave1, float2(TexC.x+rx, TexC.y)));
    p_1n = p_1n + toScalar_02( tex2D(samWave1, float2(TexC.x, TexC.y-ry)));
    p_1n = p_1n + toScalar_02( tex2D(samWave1, float2(TexC.x, TexC.y+ry)));
    p_1n = p_1n / 4;

    //float p = (p_1 + _Decay * (p_1 - p_2)) + Attack * (p_1n - p_1);
	float p = p_1 + (p_1n - p_1);
    
    return toColor_02(p);
}

// -------------------------------------------------------------------------------------------------------------------------------------
// TECHNIQUES:
// -------------------------------------------------------------------------------------------------------------------------------------

technique Wave
{
    pass P0
    {
        VertexShader = compile vs_1_1 VS();
        PixelShader  = compile ps_2_0 PS();
    }
}

technique Debug
{
    pass P0
    {
        //transforms
        WorldTransform[0]   = (tW);
        ViewTransform       = (tV);
        ProjectionTransform = (tP);

        //texturing
        Sampler[0] = (samWave1);
        Sampler[1] = (samWave2);
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 0;
        TextureTransformFlags[0] = COUNT2;
        TextureTransformFlags[1] = COUNT2;

        //shaders
        VertexShader = NULL;
        PixelShader  = NULL;
    }
}

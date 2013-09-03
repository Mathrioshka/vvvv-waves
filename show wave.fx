// a 2d Wave Simulation
// by Sebastian Gregor
// developed in 2005

// displays the waves created in "pix wave.fx"


// -------------------------------------------------------------------------------------------------------------------------------------
// PARAMETERS:
// -------------------------------------------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (DX9)
float4x4 tP: PROJECTION;   //projection matrix as set via Renderer (DX9)
float4x4 tWVP: WORLDVIEWPROJECTION;

//texture
texture txWave <string uiname="Wave";>;

sampler samWave = sampler_state
{
    Texture   = (txWave);
    MipFilter = POINT;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

float4x4 tColor  <string uiname="Color Transform";>;

float ShowMin <String uiname="ShowMin";> = 0;
float ShowMax <String uiname="ShowMax";> = 1;

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
    float p = toScalar_02(tex2D(samWave, TexC));

    float4 c;
    
    p = (p - ShowMin) / (ShowMax - ShowMin);
    
    c.rgb = p;
    c.a = 1;

    return c;
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
        Sampler[0] = (samWave);
        TexCoordIndex[0] = 0;
        TextureTransformFlags[0] = COUNT2;

        //shaders
        VertexShader = NULL;
        PixelShader  = NULL;
    }
}

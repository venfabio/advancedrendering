//--------------------------------------------------------------------------------------
// File: BasicHLSL11.fx
//
// The effect file for the BasicHLSL sample.  
// 
// Copyright (c) Microsoft Corporation. All rights reserved.
//--------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------
// Global variables
//--------------------------------------------------------------------------------------
float4 g_MaterialAmbientColor;      // Material's ambient color
float4 g_MaterialDiffuseColor;      // Material's diffuse color
int g_nNumLights;

// Variabili nuove
int g_multiplier;					// Adds partitioning select
float g_Rotation;					// Rotates the model by the value
float g_fTessellationFactor;		// Tessellation
float g_fAnimator;					// Control the animation 
float g_fCounter;
float4 eyePos = (0, 0, -200, 0);
float4x4 ViewInverse;

float3 g_LightDir[3];               // Light's direction in world space
float4 g_LightDiffuse[3];           // Light's diffuse color
float4 g_LightAmbient;              // Light's ambient color

Texture2D g_MeshTexture;            // Color texture for mesh

float    g_fTime;                   // App's time in seconds
float4x4 g_mWorld;                  // World matrix for object
float4x4 g_mWorldViewProjection;    // World * View * Projection matrix

//--------------------------------------------------------------------------------------
// DepthStates
//--------------------------------------------------------------------------------------
DepthStencilState EnableDepth
{
    DepthEnable = TRUE;
    DepthWriteMask = ALL;
    DepthFunc = LESS_EQUAL;
};

//--------------------------------------------------------------------------------------
// Texture samplers
//--------------------------------------------------------------------------------------
SamplerState MeshTextureSampler
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};

//--------------------------------------------------------------------------------------
// Rasterizer State (può essere cancellato)
//--------------------------------------------------------------------------------------

RasterizerState rsWireframe
{
	FillMode = WireFrame;
};
RasterizerState solid
{
	FillMode = Solid;
};

//--------------------------------------------------------------------------------------
// Vertex shader output structure
//--------------------------------------------------------------------------------------
struct VS_OUTPUT
{
    float4 Position   : SV_POSITION; // vertex position 
    float4 Diffuse    : COLOR0;      // vertex diffuse color (note that COLOR0 is clamped from 0..1)
    float2 TextureUV  : TEXCOORD0;   // vertex texture coords 
};
/////////////////////////////////////////////////////////////////////////////////////////

// Different Vertex Shader (lab 5)

struct VS1_OUTPUT
{
	float4 Position : SV_POSITION; // vertex position
};

VS1_OUTPUT VS1()
{
	VS1_OUTPUT Output;
	Output.Position = float4(0.0, 0.0, 0.0, 1.0);
	return Output;
}// Hull Shader
struct HS_CONSTANT_DATA_OUTPUT
{
	float Edges[4] : SV_TessFactor;
	float Inside[2] : SV_InsideTessFactor;
};


// Triangle tessellation
/*
struct HS_TRI_CONSTANT_DATA_OUTPUT
{
	float Edges[3] : SV_TessFactor;
	float Inside : SV_InsideTessFactor;
};
*/

HS_CONSTANT_DATA_OUTPUT ConstantHS(InputPatch <VS1_OUTPUT, 4> ip)
{
	HS_CONSTANT_DATA_OUTPUT Output;
	float TessAmount = g_fTessellationFactor;
	Output.Edges[0] = Output.Edges[1] = Output.Edges[2] = Output.Edges[3] = TessAmount;
	Output.Inside[0] = Output.Inside[1] = TessAmount;
	return Output;
}/*HS_TRI_CONSTANT_DATA_OUTPUT ConstantHS_TRI(InputPatch<VS1_OUTPUT, 3> ip)
{
	HS_TRI_CONSTANT_DATA_OUTPUT Output;
	float TessAmount = g_fTessellationFactor;
	Output.Edges[0] = Output.Edges[1] = Output.Edges[2] = TessAmount;
	Output.Inside = TessAmount;
	return Output;
}*/[domain("quad")]

//[partitioning("integer")]
[partitioning("fractional_odd")]
//[partitioning("fractional_even")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(4)]
[patchconstantfunc("ConstantHS")]
VS1_OUTPUT HS_QuadTess(InputPatch<VS1_OUTPUT, 4> p,
	uint i : SV_OutputControlPointID
	)
{
	VS1_OUTPUT Output;
	Output.Position = float4(0.0, 0.0, 0.0, 1.0);
	return Output;
}

/*
[domain("tri")]
[partitioning("fractional_even")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("ConstantHS_TRI")]
VS1_OUTPUT HS_TriTess(InputPatch<VS1_OUTPUT, 3> p,
	uint i : SV_OutputControlPointID)
{
	VS1_OUTPUT Output;
	Output.Position = float4(0, 0, 0, 1);
	return Output;
}*/
// Domain shader usando 4 punti di controllo QuadPos. La superficie definita è una superfice di Bezier lineare

float3 QuadPos[4] = {
	float3(-1, 1, 0),
	float3(-1, -1, 0),
	float3(1, 1, 0),
	float3(1, -1, 0)
};

[domain("quad")]
VS1_OUTPUT DS_QuadTess(HS_CONSTANT_DATA_OUTPUT input,
	float2 UV : SV_DomainLocation)
{
	VS1_OUTPUT Output;
	float3 vPos1 = (1.0 - UV.y)*QuadPos[0].xyz
		+ UV.y* QuadPos[1].xyz;
	float3 vPos2 = (1.0 - UV.y)*QuadPos[2].xyz
		+ UV.y* QuadPos[3].xyz;
	float3 uvPos = (1.0 - UV.x)*vPos1 + UV.x* vPos2;
		Output.Position = float4(100.6*uvPos, 1);

	// Model the tessellated surface
	if (Output.Position.y < -75 && Output.Position.y > -90)
		if (Output.Position.x < -80 && Output.Position.x > -95)
		{
			Output.Position.z -= (3 * g_multiplier);
		}

	if (Output.Position.y > 20 && Output.Position.y < 25)
		if (Output.Position.x > 20 && Output.Position.x < 25)
			Output.Position.z -= (3 * g_multiplier);

	if (Output.Position.y > 80 && Output.Position.y < 100)
		if (Output.Position.x > 80 && Output.Position.x < 100)
		{	
			float value = (smoothstep(80, 100, Output.Position.x) + smoothstep(80, 100, Output.Position.y)) * g_multiplier;
			Output.Position.z -= value;
		}

	if (Output.Position.y > 45 && Output.Position.y < 60)
		if (Output.Position.x > 10 && Output.Position.x < 20)
		{
			float value = (smoothstep(10, 20, Output.Position.x) + smoothstep(45, 60, Output.Position.y)) * g_multiplier;
			Output.Position.z -= value;
		}
	if (Output.Position.y > 45 && Output.Position.y < 60)
		if (Output.Position.x > 0 && Output.Position.x < 10)
		{
			float value = (smoothstep(10, 0, Output.Position.x) + smoothstep(45, 60, Output.Position.y)) * g_multiplier ;
			Output.Position.z -= value;
		}

	if (Output.Position.y > 20 && Output.Position.y < 80)
		if (Output.Position.x > 40 && Output.Position.x < 70)
		{
			float value = (smoothstep(40, 70, Output.Position.x) + smoothstep(20, 80, Output.Position.y)) * g_multiplier;
			Output.Position.z -= value;
		}

	if (Output.Position.y < -20 && Output.Position.y < -50)
		if (Output.Position.x < -10 && Output.Position.x > -40)
		{
			float value = (smoothstep(-10, -40, Output.Position.x) + smoothstep(-20, -50, Output.Position.y)) * g_multiplier;
			Output.Position.z -= value;
		}

	if (Output.Position.y < -20 && Output.Position.y > -25)
		if (Output.Position.x > 62 && Output.Position.x < 73)
			Output.Position.z -= (3 * g_multiplier);

	if (Output.Position.y > 80 && Output.Position.y < 100)
		if (Output.Position.x < -42 && Output.Position.x > -87)
		{
			float value = (smoothstep(-42, -87, Output.Position.x) + smoothstep(80, 100, Output.Position.y)) * g_multiplier;
			Output.Position.z -= value;
		}

	if (Output.Position.y < -25 && Output.Position.y < 10)
		if (Output.Position.x < -30 && Output.Position.x < 20)
		{
			float value = (smoothstep(-30, 20, Output.Position.x) + smoothstep(-25, 10, Output.Position.y)) * g_multiplier;
			Output.Position.z -= value;
		}
	if (Output.Position.y < -25 && Output.Position.y < 10)
		if (Output.Position.x < -30 && Output.Position.x < 20)
		{
			float value = (smoothstep(20, -30, Output.Position.x) + smoothstep(-25, 10, Output.Position.y)) * g_multiplier;
			Output.Position.z -= value;
		}


	Output.Position.z += 50; // little fix for a better visualization, nothing important.
	Output.Position = mul(Output.Position, g_mWorldViewProjection);
	return Output;
}

/*
[domain("tri")]
VS1_OUTPUT DS_TriTess(HS_TRI_CONSTANT_DATA_OUTPUT input,
	float3 UVW : SV_DomainLocation)
{
	VS1_OUTPUT Output;
	float3 finalPos = UVW.x * QuadPos[0].xyz
		+ UVW.y * QuadPos[2].xyz
		+ UVW.z * QuadPos[1].xyz;
	Output.Position = float4(0.6*finalPos, 1.0);
	return Output;
}
*/
//--------------------------------------------------------------------------------------
// This shader computes standard transform and lighting
//--------------------------------------------------------------------------------------
VS_OUTPUT RenderSceneVS( float4 vPos : POSITION,
                         float3 vNormal : NORMAL,
                         float2 vTexCoord0 : TEXCOORD,
                         uniform int nNumLights,
                         uniform bool bTexture,
                         uniform bool bAnimate )
{
    VS_OUTPUT Output;
    float3 vNormalWorldSpace;
  
    float4 vAnimatedPos = vPos;
    
    // Animation the vertex based on time and the vertex's object space position
    if( bAnimate )
		vAnimatedPos += float4(vNormal, 0) * (sin(g_fTime+5.5)+0.5)*5;
    
    // Transform the position from object space to homogeneous projection space
    Output.Position = mul(vAnimatedPos, g_mWorldViewProjection);
    
    // Transform the normal from object space to world space    
    vNormalWorldSpace = normalize(mul(vNormal, (float3x3)g_mWorld)); // normal (world space)
    
    // Compute simple directional lighting equation
    float3 vTotalLightDiffuse = float3(0,0,0);
    for(int i=0; i<nNumLights; i++ )
        vTotalLightDiffuse += g_LightDiffuse[i] * max(0,dot(vNormalWorldSpace, g_LightDir[i]));
        
    Output.Diffuse.rgb = g_MaterialDiffuseColor * vTotalLightDiffuse + 
                         g_MaterialAmbientColor * g_LightAmbient;   
    Output.Diffuse.a = 1.0f; 
    
    // Just copy the texture coordinate through
    if( bTexture ) 
        Output.TextureUV = vTexCoord0; 
    else
        Output.TextureUV = 0; 
    
    return Output;    
}

VS_OUTPUT RenderSceneVS_Ex1(float4 vPos : POSITION,
	float3 vNormal : NORMAL,
	float2 vTexCoord0 : TEXCOORD,
	uniform int nNumLights,
	uniform bool bTexture,
	uniform bool bAnimate)
{
	VS_OUTPUT Output;
	float3 vNormalWorldSpace;

	float4 vAnimatedPos = vPos;

	//float scale = (sin(g_activePulse * g_fTime + 5.5) + 0.5) * smoothstep(140, 160, vAnimatedPos.z) * (sin(g_fTime) + 0.5);
	//vAnimatedPos += scale * float4(vNormal, 0);

	if (vAnimatedPos.z > 170 && vAnimatedPos.y > 15)
	{
		//float value = smoothstep(1, 10, vAnimatedPos.yz) * (1 - smoothstep(1, 10, vAnimatedPos.yz));
		//vAnimatedPos.yz += value;
		float scale = (sin(2 * g_fTime + 5.5) + 0.5) * smoothstep(140, 160, vAnimatedPos.z) * (sin(g_fTime) + 0.5);
		vAnimatedPos += scale * float4(vNormal, 0);
	}

	/*
	// Rotation
	float2x2 rotationMatrix = float2x2(cos(g_Rotation), -sin(g_Rotation),
		sin(g_Rotation), cos(g_Rotation));

	if (vAnimatedPos.z > 170)
		vAnimatedPos.xy = mul(rotationMatrix, vAnimatedPos.xy);*/

	
	float2x2 rotationLeg = float2x2(cos(0.05 * g_fCounter), -sin(0.05 * g_fCounter),
		sin(0.05 * g_fCounter), cos(0.05 * g_fCounter));
	float2x2 rotationOtherLeg = float2x2(cos(0.05 * g_fCounter), sin(0.05 * g_fCounter),
		-sin(0.05 * g_fCounter), cos(0.05 * g_fCounter));

	if (vAnimatedPos.z < -90 && vAnimatedPos.x < -10)
	{
		vAnimatedPos.yz = mul(rotationLeg, vAnimatedPos.yz);
	}

	if (vAnimatedPos.z < -90 && vAnimatedPos.x > 10)
	{
		vAnimatedPos.yz = mul(rotationOtherLeg, vAnimatedPos.yz);
	}
	
	// Transform the position from object space to homogeneous projection space
	Output.Position = mul(vAnimatedPos, g_mWorldViewProjection);

	// Traslation
	//Output.Position.x += 50;
	
	// Transform the normal from object space to world space    
	vNormalWorldSpace = normalize(mul(vNormal, (float3x3)g_mWorld)); // normal (world space)

	// Compute simple directional lighting equation
	float3 vTotalLightDiffuse = float3(0, 0, 0);
		for (int i = 0; i<nNumLights; i++)
			vTotalLightDiffuse += g_LightDiffuse[i] * max(0, dot(vNormalWorldSpace, g_LightDir[i]));

	Output.Diffuse.rgb = g_MaterialDiffuseColor * vTotalLightDiffuse +
		g_MaterialAmbientColor * g_LightAmbient;
	Output.Diffuse.a = 1.0f;

	// Just copy the texture coordinate through
	if (bTexture)
		Output.TextureUV = vTexCoord0;
	else
		Output.TextureUV = 0;

	return Output;
}

VS_OUTPUT RenderSceneVS_Ex2(float4 vPos : POSITION,
	float3 vNormal : NORMAL,
	float2 vTexCoord0 : TEXCOORD,
	uniform int nNumLights,
	uniform bool bTexture,
	uniform bool bAnimate)
{
	VS_OUTPUT Output;
	float3 vNormalWorldSpace;

	float4 vAnimatedPos = vPos;

	float2x2 rotationSides = float2x2(cos(0.01 * g_fCounter), -sin(0.01 * g_fCounter),
		sin(0.01 * g_fCounter), cos(0.01 * g_fCounter));

	float2x2 rotationWing = float2x2(cos(0.1 * g_fCounter), -sin(0.1 * g_fCounter),
		sin(0.1 * g_fCounter), cos(0.1 * g_fCounter));
	float2x2 rotationOtherWing = float2x2(cos(0.1 * g_fCounter), sin(0.1 * g_fCounter),
		-sin(0.1 * g_fCounter), cos(0.1 * g_fCounter));

	// Beak

	if (vAnimatedPos.z > 180 && vAnimatedPos.z < 190 && vAnimatedPos.y < -10)
	{
		vAnimatedPos.y -= 100;
		vAnimatedPos.yz = mul(rotationSides, vAnimatedPos.yz);
	}

	if (vAnimatedPos.z > 200 && vAnimatedPos.z < 205 && vAnimatedPos.y < -10)
	{
		vAnimatedPos.y -= 100;
	}

	// Wings
	if (vAnimatedPos.x < -80)
	{
		float value = smoothstep(0, -40, vAnimatedPos.xy) * -100;
		vAnimatedPos.x += value;
		vAnimatedPos.y -= value;

		if (vAnimatedPos.x < -200)
		{
			float value = smoothstep(-180, -200, vAnimatedPos.xy);
			vAnimatedPos.z = vAnimatedPos.z * -value;
		}

		vAnimatedPos.xy = mul(rotationWing, vAnimatedPos.xy);
	}
	if (vAnimatedPos.x > 80)
	{
		float value = smoothstep(0, 80, vAnimatedPos.xy) * 100;
		vAnimatedPos.xy += value;

		if (vAnimatedPos.x > 200)
		{
			float value = smoothstep(180, 200, vAnimatedPos.xy);
			vAnimatedPos.z = vAnimatedPos.z * -value;
		}

		vAnimatedPos.xy = mul(rotationOtherWing, vAnimatedPos.xy);
	}

	// Tail
	if (vAnimatedPos.z < 40 && vAnimatedPos.z > -20)
	{
		//vAnimatedPos.y += 30;
		vAnimatedPos.y += smoothstep(-20, 40, vAnimatedPos.y) + 40;
		vAnimatedPos.z += smoothstep(-20, 40, vAnimatedPos.z) - 20;
	}

	// Palm Feet
	if (vAnimatedPos.z < -250)
	{
		vAnimatedPos.y -= 90;
		if (vAnimatedPos.x < -10)
			vAnimatedPos.x -= 20;
		if (vAnimatedPos.x > 10);
			vAnimatedPos.x += 20;
	}


	float2x2 rotationHead = float2x2(cos(12), -sin(12),
		sin(12), cos(12));

	if (vAnimatedPos.z > 170)
		vAnimatedPos.yz = mul(rotationHead, vAnimatedPos.yz); 

	// Flight Motion
	vAnimatedPos.xy = mul(rotationSides, vAnimatedPos.xy);
	
	// Rotation
	float2x2 rotationMatrix = float2x2(cos(80), -sin(90),
		sin(90), cos(80));

	vAnimatedPos.yz = mul(rotationMatrix, vAnimatedPos.yz);

	// Transform the position from object space to homogeneous projection space
	Output.Position = mul(vAnimatedPos, g_mWorldViewProjection);

	// Transform the normal from object space to world space    
	vNormalWorldSpace = normalize(mul(vNormal, (float3x3)g_mWorld)); // normal (world space)

	// Compute simple directional lighting equation
	float3 vTotalLightDiffuse = float3(0, 0, 0);
		for (int i = 0; i<nNumLights; i++)
			vTotalLightDiffuse += g_LightDiffuse[i] * max(0, dot(vNormalWorldSpace, g_LightDir[i]));

	Output.Diffuse.rgb = g_MaterialDiffuseColor * vTotalLightDiffuse +
		g_MaterialAmbientColor * g_LightAmbient;
	Output.Diffuse.a = 1.0f;

	// Just copy the texture coordinate through
	if (bTexture)
		Output.TextureUV = vTexCoord0;
	else
		Output.TextureUV = 0;

	return Output;
}

VS_OUTPUT RenderSceneVS_Ex3(float4 vPos : POSITION,
	float3 vNormal : NORMAL,
	float2 vTexCoord0 : TEXCOORD,
	uniform int nNumLights,
	uniform bool bTexture,
	uniform bool bAnimate)
{
	VS_OUTPUT Output;
	float3 vNormalWorldSpace;

	float4 vAnimatedPos = vPos;
	
	float2x2 rotationSides = float2x2(cos(0.05 * g_fCounter), -sin(0.05 * g_fCounter),
	sin(0.05 * g_fCounter), cos(0.05 * g_fCounter));
	float2x2 rotationSides_2 = float2x2(cos(0.05 * g_fCounter), sin(0.05 * g_fCounter),
		-sin(0.05 * g_fCounter), cos(0.05 * g_fCounter));

	// Front Legs
	if (vAnimatedPos.x < -80 && vAnimatedPos.z > 80)
	{
		float value = smoothstep(0, -40, vAnimatedPos.xy) * -100;
		vAnimatedPos.x += value;
		vAnimatedPos.y -= value;
		vAnimatedPos.xy = mul(rotationSides, vAnimatedPos.xy);
	}
	if (vAnimatedPos.x > 80 && vAnimatedPos.z > 80)
	{
		float value = smoothstep(0, 80, vAnimatedPos.xy) * 100;
		vAnimatedPos.xy += value;
		vAnimatedPos.xy = mul(rotationSides_2, vAnimatedPos.xy);
	}

	// Mid Legs
	if (vAnimatedPos.x < -20 && vAnimatedPos.z < 20 && vAnimatedPos.z > -20)
	{
		float value = smoothstep(60, 20, vAnimatedPos.z) * -120;
		vAnimatedPos.x += value;
		vAnimatedPos.y -= value;
		vAnimatedPos.xy = mul(rotationSides_2, vAnimatedPos.xy);
	}
	if (vAnimatedPos.x > 20 && vAnimatedPos.z < 20 && vAnimatedPos.z > -20)
	{
		float value = smoothstep(60, 20, vAnimatedPos.z) * -120;
		vAnimatedPos.x -= value;
		vAnimatedPos.y -= value;
		vAnimatedPos.xy = mul(rotationSides, vAnimatedPos.xy);
	}

	// Back legs
	if (vAnimatedPos.x < -20 && vAnimatedPos.z < -160 && vAnimatedPos.z > -200)
	{
		float value = smoothstep(60, 20, vAnimatedPos.z) * -120;
		vAnimatedPos.x += value;
		vAnimatedPos.y -= value;
		vAnimatedPos.xy = mul(rotationSides, vAnimatedPos.xy);
	}
	if (vAnimatedPos.x > 20 && vAnimatedPos.z < -160 && vAnimatedPos.z > -200)
	{
		float value = smoothstep(60, 20, vAnimatedPos.z) * -120;
		vAnimatedPos.x -= value;
		vAnimatedPos.y -= value;
		vAnimatedPos.xy = mul(rotationSides_2, vAnimatedPos.xy);
	}

	/*
	float2x2 rotationHead = float2x2(cos(7), -sin(7),
		sin(7), cos(7));

	if (vAnimatedPos.z > 170)
	{
		vAnimatedPos.yz = mul(rotationHead, vAnimatedPos.yz);
	}*/

	// Scale body parts
	if (vAnimatedPos.z > 160)
	{
		vAnimatedPos += 30 * float4(vNormal, 0);
	}

	if (vAnimatedPos.z <- 220)
	{
		float value = smoothstep(-260, -220, vAnimatedPos.yz) *50;
		vAnimatedPos += value * float4(vNormal, 0);
	}

	// Rotation
	float2x2 rotationMatrix = float2x2(cos(80), -sin(-90),
		sin(-90), cos(80));

	vAnimatedPos.yz = mul(rotationMatrix, vAnimatedPos.yz);

	rotationMatrix = float2x2(cos(40), -sin(90),
		sin(90), cos(40));

	vAnimatedPos.xy = mul(rotationMatrix, vAnimatedPos.xy);

	// Transform the position from object space to homogeneous projection space
	Output.Position = mul(vAnimatedPos, g_mWorldViewProjection);

	// Transform the normal from object space to world space    
	vNormalWorldSpace = normalize(mul(vNormal, (float3x3)g_mWorld)); // normal (world space)

	// Compute simple directional lighting equation
	float3 vTotalLightDiffuse = float3(0, 0, 0);
		for (int i = 0; i<nNumLights; i++)
			vTotalLightDiffuse += g_LightDiffuse[i] * max(0, dot(vNormalWorldSpace, g_LightDir[i]));

	Output.Diffuse.rgb = g_MaterialDiffuseColor * vTotalLightDiffuse +
		g_MaterialAmbientColor * g_LightAmbient;
	Output.Diffuse.a = 1.0f;

	// Just copy the texture coordinate through
	if (bTexture)
		Output.TextureUV = vTexCoord0;
	else
		Output.TextureUV = 0;

	return Output;
}
//--------------------------------------------------------------------------------------
// Pixel shader output structure
//--------------------------------------------------------------------------------------
struct PS_OUTPUT
{
    float4 RGBColor : SV_Target;  // Pixel color
};

//--------------------------------------------------------------------------------------
// This shader outputs the pixel's color by modulating the texture's
//       color with diffuse material color
//--------------------------------------------------------------------------------------
PS_OUTPUT RenderScenePS( VS_OUTPUT In,
                         uniform bool bTexture ) 
{ 
    PS_OUTPUT Output;

    // Lookup mesh texture and modulate it with diffuse
    if( bTexture )
        Output.RGBColor = g_MeshTexture.Sample(MeshTextureSampler, In.TextureUV) * In.Diffuse;
    else
        Output.RGBColor = In.Diffuse;

    return Output;
}

////////////////////////////////////////////////////////////////////////////////////////
// Other Pixel Shader
float4 PS1() : SV_TARGET
{
	return float4(1, 1, 1, 1);
}

////////////////////////////////////////////////////////////////////////////////////////
// Terrain
#define MIN_XYZ -115.0
#define MAX_XYZ 115.0
const float3 BoxMinimum = (float3)MIN_XYZ;
const float3 BoxMaximum = (float3)MAX_XYZ;
// Random values
float2 stepUnit = float2(1.0, 0.0);
const float2x2 rotate2D = float2x2(1.3623, 1.7531, -1.7131, 1.4623);

float nearPlane = 0.1;
float farPlane = 1000.0;
float viewportW = 500.0;
float viewportH = 600.0;
float levelVal = 1.0;
float zoom = 1.0;
float4 sphereColor_1 = (0.4, 0.6, 1.0, 1.0);
float4 sphereColor_2 = (0.2, 0.3, 0.7, 1.0);
float4 backgroundColor = (0.0, 0.0, 0.0, 0.0);
float4 lightColor = (1.0, 0.3, 0.0, 0.1);
float4 lightPosition = (-10.0, 10.0, 10.0);



float Hash(float2 p)
{
	p = frac(p / float2(3.07965, 7.4235));
	p += dot(p.xy, p.yx + 19.19);
	return frac(p.x * p.y);
}

// Define a noise at a a given position by blending the seed noise values generated at grid corners using the above seed function
float Noise(in float2 x)
{
	float2 p = floor(x);
	float2 f = frac(x);
	f = f*f*(3.0 - 2.0*f);
	float n = p.x + p.y*57.0;
	float res = lerp(lerp(Hash(p), Hash(p + stepUnit.xy), f.x),
		lerp(Hash(p + stepUnit.yx), Hash(p + stepUnit.xx), f.x), f.y);
	return res;
}

// Create a noisy height
float Terrain(in float2 p)
{
	float2 pos = p*0.05;
	float w = (Noise(pos*.25)*0.75 + .15);
	w = 66.0 * w * w;
	float2 dxy = float2(0.0, 0.0);
	float f = .0;
	for (int i = 0; i < 5; i++)
	{
		f += w * Noise(pos);
		w = -w * 0.4; //...Flip negative and positive for variation
		pos = mul(rotate2D, pos);
	}
	float ff = Noise(pos*.002);
	f += pow(abs(ff), 5.0)*275. - 5.0;
	return f;
}

struct Ray {
	float3 o; // origin
	float3 d; // direction
};

struct Sphere {
	float3 centre;
	float rad2; // radius^2
	float4 color;
	float Kd, Ks, Kr, shininess;
};

#define NOBJECTS 3

static Sphere object[NOBJECTS] = {
	// sphere 1
	{ 0.0, 0.0, 0.0, 1.0, sphereColor_1, 1.0, 1.0, 1.0, 1.0 },
	// sphere 2
	{ 2.0, -1.0, 0.0, 0.25, sphereColor_2, 1.0, 1.0, 1.0, 1.0 },
	// sphere 3
	{ 0.0, -101.0, 0.0, 10000, backgroundColor, 0.8, 0.3, 0.3, 1.0 }
};

float SphereIntersect(Sphere s, Ray ray, out bool hit)
{
	float t;
	float3 v = s.centre - ray.o;
		float A = dot(v, ray.d);
	float B = dot(v, v) - A*A;

	float R = sqrt(s.rad2);
	if (B>R*R) {
		hit = false;
		t = farPlane;
	}
	else {
		float disc = sqrt(R*R - B);
		t = A - disc;
		if (t<0.0) {
			hit = false;
		}
		else
			hit = true;
	}

	return t;
}

// Find the Normal at the Point of Hit
float3 SphereNormal(Sphere s, float3 pos)
{
	return normalize(pos - s.centre);
}

// Find the Nearest Hit
float3 NearestHit(Ray ray, out int hitobj, out bool anyhit)
{
	float mint = farPlane;
	hitobj = -1;
	anyhit = false;
	for (int i = 0; i < NOBJECTS; i++)
	{
		bool hit;
		float t = SphereIntersect(object[i], ray, hit);
		if (hit)
		{
			if (t<mint)
			{
				hitobj = i;
				mint = t;
				anyhit = true;
			}
		}
	}
	return ray.o + ray.d*mint;
}

// Find the Light Colour at the Hit Point using the basic illumination model
float4 Phong(float3 n, float3 l, float3 v, float shininess, float4 diffuseColor, float4 specularColor)
{
	float NdotL = dot(n, l);
	float diff = saturate(NdotL);
	float3 r = reflect(l, n);
		float spec = pow(saturate(dot(v, r)), shininess) * (NdotL > 0.0);
	return diff*diffuseColor + spec*specularColor;
}

// Shadows
bool AnyHit(Ray ray)
{
	bool anyhit = false;
	for (int i = 0; i<NOBJECTS; i++) {
		bool hit;
		float t = SphereIntersect(object[i], ray, hit);
		if (hit) {
			anyhit = true;
		}
	}
	return anyhit;
}

// Shading
float4 Shade(float3 hitPos, float3 normal, float3 viewDir, int hitobj, float lightIntensity)
{
	Ray shadowRay;
	shadowRay.d = normalize(lightPosition - hitPos);
	shadowRay.o = hitPos.xyz;

	float shadowVec = 1.0f;
	if (AnyHit(shadowRay))
		shadowVec = 0.01f;

	float3 lightDir = normalize(lightPosition - hitPos);
		float4 diff = object[hitobj].color * object[hitobj].Kd;
		float4 spec = object[hitobj].color * object[hitobj].Ks;

		return shadowVec * lightColor * lightIntensity * Phong(normal, lightDir, viewDir, object[hitobj].shininess, diff, spec);
}

bool IntersectBox(in Ray ray, in float3 minimum, in float3 maximum,
	out float timeIn, out float timeOut)
{
	float3 OMIN = (minimum - ray.o) / ray.d;
		float3 OMAX = (maximum - ray.o) / ray.d;
		float3 MAX = max(OMAX, OMIN);
		float3 MIN = min(OMAX, OMIN);
		timeOut = min(MAX.x, min(MAX.y, MAX.z));
	timeIn = max(max(MIN.x, 0.0), max(MIN.y, MIN.z));
	return timeOut > timeIn;
}

// Define the implicit function (can be any function)
float Function(float3 Position)
{
	float3 Pos = 25.0*Position;
		float Fun = Pos.y - 2.0*Terrain(Pos.xz);
	return Fun - levelVal;
}

// Define how fine you subdivide the ray segment contained within the bounding box
#define INTERVALS 200

// Start from the entering point, march along the ray inside the bounding box to detect when the ray intersects an implicit surface
bool RayMarching(in Ray ray, in float start, in float final, out float val)
{
	float step = (final - start) / float(INTERVALS);
	float time = start;
	float3 Position = ray.o + time * ray.d;
		float right, left = Function(Position);
	for (int i = 0; i < INTERVALS; ++i)
	{
		time += step;
		Position += step * ray.d;
		right = Function(Position);
		if (left * right < 0.0)
		{
			val = time + right * step / (left - right);
			return true;
		}
		left = right;
	}
	return false;
}

const float3 Zero = float3 (0.0, 0.0, 0.0);
const float3 Unit = float3 (1.0, 1.0, 1.0);
const float3 AxisX = float3 (1.0, 0.0, 0.0);
const float3 AxisY = float3 (0.0, 1.0, 0.0);
const float3 AxisZ = float3 (0.0, 0.0, 1.0);
#define STEP 0.01
float3 CalcNormal(float3 Position)
{
	float A = Function(Position + AxisX * STEP)
		- Function(Position - AxisX * STEP);
	float B = Function(Position + AxisY * STEP)
		- Function(Position - AxisY * STEP);
	float C = Function(Position + AxisZ * STEP)
		- Function(Position - AxisZ * STEP);
	return normalize(float3 (A, B, C));
}

float4 Raytrace(Ray ray)
{
	float4 result = (float4)0;
		float start, final;
	float t;
	int hitobj = 1;
	float lightIntensity = 2.0;
	if (IntersectBox(ray, BoxMinimum, BoxMaximum, start, final))
	{
		if (RayMarching(ray, start, final, t))
		{
			float3 Position = ray.o + ray.d * t;
				float3 normal = CalcNormal(Position);
				float3 color = (Position - BoxMinimum) / (BoxMaximum - BoxMinimum);
				result = Shade(Position, normal, ray.d, hitobj, lightIntensity);
		}
	}
	return result;
}
// Terrain Vertex Shader
struct VS_OUTPUT_T
{
	float4 pos : SV_POSITION;
	float2 texCoord : TEXCOORD0;

};

VS_OUTPUT_T Render_Terrain(float4 inPos : Position)
{
	VS_OUTPUT_T o;
	
	inPos.xy = sign(inPos.xy);
	o.pos = float4(inPos.xy, 0.0f, 1.0f);

	o.texCoord = inPos.xy;

	return o;
}

// Pixel shader Main
float4 ps_main(VS_OUTPUT_T o) : SV_Target
{
	Ray eyeray;
	eyeray.o = eyePos.xyz;
	float3 dir;

	// scale the image depending on the viewport
	dir.xy = o.texCoord.xy * float2(1.0, viewportH / viewportW);
	dir.z = zoom * nearPlane;

	// Eye ray direction d is specified in view space, in must return to the World Space
	eyeray.d = mul(float4(dir, 0.0), ViewInverse).xyz;
	eyeray.d = normalize(eyeray.d);

	return Raytrace(eyeray);
}

// Geometry shader yeah
[maxvertexcount(6)]
void GS(triangle VS_OUTPUT input[3], inout TriangleStream<VS_OUTPUT>
	NewTriangles)
{
	VS_OUTPUT output;	
	
	// Calculate triangle normal
	float Explode = 10.0;
	float3 EdgeA = input[1].Position.xyz - input[0].Position.xyz;
	float3 EdgeB = input[2].Position.xyz - input[0].Position.xyz;
	float3 triNormal = normalize(cross(EdgeA, EdgeB));
	float3 Scaling = triNormal*Explode;
	
	float3 g_positions[4] =
	{
		float3(-1, 1, 0),
		float3(-1, -1, 0),
		float3(1, 1, 0),
		float3(1, -1, 0),
	};

	float4 QuadSize = (-1,1, -1,1);

	for (int i = 0; i < 3; i++)
	{
		output.Position = mul(input[i].Position + float4(Scaling, 1), g_mWorldViewProjection);
		output.Diffuse = input[i].Diffuse;
		output.TextureUV = input[i].TextureUV;
		NewTriangles.Append(output);

	}

	for (int i = 1; i < 3; i++)
	{
		output.Position = mul(input[i].Position + float4(Scaling, 1), g_mWorldViewProjection);
		output.Diffuse = input[i].Diffuse;
		output.TextureUV = input[i].TextureUV;
		NewTriangles.Append(output);

	}
	//vertex 3:
	float3 V = normalize(input[1].Position.xyz - input[0].Position.xyz);
		output.Position = input[2].Position + (0.2)*float4(V, 0);
	output.Position = mul(output.Position + float4(Scaling, 1), g_mWorldViewProjection);

	NewTriangles.Append(output);

	NewTriangles.RestartStrip();

	float3 upVector = g_mWorldViewProjection._12_22_32;
	float3 leftVector = g_mWorldViewProjection._11_21_31;
		
	
			float4 viewPos = input[0].Position;
			viewPos = mul(viewPos, g_mWorld);
			viewPos = mul(viewPos, g_mWorldViewProjection);

		for (int i = 0; i < 3; i++)
		{
			float3 initQuadVert = QuadSize*g_positions[i];
			float4 ParticlePos = float4(initQuadVert, 1.0);

			float3 upVector = g_mWorldViewProjection._12_22_32;
			float3 leftVector = g_mWorldViewProjection._11_21_31;

			ParticlePos.xyz = initQuadVert.x * leftVector + initQuadVert.y * upVector;			ParticlePos.xyz += viewPos.xyz;
			output.Position = mul(ParticlePos, g_mWorldViewProjection);
			output.Diffuse = input[i].Diffuse;
			output.TextureUV = input[i].TextureUV;
			NewTriangles.Append(output);
		}

		NewTriangles.RestartStrip();

}

VS_OUTPUT RenderSceneVS_Ex6(float4 vPos : POSITION,
	float3 vNormal : NORMAL,
	float2 vTexCoord0 : TEXCOORD,
	uniform int nNumLights,
	uniform bool bTexture,
	uniform bool bAnimate)
{
	VS_OUTPUT Output;
	float3 vNormalWorldSpace;

	float4 vAnimatedPos = vPos;


	// Transform the position from object space to homogeneous projection space
	Output.Position = vAnimatedPos;

	// Transform the normal from object space to world space    
	vNormalWorldSpace = normalize(mul(vNormal, (float3x3)g_mWorld)); // normal (world space)
	
	// Compute simple directional lighting equation
	float3 vTotalLightDiffuse = float3(0, 0, 0);
		for (int i = 0; i<nNumLights; i++)
			vTotalLightDiffuse += g_LightDiffuse[i] * max(0, dot(vNormalWorldSpace, g_LightDir[i]));

	Output.Diffuse.rgb = g_MaterialDiffuseColor * vTotalLightDiffuse +
		g_MaterialAmbientColor * g_LightAmbient;
	Output.Diffuse.a = 1.0f;

	// Just copy the texture coordinate through
	if (bTexture)
		Output.TextureUV = vTexCoord0;
	else
		Output.TextureUV = 0;

	return Output;
}
//--------------------------------------------------------------------------------------
// Renders scene to render target using D3D11 Techniques
//--------------------------------------------------------------------------------------
// Original (working)
technique11 RenderSceneWithTexture1Light
{
    pass P0
    {
        SetVertexShader( CompileShader( vs_4_0_level_9_1, RenderSceneVS_Ex1( 1, true, true ) ) );
		SetGeometryShader(NULL);
        SetPixelShader( CompileShader( ps_4_0_level_9_1, RenderScenePS( true ) ) );

        SetDepthStencilState( EnableDepth, 0 );

		SetRasterizerState(solid);
    }
}
/*
technique11 RenderSceneWithTexture1Light
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_5_0, VS1()));
		//SetHullShader(CompileShader(hs_5_0, HS_QuadTess()));
		SetHullShader(CompileShader(hs_5_0, HS_TriTess()));
		//SetDomainShader(CompileShader(ds_5_0, DS_QuadTess()));
		SetDomainShader(CompileShader(ds_5_0, DS_TriTess()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0_level_9_1, PS1()));

		SetRasterizerState(rsWireframe);
	}

	
}
*/
technique11 RenderSceneWithTexture2Light
{
    pass P0
    {          
        SetVertexShader( CompileShader( vs_5_0, RenderSceneVS_Ex2( 1, true, true ) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0_level_9_1, RenderScenePS( true ) ) ); 
        
        SetDepthStencilState( EnableDepth, 0 );

		SetRasterizerState(solid);
    }
}

technique11 RenderSceneWithTexture3Light
{
    pass P0
    {          
        SetVertexShader( CompileShader( vs_5_0, RenderSceneVS_Ex3( 1, true, true ) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_5_0, RenderScenePS( true ) ) );

        SetDepthStencilState( EnableDepth, 0 );

		SetRasterizerState(solid);
    }
}

technique11 RenderSceneWithTexture4Light
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_5_0, VS1()));
		SetHullShader(CompileShader(hs_5_0, HS_QuadTess()));
		//SetHullShader(CompileShader(hs_5_0, HS_TriTess()));
		SetDomainShader(CompileShader(ds_5_0, DS_QuadTess()));
		//SetDomainShader(CompileShader(ds_5_0, DS_TriTess()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0_level_9_1, PS1()));

		SetRasterizerState(rsWireframe);
	}
}

technique11 RenderSceneWithTexture5Light
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_5_0, Render_Terrain()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, ps_main()));

		SetDepthStencilState(EnableDepth, 0);

		SetRasterizerState(solid);
	}
}

technique11 RenderSceneWithTexture6Light
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_4_0_level_9_1, RenderSceneVS_Ex6(1, true, true)));
		SetGeometryShader(CompileShader(gs_5_0, GS()));
		SetPixelShader(CompileShader(ps_4_0_level_9_1, RenderScenePS(true)));

		SetDepthStencilState(EnableDepth, 0);

		SetRasterizerState(solid);
	}
}

technique11 RenderSceneNoTexture
{
    pass P0
    {          
        SetVertexShader( CompileShader( vs_4_0_level_9_1, RenderSceneVS_Ex1( 1, true, true ) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0_level_9_1, RenderScenePS( false ) ) );

        SetDepthStencilState( EnableDepth, 0 );
    }
}
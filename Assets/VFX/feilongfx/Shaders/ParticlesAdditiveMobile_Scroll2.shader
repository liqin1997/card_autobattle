// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "GAP/ParticlesAdditiveMobile_Scroll"
{
	Properties
	{
		[HDR]_Color("Color", Color) = (0,0,0,0)
		[NoScaleOffset]_Mask("Mask", 2D) = "white" {}
		[NoScaleOffset]_MainTex("MainTex", 2D) = "white" {}
		_MainTexTiling("MainTexTiling", Vector) = (1,1,0,0)
		_MainTexSpeed("MainTexSpeed", Vector) = (0,0,0,0)
		_DistortionAmount("DistortionAmount", Range( -1 , 1)) = 0.1741219
		[NoScaleOffset]_DistortionTexture("DistortionTexture", 2D) = "white" {}
		_DistortionTiling("DistortionTiling", Vector) = (1,1,0,0)
		_DistortionSpeed("DistortionSpeed", Vector) = (0,0.1,0,0)
		_DissolveAmount("DissolveAmount", Float) = 2
		[NoScaleOffset]_DissolveTexture("DissolveTexture", 2D) = "white" {}
		_DissolveTiling("DissolveTiling", Vector) = (1,1,0,0)
		_DissolveSpeed("DissolveSpeed", Vector) = (0,0.1,0,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags
		{
			"RenderType"="Transparent"
			"Queue"="Transparent"
			"IgnoreProjector"="True"
			"IsEmissive"="true"
			"RenderPipeline"="UniversalPipeline"
		}
		Cull Off
		ZWrite Off
		ZTest LEqual
		Offset 0, 0
		Blend One One, One One

		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="SRPDefaultUnlit" }

			HLSLPROGRAM
			#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_Mask);              SAMPLER(sampler_Mask);
			TEXTURE2D(_MainTex);           SAMPLER(sampler_MainTex);
			TEXTURE2D(_DistortionTexture); SAMPLER(sampler_DistortionTexture);
			TEXTURE2D(_DissolveTexture);   SAMPLER(sampler_DissolveTexture);

			CBUFFER_START(UnityPerMaterial)
				half4 _Color;
				float4 _MainTexTiling;
				float4 _MainTexSpeed;
				float _DistortionAmount;
				float4 _DistortionTiling;
				float4 _DistortionSpeed;
				float _DissolveAmount;
				float4 _DissolveTiling;
				float4 _DissolveSpeed;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				half4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				half4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			Varyings vert(Attributes input)
			{
				Varyings output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
				output.uv = input.uv;
				output.color = input.color;
				return output;
			}

			half4 frag(Varyings input) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				float2 uv = input.uv;
				float2 mainPanner = _Time.y * _MainTexSpeed.xy + uv * (_MainTexTiling.xy - float2(1.0, 1.0));
				float2 distortionPanner = _Time.y * _DistortionSpeed.xy + uv * _DistortionTiling.xy;
				half4 distortion = SAMPLE_TEXTURE2D(_DistortionTexture, sampler_DistortionTexture, distortionPanner);
				float4 distortedUv = lerp(float4(uv, 0.0, 0.0), distortion, _DistortionAmount);
				float2 dissolvePanner = _Time.y * _DissolveSpeed.xy + uv * _DissolveTiling.xy;

				half4 mask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, uv);
				half mainAlpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, (float4(mainPanner, 0.0, 0.0) + distortedUv).xy).a;
				half4 dissolve = pow(
					abs(SAMPLE_TEXTURE2D(_DissolveTexture, sampler_DissolveTexture, (distortedUv + float4(dissolvePanner, 0.0, 0.0)).xy)),
					_DissolveAmount.xxxx);
				return input.color * _Color * mask * (mainAlpha * dissolve);
			}
			ENDHLSL
		}
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18707
0;73;1568;675;2157.226;584.205;2.172875;True;False
Node;AmplifyShaderEditor.Vector2Node;43;-2708.157,526.3832;Inherit;False;Property;_DistortionTiling;DistortionTiling;7;0;Create;True;0;0;False;0;False;1,1;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;26;-2424.052,685.0979;Inherit;False;Property;_DistortionSpeed;DistortionSpeed;8;0;Create;True;0;0;False;0;False;0,0.1;0,0.1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;42;-2478.025,505.0165;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;38;-2004.389,-161.5048;Inherit;False;Property;_MainTexTiling;MainTexTiling;3;0;Create;True;0;0;False;0;False;1,1;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;46;-1782.672,852.5932;Inherit;False;Property;_DissolveTiling;DissolveTiling;11;0;Create;True;0;0;False;0;False;1,1;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.PannerNode;25;-2154.052,666.0979;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode;22;-2157.932,403.4965;Inherit;True;Property;_DistortionTexture;DistortionTexture;6;1;[NoScaleOffset];Create;True;0;0;False;0;False;28c7aad1372ff114b90d330f8a2dd938;28c7aad1372ff114b90d330f8a2dd938;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TextureCoordinatesNode;45;-1561.007,839.3096;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;23;-1913.933,517.4965;Inherit;True;Property;_TextureSample3;Texture Sample 3;9;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexCoordVertexDataNode;18;-2143.665,227.9672;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;29;-1573.513,986.1611;Inherit;False;Property;_DissolveSpeed;DissolveSpeed;12;0;Create;True;0;0;False;0;False;0,0.1;0,0.1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;3;-1631.658,380.9719;Inherit;False;Property;_DistortionAmount;DistortionAmount;5;0;Create;True;0;0;False;0;False;0.1741219;0;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;39;-1805.189,-156.9048;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;19;-1601.442,18.2576;Inherit;False;Property;_MainTexSpeed;MainTexSpeed;4;0;Create;True;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.PannerNode;30;-1306.513,892.1611;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;37;-1633.689,-177.6048;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;17;-1351.442,231.3646;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TexturePropertyNode;12;-1123.676,604.1027;Inherit;True;Property;_DissolveTexture;DissolveTexture;10;1;[NoScaleOffset];Create;True;0;0;False;0;False;28c7aad1372ff114b90d330f8a2dd938;28c7aad1372ff114b90d330f8a2dd938;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleAddOpNode;47;-1111.97,871.4551;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT2;0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PannerNode;27;-1375.43,4.495213;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;14;-781.6763,943.1025;Inherit;False;Property;_DissolveAmount;DissolveAmount;9;0;Create;True;0;0;False;0;False;2;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;16;-871.6763,715.1025;Inherit;True;Property;_TextureSample2;Texture Sample 2;6;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;28;-1149.429,159.4951;Inherit;False;2;2;0;FLOAT2;0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TexturePropertyNode;2;-1101.703,-162.8539;Inherit;True;Property;_MainTex;MainTex;2;1;[NoScaleOffset];Create;True;0;0;False;0;False;c936e49026718a642958d0ce5d715cd1;c936e49026718a642958d0ce5d715cd1;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;6;-411.7605,-132.3863;Inherit;True;Property;_Mask;Mask;1;1;[NoScaleOffset];Create;True;0;0;False;0;False;03e4ee8d0b5f45045bb12e2930ed4058;03e4ee8d0b5f45045bb12e2930ed4058;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.PowerNode;13;-566.6763,724.1025;Inherit;False;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;1;-805.8174,134.0206;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-356.4419,548.3646;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;5;-148.7605,-133.3863;Inherit;True;Property;_TextureSample1;Texture Sample 1;2;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;209.2395,4.613708;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;20;210.2395,-251.3863;Inherit;False;Property;_Color;Color;0;1;[HDR];Create;True;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;8;732.7843,-153.6375;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;540.2395,-14.38629;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;9;934.7041,-35.3247;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.BreakToComponentsNode;10;1128.349,-35.90201;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1338.465,-205.9384;Float;False;True;-1;0;ASEMaterialInspector;0;0;Unlit;GAP/ParticlesAdditiveMobile_Scroll;False;False;False;False;True;True;True;True;True;True;True;True;False;False;True;False;False;False;False;False;False;Off;2;False;-1;3;False;-1;True;0;False;-1;0;False;-1;False;3;Custom;0.5;True;False;0;True;Transparent;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;4;1;False;-1;1;False;-1;4;1;False;-1;1;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;13;-1;-1;-1;2;RenderType=Transparent;Queue=Transparent;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;42;0;43;0
WireConnection;25;0;42;0
WireConnection;25;2;26;0
WireConnection;45;0;46;0
WireConnection;23;0;22;0
WireConnection;23;1;25;0
WireConnection;39;0;38;0
WireConnection;30;0;45;0
WireConnection;30;2;29;0
WireConnection;37;0;39;0
WireConnection;17;0;18;0
WireConnection;17;1;23;0
WireConnection;17;2;3;0
WireConnection;47;0;17;0
WireConnection;47;1;30;0
WireConnection;27;0;37;0
WireConnection;27;2;19;0
WireConnection;16;0;12;0
WireConnection;16;1;47;0
WireConnection;28;0;27;0
WireConnection;28;1;17;0
WireConnection;13;0;16;0
WireConnection;13;1;14;0
WireConnection;1;0;2;0
WireConnection;1;1;28;0
WireConnection;11;0;1;4
WireConnection;11;1;13;0
WireConnection;5;0;6;0
WireConnection;7;0;5;0
WireConnection;7;1;11;0
WireConnection;21;0;20;0
WireConnection;21;1;7;0
WireConnection;9;0;8;0
WireConnection;9;1;21;0
WireConnection;10;0;9;0
WireConnection;0;2;9;0
WireConnection;0;9;10;3
ASEEND*/
//CHKSM=4083D7B658B1AB52E87685B8CB1AFC59B213F4B3

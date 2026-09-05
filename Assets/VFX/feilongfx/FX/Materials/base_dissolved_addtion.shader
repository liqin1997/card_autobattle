// Upgrade NOTE: upgraded instancing buffer 'Unlitparticle_dissolve_addtion' to new syntax.

// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Unlit/particle_dissolve_addtion"
{
	Properties
	{
		_maintex("maintex", 2D) = "white" {}
		_TextureSample1("Texture Sample 1", 2D) = "white" {}
		_Vector0("Vector 0", Vector) = (0,0,0,0)
		_mask_speed("mask_speed", Vector) = (0,0,0,0)
		_Float2("Float 2", Float) = 0.5
		_mask("mask", 2D) = "white" {}
		_maskpower("maskpower", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Transparent" "Queue"="Transparent"  "RenderPipeline"="UniversalPipeline" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend One One, One One
		AlphaToMask Off
		Cull Off
		ColorMask RGBA
		ZWrite Off
		ZTest LEqual
		Offset 0 , 0
		
		
		
		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="SRPDefaultUnlit" }
			CGPROGRAM

			

			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
			#define ASE_NEEDS_FRAG_COLOR


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform sampler2D _maintex;
			uniform float2 _Vector0;
			uniform sampler2D _TextureSample1;
			uniform float2 _mask_speed;
			uniform float _maskpower;
			uniform sampler2D _mask;
			UNITY_INSTANCING_BUFFER_START(Unlitparticle_dissolve_addtion)
				UNITY_DEFINE_INSTANCED_PROP(float4, _maintex_ST)
#define _maintex_ST_arr Unlitparticle_dissolve_addtion
				UNITY_DEFINE_INSTANCED_PROP(float4, _TextureSample1_ST)
#define _TextureSample1_ST_arr Unlitparticle_dissolve_addtion
				UNITY_DEFINE_INSTANCED_PROP(float4, _mask_ST)
#define _mask_ST_arr Unlitparticle_dissolve_addtion
				UNITY_DEFINE_INSTANCED_PROP(float, _Float2)
#define _Float2_arr Unlitparticle_dissolve_addtion
			UNITY_INSTANCING_BUFFER_END(Unlitparticle_dissolve_addtion)

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord1 = v.ase_texcoord;
				o.ase_color = v.color;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				float4 _maintex_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_maintex_ST_arr, _maintex_ST);
				float2 uv_maintex = i.ase_texcoord1.xy * _maintex_ST_Instance.xy + _maintex_ST_Instance.zw;
				float2 panner6 = ( 1.0 * _Time.y * _Vector0 + uv_maintex);
				float4 tex2DNode7 = tex2D( _maintex, panner6 );
				float4 appendResult86 = (float4(tex2DNode7.r , tex2DNode7.g , tex2DNode7.b , 0.0));
				float4 appendResult87 = (float4(i.ase_color.r , i.ase_color.g , i.ase_color.b , 0.0));
				float _Float2_Instance = UNITY_ACCESS_INSTANCED_PROP(_Float2_arr, _Float2);
				float4 uvs4_maintex = i.ase_texcoord1;
				uvs4_maintex.xy = i.ase_texcoord1.xy * _maintex_ST_Instance.xy + _maintex_ST_Instance.zw;
				float4 _TextureSample1_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_TextureSample1_ST_arr, _TextureSample1_ST);
				float2 uv_TextureSample1 = i.ase_texcoord1.xy * _TextureSample1_ST_Instance.xy + _TextureSample1_ST_Instance.zw;
				float2 panner12 = ( 1.0 * _Time.y * _mask_speed + uv_TextureSample1);
				float4 _mask_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_mask_ST_arr, _mask_ST);
				float2 uv_mask = i.ase_texcoord1.xy * _mask_ST_Instance.xy + _mask_ST_Instance.zw;
				float4 appendResult22 = (float4(( ( appendResult86 * appendResult87 ) * ( ( i.ase_color.a * step( ( _Float2_Instance + uvs4_maintex.z ) , tex2D( _TextureSample1, panner12 ).r ) * tex2DNode7.a ) * ( _maskpower + tex2D( _mask, uv_mask ).r ) ) )));
				
				
				finalColor = appendResult22;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18935
0;55.2;1957;1068;780.849;47.71653;1.3;True;False
Node;AmplifyShaderEditor.TextureCoordinatesNode;11;-1365.324,419.938;Inherit;False;0;8;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;10;-1368.076,675.1183;Inherit;False;Property;_mask_speed;mask_speed;3;0;Create;True;0;0;0;False;0;False;0,0;1,3;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;9;-1482.091,254.9501;Inherit;False;Property;_Vector0;Vector 0;2;0;Create;True;0;0;0;False;0;False;0,0;0,2;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;4;-1406.634,-125.2302;Inherit;False;0;7;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;12;-1047.959,505.851;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;82;-934.7259,764.8068;Inherit;False;0;7;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;74;-674.0973,754.916;Inherit;False;InstancedProperty;_Float2;Float 2;4;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;6;-1089.269,-39.31718;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;83;-492.4321,801.4556;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;8;-753.7881,437.1998;Inherit;True;Property;_TextureSample1;Texture Sample 1;1;0;Create;True;0;0;0;False;0;False;-1;d3f704dac5f7e5646a6f2990c88b428b;1763184fee992fa478d54a0c32a8ca57;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;84;-403.6927,129.0557;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;7;-725.1664,-183.4243;Inherit;True;Property;_maintex;maintex;0;0;Create;True;0;0;0;False;0;False;-1;1a511046c3d9790468674250c2ef39ac;e505e649e0a8d5045985b89a5176bdc5;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;94;199.3507,605.5336;Inherit;False;Property;_maskpower;maskpower;6;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;76;-241.7193,403.885;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;91;-2.081915,712.3762;Inherit;True;Property;_mask;mask;5;0;Create;True;0;0;0;False;0;False;-1;None;e505e649e0a8d5045985b89a5176bdc5;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;86;-230.9507,-232.5127;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;85;129.9436,292.6005;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;87;-133.0796,-92.88317;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;95;500.9509,642.5834;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;89;46.02007,-254.7977;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;623.972,304.126;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;90;456.9003,39.42224;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;22;790.321,-157.6903;Inherit;True;FLOAT4;4;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ComponentMaskNode;21;293.0396,-359.5585;Inherit;True;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1519.456,-243.4696;Float;False;True;-1;2;ASEMaterialInspector;100;1;Unlit/particle_dissolve_addtion;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;4;1;False;-1;1;False;-1;4;1;False;-1;1;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;2;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;12;0;11;0
WireConnection;12;2;10;0
WireConnection;6;0;4;0
WireConnection;6;2;9;0
WireConnection;83;0;74;0
WireConnection;83;1;82;3
WireConnection;8;1;12;0
WireConnection;7;1;6;0
WireConnection;76;0;83;0
WireConnection;76;1;8;1
WireConnection;86;0;7;1
WireConnection;86;1;7;2
WireConnection;86;2;7;3
WireConnection;85;0;84;4
WireConnection;85;1;76;0
WireConnection;85;2;7;4
WireConnection;87;0;84;1
WireConnection;87;1;84;2
WireConnection;87;2;84;3
WireConnection;95;0;94;0
WireConnection;95;1;91;1
WireConnection;89;0;86;0
WireConnection;89;1;87;0
WireConnection;92;0;85;0
WireConnection;92;1;95;0
WireConnection;90;0;89;0
WireConnection;90;1;92;0
WireConnection;22;0;90;0
WireConnection;1;0;22;0
ASEEND*/
//CHKSM=D13450BB4E16F6A40A4852C4AA6F1805B2DEEAA9
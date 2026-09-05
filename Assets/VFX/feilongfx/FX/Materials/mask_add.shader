// Upgrade NOTE: upgraded instancing buffer 'Unlitmask_add' to new syntax.

// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Unlit/mask_add"
{
	Properties
	{
		_maintex("maintex", 2D) = "white" {}
		_TextureSample1("Texture Sample 1", 2D) = "white" {}
		_Vector0("Vector 0", Vector) = (0,0,0,0)
		[HDR]_maincolor("maincolor", Color) = (1,1,1,0)
		_Vector1("Vector 1", Vector) = (0,0,0,0)
		_Float2("Float 2", Float) = 0.39
		[HDR]_edgecolor("edgecolor", Color) = (0,0,0,0)
		_edge("edge", Float) = 0.02
		[HDR]_add("add", Color) = (0,0,0,0)

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Transparent" "Queue"="Transparent"  "RenderPipeline"="UniversalPipeline" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend One One
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
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform float4 _add;
			uniform sampler2D _maintex;
			uniform float2 _Vector0;
			uniform sampler2D _TextureSample1;
			uniform float2 _Vector1;
			UNITY_INSTANCING_BUFFER_START(Unlitmask_add)
				UNITY_DEFINE_INSTANCED_PROP(float4, _maintex_ST)
#define _maintex_ST_arr Unlitmask_add
				UNITY_DEFINE_INSTANCED_PROP(float4, _maincolor)
#define _maincolor_arr Unlitmask_add
				UNITY_DEFINE_INSTANCED_PROP(float4, _TextureSample1_ST)
#define _TextureSample1_ST_arr Unlitmask_add
				UNITY_DEFINE_INSTANCED_PROP(float4, _edgecolor)
#define _edgecolor_arr Unlitmask_add
				UNITY_DEFINE_INSTANCED_PROP(float, _Float2)
#define _Float2_arr Unlitmask_add
				UNITY_DEFINE_INSTANCED_PROP(float, _edge)
#define _edge_arr Unlitmask_add
			UNITY_INSTANCING_BUFFER_END(Unlitmask_add)

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
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
				float4 _maincolor_Instance = UNITY_ACCESS_INSTANCED_PROP(_maincolor_arr, _maincolor);
				float _Float2_Instance = UNITY_ACCESS_INSTANCED_PROP(_Float2_arr, _Float2);
				float4 _TextureSample1_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_TextureSample1_ST_arr, _TextureSample1_ST);
				float2 uv_TextureSample1 = i.ase_texcoord1.xy * _TextureSample1_ST_Instance.xy + _TextureSample1_ST_Instance.zw;
				float2 panner12 = ( 1.0 * _Time.y * _Vector1 + uv_TextureSample1);
				float4 tex2DNode8 = tex2D( _TextureSample1, panner12 );
				float _edge_Instance = UNITY_ACCESS_INSTANCED_PROP(_edge_arr, _edge);
				float temp_output_32_0 = step( _Float2_Instance , ( tex2DNode8.r + _edge_Instance ) );
				float temp_output_31_0 = ( temp_output_32_0 - step( _Float2_Instance , tex2DNode8.r ) );
				float4 temp_cast_0 = (temp_output_31_0).xxxx;
				float4 _edgecolor_Instance = UNITY_ACCESS_INSTANCED_PROP(_edgecolor_arr, _edgecolor);
				float4 lerpResult59 = lerp( ( tex2DNode7 * _maincolor_Instance ) , temp_cast_0 , ( temp_output_31_0 * _edgecolor_Instance * 0.58 ));
				float4 appendResult22 = (float4((( _add + lerpResult59 )).rgb , ( tex2DNode7.a * temp_output_32_0 )));
				
				
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
-2020;244.8;1957;878;1248.145;883.2758;1.490602;True;False
Node;AmplifyShaderEditor.Vector2Node;10;-1368.076,675.1183;Inherit;False;Property;_Vector1;Vector 1;4;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;11;-1365.324,419.938;Inherit;False;0;8;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;12;-1047.959,505.851;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;75;-603.7831,1110.099;Inherit;False;InstancedProperty;_edge;edge;7;0;Create;True;0;0;0;False;0;False;0.02;0.02;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;8;-753.7881,437.1998;Inherit;True;Property;_TextureSample1;Texture Sample 1;1;0;Create;True;0;0;0;False;0;False;-1;None;35df857e018518246838a3d010d8d37e;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;4;-1406.634,-125.2302;Inherit;False;0;7;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;74;-638.1332,684.398;Inherit;False;InstancedProperty;_Float2;Float 2;5;0;Create;True;0;0;0;False;0;False;0.39;0.43;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;9;-1410.386,129.9501;Inherit;False;Property;_Vector0;Vector 0;2;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleAddOpNode;28;-404.6623,1006.423;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;6;-1089.269,-39.31718;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StepOpNode;76;-241.7193,403.885;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;32;-86.31881,948.843;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;77;778.7322,853.334;Inherit;False;Constant;_Float0;Float 0;8;0;Create;True;0;0;0;False;0;False;0.58;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;57;446.1554,790.8004;Inherit;False;InstancedProperty;_edgecolor;edgecolor;6;1;[HDR];Create;True;0;0;0;False;0;False;0,0,0,0;1,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;7;-682.2665,-132.7243;Inherit;True;Property;_maintex;maintex;0;0;Create;True;0;0;0;False;0;False;-1;None;2abd563467bb54948852ccb668a9c330;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;31;115.5754,462.3264;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;14;-497.0641,164.4612;Inherit;False;InstancedProperty;_maincolor;maincolor;3;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;58;739.2534,513.2089;Inherit;True;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;-193.7079,-334.4185;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;59;409.4488,-428.7412;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;80;508.887,-712.5522;Inherit;False;Property;_add;add;8;1;[HDR];Create;True;0;0;0;False;0;False;0,0,0,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;79;841.6869,-596.8522;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ComponentMaskNode;21;928.2394,-417.1586;Inherit;True;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;23;664.3851,-22.86805;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;22;1196.721,-229.6903;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1519.456,-243.4696;Float;False;True;-1;2;ASEMaterialInspector;100;1;Unlit/mask_add;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;4;1;False;-1;1;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;2;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;12;0;11;0
WireConnection;12;2;10;0
WireConnection;8;1;12;0
WireConnection;28;0;8;1
WireConnection;28;1;75;0
WireConnection;6;0;4;0
WireConnection;6;2;9;0
WireConnection;76;0;74;0
WireConnection;76;1;8;1
WireConnection;32;0;74;0
WireConnection;32;1;28;0
WireConnection;7;1;6;0
WireConnection;31;0;32;0
WireConnection;31;1;76;0
WireConnection;58;0;31;0
WireConnection;58;1;57;0
WireConnection;58;2;77;0
WireConnection;15;0;7;0
WireConnection;15;1;14;0
WireConnection;59;0;15;0
WireConnection;59;1;31;0
WireConnection;59;2;58;0
WireConnection;79;0;80;0
WireConnection;79;1;59;0
WireConnection;21;0;79;0
WireConnection;23;0;7;4
WireConnection;23;1;32;0
WireConnection;22;0;21;0
WireConnection;22;3;23;0
WireConnection;1;0;22;0
ASEEND*/
//CHKSM=EDFD5F3D40B3511CF85DF3B4AE927D651B6E82FC
// Upgrade NOTE: upgraded instancing buffer 'base_dissolved_alpha_blend_z_off' to new syntax.

// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_dissolved_alpha_blend_z_off"
{
	Properties
	{
		_maintex("maintex", 2D) = "white" {}
		_TextureSample1("Texture Sample 1", 2D) = "white" {}
		_main_tex_speed("main_tex_speed", Vector) = (0,0,0,0)
		_mask_speed("mask_speed", Vector) = (0,0,0,0)
		_step("step", Float) = 0.5
		[HDR]_backcolor("背面颜色", Color) = (1,1,1,0)
		[Enum(zwrite off,0,zwrite on,1)]_zwirte("zwirte", Float) = 0

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Transparent" "Queue"="Transparent"  "RenderPipeline"="UniversalPipeline" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha
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

			#if defined(SHADER_API_GLCORE) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) || defined(SHADER_API_D3D9)
			#define FRONT_FACE_SEMANTIC VFACE
			#define FRONT_FACE_TYPE float
			#else
			#define FRONT_FACE_SEMANTIC SV_IsFrontFace
			#define FRONT_FACE_TYPE bool
			#endif


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

			uniform float _zwirte;
			uniform sampler2D _maintex;
			uniform float2 _main_tex_speed;
			uniform float4 _backcolor;
			uniform sampler2D _TextureSample1;
			uniform float2 _mask_speed;
			UNITY_INSTANCING_BUFFER_START(base_dissolved_alpha_blend_z_off)
				UNITY_DEFINE_INSTANCED_PROP(float4, _maintex_ST)
#define _maintex_ST_arr base_dissolved_alpha_blend_z_off
				UNITY_DEFINE_INSTANCED_PROP(float4, _TextureSample1_ST)
#define _TextureSample1_ST_arr base_dissolved_alpha_blend_z_off
				UNITY_DEFINE_INSTANCED_PROP(float, _step)
#define _step_arr base_dissolved_alpha_blend_z_off
			UNITY_INSTANCING_BUFFER_END(base_dissolved_alpha_blend_z_off)

			
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
			
			fixed4 frag (v2f i , FRONT_FACE_TYPE ase_vface : FRONT_FACE_SEMANTIC) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				float4 _maintex_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_maintex_ST_arr, _maintex_ST);
				float2 uv_maintex = i.ase_texcoord1.xy * _maintex_ST_Instance.xy + _maintex_ST_Instance.zw;
				float2 panner6 = ( 1.0 * _Time.y * _main_tex_speed + uv_maintex);
				float4 tex2DNode7 = tex2D( _maintex, panner6 );
				float4 temp_output_15_0 = ( tex2DNode7 * i.ase_color );
				float4 switchResult87 = (((ase_vface>0)?(temp_output_15_0):(( _backcolor * temp_output_15_0 ))));
				float4 _TextureSample1_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_TextureSample1_ST_arr, _TextureSample1_ST);
				float2 uv_TextureSample1 = i.ase_texcoord1.xy * _TextureSample1_ST_Instance.xy + _TextureSample1_ST_Instance.zw;
				float2 panner12 = ( 1.0 * _Time.y * _mask_speed + uv_TextureSample1);
				float _step_Instance = UNITY_ACCESS_INSTANCED_PROP(_step_arr, _step);
				float4 uvs4_maintex = i.ase_texcoord1;
				uvs4_maintex.xy = i.ase_texcoord1.xy * _maintex_ST_Instance.xy + _maintex_ST_Instance.zw;
				float4 appendResult22 = (float4((switchResult87).rgb , ( tex2DNode7.a * step( tex2D( _TextureSample1, panner12 ).r , ( _step_Instance + uvs4_maintex.z ) ) * i.ase_color.a )));
				
				
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
7.2;270.4;1957;603;3359.082;493.2292;3.363035;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;4;-1406.634,-125.2302;Inherit;False;0;7;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;9;-1482.091,254.9501;Inherit;False;Property;_main_tex_speed;main_tex_speed;2;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.PannerNode;6;-1089.269,-39.31718;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;10;-1368.076,675.1183;Inherit;False;Property;_mask_speed;mask_speed;3;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;11;-1365.324,419.938;Inherit;False;0;8;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;84;-571.5617,146.1534;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;7;-755.3206,-211.9958;Inherit;True;Property;_maintex;maintex;0;0;Create;True;0;0;0;False;0;False;-1;1a511046c3d9790468674250c2ef39ac;1a511046c3d9790468674250c2ef39ac;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;-251.1412,-388.3947;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;93;-518.3226,888.5453;Inherit;False;InstancedProperty;_step;step;4;0;Create;True;0;0;0;False;0;False;0.5;0.6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;86;-604.6623,-701.7783;Inherit;False;Property;_backcolor;背面颜色;5;1;[HDR];Create;False;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;12;-1047.959,505.851;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;82;-934.7259,764.8068;Inherit;False;0;7;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;8;-753.7881,437.1998;Inherit;True;Property;_TextureSample1;Texture Sample 1;1;0;Create;True;0;0;0;False;0;False;-1;d3f704dac5f7e5646a6f2990c88b428b;d3f704dac5f7e5646a6f2990c88b428b;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;92;-319.7575,907.7848;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;88;1.54908,-651.0969;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StepOpNode;89;-17.23989,740.8654;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwitchByFaceNode;87;242.2466,-622.0266;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ComponentMaskNode;21;293.0396,-359.5585;Inherit;True;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;81;310.7222,13.5884;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;22;790.321,-157.6903;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;94;798.5139,226.1943;Inherit;False;Property;_zwirte;zwirte;6;1;[Enum];Create;True;0;2;zwrite off;0;zwrite on;1;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1519.456,-243.4696;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_dissolved_alpha_blend_z_off;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;2;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;False;94;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;6;0;4;0
WireConnection;6;2;9;0
WireConnection;7;1;6;0
WireConnection;15;0;7;0
WireConnection;15;1;84;0
WireConnection;12;0;11;0
WireConnection;12;2;10;0
WireConnection;8;1;12;0
WireConnection;92;0;93;0
WireConnection;92;1;82;3
WireConnection;88;0;86;0
WireConnection;88;1;15;0
WireConnection;89;0;8;1
WireConnection;89;1;92;0
WireConnection;87;0;15;0
WireConnection;87;1;88;0
WireConnection;21;0;87;0
WireConnection;81;0;7;4
WireConnection;81;1;89;0
WireConnection;81;2;84;4
WireConnection;22;0;21;0
WireConnection;22;3;81;0
WireConnection;1;0;22;0
ASEEND*/
//CHKSM=2FC154C50E38E1E53C6B31C17A85C133DFC870DB
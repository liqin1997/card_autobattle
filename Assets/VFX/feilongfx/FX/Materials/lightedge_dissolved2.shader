// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "lightedge_dissolved2"
{
	Properties
	{
		_Noise_tex("Noise_tex", 2D) = "white" {}
		_Float3("边缘锐利程度", Range( 0 , 1)) = 0.3620715
		Float2("Float2 溶解度", Range( 0 , 1)) = 0.4979893
		_Ramptex("Ramptex", 2D) = "white" {}
		_MainTex("MainTex", 2D) = "white" {}
		_Maincolor("Maincolor", Color) = (1,1,1,1)
		[HDR]_edge_color("edge_color", Color) = (1,1,1,1)
		[Enum(custom_on,0,custom_off,1)]_Float4("Float 4", Float) = 1
		[Enum(zwrite on,1,zwrite off,0)]_zwrite("zwrite", Float) = 0
		_mask("mask", 2D) = "white" {}
		_mask_power("mask_power", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" "Queue"="Transparent"  "RenderPipeline"="UniversalPipeline" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha
		AlphaToMask Off
		Cull Off
		ColorMask RGBA
		ZWrite [_zwrite]
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

			uniform float _zwrite;
			uniform sampler2D _Ramptex;
			uniform float _Float3;
			uniform sampler2D _Noise_tex;
			uniform float4 _Noise_tex_ST;
			uniform float Float2;
			uniform float _Float4;
			uniform float4 _edge_color;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform float4 _Maincolor;
			uniform sampler2D _mask;
			uniform float4 _mask_ST;
			uniform float _mask_power;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord1.xyz = v.ase_texcoord.xyz;
				o.ase_color = v.color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.w = 0;
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
				float2 uv_Noise_tex = i.ase_texcoord1.xyz.xy * _Noise_tex_ST.xy + _Noise_tex_ST.zw;
				float3 texCoord28 = i.ase_texcoord1.xyz;
				texCoord28.xy = i.ase_texcoord1.xyz.xy * float2( 1,1 ) + float2( 0,0 );
				float lerpResult29 = lerp( texCoord28.z , 1.0 , _Float4);
				float smoothstepResult8 = smoothstep( 0.0 , _Float3 , ( tex2D( _Noise_tex, uv_Noise_tex ).r + 1.0 + ( -2.0 * Float2 * lerpResult29 ) ));
				float2 appendResult10 = (float2(smoothstepResult8 , smoothstepResult8));
				float4 tex2DNode11 = tex2D( _Ramptex, appendResult10 );
				float2 uv_MainTex = i.ase_texcoord1.xyz.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 tex2DNode12 = tex2D( _MainTex, uv_MainTex );
				float temp_output_24_0 = ( tex2DNode12.a * _Maincolor.a * i.ase_color.a * saturate( smoothstepResult8 ) );
				float4 lerpResult19 = lerp( ( tex2DNode11 * _edge_color ) , ( tex2DNode12 * _Maincolor * i.ase_color ) , temp_output_24_0);
				float2 uv_mask = i.ase_texcoord1.xyz.xy * _mask_ST.xy + _mask_ST.zw;
				float4 appendResult22 = (float4((lerpResult19).rgb , ( temp_output_24_0 * ( tex2D( _mask, uv_mask ).r * _mask_power ) )));
				
				
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
0;89.6;1957;1035;1528.304;187.4436;1;True;True
Node;AmplifyShaderEditor.RangedFloatNode;30;-769.017,664.4409;Inherit;False;Property;_Float4;Float 4;7;1;[Enum];Create;True;0;2;custom_on;0;custom_off;1;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;28;-1121.388,435.3766;Inherit;False;0;-1;3;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;5;-880.942,-8.369703;Inherit;False;Constant;_Float1;Float 1;1;0;Create;True;0;0;0;False;0;False;-2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-1032.513,134.5621;Inherit;False;Property;Float2;Float2 溶解度;2;0;Create;False;0;0;0;False;0;False;0.4979893;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;29;-702.017,364.4409;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;4;-736.942,-152.3697;Inherit;False;Constant;_Float0;Float 0;1;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;2;-1165.942,-246.3697;Inherit;True;Property;_Noise_tex;Noise_tex;0;0;Create;True;0;0;0;False;0;False;-1;3c2220205bf33b74e91fb46cd5858af1;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-650.9421,109.6303;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;3;-520.942,-249.3697;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;9;-435.942,19.6303;Inherit;False;Property;_Float3;边缘锐利程度;1;0;Create;False;0;0;0;False;0;False;0.3620715;0.3620715;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;8;-158.942,-277.3697;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;10;109.2369,-284.4419;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;16;314.7593,-58.61945;Inherit;False;Property;_edge_color;edge_color;6;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;12;-116.2407,10.38055;Inherit;True;Property;_MainTex;MainTex;4;0;Create;True;0;0;0;False;0;False;-1;84d2065fb5a7631498e52c89d8241193;7296084fac299eb4bbd90995f110e4db;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;23;-72.22351,774.4783;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;11;284.2369,-299.4419;Inherit;True;Property;_Ramptex;Ramptex;3;0;Create;True;0;0;0;False;0;False;-1;4cd9fe53ba4453f40bda7bec8a4bf018;082017362d8a89142ad6bf9963cce02d;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;25;9.002808,461.1712;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;14;-77.24072,256.3806;Inherit;False;Property;_Maincolor;Maincolor;5;0;Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;13;332.7593,158.3806;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;388.8939,528.9096;Inherit;True;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;35;708.1863,1088.491;Inherit;False;Property;_mask_power;mask_power;10;0;Create;True;0;0;0;False;0;False;0;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;32;505.1213,850.0247;Inherit;True;Property;_mask;mask;9;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;17;672.7593,-223.6194;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;19;884.9301,6.522259;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;890.1197,833.0103;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;998.5109,531.0323;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;21;1152.41,30.7639;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-835.6222,868.0056;Inherit;False;Property;_zwrite;zwrite;8;1;[Enum];Create;True;0;2;zwrite on;1;zwrite off;0;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;27;861.5504,-521.6392;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;22;1391.033,88.18178;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1619.56,54.44118;Float;False;True;-1;2;ASEMaterialInspector;100;1;lightedge_dissolved2;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;2;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;True;31;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;29;0;28;3
WireConnection;29;2;30;0
WireConnection;7;0;5;0
WireConnection;7;1;6;0
WireConnection;7;2;29;0
WireConnection;3;0;2;1
WireConnection;3;1;4;0
WireConnection;3;2;7;0
WireConnection;8;0;3;0
WireConnection;8;2;9;0
WireConnection;10;0;8;0
WireConnection;10;1;8;0
WireConnection;23;0;8;0
WireConnection;11;1;10;0
WireConnection;13;0;12;0
WireConnection;13;1;14;0
WireConnection;13;2;25;0
WireConnection;24;0;12;4
WireConnection;24;1;14;4
WireConnection;24;2;25;4
WireConnection;24;3;23;0
WireConnection;17;0;11;0
WireConnection;17;1;16;0
WireConnection;19;0;17;0
WireConnection;19;1;13;0
WireConnection;19;2;24;0
WireConnection;34;0;32;1
WireConnection;34;1;35;0
WireConnection;33;0;24;0
WireConnection;33;1;34;0
WireConnection;21;0;19;0
WireConnection;27;0;11;4
WireConnection;22;0;21;0
WireConnection;22;3;33;0
WireConnection;1;0;22;0
ASEEND*/
//CHKSM=5FDB4D5515005238CD6175ACACFD897CC88512F5
// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "lightedge_dissolved_flow"
{
	Properties
	{
		_Noise_tex("Noise_tex", 2D) = "white" {}
		_noise_speedtime("noise_speed/time", Vector) = (0,0,0,0)
		_noise_scaleoffset("noise_scale/offset", Vector) = (1,1,0,0)
		_Float3("边缘锐利程度", Range( 0 , 1)) = 0.3620715
		Float2("Float2 溶解度", Range( 0 , 1)) = 0.4979893
		_Ramptex("Ramptex", 2D) = "white" {}
		_MainTex("MainTex", 2D) = "white" {}
		_noise_speedtime1("maintex_speed/time", Vector) = (0,0,0,0)
		_maintex_scaleoffset("maintex_scale/offset", Vector) = (1,1,0,0)
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

			uniform float _zwrite;
			uniform sampler2D _Ramptex;
			uniform float _Float3;
			uniform sampler2D _Noise_tex;
			uniform float4 _noise_speedtime;
			uniform float4 _noise_scaleoffset;
			uniform float Float2;
			uniform float _Float4;
			uniform float4 _edge_color;
			uniform sampler2D _MainTex;
			uniform float4 _noise_speedtime1;
			uniform float4 _maintex_scaleoffset;
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
				float mulTime42 = _Time.y * _noise_speedtime.z;
				float2 appendResult43 = (float2(mulTime42 , _noise_speedtime.w));
				float2 appendResult41 = (float2(_noise_speedtime.x , _noise_speedtime.y));
				float2 texCoord37 = i.ase_texcoord1.xyz.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult59 = (float2(_noise_scaleoffset.x , _noise_scaleoffset.y));
				float2 appendResult60 = (float2(_noise_scaleoffset.z , _noise_scaleoffset.w));
				float2 panner38 = ( appendResult43.x * appendResult41 + (texCoord37*appendResult59 + appendResult60));
				float3 texCoord28 = i.ase_texcoord1.xyz;
				texCoord28.xy = i.ase_texcoord1.xyz.xy * float2( 1,1 ) + float2( 0,0 );
				float lerpResult29 = lerp( texCoord28.z , 1.0 , _Float4);
				float smoothstepResult8 = smoothstep( 0.0 , _Float3 , ( tex2D( _Noise_tex, panner38 ).r + 1.0 + ( -2.0 * Float2 * lerpResult29 ) ));
				float2 appendResult10 = (float2(smoothstepResult8 , smoothstepResult8));
				float4 tex2DNode11 = tex2D( _Ramptex, appendResult10 );
				float mulTime46 = _Time.y * _noise_speedtime1.z;
				float2 appendResult48 = (float2(mulTime46 , _noise_speedtime1.w));
				float2 appendResult47 = (float2(_noise_speedtime1.x , _noise_speedtime1.y));
				float2 texCoord45 = i.ase_texcoord1.xyz.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult53 = (float2(_maintex_scaleoffset.x , _maintex_scaleoffset.y));
				float2 appendResult54 = (float2(_maintex_scaleoffset.z , _maintex_scaleoffset.w));
				float2 panner44 = ( appendResult48.x * appendResult47 + (texCoord45*appendResult53 + appendResult54));
				float4 tex2DNode12 = tex2D( _MainTex, panner44 );
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
0;23.2;1957;1100;3831.221;600.0082;1.167056;True;True
Node;AmplifyShaderEditor.CommentaryNode;56;-3361.423,-456.1595;Inherit;False;1631.163;535.4941;Comment;10;37;61;60;59;58;38;43;41;42;40;noise流动;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector4Node;61;-3257.827,-186.554;Inherit;False;Property;_noise_scaleoffset;noise_scale/offset;2;0;Create;True;0;0;0;False;0;False;1,1,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;40;-2535.57,-136.2037;Inherit;False;Property;_noise_speedtime;noise_speed/time;1;0;Create;False;0;0;0;False;0;False;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;60;-2933.827,-133.5551;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;59;-2889.827,-258.555;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;42;-2274.856,-21.71771;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;37;-3302.172,-381.2326;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;57;-1387.026,-289.2062;Inherit;False;1080;1079.273;Comment;11;30;28;5;6;29;2;7;4;3;9;31;溶解;1,1,1,1;0;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;28;-1292.472,445.54;Inherit;False;0;-1;3;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;30;-940.1013,674.6044;Inherit;False;Property;_Float4;Float 4;11;1;[Enum];Create;True;0;2;custom_on;0;custom_off;1;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;41;-2117.856,-185.7177;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;43;-2096.856,-61.71771;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;58;-2552.827,-412.5538;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;55;-1648.044,1035.274;Inherit;False;1737.035;588.8422;Comment;10;49;51;46;54;53;45;50;48;47;44;主纹理流动;1,1,1,1;0;0
Node;AmplifyShaderEditor.PannerNode;38;-1938.66,-347.702;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;5;-1052.026,1.793719;Inherit;False;Constant;_Float1;Float 1;1;0;Create;True;0;0;0;False;0;False;-2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-1203.597,144.7255;Inherit;False;Property;Float2;Float2 溶解度;4;0;Create;False;0;0;0;False;0;False;0.4979893;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;29;-873.1013,374.6043;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;49;-715.0178,1399.23;Inherit;False;Property;_noise_speedtime1;maintex_speed/time;7;0;Create;False;0;0;0;False;0;False;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;2;-1337.026,-236.2063;Inherit;True;Property;_Noise_tex;Noise_tex;0;0;Create;True;0;0;0;False;0;False;-1;3c2220205bf33b74e91fb46cd5858af1;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;4;-908.0262,-142.2063;Inherit;False;Constant;_Float0;Float 0;1;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;51;-1598.044,1374.366;Inherit;False;Property;_maintex_scaleoffset;maintex_scale/offset;8;0;Create;True;0;0;0;False;0;False;1,1,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-822.0263,119.7937;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;54;-1274.044,1427.365;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;53;-1230.044,1302.365;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;45;-1406.853,1085.274;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;9;-607.0262,29.79372;Inherit;False;Property;_Float3;边缘锐利程度;3;0;Create;False;0;0;0;False;0;False;0.3620715;0.3620715;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;3;-692.0262,-239.2063;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;46;-455.6045,1513.716;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;50;-893.0439,1148.366;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;47;-298.6052,1349.715;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SmoothstepOpNode;8;-158.942,-277.3697;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;48;-277.6052,1473.716;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;10;109.2369,-284.4419;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;44;-119.4094,1187.731;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.VertexColorNode;25;9.002808,461.1712;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;11;284.2369,-299.4419;Inherit;True;Property;_Ramptex;Ramptex;5;0;Create;True;0;0;0;False;0;False;-1;4cd9fe53ba4453f40bda7bec8a4bf018;082017362d8a89142ad6bf9963cce02d;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;23;-72.22351,774.4783;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;14;-77.24072,256.3806;Inherit;False;Property;_Maincolor;Maincolor;9;0;Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;16;314.7593,-58.61945;Inherit;False;Property;_edge_color;edge_color;10;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;12;-116.2407,10.38055;Inherit;True;Property;_MainTex;MainTex;6;0;Create;True;0;0;0;False;0;False;-1;84d2065fb5a7631498e52c89d8241193;7296084fac299eb4bbd90995f110e4db;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;13;332.7593,158.3806;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;32;505.1213,850.0247;Inherit;True;Property;_mask;mask;13;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;388.8939,528.9096;Inherit;True;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;17;672.7593,-223.6194;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;35;708.1863,1088.491;Inherit;False;Property;_mask_power;mask_power;14;0;Create;True;0;0;0;False;0;False;0;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;19;884.9301,6.522259;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;890.1197,833.0103;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;21;1152.41,30.7639;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;998.5109,531.0323;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-1130.706,674.6666;Inherit;False;Property;_zwrite;zwrite;12;1;[Enum];Create;True;0;2;zwrite on;1;zwrite off;0;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;22;1391.033,88.18178;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;27;861.5504,-521.6392;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1619.56,54.44118;Float;False;True;-1;2;ASEMaterialInspector;100;1;lightedge_dissolved_flow;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;2;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;True;31;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;60;0;61;3
WireConnection;60;1;61;4
WireConnection;59;0;61;1
WireConnection;59;1;61;2
WireConnection;42;0;40;3
WireConnection;41;0;40;1
WireConnection;41;1;40;2
WireConnection;43;0;42;0
WireConnection;43;1;40;4
WireConnection;58;0;37;0
WireConnection;58;1;59;0
WireConnection;58;2;60;0
WireConnection;38;0;58;0
WireConnection;38;2;41;0
WireConnection;38;1;43;0
WireConnection;29;0;28;3
WireConnection;29;2;30;0
WireConnection;2;1;38;0
WireConnection;7;0;5;0
WireConnection;7;1;6;0
WireConnection;7;2;29;0
WireConnection;54;0;51;3
WireConnection;54;1;51;4
WireConnection;53;0;51;1
WireConnection;53;1;51;2
WireConnection;3;0;2;1
WireConnection;3;1;4;0
WireConnection;3;2;7;0
WireConnection;46;0;49;3
WireConnection;50;0;45;0
WireConnection;50;1;53;0
WireConnection;50;2;54;0
WireConnection;47;0;49;1
WireConnection;47;1;49;2
WireConnection;8;0;3;0
WireConnection;8;2;9;0
WireConnection;48;0;46;0
WireConnection;48;1;49;4
WireConnection;10;0;8;0
WireConnection;10;1;8;0
WireConnection;44;0;50;0
WireConnection;44;2;47;0
WireConnection;44;1;48;0
WireConnection;11;1;10;0
WireConnection;23;0;8;0
WireConnection;12;1;44;0
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
WireConnection;21;0;19;0
WireConnection;33;0;24;0
WireConnection;33;1;34;0
WireConnection;22;0;21;0
WireConnection;22;3;33;0
WireConnection;27;0;11;4
WireConnection;1;0;22;0
ASEEND*/
//CHKSM=0E02817062099E435DAB9B867A28144FF5D5767B
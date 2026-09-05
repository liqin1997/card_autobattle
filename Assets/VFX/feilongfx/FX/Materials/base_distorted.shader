// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_distorted"
{
	Properties
	{
		_main_tex("main_tex", 2D) = "white" {}
		_distorted_map("distorted_map", 2D) = "white" {}
		_distorted_map01power("distorted_map01 power", Float) = 1
		_noise_speed("noise_speed", Vector) = (1,1,-1,0)
		_distorted_scale_offset("distorted_scale_offset", Vector) = (1,1,-1,0)
		_main_tes_speed("main_tes_speed", Vector) = (1,1,-1,0)
		_TextureSample0("Texture Sample 0", 2D) = "white" {}
		[HDR]_color_map("color_map", Color) = (1,1,1,0)
		_mask("mask", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

	}
	
	SubShader
	{
		
		
		Tags
		{
			"RenderType"="Transparent"
			"Queue"="Transparent"
			"RenderPipeline"="UniversalPipeline"
		}
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

			uniform sampler2D _TextureSample0;
			uniform float4 _TextureSample0_ST;
			uniform float4 _color_map;
			uniform sampler2D _main_tex;
			uniform float4 _main_tes_speed;
			uniform sampler2D _distorted_map;
			uniform float4 _noise_speed;
			uniform float4 _distorted_scale_offset;
			uniform float _distorted_map01power;
			uniform sampler2D _mask;
			uniform float4 _mask_ST;

			
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
				float2 uv_TextureSample0 = i.ase_texcoord1.xy * _TextureSample0_ST.xy + _TextureSample0_ST.zw;
				float mulTime64 = _Time.y * _main_tes_speed.z;
				float2 appendResult66 = (float2(_main_tes_speed.x , _main_tes_speed.y));
				float2 texCoord2 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 panner67 = ( mulTime64 * appendResult66 + texCoord2);
				float mulTime23 = _Time.y * _noise_speed.z;
				float2 appendResult19 = (float2(_noise_speed.x , _noise_speed.y));
				float2 texCoord17 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult106 = (float2(_distorted_scale_offset.x , _distorted_scale_offset.y));
				float2 appendResult107 = (float2(_distorted_scale_offset.z , _distorted_scale_offset.w));
				float2 panner18 = ( mulTime23 * appendResult19 + (texCoord17*appendResult106 + appendResult107));
				float2 temp_cast_0 = (( tex2D( _distorted_map, panner18 ).r * _distorted_map01power )).xx;
				float4 texCoord57 = i.ase_texcoord1;
				texCoord57.xy = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 lerpResult8 = lerp( panner67 , temp_cast_0 , texCoord57.z);
				float4 tex2DNode3 = tex2D( _main_tex, lerpResult8 );
				float3 appendResult53 = (float3(tex2DNode3.r , tex2DNode3.g , tex2DNode3.b));
				float2 uv_mask = i.ase_texcoord1.xy * _mask_ST.xy + _mask_ST.zw;
				float4 appendResult55 = (float4((( ( tex2D( _TextureSample0, uv_TextureSample0 ) * _color_map * i.ase_color ) * float4( appendResult53 , 0.0 ) )).rgb , ( tex2DNode3.a * i.ase_color.a * tex2D( _mask, uv_mask ).r )));
				
				
				finalColor = appendResult55;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18935
68;612;1957;643;4082.633;409.5649;2.397769;True;True
Node;AmplifyShaderEditor.Vector4Node;105;-3615.094,161.438;Inherit;False;Property;_distorted_scale_offset;distorted_scale_offset;4;0;Create;True;0;0;0;False;0;False;1,1,-1,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;106;-3230.782,141.8017;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;24;-3161.89,385.0556;Inherit;False;Property;_noise_speed;noise_speed;3;0;Create;True;0;0;0;False;0;False;1,1,-1,0;10,0,1,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;17;-3602.363,-136.3001;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;107;-3246.21,255.4121;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;19;-2882.366,220.7269;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;104;-2967.823,-78.82156;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;23;-2510.63,390.4307;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;63;-2117.922,-236.126;Inherit;False;Property;_main_tes_speed;main_tes_speed;5;0;Create;True;0;0;0;False;0;False;1,1,-1,0;-10,0,1,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;18;-2607.284,-42.56373;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;2;-2500.351,-567.4858;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;4;-1995.128,-21.30492;Inherit;True;Property;_distorted_map;distorted_map;1;0;Create;True;0;0;0;False;0;False;-1;3c2220205bf33b74e91fb46cd5858af1;dbec9039c70e09e47b8ff15d508f39ac;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;35;-1957.938,205.2285;Inherit;False;Property;_distorted_map01power;distorted_map01 power;2;0;Create;True;0;0;0;False;0;False;1;0.59;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;64;-1816.566,-169.0508;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;66;-1849.23,-292.9339;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;57;-1896.634,325.9072;Inherit;False;0;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-1666.596,109.6958;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;67;-1594.974,-330.4107;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;8;-1129.005,-140.6214;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.VertexColorNode;58;-1246.396,-604.5615;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;43;-1196.271,-367.5294;Inherit;False;Property;_color_map;color_map;7;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;3.103399,3.103399,3.103399,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;3;-801.5157,-135.0742;Inherit;True;Property;_main_tex;main_tex;0;0;Create;True;0;0;0;False;0;False;-1;32a2a0fff0c45634fb83d8d541ab67a1;166f785056007484fb0416e339946f93;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;44;-1667.683,-968.4398;Inherit;True;Property;_TextureSample0;Texture Sample 0;6;0;Create;True;0;0;0;False;0;False;-1;84d2065fb5a7631498e52c89d8241193;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;46;-765.656,-454.5416;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;53;-433.345,-190.5329;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;103;-636.3,179.1223;Inherit;True;Property;_mask;mask;8;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;-278.573,-452.1475;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;59;-124.103,-53.83505;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;54;-24.47424,-217.9738;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;55;125.5641,-111.7444;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;598.6392,-185.5845;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_distorted;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;2;5;False;57;10;False;58;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;2;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;106;0;105;1
WireConnection;106;1;105;2
WireConnection;107;0;105;3
WireConnection;107;1;105;4
WireConnection;19;0;24;1
WireConnection;19;1;24;2
WireConnection;104;0;17;0
WireConnection;104;1;106;0
WireConnection;104;2;107;0
WireConnection;23;0;24;3
WireConnection;18;0;104;0
WireConnection;18;2;19;0
WireConnection;18;1;23;0
WireConnection;4;1;18;0
WireConnection;64;0;63;3
WireConnection;66;0;63;1
WireConnection;66;1;63;2
WireConnection;31;0;4;1
WireConnection;31;1;35;0
WireConnection;67;0;2;0
WireConnection;67;2;66;0
WireConnection;67;1;64;0
WireConnection;8;0;67;0
WireConnection;8;1;31;0
WireConnection;8;2;57;3
WireConnection;3;1;8;0
WireConnection;46;0;44;0
WireConnection;46;1;43;0
WireConnection;46;2;58;0
WireConnection;53;0;3;1
WireConnection;53;1;3;2
WireConnection;53;2;3;3
WireConnection;47;0;46;0
WireConnection;47;1;53;0
WireConnection;59;0;3;4
WireConnection;59;1;58;4
WireConnection;59;2;103;1
WireConnection;54;0;47;0
WireConnection;55;0;54;0
WireConnection;55;3;59;0
WireConnection;1;0;55;0
ASEEND*/
//CHKSM=110DBA4AD8B63DED321F3C886C0C69F4A7E3550C

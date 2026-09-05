// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "blade_flow_ab_hard"
{
	Properties
	{
		_maintex("主贴图", 2D) = "white" {}
		_mask("mask", 2D) = "white" {}
		_TextureSample0("扭曲贴图", 2D) = "white" {}
		_Vector0("扭曲速度", Vector) = (0,0,0,0)
		_Vector5("溶解贴图速度", Vector) = (0,0,0,0)
		_TextureSample1("溶解贴图", 2D) = "white" {}
		_mask_power("遮罩强度", Float) = 2.19
		_Float2("黑边宽度", Float) = 0.16
		_Color0("主颜色", Color) = (1,1,1,0)
		_Vector1("主纹理缩放", Vector) = (1,1,0,0)
		_Vector2("溶解贴图缩放", Vector) = (1,1,0,0)
		color02("边缘颜色", Color) = (0,0,0,0)
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
		Cull Back
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
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform sampler2D _maintex;
			uniform sampler2D _TextureSample0;
			uniform float2 _Vector0;
			uniform float2 _Vector1;
			uniform sampler2D _TextureSample1;
			uniform float2 _Vector5;
			uniform float2 _Vector2;
			uniform float4 _Color0;
			uniform float4 color02;
			uniform float _Float2;
			uniform sampler2D _mask;
			uniform float4 _mask_ST;
			uniform float _mask_power;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord1 = v.ase_texcoord;
				o.ase_texcoord2 = v.ase_texcoord1;
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
				float2 appendResult35 = (float2(_Vector0.x , _Vector0.y));
				float4 texCoord78 = i.ase_texcoord1;
				texCoord78.xy = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 panner31 = ( 1.0 * _Time.y * appendResult35 + texCoord78.xy);
				float4 texCoord30 = i.ase_texcoord2;
				texCoord30.xy = i.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_37_0 = ( tex2D( _TextureSample0, panner31 ).r * texCoord30.z );
				float2 appendResult80 = (float2(_Vector1.x , _Vector1.y));
				float2 appendResult81 = (float2(texCoord30.x , texCoord30.y));
				float4 tex2DNode2 = tex2D( _maintex, ( temp_output_37_0 + (texCoord78*float4( appendResult80, 0.0 , 0.0 ) + float4( appendResult81, 0.0 , 0.0 )) ).xy );
				float2 appendResult83 = (float2(_Vector5.x , _Vector5.y));
				float2 appendResult95 = (float2(_Vector2.x , _Vector2.y));
				float2 panner84 = ( 1.0 * _Time.y * appendResult83 + ( temp_output_37_0 + (texCoord78*float4( appendResult95, 0.0 , 0.0 ) + float4( 0,0,0,0 )) ).xy);
				float4 tex2DNode42 = tex2D( _TextureSample1, panner84 );
				float temp_output_60_0 = step( tex2DNode42.r , texCoord30.w );
				float3 appendResult72 = (float3(i.ase_color.r , i.ase_color.g , i.ase_color.b));
				float temp_output_97_0 = step( ( tex2DNode42.r + _Float2 ) , ( texCoord30.w + 0.1 ) );
				float2 uv_mask = i.ase_texcoord1.xy * _mask_ST.xy + _mask_ST.zw;
				float4 appendResult9 = (float4(( ( tex2DNode2 * ( 1.0 - temp_output_60_0 ) * _Color0 * float4( appendResult72 , 0.0 ) ) + ( color02 * ( temp_output_60_0 - temp_output_97_0 ) ) ).rgb , ( tex2DNode2.a * ( 1.0 - temp_output_97_0 ) * ( tex2D( _mask, uv_mask ).r * _mask_power ) * i.ase_color.a )));
				
				
				finalColor = appendResult9;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18935
0;0;1957;1131;1297.271;873.0012;1.3;True;True
Node;AmplifyShaderEditor.CommentaryNode;75;-2865.776,-1106.25;Inherit;False;1424.997;546.7424;Comment;5;35;32;37;31;36;扭曲;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;77;-2805.042,-266.062;Inherit;False;1153.639;708.1528;Comment;6;39;30;4;78;79;80;自定义顶点流;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector2Node;36;-2858.565,-822.3881;Inherit;False;Property;_Vector0;扭曲速度;3;0;Create;False;0;0;0;False;0;False;0,0;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;78;-2788.91,-133.7124;Inherit;False;0;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;35;-2684.659,-944.078;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;96;-2513.736,812.0877;Inherit;False;Property;_Vector2;溶解贴图缩放;11;0;Create;False;0;0;0;False;0;False;1,1;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.PannerNode;31;-2283.089,-1043.7;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;92;-2147.313,689.5081;Inherit;False;880.1641;437.8488;Comment;3;82;83;84;溶解贴图流动;1,1,1,1;0;0
Node;AmplifyShaderEditor.DynamicAppendNode;95;-2253.965,810.7953;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;32;-2014.031,-1056.25;Inherit;True;Property;_TextureSample0;扭曲贴图;2;0;Create;False;0;0;0;False;0;False;-1;3c2220205bf33b74e91fb46cd5858af1;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;30;-2764.825,320.241;Inherit;True;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;82;-2097.313,965.157;Inherit;False;Property;_Vector5;溶解贴图速度;4;0;Create;False;0;0;0;False;0;False;0,0;1,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;37;-1676.979,-893.2117;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;94;-1981.225,632.3572;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;107;-1768.912,533.4203;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;83;-1800.749,860.1937;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;76;-1247.946,360.3424;Inherit;False;1208.602;784.8197;Comment;10;44;60;63;45;42;61;88;89;97;98;溶解;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector2Node;79;-2665.885,88.11233;Inherit;False;Property;_Vector1;主纹理缩放;10;0;Create;False;0;0;0;False;0;False;1,1;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.PannerNode;84;-1491.542,728.9663;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;81;-2378.665,327.7054;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-1065.023,1014.968;Inherit;False;Property;_Float2;黑边宽度;8;0;Create;False;0;0;0;False;0;False;0.16;0.25;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;42;-1197.946,722.0557;Inherit;True;Property;_TextureSample1;溶解贴图;5;0;Create;False;0;0;0;False;0;False;-1;4d063b83542f6d749aafe52a1453b739;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;80;-2406.114,86.81995;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;4;-2133.373,-91.61814;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;93;-1137.396,-439.7387;Inherit;False;673.8545;598.9821;Comment;3;71;72;99;颜色;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;88;-798.2474,659.8853;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;44;-782.6729,866.2086;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;73;193.4275,309.4892;Inherit;False;679.0322;576.3525;comment;3;6;67;68;遮罩;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;39;-1734.203,-154.691;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StepOpNode;60;-732.1187,426.247;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;71;-1133.9,-378.1905;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StepOpNode;97;-598.4705,712.0438;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;68;522.3373,770.4417;Inherit;False;Property;_mask_power;遮罩强度;6;0;Create;False;0;0;0;False;0;False;2.19;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;72;-904.6713,-385.6948;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;6;243.4276,359.4892;Inherit;True;Property;_mask;mask;1;0;Create;True;0;0;0;False;0;False;-1;ca9d7dc4791fe4e4c9a5f7f306114517;ca9d7dc4791fe4e4c9a5f7f306114517;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;103;-182.2647,-162.1564;Inherit;False;Property;color02;边缘颜色;12;0;Create;False;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;2;-1537.654,86.77547;Inherit;True;Property;_maintex;主贴图;0;0;Create;False;0;0;0;False;0;False;-1;65116b446942ee548abdf01d27ba7491;52359486578666d4e905ca80058d75fb;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;99;-728.5708,-69.75396;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;105;-112.1267,584.1995;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;70;-1226.57,-861.9886;Inherit;False;Property;_Color0;主颜色;9;0;Create;False;0;0;0;False;0;False;1,1,1,0;1,0,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;106;83.58171,-315.6303;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;67;706.8599,389.3934;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;98;-360.9778,196.1635;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;-877.3027,-868.2894;Inherit;True;4;4;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;104;-231.8142,-510.2261;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;55;-366.4965,-860.2787;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;89;-1073.847,615.6855;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;63;-143.7043,895.7983;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;9;18.37844,-779.2313;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;61;-1027.182,436.1394;Inherit;False;Property;_Float3;溶解值;7;0;Create;False;0;0;0;False;0;False;0.75;0.19;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;634.1335,-457.3372;Float;False;True;-1;2;ASEMaterialInspector;100;1;blade_flow_ab_hard;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;2;5;False;40;10;False;41;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;35;0;36;1
WireConnection;35;1;36;2
WireConnection;31;0;78;0
WireConnection;31;2;35;0
WireConnection;95;0;96;1
WireConnection;95;1;96;2
WireConnection;32;1;31;0
WireConnection;37;0;32;1
WireConnection;37;1;30;3
WireConnection;94;0;78;0
WireConnection;94;1;95;0
WireConnection;107;0;37;0
WireConnection;107;1;94;0
WireConnection;83;0;82;1
WireConnection;83;1;82;2
WireConnection;84;0;107;0
WireConnection;84;2;83;0
WireConnection;81;0;30;1
WireConnection;81;1;30;2
WireConnection;42;1;84;0
WireConnection;80;0;79;1
WireConnection;80;1;79;2
WireConnection;4;0;78;0
WireConnection;4;1;80;0
WireConnection;4;2;81;0
WireConnection;88;0;30;4
WireConnection;44;0;42;1
WireConnection;44;1;45;0
WireConnection;39;0;37;0
WireConnection;39;1;4;0
WireConnection;60;0;42;1
WireConnection;60;1;30;4
WireConnection;97;0;44;0
WireConnection;97;1;88;0
WireConnection;72;0;71;1
WireConnection;72;1;71;2
WireConnection;72;2;71;3
WireConnection;2;1;39;0
WireConnection;99;0;60;0
WireConnection;105;0;60;0
WireConnection;105;1;97;0
WireConnection;106;0;103;0
WireConnection;106;1;105;0
WireConnection;67;0;6;1
WireConnection;67;1;68;0
WireConnection;98;0;97;0
WireConnection;24;0;2;0
WireConnection;24;1;99;0
WireConnection;24;2;70;0
WireConnection;24;3;72;0
WireConnection;104;0;2;4
WireConnection;104;1;98;0
WireConnection;104;2;67;0
WireConnection;104;3;71;4
WireConnection;55;0;24;0
WireConnection;55;1;106;0
WireConnection;9;0;55;0
WireConnection;9;3;104;0
WireConnection;1;0;9;0
ASEEND*/
//CHKSM=05A8774E492425DC128407F7AF6A319ECCE31234
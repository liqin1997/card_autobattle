// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "line shrink"
{
	Properties
	{
		_maintex("maintex", 2D) = "white" {}
		_scakeoffset("scake/offset", Vector) = (1,1,0,0)
		_centermaskpower("center/maskpower", Float) = 1
		_speedxy("speed x/y", Vector) = (0,1,0,0)
		_mask("mask", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_MASKPOWER("MASKPOWER", Float) = 0
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
			uniform float2 _speedxy;
			uniform float4 _scakeoffset;
			uniform float4 _Color;
			uniform sampler2D _mask;
			uniform float4 _mask_ST;
			uniform float _MASKPOWER;
			uniform float _centermaskpower;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_color = v.color;
				
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
				float2 appendResult12 = (float2(_speedxy.x , _speedxy.y));
				float2 texCoord2 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult74 = (float2(texCoord2.x , ( pow( texCoord2.y , 5.0 ) + pow( ( 1.0 - texCoord2.y ) , 5.0 ) )));
				float2 appendResult89 = (float2(_scakeoffset.x , _scakeoffset.y));
				float2 appendResult90 = (float2(_scakeoffset.z , _scakeoffset.w));
				float2 panner9 = ( 1.0 * _Time.y * appendResult12 + (appendResult74*appendResult89 + appendResult90));
				float4 tex2DNode3 = tex2D( _maintex, panner9 );
				float3 appendResult100 = (float3(tex2DNode3.r , tex2DNode3.g , tex2DNode3.b));
				float3 appendResult106 = (float3(i.ase_color.r , i.ase_color.g , i.ase_color.b));
				float3 appendResult108 = (float3(_Color.r , _Color.g , _Color.b));
				float2 uv_mask = i.ase_texcoord1.xy * _mask_ST.xy + _mask_ST.zw;
				float4 appendResult102 = (float4((( appendResult100 * appendResult106 * appendResult108 )).xyz , ( pow( tex2D( _mask, uv_mask ).r , _MASKPOWER ) * saturate( ( length( ( texCoord2.y + -0.5 ) ) * _centermaskpower ) ) * tex2DNode3.r * _Color.a * i.ase_color.a )));
				
				
				finalColor = appendResult102;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18935
0;0;1957;1131;2589.708;728.3726;1.198572;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;2;-3711.444,-747.4861;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;80;-3442.519,-420.2262;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;83;-3422.99,-1000.139;Inherit;False;Constant;_Float5;Float 5;2;0;Create;True;0;0;0;False;0;False;5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;76;-3073.855,-992.7667;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;8.57;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;81;-3171.51,-629.575;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;12.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;88;-3022.042,-254.0417;Inherit;False;Property;_scakeoffset;scake/offset;1;0;Create;True;0;0;0;False;0;False;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;82;-2858.791,-643.8362;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;90;-2771.366,-167.4681;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;93;-2927.621,73.07771;Inherit;False;Property;_speedxy;speed x/y;3;0;Create;True;0;0;0;False;0;False;0,1;-1,3;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;74;-2596.167,-763.1738;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;89;-2786.873,-339.323;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;12;-2546.115,34.09799;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;84;-2379.608,-501.0383;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;94;-3168.624,634.0229;Inherit;False;Constant;_Float0;Float 0;2;0;Create;True;0;0;0;False;0;False;-0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;95;-2823.883,522.101;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;9;-2112.352,-576.6104;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;98;-2243.46,541.1313;Inherit;False;Property;_centermaskpower;center/maskpower;2;0;Create;True;0;0;0;False;0;False;1;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;91;-2511.944,471.5347;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;110;-1637.418,-121.0946;Inherit;False;Property;_Color;Color;5;0;Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;105;-1960.865,9.689514;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;3;-1758.368,-523.783;Inherit;True;Property;_maintex;maintex;0;0;Create;True;0;0;0;False;0;False;3;8349bf0a0a5896d40ba8da1add62fbef;84e8033e53db39048a3e212ed5baf6a9;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;114;-1792.953,250.7197;Inherit;False;Property;_MASKPOWER;MASKPOWER;6;0;Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;100;-1415.981,-744.0001;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;106;-1405.164,-374.1105;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;103;-1948.755,379.1686;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;108;-1297.977,-168.5625;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;104;-2107.265,-276.7106;Inherit;True;Property;_mask;mask;4;0;Create;True;0;0;0;False;0;False;-1;None;05b2a1c3e0dafdd48ad0a8453cc5de6c;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;112;-1650.498,412.7296;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;-1197.765,-532.4105;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PowerNode;115;-1568.462,212.1229;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;101;-1127.015,-678.394;Inherit;False;True;True;True;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;111;-1049.209,62.91811;Inherit;True;5;5;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;102;-798.8301,-480.1617;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;-369.4529,-451.0189;Float;False;True;-1;2;ASEMaterialInspector;100;1;line shrink;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;2;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;80;0;2;2
WireConnection;76;0;2;2
WireConnection;76;1;83;0
WireConnection;81;0;80;0
WireConnection;81;1;83;0
WireConnection;82;0;76;0
WireConnection;82;1;81;0
WireConnection;90;0;88;3
WireConnection;90;1;88;4
WireConnection;74;0;2;1
WireConnection;74;1;82;0
WireConnection;89;0;88;1
WireConnection;89;1;88;2
WireConnection;12;0;93;1
WireConnection;12;1;93;2
WireConnection;84;0;74;0
WireConnection;84;1;89;0
WireConnection;84;2;90;0
WireConnection;95;0;2;2
WireConnection;95;1;94;0
WireConnection;9;0;84;0
WireConnection;9;2;12;0
WireConnection;91;0;95;0
WireConnection;3;1;9;0
WireConnection;100;0;3;1
WireConnection;100;1;3;2
WireConnection;100;2;3;3
WireConnection;106;0;105;1
WireConnection;106;1;105;2
WireConnection;106;2;105;3
WireConnection;103;0;91;0
WireConnection;103;1;98;0
WireConnection;108;0;110;1
WireConnection;108;1;110;2
WireConnection;108;2;110;3
WireConnection;112;0;103;0
WireConnection;107;0;100;0
WireConnection;107;1;106;0
WireConnection;107;2;108;0
WireConnection;115;0;104;1
WireConnection;115;1;114;0
WireConnection;101;0;107;0
WireConnection;111;0;115;0
WireConnection;111;1;112;0
WireConnection;111;2;3;1
WireConnection;111;3;110;4
WireConnection;111;4;105;4
WireConnection;102;0;101;0
WireConnection;102;3;111;0
WireConnection;1;0;102;0
ASEEND*/
//CHKSM=5E540AB36E4FCFF7AAF603825E7A028E865A7C99
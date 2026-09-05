// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "blade_flow_ab"
{
	Properties
	{
		_maintex("主贴图", 2D) = "white" {}
		_mask("mask", 2D) = "white" {}
		_TextureSample0("扭曲贴图", 2D) = "white" {}
		_Color("边缘颜色", Color) = (0,0,0,0)
		_Vector0("扭曲速度", Vector) = (0,0,0,0)
		_Vector5("溶解贴图速度", Vector) = (0,0,0,0)
		_TextureSample1("溶解贴图", 2D) = "white" {}
		_mask_power("遮罩强度", Float) = 0
		_Float2("黑边宽度", Float) = 0
		_Color0("主颜色", Color) = (0,0,0,0)
		_Vector1("主纹理缩放", Vector) = (0,0,0,0)
		_Vector2("溶解贴图缩放", Vector) = (1,1,0,0)
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


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_color : COLOR;
			};

			uniform float4 _Color;
			uniform sampler2D _maintex;
			uniform sampler2D _TextureSample0;
			uniform float2 _Vector0;
			uniform float2 _Vector1;
			uniform float4 _Color0;
			uniform sampler2D _TextureSample1;
			uniform float2 _Vector5;
			uniform float2 _Vector2;
			uniform sampler2D _mask;
			uniform float4 _mask_ST;
			uniform float _mask_power;
			uniform float _Float2;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
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
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				float2 appendResult35 = (float2(_Vector0.x , _Vector0.y));
				float4 uv078 = i.ase_texcoord;
				uv078.xy = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 panner31 = ( 1.0 * _Time.y * appendResult35 + uv078.xy);
				float4 uv130 = i.ase_texcoord1;
				uv130.xy = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult80 = (float2(_Vector1.x , _Vector1.y));
				float2 appendResult81 = (float2(uv130.x , uv130.y));
				float4 tex2DNode2 = tex2D( _maintex, ( ( tex2D( _TextureSample0, panner31 ).r * uv130.z ) + (uv078*float4( appendResult80, 0.0 , 0.0 ) + float4( appendResult81, 0.0 , 0.0 )) ).xy );
				float2 appendResult83 = (float2(_Vector5.x , _Vector5.y));
				float2 appendResult95 = (float2(_Vector2.x , _Vector2.y));
				float2 panner84 = ( 1.0 * _Time.y * appendResult83 + (uv078*float4( appendResult95, 0.0 , 0.0 ) + float4( 0,0,0,0 )).xy);
				float4 tex2DNode42 = tex2D( _TextureSample1, panner84 );
				float3 appendResult72 = (float3(i.ase_color.r , i.ase_color.g , i.ase_color.b));
				float2 uv_mask = i.ase_texcoord.xy * _mask_ST.xy + _mask_ST.zw;
				float smoothstepResult85 = smoothstep( 0.1 , ( tex2DNode42.r + _Float2 ) , ( saturate( uv130.w ) + 0.1 ));
				float4 appendResult9 = (float4(( ( _Color * tex2DNode2 ) + ( _Color0 * step( tex2DNode42.r , uv130.w ) * float4( appendResult72 , 0.0 ) ) ).rgb , ( ( tex2D( _mask, uv_mask ).r * _mask_power ) * ( tex2DNode2.a * smoothstepResult85 ) * i.ase_color.a )));
				
				
				finalColor = appendResult9;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	Fallback "False"
}
/*ASEBEGIN
Version=17500
-2041.6;145.6;1957;887;2680.942;759.2045;2.117952;True;True
Node;AmplifyShaderEditor.CommentaryNode;75;-2865.776,-1106.25;Inherit;False;1424.997;546.7424;Comment;6;35;32;37;31;36;38;扭曲;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector2Node;36;-2858.565,-822.3881;Inherit;False;Property;_Vector0;扭曲速度;5;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;96;-2513.736,812.0877;Inherit;False;Property;_Vector2;溶解贴图缩放;13;0;Create;False;0;0;False;0;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.CommentaryNode;92;-2147.313,689.5081;Inherit;False;880.1641;437.8488;Comment;3;82;83;84;溶解贴图流动;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;77;-2805.042,-266.062;Inherit;False;1153.639;708.1528;Comment;6;39;30;4;78;79;80;自定义顶点流;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector2Node;82;-2097.313,965.157;Inherit;False;Property;_Vector5;溶解贴图速度;6;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;78;-2788.91,-133.7124;Inherit;False;0;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;35;-2684.659,-944.078;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;95;-2253.965,810.7953;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;31;-2283.089,-1043.7;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;83;-1800.749,860.1937;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;79;-2665.885,88.11233;Inherit;False;Property;_Vector1;主纹理缩放;12;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ScaleAndOffsetNode;94;-1981.225,632.3572;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;30;-2764.825,320.241;Inherit;True;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;84;-1475.549,739.5081;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;32;-2014.031,-1056.25;Inherit;True;Property;_TextureSample0;扭曲贴图;2;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;76;-1247.946,360.3424;Inherit;False;1208.602;784.8197;Comment;10;44;60;63;64;45;42;61;85;88;89;溶解;1,1,1,1;0;0
Node;AmplifyShaderEditor.DynamicAppendNode;81;-2378.665,327.7054;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;80;-2406.114,86.81995;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-1065.023,1014.968;Inherit;False;Property;_Float2;黑边宽度;10;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;93;-1149.898,-429.737;Inherit;False;673.8545;598.9821;Comment;4;71;70;72;22;颜色;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;42;-1197.946,722.0557;Inherit;True;Property;_TextureSample1;溶解贴图;7;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;4;-2133.373,-91.61814;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SaturateNode;89;-1073.847,615.6855;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;37;-1676.979,-893.2117;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;71;-840.4174,-368.1888;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;88;-798.2474,659.8853;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;73;193.4275,309.4892;Inherit;False;679.0322;576.3525;comment;3;6;67;68;遮罩;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;39;-1734.203,-154.691;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;44;-782.6729,866.2086;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;68;522.3373,770.4417;Inherit;False;Property;_mask_power;遮罩强度;8;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;22;-1099.898,-371.4598;Inherit;False;Property;_Color;边缘颜色;3;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;2;-1537.654,86.77547;Inherit;True;Property;_maintex;主贴图;0;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;6;243.4276,359.4892;Inherit;True;Property;_mask;mask;1;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;70;-835.0863,-71.49474;Inherit;False;Property;_Color0;主颜色;11;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;72;-640.8437,-379.737;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;85;-628.4462,672.1218;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0.1;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;60;-674.4645,410.3424;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-275.5441,487.4624;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;-877.3027,-868.2894;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;67;706.8599,389.3934;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;62;-408.4034,-166.7766;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;55;-462.8794,-925.8192;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;65;48.49747,-334.458;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;38;-2079.357,-625.564;Inherit;False;Property;_Float0;扭曲强度;4;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;61;-950.3559,517.7473;Inherit;False;Property;_Float3;溶解值;9;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;63;-164.0486,803.1186;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;9;18.37844,-779.2313;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;634.1335,-457.3372;Float;False;True;-1;2;ASEMaterialInspector;100;1;blade_flow_ab;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;False;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;35;0;36;1
WireConnection;35;1;36;2
WireConnection;95;0;96;1
WireConnection;95;1;96;2
WireConnection;31;0;78;0
WireConnection;31;2;35;0
WireConnection;83;0;82;1
WireConnection;83;1;82;2
WireConnection;94;0;78;0
WireConnection;94;1;95;0
WireConnection;84;0;94;0
WireConnection;84;2;83;0
WireConnection;32;1;31;0
WireConnection;81;0;30;1
WireConnection;81;1;30;2
WireConnection;80;0;79;1
WireConnection;80;1;79;2
WireConnection;42;1;84;0
WireConnection;4;0;78;0
WireConnection;4;1;80;0
WireConnection;4;2;81;0
WireConnection;89;0;30;4
WireConnection;37;0;32;1
WireConnection;37;1;30;3
WireConnection;88;0;89;0
WireConnection;39;0;37;0
WireConnection;39;1;4;0
WireConnection;44;0;42;1
WireConnection;44;1;45;0
WireConnection;2;1;39;0
WireConnection;72;0;71;1
WireConnection;72;1;71;2
WireConnection;72;2;71;3
WireConnection;85;0;88;0
WireConnection;85;2;44;0
WireConnection;60;0;42;1
WireConnection;60;1;30;4
WireConnection;64;0;2;4
WireConnection;64;1;85;0
WireConnection;24;0;22;0
WireConnection;24;1;2;0
WireConnection;67;0;6;1
WireConnection;67;1;68;0
WireConnection;62;0;70;0
WireConnection;62;1;60;0
WireConnection;62;2;72;0
WireConnection;55;0;24;0
WireConnection;55;1;62;0
WireConnection;65;0;67;0
WireConnection;65;1;64;0
WireConnection;65;2;71;4
WireConnection;9;0;55;0
WireConnection;9;3;65;0
WireConnection;1;0;9;0
ASEEND*/
//CHKSM=5BAE7CDD111F40EC2C9CFE090EE051D16ACF3D2F
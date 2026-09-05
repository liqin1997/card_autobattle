// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_Screen inversion"
{
	Properties
	{
		_Float0("遮罩缩放", Float) = 0.51
		_TextureSample0("外侧扭曲贴图", 2D) = "white" {}
		_Vector0("外侧遮罩扭曲贴图缩放", Vector) = (1,1,0,0)
		_Vector1("外侧遮罩扭曲贴图速度", Vector) = (1,0,0,0)
		_Float4("外侧扭曲强度", Float) = 0
		_TextureSample1("内侧扭曲贴图", 2D) = "white" {}
		_Vector2("内侧遮罩扭曲贴图缩放", Vector) = (1,1,0,0)
		_Vector3("内侧遮罩扭曲贴图速度", Vector) = (0,0,0,0)
		_Float1("内侧扭曲强度", Float) = 0
		_TextureSample2("描边贴图", 2D) = "white" {}
		_Float6("描边强度", Float) = 0
		_Float5("解除屏幕坐标", Float) = 0
		[HDR]_Color0("主颜色", Color) = (1,1,1,1)
		_Float9("反相/黑白", Float) = 0
		_Float10("饱和度", Float) = 1

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" "Queue"="Transparent"  "RenderPipeline"="UniversalPipeline" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off
		ColorMask RGBA
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		
		
		

		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="SRPDefaultUnlit" }
			CGPROGRAM

			#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
			#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex);
			#else
			#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)
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
			};

			uniform float4 _Color0;
			ASE_DECLARE_SCREENSPACE_TEXTURE( _CameraOpaqueTexture )
			uniform float _Float5;
			uniform sampler2D _TextureSample1;
			uniform float2 _Vector3;
			uniform float4 _Vector2;
			uniform float _Float1;
			uniform float _Float10;
			uniform float _Float9;
			uniform sampler2D _TextureSample2;
			uniform float _Float6;
			uniform sampler2D _TextureSample0;
			uniform float2 _Vector1;
			uniform float4 _Vector0;
			uniform float _Float4;
			uniform float _Float0;
			inline float4 ASE_ComputeGrabScreenPos( float4 pos )
			{
				#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
				#else
				float scale = 1.0;
				#endif
				float4 o = pos;
				o.y = pos.w * 0.5f;
				o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
				return o;
			}
			

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float4 ase_clipPos = UnityObjectToClipPos(v.vertex);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord1 = screenPos;
				
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_texcoord.zw = v.ase_texcoord1.xy;
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
				float3 appendResult124 = (float3(_Color0.r , _Color0.g , _Color0.b));
				float2 uv0105 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult4 = (float2(uv0105.y , uv0105.x));
				float4 screenPos = i.ase_texcoord1;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float2 appendResult106 = (float2(ase_grabScreenPosNorm.r , ase_grabScreenPosNorm.g));
				float2 lerpResult107 = lerp( appendResult4 , appendResult106 , _Float5);
				float2 appendResult71 = (float2(_Vector3.x , _Vector3.y));
				float2 uv055 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult68 = (float2(_Vector2.x , _Vector2.y));
				float2 appendResult67 = (float2(_Vector2.z , _Vector2.w));
				float2 panner58 = ( 1.0 * _Time.y * appendResult71 + (uv055*appendResult68 + appendResult67));
				float2 temp_cast_1 = (tex2D( _TextureSample1, panner58 ).r).xx;
				float2 lerpResult54 = lerp( lerpResult107 , temp_cast_1 , _Float1);
				float2 _Vector5 = float2(0,0.005);
				float2 appendResult91 = (float2(_Vector5.x , _Vector5.y));
				float4 screenColor100 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,(lerpResult54*1.0 + appendResult91));
				float2 _Vector6 = float2(0,-0.005);
				float2 appendResult93 = (float2(_Vector6.x , _Vector6.y));
				float4 screenColor3 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,(lerpResult54*1.0 + appendResult93));
				float2 _Vector7 = float2(0.005,0);
				float2 appendResult96 = (float2(_Vector7.x , _Vector7.y));
				float4 screenColor101 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,(lerpResult54*1.0 + appendResult96));
				float3 appendResult123 = (float3(( 1.0 - screenColor100.r ) , ( 1.0 - screenColor3.g ) , ( 1.0 - screenColor101.b )));
				float4 screenColor143 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,lerpResult54);
				float3 appendResult140 = (float3(screenColor143.r , screenColor143.g , screenColor143.b));
				float3 break134 = appendResult140;
				float4 appendResult136 = (float4(break134.x , break134.y , break134.z , 0.0));
				float3 break128 = appendResult140;
				float temp_output_135_0 = ( ( break128.x * 0.2125 ) + ( break128.y * 0.7154 ) + ( 0.0 * 0.0721 ) );
				float4 appendResult138 = (float4(temp_output_135_0 , temp_output_135_0 , temp_output_135_0 , 0.0));
				float4 lerpResult139 = lerp( appendResult136 , appendResult138 , _Float10);
				float4 lerpResult141 = lerp( float4( appendResult123 , 0.0 ) , lerpResult139 , _Float9);
				float2 uv1118 = i.ase_texcoord.zw * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult119 = (float2(uv1118.x , uv1118.y));
				float2 uv034 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult66 = (float2(_Vector1.x , _Vector1.y));
				float2 uv040 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_79_0 = (uv040*2.0 + -1.0);
				float2 break83 = temp_output_79_0;
				float2 appendResult84 = (float2(length( temp_output_79_0 ) , atan2( break83.y , break83.x )));
				float2 appendResult63 = (float2(_Vector0.x , _Vector0.y));
				float2 appendResult64 = (float2(_Vector0.z , _Vector0.w));
				float2 panner42 = ( 1.0 * _Time.y * appendResult66 + (appendResult84*appendResult63 + appendResult64));
				float4 tex2DNode39 = tex2D( _TextureSample0, panner42 );
				float2 temp_cast_5 = (tex2DNode39.r).xx;
				float2 lerpResult52 = lerp( uv034 , temp_cast_5 , _Float4);
				float temp_output_35_0 = length( (lerpResult52*2.0 + -1.0) );
				float temp_output_37_0 = step( temp_output_35_0 , _Float0 );
				float4 appendResult28 = (float4(( float4( appendResult124 , 0.0 ) * ( lerpResult141 + ( tex2D( _TextureSample2, appendResult119 ) * _Float6 ) ) ).xyz , ( _Color0.a * saturate( temp_output_37_0 ) )));
				
				
				finalColor = appendResult28;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=17500
-2041.6;6.4;1957;1117;-673.0509;1776.121;1;True;True
Node;AmplifyShaderEditor.Vector4Node;69;-2720.283,298.4468;Inherit;False;Property;_Vector2;内侧遮罩扭曲贴图缩放;6;0;Create;False;0;0;False;0;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;70;-2306.711,433.8038;Inherit;False;Property;_Vector3;内侧遮罩扭曲贴图速度;7;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;55;-2525.034,105.9248;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;67;-2467.283,473.4468;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;68;-2475.283,363.4468;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;105;-2572.074,-805.6841;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GrabScreenPosition;2;-2395.188,-549.2629;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;71;-2069.184,381.4468;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;56;-2239.773,104.7135;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;5,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;40;-4221.653,951.763;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;4;-2092.018,-827.5787;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;58;-2016.274,151.0137;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;108;-1968.987,-223.9805;Inherit;False;Property;_Float5;解除屏幕坐标;11;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;79;-3829.765,955.3427;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;106;-2086.077,-549.1227;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;107;-1601.87,-546.902;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;83;-3452.836,1216.653;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;72;-1541.719,199.2161;Inherit;False;Property;_Float1;内侧扭曲强度;8;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;59;-1859.344,48.12667;Inherit;True;Property;_TextureSample1;内侧扭曲贴图;5;0;Create;False;0;0;False;0;-1;3f1d4fadb37c37e4488860109d7dce4b;3f1d4fadb37c37e4488860109d7dce4b;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ATan2OpNode;82;-3037.524,1167.472;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;62;-2333.223,1379.579;Inherit;False;Property;_Vector0;外侧遮罩扭曲贴图缩放;2;0;Create;False;0;0;False;0;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;54;-971.0208,-529.0358;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LengthOpNode;78;-3082.562,942.6372;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;143;133.6664,-1229.487;Inherit;False;Global;_GrabScreen3;Grab Screen 1;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;65;-1949.651,1406.936;Inherit;False;Property;_Vector1;外侧遮罩扭曲贴图速度;3;0;Create;False;0;0;False;0;1,0;1,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;63;-2118.223,1336.579;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;84;-2642.508,1093.592;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;64;-2110.223,1446.579;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;41;-1940.152,1186.665;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;10,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;66;-1712.124,1354.579;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;140;565.9073,-1029.212;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector2Node;97;-543.1344,149.6058;Inherit;False;Constant;_Vector7;Vector 7;10;0;Create;True;0;0;False;0;0.005,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;90;-594.8331,-302.4605;Inherit;False;Constant;_Vector5;Vector 5;10;0;Create;True;0;0;False;0;0,0.005;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;94;-598.466,-120.8906;Inherit;False;Constant;_Vector6;Vector 6;10;0;Create;True;0;0;False;0;0,-0.005;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.PannerNode;42;-1659.08,1194.294;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;129;958.7095,-1576.643;Inherit;False;Constant;_Float7;Float 7;22;0;Create;True;0;0;False;0;0.2125;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;93;-334.3021,-174.3968;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;130;974.8448,-1417.167;Inherit;False;Constant;_Float8;Float 8;22;0;Create;True;0;0;False;0;0.7154;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;91;-402.8331,-366.4605;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;96;-341.3771,86.21042;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;127;952.0714,-1293.986;Inherit;False;Constant;_Float2;Float 2;22;0;Create;True;0;0;False;0;0.0721;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;128;1364,-852.1119;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ScaleAndOffsetNode;92;-301.5073,-387.8372;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT2;0.2,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;39;-1461.435,1158.839;Inherit;True;Property;_TextureSample0;外侧扭曲贴图;1;0;Create;False;0;0;False;0;-1;3c2220205bf33b74e91fb46cd5858af1;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;89;-178.8331,-542.4607;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT2;0.2,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;133;1178.026,-1541.032;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;131;1249.411,-1461.827;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;95;-62.55517,25.37536;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT2;0.2,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;34;-1453.713,427.6235;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;132;1234.934,-1348.213;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;53;-1553.673,774.5863;Inherit;False;Property;_Float4;外侧扭曲强度;4;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;135;1330.764,-1718.224;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;118;1209.116,744.1025;Inherit;False;1;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;32;957.496,351.2489;Inherit;False;Constant;_Float3;Float 3;5;0;Create;True;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;52;-1239.322,671.457;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScreenColorNode;101;664.9454,26.19817;Inherit;False;Global;_GrabScreen2;Grab Screen 2;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenColorNode;3;784.0931,-254.2339;Inherit;False;Global;_GrabScreen0;Grab Screen 0;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenColorNode;100;543.9764,-553.2142;Inherit;False;Global;_GrabScreen1;Grab Screen 1;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;134;979.2065,-1053.33;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;137;1501.206,-1025.33;Inherit;False;Property;_Float10;饱和度;14;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;138;1620.677,-1377.557;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;136;1317.207,-1022.33;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;30;1454.177,-74.42006;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;119;1578.382,664.3735;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;31;1435.532,247.2446;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;36;-1031.046,690.5364;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;29;1404.849,-377.0648;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;122;1468.584,395.2229;Inherit;False;Property;_Float6;描边强度;10;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;120;1753.851,532.3232;Inherit;True;Property;_TextureSample2;描边贴图;9;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;38;-756.288,968.7595;Inherit;False;Property;_Float0;遮罩缩放;0;0;Create;False;0;0;True;0;0.51;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;35;-797.837,513.0076;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;123;1711.086,-291.0252;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;139;1679.207,-1195.331;Inherit;True;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;142;1825.216,-808.676;Inherit;False;Property;_Float9;反相/黑白;13;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;121;1884.467,337.3146;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;141;2262.963,-977.8763;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ColorNode;116;1847.296,-516.8837;Inherit;False;Property;_Color0;主颜色;12;1;[HDR];Create;False;0;0;False;0;1,1,1,1;1.109569,1.109569,1.109569,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StepOpNode;37;-440.8126,631.4725;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;111;2046.599,-171.2922;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SaturateNode;49;567.1544,572.8292;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;124;2211.331,-524.0445;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;115;2410.181,-450.5316;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;125;2424.863,-108.3983;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;50;-317.6847,1206.82;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.4;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;87;-3780.663,1205.797;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;28;2620.315,-130.8356;Inherit;True;FLOAT4;4;0;FLOAT3;1,0,0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StepOpNode;45;-75.30244,980.6524;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;44;274.8384,773.758;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;47;-854.5585,1165.105;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;88;-4026.363,1253.897;Inherit;False;Constant;_Vector4;Vector 4;10;0;Create;True;0;0;False;0;1,2;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SaturateNode;48;-403.8247,1057.844;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;77;-1974.829,865.8867;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;2844.44,-544.1445;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_Screen inversion;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;2;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;67;0;69;3
WireConnection;67;1;69;4
WireConnection;68;0;69;1
WireConnection;68;1;69;2
WireConnection;71;0;70;1
WireConnection;71;1;70;2
WireConnection;56;0;55;0
WireConnection;56;1;68;0
WireConnection;56;2;67;0
WireConnection;4;0;105;2
WireConnection;4;1;105;1
WireConnection;58;0;56;0
WireConnection;58;2;71;0
WireConnection;79;0;40;0
WireConnection;106;0;2;1
WireConnection;106;1;2;2
WireConnection;107;0;4;0
WireConnection;107;1;106;0
WireConnection;107;2;108;0
WireConnection;83;0;79;0
WireConnection;59;1;58;0
WireConnection;82;0;83;1
WireConnection;82;1;83;0
WireConnection;54;0;107;0
WireConnection;54;1;59;1
WireConnection;54;2;72;0
WireConnection;78;0;79;0
WireConnection;143;0;54;0
WireConnection;63;0;62;1
WireConnection;63;1;62;2
WireConnection;84;0;78;0
WireConnection;84;1;82;0
WireConnection;64;0;62;3
WireConnection;64;1;62;4
WireConnection;41;0;84;0
WireConnection;41;1;63;0
WireConnection;41;2;64;0
WireConnection;66;0;65;1
WireConnection;66;1;65;2
WireConnection;140;0;143;1
WireConnection;140;1;143;2
WireConnection;140;2;143;3
WireConnection;42;0;41;0
WireConnection;42;2;66;0
WireConnection;93;0;94;1
WireConnection;93;1;94;2
WireConnection;91;0;90;1
WireConnection;91;1;90;2
WireConnection;96;0;97;1
WireConnection;96;1;97;2
WireConnection;128;0;140;0
WireConnection;92;0;54;0
WireConnection;92;2;93;0
WireConnection;39;1;42;0
WireConnection;89;0;54;0
WireConnection;89;2;91;0
WireConnection;133;0;128;0
WireConnection;133;1;129;0
WireConnection;131;0;128;1
WireConnection;131;1;130;0
WireConnection;95;0;54;0
WireConnection;95;2;96;0
WireConnection;132;1;127;0
WireConnection;135;0;133;0
WireConnection;135;1;131;0
WireConnection;135;2;132;0
WireConnection;52;0;34;0
WireConnection;52;1;39;1
WireConnection;52;2;53;0
WireConnection;101;0;95;0
WireConnection;3;0;92;0
WireConnection;100;0;89;0
WireConnection;134;0;140;0
WireConnection;138;0;135;0
WireConnection;138;1;135;0
WireConnection;138;2;135;0
WireConnection;136;0;134;0
WireConnection;136;1;134;1
WireConnection;136;2;134;2
WireConnection;30;0;32;0
WireConnection;30;1;3;2
WireConnection;119;0;118;1
WireConnection;119;1;118;2
WireConnection;31;0;32;0
WireConnection;31;1;101;3
WireConnection;36;0;52;0
WireConnection;29;0;32;0
WireConnection;29;1;100;1
WireConnection;120;1;119;0
WireConnection;35;0;36;0
WireConnection;123;0;29;0
WireConnection;123;1;30;0
WireConnection;123;2;31;0
WireConnection;139;0;136;0
WireConnection;139;1;138;0
WireConnection;139;2;137;0
WireConnection;121;0;120;0
WireConnection;121;1;122;0
WireConnection;141;0;123;0
WireConnection;141;1;139;0
WireConnection;141;2;142;0
WireConnection;37;0;35;0
WireConnection;37;1;38;0
WireConnection;111;0;141;0
WireConnection;111;1;121;0
WireConnection;49;0;37;0
WireConnection;124;0;116;1
WireConnection;124;1;116;2
WireConnection;124;2;116;3
WireConnection;115;0;124;0
WireConnection;115;1;111;0
WireConnection;125;0;116;4
WireConnection;125;1;49;0
WireConnection;50;0;38;0
WireConnection;87;1;88;2
WireConnection;28;0;115;0
WireConnection;28;3;125;0
WireConnection;45;0;48;0
WireConnection;45;1;50;0
WireConnection;44;0;37;0
WireConnection;44;1;45;0
WireConnection;47;0;35;0
WireConnection;47;1;39;1
WireConnection;48;0;47;0
WireConnection;1;0;28;0
ASEEND*/
//CHKSM=6655237CCEA43B36AE05407170218D24FFC63162
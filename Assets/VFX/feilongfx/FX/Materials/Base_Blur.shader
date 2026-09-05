// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_Blur"
{
	Properties
	{
		_Vector0("缩放", Vector) = (2,2,-1,-1)
		_Vector1("模糊偏移", Vector) = (0,0,0,0)
		_Float2("中心缩放值", Float) = 1
		_Float9("Custom Data 开启", Float) = 0
		_TextureSample0("遮罩", 2D) = "white" {}

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" "Queue"="Transparent+3000"  "RenderPipeline"="UniversalPipeline" }
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
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
			};

			uniform sampler2D _TextureSample0;
			ASE_DECLARE_SCREENSPACE_TEXTURE( _CameraOpaqueTexture )
			uniform float _Float2;
			uniform float4 _Vector0;
			uniform float2 _Vector1;
			uniform float _Float9;
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
				
				o.ase_color = v.color;
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_texcoord2 = v.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
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
				float2 uv0201 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float4 appendResult205 = (float4(i.ase_color.r , i.ase_color.g , i.ase_color.b , ( tex2D( _TextureSample0, uv0201 ).r * i.ase_color.a )));
				float4 screenPos = i.ase_texcoord1;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float2 appendResult187 = (float2(ase_grabScreenPosNorm.r , ase_grabScreenPosNorm.g));
				float2 temp_output_188_0 = ( ( appendResult187 * _Float2 ) + -( _Float2 * 0.5 ) + 0.5 );
				float2 appendResult105 = (float2(_Vector0.x , _Vector0.y));
				float2 appendResult106 = (float2(_Vector0.z , _Vector0.w));
				float4 screenColor4 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,(temp_output_188_0*appendResult105 + appendResult106));
				float2 _Vector2 = float2(0,0);
				float temp_output_150_0 = ( _Vector0.x + _Vector2.x );
				float temp_output_149_0 = ( _Vector0.y + _Vector2.y );
				float2 appendResult160 = (float2(temp_output_150_0 , temp_output_149_0));
				float4 uv1193 = i.ase_texcoord2;
				uv1193.xy = i.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float lerpResult194 = lerp( _Vector1.x , uv1193.x , _Float9);
				float X172 = (0.0 + (lerpResult194 - 0.0) * (1.0 - 0.0) / (10.0 - 0.0));
				float temp_output_130_0 = ( _Vector0.z + X172 );
				float lerpResult195 = lerp( _Vector1.y , uv1193.y , _Float9);
				float Y177 = (0.0 + (lerpResult195 - 0.0) * (1.0 - 0.0) / (10.0 - 0.0));
				float temp_output_133_0 = ( _Vector0.w + Y177 );
				float2 appendResult126 = (float2(temp_output_130_0 , temp_output_133_0));
				float4 screenColor67 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,(temp_output_188_0*appendResult160 + appendResult126));
				float temp_output_151_0 = ( temp_output_150_0 + _Vector2.x );
				float temp_output_152_0 = ( temp_output_149_0 + _Vector2.y );
				float2 appendResult163 = (float2(temp_output_151_0 , temp_output_152_0));
				float temp_output_134_0 = ( temp_output_130_0 + ( X172 * -1.0 ) );
				float temp_output_135_0 = ( temp_output_133_0 + ( Y177 * -1.0 ) );
				float2 appendResult127 = (float2(temp_output_134_0 , temp_output_135_0));
				float4 screenColor68 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,(temp_output_188_0*appendResult163 + appendResult127));
				float temp_output_153_0 = ( temp_output_151_0 + _Vector2.x );
				float temp_output_154_0 = ( temp_output_152_0 + _Vector2.y );
				float2 appendResult159 = (float2(temp_output_153_0 , temp_output_154_0));
				float temp_output_136_0 = ( temp_output_134_0 + ( X172 * -1.0 ) );
				float temp_output_137_0 = ( temp_output_135_0 + ( Y177 * -1.0 ) );
				float2 appendResult128 = (float2(temp_output_136_0 , temp_output_137_0));
				float4 screenColor69 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,(temp_output_188_0*appendResult159 + appendResult128));
				float temp_output_156_0 = ( temp_output_153_0 + _Vector2.x );
				float temp_output_155_0 = ( temp_output_154_0 + _Vector2.y );
				float2 appendResult161 = (float2(temp_output_156_0 , temp_output_155_0));
				float temp_output_139_0 = ( temp_output_136_0 + X172 );
				float temp_output_138_0 = ( temp_output_137_0 + Y177 );
				float2 appendResult129 = (float2(temp_output_139_0 , temp_output_138_0));
				float4 screenColor70 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,(temp_output_188_0*appendResult161 + appendResult129));
				float2 appendResult162 = (float2(( temp_output_156_0 + _Vector2.y ) , ( temp_output_155_0 + _Vector2.y )));
				float2 appendResult143 = (float2(( temp_output_139_0 + ( X172 * -1.0 ) ) , ( temp_output_138_0 + ( Y177 * -1.0 ) )));
				float4 screenColor71 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,(temp_output_188_0*appendResult162 + appendResult143));
				
				
				finalColor = ( appendResult205 * ( ( screenColor4 * 0.382 ) + ( screenColor67 * 0.3 ) + ( screenColor68 * 0.184 ) + ( screenColor69 * 0.088 ) + ( screenColor70 * 0.034 ) + ( screenColor71 * 0.016 ) ) );
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=17500
212.8;671.2;1957;1111;2498.506;1225.634;3.500539;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;193;-5276.826,795.8574;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;196;-5003.157,1347.287;Inherit;False;Property;_Float9;Custom Data 开启;3;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;132;-5294.018,1094.145;Inherit;False;Property;_Vector1;模糊偏移;1;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.LerpOp;195;-4834.803,1145.049;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;194;-4902.049,823.5576;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;197;-4556.793,786.9971;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;10;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;198;-4565.032,1190.68;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;10;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;172;-4260.303,964.8002;Inherit;False;X;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;177;-4262.488,1075.941;Inherit;False;Y;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;178;-5046.827,1530.244;Inherit;False;177;Y;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;148;-2455.228,705.9409;Inherit;False;Constant;_Vector2;缩放;2;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.GetLocalVarNode;173;-4277.834,1455.857;Inherit;False;172;X;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;104;-2663.786,260.2462;Inherit;False;Property;_Vector0;缩放;0;0;Create;False;0;0;False;0;2,2,-1,-1;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;171;-3877.838,974.8606;Inherit;False;172;X;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;181;-3420.494,1119.178;Inherit;False;177;Y;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;133;-3213.231,1057.441;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;150;-2146.228,634.9417;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;149;-1993.228,732.9409;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;170;-4803.31,1535.938;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;179;-5073.553,1685.242;Inherit;False;177;Y;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;164;-3989.482,1393.564;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;130;-3541.251,965.1334;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;174;-4282.198,1617.812;Inherit;False;172;X;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;165;-4000.051,1614.692;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;169;-4823.231,1678.231;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;151;-2167.427,831.2018;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;134;-3562.45,1161.394;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;152;-2018.427,939.2008;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;135;-3168.707,1252.317;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;185;-3920.776,140.0091;Inherit;False;Property;_Float2;中心缩放值;2;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;176;-3973.87,1508.865;Inherit;False;172;X;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;182;-3502.573,1645.423;Inherit;False;177;Y;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;153;-2177.735,1058.832;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;137;-3173.667,1472.64;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GrabScreenPosition;3;-4067.077,-295.1063;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;190;-3716.097,349.0045;Inherit;False;Constant;_Float3;Float 3;3;0;Create;True;0;0;False;0;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;175;-4265.299,1805.012;Inherit;False;172;X;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;154;-2007.735,1153.832;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;180;-5076.227,1870.972;Inherit;False;177;Y;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;136;-3538.608,1333.53;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;167;-4021.394,1792.557;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;187;-3608.102,-225.1776;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;139;-3570.112,1491.49;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;168;-4844.575,1856.096;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;156;-2193.847,1226.284;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;155;-2023.847,1321.284;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;138;-3194.048,1632.978;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;189;-3525.357,254.3206;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;158;-2184,1405.525;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;141;-3191.314,1820.755;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;142;-3550.564,1704.412;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;184;-3480.448,-37.83478;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;157;-2013.999,1500.524;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;192;-3326.384,445.0607;Inherit;False;Constant;_Float8;Float 8;3;0;Create;True;0;0;False;0;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;191;-3366.179,210.4092;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;143;-2974.779,1663.452;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;163;-1763.035,859.0048;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;160;-1761.286,710.3318;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;105;-1884.141,-30.317;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;106;-1860.254,64.32232;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;159;-1757.788,998.9337;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;161;-1759.537,1152.856;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;128;-2977.791,1323.434;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;129;-2979.54,1477.356;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;162;-1754.776,1338.952;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;188;-3076.637,48.48589;Inherit;True;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;126;-2981.289,1034.832;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;127;-2983.038,1183.505;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;122;-1212.61,1254.808;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;201;-126.4214,-773.5333;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;87;-1312.686,-105.4023;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;125;-1198.374,1481.545;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;114;-1217.574,736.6136;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;110;-1228.573,511.8786;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;119;-1181.897,1007.423;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;60;-399.5079,904.532;Inherit;False;Constant;_Float7;Float 7;0;0;Create;True;0;0;False;0;0.034;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;67;-758.3287,137.2734;Inherit;False;Global;_GrabScreen1;Grab Screen 1;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;55;-391.254,697.7973;Inherit;False;Constant;_Float6;Float 6;0;0;Create;True;0;0;False;0;0.088;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;202;151.3493,-843.9185;Inherit;True;Property;_TextureSample0;遮罩;4;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;27;-408.8769,-18.18426;Inherit;False;Constant;_Float1;Float 1;0;0;Create;True;0;0;False;0;0.382;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;199;-230.9338,-442.9666;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;50;-390.1811,447.5213;Inherit;False;Constant;_Float5;Float 5;0;0;Create;True;0;0;False;0;0.184;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;71;-777.691,1044.062;Inherit;False;Global;_GrabScreen5;Grab Screen 5;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenColorNode;70;-772.8503,785.9017;Inherit;False;Global;_GrabScreen4;Grab Screen 4;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenColorNode;69;-769.6234,560.0112;Inherit;False;Global;_GrabScreen3;Grab Screen 3;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;45;-392.5127,209.6892;Inherit;False;Constant;_Float4;Float 4;0;0;Create;True;0;0;False;0;0.3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;65;-392.4433,1127.871;Inherit;False;Constant;_Float0;Float 0;0;0;Create;True;0;0;False;0;0.016;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;68;-761.5558,366.3908;Inherit;False;Global;_GrabScreen2;Grab Screen 2;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenColorNode;4;-740.705,-87.93198;Inherit;False;Global;_GrabScreen0;Grab Screen 0;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;59;-219.1474,889.9921;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;-211.3588,-59.24044;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;203;109.8721,-260.7265;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-212.0828,1113.331;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;-189.4945,653.047;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;44;-212.1522,195.1492;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;-209.8205,432.9813;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;66;241.0993,5.626202;Inherit;False;6;6;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;205;305.9455,-385.1577;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;200;516.1067,-198.3402;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;186;-3243.448,-187.8348;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;930.8188,-211.9094;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_Blur;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=3000;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;195;0;132;2
WireConnection;195;1;193;2
WireConnection;195;2;196;0
WireConnection;194;0;132;1
WireConnection;194;1;193;1
WireConnection;194;2;196;0
WireConnection;197;0;194;0
WireConnection;198;0;195;0
WireConnection;172;0;197;0
WireConnection;177;0;198;0
WireConnection;133;0;104;4
WireConnection;133;1;181;0
WireConnection;150;0;104;1
WireConnection;150;1;148;1
WireConnection;149;0;104;2
WireConnection;149;1;148;2
WireConnection;170;0;178;0
WireConnection;164;0;173;0
WireConnection;130;0;104;3
WireConnection;130;1;171;0
WireConnection;165;0;174;0
WireConnection;169;0;179;0
WireConnection;151;0;150;0
WireConnection;151;1;148;1
WireConnection;134;0;130;0
WireConnection;134;1;164;0
WireConnection;152;0;149;0
WireConnection;152;1;148;2
WireConnection;135;0;133;0
WireConnection;135;1;170;0
WireConnection;153;0;151;0
WireConnection;153;1;148;1
WireConnection;137;0;135;0
WireConnection;137;1;169;0
WireConnection;154;0;152;0
WireConnection;154;1;148;2
WireConnection;136;0;134;0
WireConnection;136;1;165;0
WireConnection;167;0;175;0
WireConnection;187;0;3;1
WireConnection;187;1;3;2
WireConnection;139;0;136;0
WireConnection;139;1;176;0
WireConnection;168;0;180;0
WireConnection;156;0;153;0
WireConnection;156;1;148;1
WireConnection;155;0;154;0
WireConnection;155;1;148;2
WireConnection;138;0;137;0
WireConnection;138;1;182;0
WireConnection;189;0;185;0
WireConnection;189;1;190;0
WireConnection;158;0;156;0
WireConnection;158;1;148;2
WireConnection;141;0;138;0
WireConnection;141;1;168;0
WireConnection;142;0;139;0
WireConnection;142;1;167;0
WireConnection;184;0;187;0
WireConnection;184;1;185;0
WireConnection;157;0;155;0
WireConnection;157;1;148;2
WireConnection;191;0;189;0
WireConnection;143;0;142;0
WireConnection;143;1;141;0
WireConnection;163;0;151;0
WireConnection;163;1;152;0
WireConnection;160;0;150;0
WireConnection;160;1;149;0
WireConnection;105;0;104;1
WireConnection;105;1;104;2
WireConnection;106;0;104;3
WireConnection;106;1;104;4
WireConnection;159;0;153;0
WireConnection;159;1;154;0
WireConnection;161;0;156;0
WireConnection;161;1;155;0
WireConnection;128;0;136;0
WireConnection;128;1;137;0
WireConnection;129;0;139;0
WireConnection;129;1;138;0
WireConnection;162;0;158;0
WireConnection;162;1;157;0
WireConnection;188;0;184;0
WireConnection;188;1;191;0
WireConnection;188;2;192;0
WireConnection;126;0;130;0
WireConnection;126;1;133;0
WireConnection;127;0;134;0
WireConnection;127;1;135;0
WireConnection;122;0;188;0
WireConnection;122;1;161;0
WireConnection;122;2;129;0
WireConnection;87;0;188;0
WireConnection;87;1;105;0
WireConnection;87;2;106;0
WireConnection;125;0;188;0
WireConnection;125;1;162;0
WireConnection;125;2;143;0
WireConnection;114;0;188;0
WireConnection;114;1;163;0
WireConnection;114;2;127;0
WireConnection;110;0;188;0
WireConnection;110;1;160;0
WireConnection;110;2;126;0
WireConnection;119;0;188;0
WireConnection;119;1;159;0
WireConnection;119;2;128;0
WireConnection;67;0;110;0
WireConnection;202;1;201;0
WireConnection;71;0;125;0
WireConnection;70;0;122;0
WireConnection;69;0;119;0
WireConnection;68;0;114;0
WireConnection;4;0;87;0
WireConnection;59;0;70;0
WireConnection;59;1;60;0
WireConnection;26;0;4;0
WireConnection;26;1;27;0
WireConnection;203;0;202;1
WireConnection;203;1;199;4
WireConnection;64;0;71;0
WireConnection;64;1;65;0
WireConnection;54;0;69;0
WireConnection;54;1;55;0
WireConnection;44;0;67;0
WireConnection;44;1;45;0
WireConnection;49;0;68;0
WireConnection;49;1;50;0
WireConnection;66;0;26;0
WireConnection;66;1;44;0
WireConnection;66;2;49;0
WireConnection;66;3;54;0
WireConnection;66;4;59;0
WireConnection;66;5;64;0
WireConnection;205;0;199;1
WireConnection;205;1;199;2
WireConnection;205;2;199;3
WireConnection;205;3;203;0
WireConnection;200;0;205;0
WireConnection;200;1;66;0
WireConnection;1;0;200;0
ASEEND*/
//CHKSM=96A9F881B1395759F3F0D9FBEA27B91187C069BD
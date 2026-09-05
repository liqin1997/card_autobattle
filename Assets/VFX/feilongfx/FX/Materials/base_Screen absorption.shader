// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_Screen absorption"
{
	Properties
	{
		_TextureSample4("扭曲贴图2", 2D) = "white" {}
		_TextureSample0("扭曲贴图", 2D) = "white" {}
		_Float0("主贴图缩放(中心缩放)", Float) = 1.46
		_Float2("扭曲贴图强度", Float) = 0
		_Color0("Color 0", Color) = (1,1,1,1)
		_Float3("扭曲度", Float) = 0
		_TextureSample1("扰动贴图", 2D) = "white" {}
		_pi("pi", Float) = 0
		_Vector0("扰动贴图缩放", Vector) = (1,1,0,0)
		_Float4("扰动值", Float) = 0
		_Vector1("扰动贴图速度", Vector) = (0,0,0,0)
		_TextureSample2("扰动贴图遮罩", 2D) = "white" {}
		_TextureSample3("整体遮罩贴图", 2D) = "white" {}
		_Float6("遮罩贴图强度/放了贴图数值不要为0", Float) = 1
		_Float7("扰动贴图强度", Float) = 1
		_Float8("开启CustomData(扭曲值 扰动值 扰动贴图速度X Y) (扭曲混合，中心缩放)", Float) = 0
		_Float9("关闭屏幕坐标遮罩", Float) = 0
		_Float10("关闭以屏幕中心扭曲和扰动", Float) = 0
		_Float11("扭曲贴图混合", Float) = 0

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
				float4 ase_texcoord2 : TEXCOORD2;
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
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_color : COLOR;
			};

			ASE_DECLARE_SCREENSPACE_TEXTURE( _CameraOpaqueTexture )
			uniform float _Float0;
			uniform float _Float8;
			uniform sampler2D _TextureSample0;
			uniform float _Float10;
			uniform float _Float2;
			uniform sampler2D _TextureSample4;
			uniform float _Float11;
			uniform float _Float3;
			uniform sampler2D _TextureSample1;
			uniform float2 _Vector1;
			uniform float _pi;
			uniform float4 _Vector0;
			uniform float _Float7;
			uniform float _Float4;
			uniform sampler2D _TextureSample2;
			uniform float4 _Color0;
			uniform sampler2D _TextureSample3;
			uniform float _Float9;
			uniform float _Float6;
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
				o.ase_texcoord = screenPos;
				
				o.ase_texcoord1 = v.ase_texcoord2;
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				o.ase_texcoord3 = v.ase_texcoord1;
				o.ase_color = v.color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
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
				float4 screenPos = i.ase_texcoord;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float2 appendResult4 = (float2(ase_grabScreenPosNorm.r , ase_grabScreenPosNorm.g));
				float4 uv2116 = i.ase_texcoord1;
				uv2116.xy = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				half CustomData84 = _Float8;
				float lerpResult167 = lerp( _Float0 , uv2116.y , CustomData84);
				float2 temp_output_11_0 = ( ( appendResult4 * lerpResult167 ) + -( lerpResult167 * 0.5 ) + 0.5 );
				float2 uv098 = i.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 lerpResult99 = lerp( temp_output_11_0 , uv098 , _Float10);
				float4 tex2DNode12 = tex2D( _TextureSample0, lerpResult99 );
				float2 appendResult16 = (float2(tex2DNode12.r , tex2DNode12.g));
				float4 tex2DNode102 = tex2D( _TextureSample4, lerpResult99 );
				float2 appendResult103 = (float2(tex2DNode102.r , tex2DNode102.g));
				float lerpResult124 = lerp( _Float11 , uv2116.x , CustomData84);
				float2 lerpResult111 = lerp( ( appendResult16 * _Float2 ) , appendResult103 , lerpResult124);
				float4 uv176 = i.ase_texcoord3;
				uv176.xy = i.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float lerpResult79 = lerp( _Float3 , uv176.x , CustomData84);
				float2 lerpResult24 = lerp( temp_output_11_0 , lerpResult111 , lerpResult79);
				float lerpResult80 = lerp( _Vector1.x , uv176.z , CustomData84);
				float lerpResult81 = lerp( _Vector1.y , uv176.w , CustomData84);
				float2 appendResult46 = (float2(lerpResult80 , lerpResult81));
				float2 temp_output_35_0 = (lerpResult99*2.0 + -1.0);
				float2 break36 = temp_output_35_0;
				float2 appendResult41 = (float2(length( temp_output_35_0 ) , ( atan2( break36.y , break36.x ) * _pi )));
				float2 appendResult31 = (float2(_Vector0.x , _Vector0.y));
				float2 appendResult32 = (float2(_Vector0.z , _Vector0.w));
				float2 panner44 = ( 1.0 * _Time.y * appendResult46 + (appendResult41*appendResult31 + appendResult32));
				float2 temp_cast_0 = (( tex2D( _TextureSample1, panner44 ).r * _Float7 )).xx;
				float4 tex2DNode92 = tex2D( _TextureSample2, temp_output_11_0 );
				float lerpResult78 = lerp( ( _Float4 * tex2DNode92.r ) , ( tex2DNode92.r * uv176.y ) , CustomData84);
				float2 lerpResult42 = lerp( lerpResult24 , temp_cast_0 , lerpResult78);
				float4 screenColor3 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,lerpResult42);
				float4 break70 = ( screenColor3 * _Color0 * i.ase_color );
				float4 appendResult71 = (float4(break70.r , break70.g , break70.b , 0.0));
				float2 uv06 = i.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 lerpResult90 = lerp( temp_output_11_0 , uv06 , _Float9);
				float4 appendResult63 = (float4(appendResult71.xyz , ( _Color0.a * ( screenColor3.a * 10.0 ) * pow( tex2D( _TextureSample3, lerpResult90 ).r , _Float6 ) * i.ase_color.a )));
				
				
				finalColor = appendResult63;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=17500
-2041.6;80;1957;1014;1681.925;-868.9806;1;True;True
Node;AmplifyShaderEditor.RangedFloatNode;77;-492.4577,1353.112;Inherit;False;Property;_Float8;开启CustomData(扭曲值 扰动值 扰动贴图速度X Y) (扭曲混合，中心缩放);15;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;84;-198.5371,1353.681;Half;False;CustomData;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;166;-1855.554,100.7675;Inherit;False;84;CustomData;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;7;-1880.151,-72.34209;Inherit;False;Property;_Float0;主贴图缩放(中心缩放);2;0;Create;False;0;0;False;0;1.46;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;116;-347.9115,-1112.836;Inherit;False;2;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;167;-1578.652,-51.9788;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GrabScreenPosition;23;-1831.491,-459.6382;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;10;-1387.281,13.26321;Inherit;False;Constant;_Float1;Float 1;0;0;Create;True;0;0;False;0;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;9;-1231.281,-23.7368;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;4;-1250.565,-257.7132;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NegateNode;8;-1029.22,-12.7928;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-1019.192,209.1141;Inherit;False;Constant;_Float5;Float 5;10;0;Create;True;0;0;False;0;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;5;-1083.985,-258.6913;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;100;-1423.34,-654.0417;Inherit;False;Property;_Float10;关闭以屏幕中心扭曲和扰动;17;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;11;-840.6597,-131.1481;Inherit;True;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;98;-1526.586,-897.713;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;99;-1046.262,-885.0711;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;130;-1055.614,-1064.244;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;131;-2706.195,-878.0886;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;35;-3005.881,552.834;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;123;-2776.122,660.2252;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;122;-2798.122,744.2252;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;121;-3059.122,761.2252;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;120;-3275.122,822.2252;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LengthOpNode;40;-2740.999,565.53;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;36;-3261.437,909.7803;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ATan2OpNode;37;-2982.176,793.5071;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;38;-2926.109,1030.697;Inherit;False;Property;_pi;pi;7;0;Create;True;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;118;-2585.417,610.3982;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;39;-2768.356,788.7491;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;119;-2588.417,755.3982;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;41;-2556.033,765.1723;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;45;-1790.663,814.5945;Inherit;False;Property;_Vector1;扰动贴图速度;10;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.GetLocalVarNode;86;-1794.642,1020.473;Inherit;False;84;CustomData;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;30;-2185.324,712.0163;Inherit;False;Property;_Vector0;扰动贴图缩放;8;0;Create;False;0;0;False;0;1,1,0,0;0.2,2,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;76;-1804.17,1096.461;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;126;-2218.447,760.6454;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;85;-1795.593,947.6097;Inherit;False;84;CustomData;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;80;-1544.396,803.6913;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;32;-2021.139,787.3818;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;12;-781.572,-622.7376;Inherit;True;Property;_TextureSample0;扭曲贴图;1;0;Create;False;0;0;False;0;-1;79b2e17c439502c4d93d0c5510165838;127af731760193f408e2f6fb052bd832;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;127;-2219.447,684.6454;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;31;-2023.74,686.6927;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;81;-1555.268,919.5226;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;17;-494.4975,-505.6809;Inherit;False;Property;_Float2;扭曲贴图强度;3;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;46;-1364.863,799.1359;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;29;-1881.321,644.0358;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;16;-487.0663,-613.1418;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;117;-339.4613,-938.7865;Inherit;False;Property;_Float11;扭曲贴图混合;18;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;125;-343.449,-847.4214;Inherit;False;84;CustomData;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;102;-771.3137,-838.1216;Inherit;True;Property;_TextureSample4;扭曲贴图2;0;0;Create;False;0;0;False;0;-1;79b2e17c439502c4d93d0c5510165838;127af731760193f408e2f6fb052bd832;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;124;1.453364,-878.1677;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;25;-230.8278,-619.0781;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;103;-481.8079,-747.3259;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;44;-1221.069,761.5519;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;92;-237.2518,540.5779;Inherit;True;Property;_TextureSample2;扰动贴图遮罩;11;0;Create;False;0;0;False;0;-1;None;58b4ff61ca569744fba1dbb378d6d259;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;43;-729.7778,1151.703;Inherit;True;Property;_Float4;扰动值;9;0;Create;False;0;0;False;0;0;0.05;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;26;-347.8145,248.9364;Inherit;False;Property;_Float3;扭曲度;5;0;Create;False;0;0;False;0;0;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;87;-337.1669,409.6385;Inherit;False;84;CustomData;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;79;-72.56418,347.0006;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;75;-564.3271,875.1878;Inherit;False;Property;_Float7;扰动贴图强度;14;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;89;-227.9345,1160.447;Inherit;False;84;CustomData;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;27;-952.063,686.4939;Inherit;True;Property;_TextureSample1;扰动贴图;6;0;Create;False;0;0;False;0;-1;None;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;96;23.42789,928.0961;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;111;15.40355,-742.4283;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;93;197.2394,769.3978;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;78;286.9492,979.8153;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;74;-399.4294,722.2827;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;24;-60.08479,-37.30449;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;42;357.7442,68.84928;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;6;454.2296,457.5716;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;91;668.4771,622.1692;Inherit;False;Property;_Float9;关闭屏幕坐标遮罩;16;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;3;473.6161,-202.5164;Inherit;False;Global;_GrabScreen0;Grab Screen 0;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;73;274.9829,-678.5096;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;21;288.3229,-434.3412;Inherit;False;Property;_Color0;Color 0;4;0;Create;True;0;0;False;0;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;90;858.6175,368.6486;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;164;746.7458,-8.79623;Inherit;False;Constant;_Float14;Float 14;19;0;Create;True;0;0;False;0;10;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;681.7354,-545.5146;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;67;1051.004,315.5072;Inherit;True;Property;_Float6;遮罩贴图强度/放了贴图数值不要为0;13;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;64;937.2347,69.05647;Inherit;True;Property;_TextureSample3;整体遮罩贴图;12;0;Create;False;0;0;False;0;-1;None;58b4ff61ca569744fba1dbb378d6d259;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;163;998.9307,-81.00309;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;66;1228.467,88.08057;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;70;872.4791,-511.5141;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;68;1425.683,-131.9141;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;71;1184.678,-507.6116;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;63;1366.794,-433.4643;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;132;1060.266,-286.0403;Inherit;False;Constant;_Float12;Float 12;19;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;157;-2135.313,-281.9366;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1570.362,-255.7822;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_Screen absorption;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;84;0;77;0
WireConnection;167;0;7;0
WireConnection;167;1;116;2
WireConnection;167;2;166;0
WireConnection;9;0;167;0
WireConnection;9;1;10;0
WireConnection;4;0;23;1
WireConnection;4;1;23;2
WireConnection;8;0;9;0
WireConnection;5;0;4;0
WireConnection;5;1;167;0
WireConnection;11;0;5;0
WireConnection;11;1;8;0
WireConnection;11;2;47;0
WireConnection;99;0;11;0
WireConnection;99;1;98;0
WireConnection;99;2;100;0
WireConnection;130;0;99;0
WireConnection;131;0;130;0
WireConnection;35;0;131;0
WireConnection;123;0;35;0
WireConnection;122;0;123;0
WireConnection;121;0;122;0
WireConnection;120;0;121;0
WireConnection;40;0;35;0
WireConnection;36;0;120;0
WireConnection;37;0;36;1
WireConnection;37;1;36;0
WireConnection;118;0;40;0
WireConnection;39;0;37;0
WireConnection;39;1;38;0
WireConnection;119;0;118;0
WireConnection;41;0;119;0
WireConnection;41;1;39;0
WireConnection;126;0;41;0
WireConnection;80;0;45;1
WireConnection;80;1;76;3
WireConnection;80;2;85;0
WireConnection;32;0;30;3
WireConnection;32;1;30;4
WireConnection;12;1;99;0
WireConnection;127;0;126;0
WireConnection;31;0;30;1
WireConnection;31;1;30;2
WireConnection;81;0;45;2
WireConnection;81;1;76;4
WireConnection;81;2;86;0
WireConnection;46;0;80;0
WireConnection;46;1;81;0
WireConnection;29;0;127;0
WireConnection;29;1;31;0
WireConnection;29;2;32;0
WireConnection;16;0;12;1
WireConnection;16;1;12;2
WireConnection;102;1;99;0
WireConnection;124;0;117;0
WireConnection;124;1;116;1
WireConnection;124;2;125;0
WireConnection;25;0;16;0
WireConnection;25;1;17;0
WireConnection;103;0;102;1
WireConnection;103;1;102;2
WireConnection;44;0;29;0
WireConnection;44;2;46;0
WireConnection;92;1;11;0
WireConnection;79;0;26;0
WireConnection;79;1;76;1
WireConnection;79;2;87;0
WireConnection;27;1;44;0
WireConnection;96;0;43;0
WireConnection;96;1;92;1
WireConnection;111;0;25;0
WireConnection;111;1;103;0
WireConnection;111;2;124;0
WireConnection;93;0;92;1
WireConnection;93;1;76;2
WireConnection;78;0;96;0
WireConnection;78;1;93;0
WireConnection;78;2;89;0
WireConnection;74;0;27;1
WireConnection;74;1;75;0
WireConnection;24;0;11;0
WireConnection;24;1;111;0
WireConnection;24;2;79;0
WireConnection;42;0;24;0
WireConnection;42;1;74;0
WireConnection;42;2;78;0
WireConnection;3;0;42;0
WireConnection;90;0;11;0
WireConnection;90;1;6;0
WireConnection;90;2;91;0
WireConnection;20;0;3;0
WireConnection;20;1;21;0
WireConnection;20;2;73;0
WireConnection;64;1;90;0
WireConnection;163;0;3;4
WireConnection;163;1;164;0
WireConnection;66;0;64;1
WireConnection;66;1;67;0
WireConnection;70;0;20;0
WireConnection;68;0;21;4
WireConnection;68;1;163;0
WireConnection;68;2;66;0
WireConnection;68;3;73;4
WireConnection;71;0;70;0
WireConnection;71;1;70;1
WireConnection;71;2;70;2
WireConnection;63;0;71;0
WireConnection;63;3;68;0
WireConnection;1;0;63;0
ASEEND*/
//CHKSM=F81B70AE88BDA948AFE7E48C59AD0DE131E88658
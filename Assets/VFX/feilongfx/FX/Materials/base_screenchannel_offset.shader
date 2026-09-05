// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_screenchannel_offset"
{
	Properties
	{
		_TextureSample0("Texture Sample 0", 2D) = "white" {}
		_Vector0("流动速度", Vector) = (1,0,0,0)
		_Float1("遮罩强度", Float) = 0
		_power("扰动强度", Float) = 0
		_Vector1("通道偏移", Vector) = (0,0,0,0)
		_Vector3("缩放和偏移", Vector) = (1,1,0,0)
		_Float5("极坐标开关", Float) = 0
		_Float4("极坐标偏移", Float) = 1
		_Float2("粒子系统开关", Float) = 0
		_Float3("备注：custom1 扰动强度 极坐标偏移 通道偏移XY", Float) = 0
		_Float6("备注：custom2_扰动流速", Float) = 0

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" "Queue"="Transparent+3000"  "RenderPipeline"="UniversalPipeline" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha
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
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
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
				float4 ase_texcoord3 : TEXCOORD3;
			};

			uniform float _Float3;
			uniform float _Float6;
			ASE_DECLARE_SCREENSPACE_TEXTURE( _CameraOpaqueTexture )
			uniform sampler2D _TextureSample0;
			uniform float2 _Vector0;
			uniform float _Float2;
			uniform float _Float4;
			uniform float _Float5;
			uniform float4 _Vector3;
			uniform float _power;
			uniform float2 _Vector1;
			uniform float _Float1;
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
				
				o.ase_color = v.color;
				o.ase_texcoord1 = v.ase_texcoord2;
				o.ase_texcoord2 = v.ase_texcoord1;
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
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
				float4 uv287 = i.ase_texcoord1;
				uv287.xy = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult88 = (float2(uv287.x , uv287.y));
				float2 lerpResult85 = lerp( _Vector0 , appendResult88 , _Float2);
				float2 appendResult9 = (float2(lerpResult85));
				float4 uv178 = i.ase_texcoord2;
				uv178.xy = i.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float lerpResult82 = lerp( _Float4 , uv178.y , _Float2);
				float2 uv041 = i.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_output_45_0 = (uv041*2.0 + -1.0);
				float2 break54 = temp_output_45_0;
				float2 appendResult63 = (float2(( lerpResult82 * length( temp_output_45_0 ) ) , atan2( break54.y , break54.x )));
				float2 uv07 = i.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float2 lerpResult75 = lerp( appendResult63 , uv07 , _Float5);
				float2 panner8 = ( _Time.y * appendResult9 + lerpResult75);
				float2 appendResult34 = (float2(_Vector3.x , _Vector3.y));
				float2 appendResult35 = (float2(_Vector3.z , _Vector3.w));
				float lerpResult79 = lerp( _power , uv178.x , _Float2);
				float4 temp_output_5_0 = ( (ase_grabScreenPosNorm).xyzw + ( (-0.3 + (tex2D( _TextureSample0, (panner8*appendResult34 + appendResult35) ).r - 0.0) * (0.5 - -0.3) / (1.0 - 0.0)) * (0.0 + (lerpResult79 - 0.0) * (0.1 - 0.0) / (2.0 - 0.0)) ) );
				float2 appendResult86 = (float2(uv178.z , uv178.w));
				float2 lerpResult80 = lerp( _Vector1 , appendResult86 , _Float2);
				float4 screenColor19 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,( temp_output_5_0 + float4( (float2( 0,0 ) + (lerpResult80 - float2( 0,0 )) * (float2( 0.1,0.1 ) - float2( 0,0 )) / (float2( 2,2 ) - float2( 0,0 ))), 0.0 , 0.0 ) ).xy);
				float4 screenColor3 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,ase_grabScreenPos.xy/ase_grabScreenPos.w);
				float4 screenColor20 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,( temp_output_5_0 + float4( (float2( 0,0 ) + (lerpResult80 - float2( 0,0 )) * (float2( -0.1,-0.1 ) - float2( 0,0 )) / (float2( 2,2 ) - float2( 0,0 ))), 0.0 , 0.0 ) ).xy);
				float2 uv097 = i.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float4 appendResult17 = (float4(screenColor19.r , screenColor3.g , screenColor20.b , pow( length( (uv097*2.0 + -1.0) ) , _Float1 )));
				
				
				finalColor = ( i.ase_color * appendResult17 );
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=17500
-2020;112;1957;1011;2141.597;191.325;1.9;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;41;-4224.566,-4.69464;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;72;-3808.511,467.4548;Inherit;False;Property;_Float4;极坐标偏移;8;0;Create;False;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;84;-3750.239,942.9036;Inherit;False;Property;_Float2;粒子系统开关;9;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;78;-4191.699,787.9943;Inherit;True;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;45;-3895.766,-15.09454;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;87;-4207.594,1167.457;Inherit;True;2;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;54;-3404.994,1.367493;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.LerpOp;82;-3578.252,485.7063;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;50;-3345.442,-321.1813;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;10;-3350.479,515.5438;Inherit;False;Property;_Vector0;流动速度;1;0;Create;False;0;0;False;0;1,0;2,2;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;88;-3902.094,1192.156;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;71;-2997.684,-412.0372;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ATan2OpNode;48;-3065.567,-12.19452;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;76;-2713.106,30.67683;Inherit;False;Property;_Float5;极坐标开关;7;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;63;-2873.322,-294.7713;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;14;-2676.22,720.775;Inherit;False;Constant;_Float0;Float 0;1;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;7;-2785.88,222.4422;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;85;-2954.393,687.7563;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;9;-2622.628,432.5308;Inherit;False;FLOAT2;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;16;-2548.312,572.3936;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;33;-2342.642,581.8549;Inherit;False;Property;_Vector3;缩放和偏移;6;0;Create;False;0;0;False;0;1,1,0,0;0.5,0.5,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;75;-2435.006,-98.62315;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;8;-2371.128,250.8307;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;34;-2134.642,509.8549;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;35;-2124.642,618.8549;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;24;-3158.898,906.6229;Inherit;False;Property;_power;扰动强度;3;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;32;-2024.642,276.8549;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;13;-1769.565,336.5743;Inherit;True;Property;_TextureSample0;Texture Sample 0;0;0;Create;True;0;0;False;0;-1;4d063b83542f6d749aafe52a1453b739;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;79;-2930.333,953.8503;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;37;-1477.811,591.6533;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;2;False;3;FLOAT;0;False;4;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;25;-1451.664,268.7806;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-0.3;False;4;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;86;-3306.694,1266.256;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GrabScreenPosition;2;-1813.859,-73.76867;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;30;-3244.68,1112.668;Inherit;False;Property;_Vector1;通道偏移;4;0;Create;False;0;0;False;0;0,0;-0.03,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ComponentMaskNode;4;-1496.008,-25.4666;Inherit;False;True;True;True;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LerpOp;80;-2724.619,1251.752;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;-1168.135,297.2137;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;97;-796.1525,951.9481;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;39;-1022.811,755.6533;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;2,2;False;3;FLOAT2;0,0;False;4;FLOAT2;-0.1,-0.1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;38;-1039.812,538.6533;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;2,2;False;3;FLOAT2;0,0;False;4;FLOAT2;0.1,0.1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;5;-910.3926,80.77087;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;98;-498.1525,976.9481;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;26;-806.2426,391.8459;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;27;-810.497,632.3087;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LengthOpNode;99;-255.1525,860.9481;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;18;-347.4831,723.3409;Inherit;False;Property;_Float1;遮罩强度;2;0;Create;False;0;0;False;0;0;0.3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;19;-573.515,311.9413;Inherit;False;Global;_GrabScreen1;Grab Screen 1;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;100;-11.15247,691.9481;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;20;-646.9476,604.6029;Inherit;False;Global;_GrabScreen2;Grab Screen 2;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenColorNode;3;-689.3773,65.58258;Inherit;False;Global;_GrabScreen0;Grab Screen 0;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;92;-564.0188,-432.8279;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;17;-150.8905,212.196;Inherit;True;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;90;-3657.352,1689.665;Inherit;False;Property;_Float6;备注：custom2_扰动流速;11;0;Create;False;0;0;True;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;91;38.69018,-171.226;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector2Node;31;-1164.606,977.2953;Inherit;False;Property;_Vector2;蓝通道偏移;5;0;Create;False;0;0;False;0;0,0;0.2,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;89;-3664.294,1556.59;Inherit;False;Property;_Float3;备注：custom1 扰动强度 极坐标偏移 通道偏移XY;10;0;Create;False;0;0;True;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;265.9971,-10.04123;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_screenchannel_offset;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;2;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=3000;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;45;0;41;0
WireConnection;54;0;45;0
WireConnection;82;0;72;0
WireConnection;82;1;78;2
WireConnection;82;2;84;0
WireConnection;50;0;45;0
WireConnection;88;0;87;1
WireConnection;88;1;87;2
WireConnection;71;0;82;0
WireConnection;71;1;50;0
WireConnection;48;0;54;1
WireConnection;48;1;54;0
WireConnection;63;0;71;0
WireConnection;63;1;48;0
WireConnection;85;0;10;0
WireConnection;85;1;88;0
WireConnection;85;2;84;0
WireConnection;9;0;85;0
WireConnection;16;0;14;0
WireConnection;75;0;63;0
WireConnection;75;1;7;0
WireConnection;75;2;76;0
WireConnection;8;0;75;0
WireConnection;8;2;9;0
WireConnection;8;1;16;0
WireConnection;34;0;33;1
WireConnection;34;1;33;2
WireConnection;35;0;33;3
WireConnection;35;1;33;4
WireConnection;32;0;8;0
WireConnection;32;1;34;0
WireConnection;32;2;35;0
WireConnection;13;1;32;0
WireConnection;79;0;24;0
WireConnection;79;1;78;1
WireConnection;79;2;84;0
WireConnection;37;0;79;0
WireConnection;25;0;13;1
WireConnection;86;0;78;3
WireConnection;86;1;78;4
WireConnection;4;0;2;0
WireConnection;80;0;30;0
WireConnection;80;1;86;0
WireConnection;80;2;84;0
WireConnection;21;0;25;0
WireConnection;21;1;37;0
WireConnection;39;0;80;0
WireConnection;38;0;80;0
WireConnection;5;0;4;0
WireConnection;5;1;21;0
WireConnection;98;0;97;0
WireConnection;26;0;5;0
WireConnection;26;1;38;0
WireConnection;27;0;5;0
WireConnection;27;1;39;0
WireConnection;99;0;98;0
WireConnection;19;0;26;0
WireConnection;100;0;99;0
WireConnection;100;1;18;0
WireConnection;20;0;27;0
WireConnection;17;0;19;1
WireConnection;17;1;3;2
WireConnection;17;2;20;3
WireConnection;17;3;100;0
WireConnection;91;0;92;0
WireConnection;91;1;17;0
WireConnection;1;0;91;0
ASEEND*/
//CHKSM=CDED8688871EF533099921BB127988C5D39367AC
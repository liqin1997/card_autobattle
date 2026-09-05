// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "screen_BW"
{
	Properties
	{
		_Float0("黑白闪范围", Range( -1 , 1)) = 0.5431729
		_Float1("黑白闪正负值", Range( -1 , 1)) = 0
		_TextureSample0("放射线贴图", 2D) = "white" {}
		_Vector0("流动速度", Vector) = (10,0,0,0)
		_Vector1("放射线贴图缩放", Vector) = (1,6.57,0,0)
		_mask("放射线遮罩", 2D) = "white" {}
		_Float2("遮罩强度", Float) = 1
		_Float3("遮罩开关", Float) = 1
		_Color0("颜色", Color) = (1,1,1,1)
		_Float4("屏幕黑白强度", Float) = 1

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" "Queue"="Transparent"  "RenderPipeline"="UniversalPipeline" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend Off
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
				
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_texcoord : TEXCOORD0;
			};

			uniform float4 _Color0;
			uniform float _Float1;
			uniform float _Float0;
			ASE_DECLARE_SCREENSPACE_TEXTURE( _CameraOpaqueTexture )
			uniform float _Float4;
			uniform sampler2D _TextureSample0;
			uniform float2 _Vector0;
			uniform float2 _Vector1;
			uniform float _Float3;
			uniform sampler2D _mask;
			uniform float _Float2;
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
				float2 appendResult11 = (float2(ase_grabScreenPosNorm.r , ase_grabScreenPosNorm.g));
				float4 screenColor2 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,appendResult11);
				float2 appendResult26 = (float2(_Vector0.x , _Vector0.y));
				float2 temp_output_18_0 = (appendResult11*2.0 + -1.0);
				float2 break21 = temp_output_18_0;
				float2 appendResult22 = (float2(length( temp_output_18_0 ) , atan2( break21.y , break21.x )));
				float2 appendResult41 = (float2(_Vector1.x , _Vector1.y));
				float2 panner24 = ( 1.0 * _Time.y * appendResult26 + (appendResult22*appendResult41 + 0.0));
				float smoothstepResult38 = smoothstep( (-1.0 + (_Float1 - -10.0) * (1.0 - -1.0) / (10.0 - -10.0)) , (-1.0 + (_Float0 - -10.0) * (1.0 - -1.0) / (10.0 - -10.0)) , ( ( screenColor2.r * (-1.0 + (_Float4 - -10.0) * (1.0 - -1.0) / (10.0 - -10.0)) ) * ( tex2D( _TextureSample0, panner24 ).r * ( _Float3 + pow( ( 1.0 - tex2D( _mask, appendResult11 ).r ) , _Float2 ) ) ) ));
				
				
				finalColor = ( _Color0 * ( 1.0 - smoothstepResult38 ) );
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=17500
-2048;0;1985;1131;2850.356;725.7915;1;True;True
Node;AmplifyShaderEditor.GrabScreenPosition;67;-2444.832,-356.9781;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;11;-1742.371,-308.3923;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;18;-1679.115,4.503387;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;21;-2256.096,571.0831;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ATan2OpNode;19;-1699.637,548.252;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;17;-1664.88,262.8915;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;40;-1190.316,558.8151;Inherit;False;Property;_Vector1;放射线贴图缩放;4;0;Create;False;0;0;False;0;1,6.57;0,5;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;41;-1003.316,595.8151;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;25;-1262.366,792.195;Inherit;False;Property;_Vector0;流动速度;3;0;Create;False;0;0;False;0;10,0;10,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;22;-1401.757,401.2679;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;46;-544.2806,735.1944;Inherit;True;Property;_mask;放射线遮罩;5;0;Create;False;0;0;False;0;-1;7605196420d204945843c4c794c58361;7605196420d204945843c4c794c58361;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;48;-206.0553,748.654;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;52;-224.7484,953.0853;Inherit;False;Property;_Float2;遮罩强度;6;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;26;-823.782,652.4106;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;31;-902.4946,425.2122;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;5,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PowerNode;51;-39.74841,854.0853;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;24;-640.7372,446.1804;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;65;-1432.254,-60.65411;Inherit;False;Property;_Float4;屏幕黑白强度;9;0;Create;False;0;0;False;0;1;0.99;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;56;-30.74841,591.0853;Inherit;False;Property;_Float3;遮罩开关;7;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;23;-347.8381,371.043;Inherit;True;Property;_TextureSample0;放射线贴图;2;0;Create;False;0;0;False;0;-1;1763184fee992fa478d54a0c32a8ca57;e793730e1790ae2408948cf883bcac1a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;66;-1247.843,-113.4658;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-10;False;2;FLOAT;10;False;3;FLOAT;-1;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;2;-1396.489,-347.8143;Inherit;False;Global;_GrabScreen0;Grab Screen 0;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;57;173.2516,577.0853;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-1121.254,-235.6541;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;406.46,444.282;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;7;-1327.9,189.5708;Inherit;False;Property;_Float1;黑白闪正负值;1;0;Create;False;0;0;False;0;0;0.19;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-1387.859,69.48774;Inherit;False;Property;_Float0;黑白闪范围;0;0;Create;False;0;0;False;0;0.5431729;-0.04;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;62;-951.675,214.7714;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-10;False;2;FLOAT;10;False;3;FLOAT;-1;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;61;-1061.675,-68.22864;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-10;False;2;FLOAT;10;False;3;FLOAT;-1;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;36;-869.752,-165.3047;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;38;-450.2842,-215.9974;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;37;-245.7007,-113.2445;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;59;-216.9057,-417.2393;Inherit;False;Property;_Color0;颜色;8;0;Create;False;0;0;False;0;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;63;225.0651,-275.6074;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;69;-2236.999,-546.1959;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;16;-2466.504,217.9426;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;12;-2071.441,-227.9829;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;466.9534,-201.6721;Float;False;True;-1;2;ASEMaterialInspector;100;1;screen_BW;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;0;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;2;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;11;0;67;1
WireConnection;11;1;67;2
WireConnection;18;0;11;0
WireConnection;21;0;18;0
WireConnection;19;0;21;1
WireConnection;19;1;21;0
WireConnection;17;0;18;0
WireConnection;41;0;40;1
WireConnection;41;1;40;2
WireConnection;22;0;17;0
WireConnection;22;1;19;0
WireConnection;46;1;11;0
WireConnection;48;0;46;1
WireConnection;26;0;25;1
WireConnection;26;1;25;2
WireConnection;31;0;22;0
WireConnection;31;1;41;0
WireConnection;51;0;48;0
WireConnection;51;1;52;0
WireConnection;24;0;31;0
WireConnection;24;2;26;0
WireConnection;23;1;24;0
WireConnection;66;0;65;0
WireConnection;2;0;11;0
WireConnection;57;0;56;0
WireConnection;57;1;51;0
WireConnection;64;0;2;1
WireConnection;64;1;66;0
WireConnection;47;0;23;1
WireConnection;47;1;57;0
WireConnection;62;0;7;0
WireConnection;61;0;6;0
WireConnection;36;0;64;0
WireConnection;36;1;47;0
WireConnection;38;0;36;0
WireConnection;38;1;62;0
WireConnection;38;2;61;0
WireConnection;37;0;38;0
WireConnection;63;0;59;0
WireConnection;63;1;37;0
WireConnection;1;0;63;0
ASEEND*/
//CHKSM=9FFFD50A0FAC00741C87AD4058712830053740FA
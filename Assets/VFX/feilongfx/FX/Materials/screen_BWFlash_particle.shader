// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "screen_BWFlash_particle"
{
	Properties
	{
		_TextureSample0("放射线贴图", 2D) = "white" {}
		_Vector0("流动速度", Vector) = (10,0,0,0)
		_Vector1("放射线贴图缩放", Vector) = (1,6.57,0,0)
		_mask("放射线遮罩", 2D) = "white" {}
		_Float2("遮罩强度", Float) = 1
		_Float3("遮罩开关", Float) = 1
		_TextureSample2("扭曲贴图", 2D) = "white" {}
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
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
			};

			ASE_DECLARE_SCREENSPACE_TEXTURE( _CameraOpaqueTexture )
			uniform sampler2D _TextureSample2;
			uniform float4 _TextureSample2_ST;
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
				o.ase_texcoord1 = screenPos;
				
				o.ase_texcoord = v.ase_texcoord1;
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
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
				float4 color78 = IsGammaSpace() ? float4(0,0,0,1) : float4(0,0,0,1);
				float4 color79 = IsGammaSpace() ? float4(1,1,1,1) : float4(1,1,1,1);
				float4 uv116 = i.ase_texcoord;
				uv116.xy = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float4 screenPos = i.ase_texcoord1;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float2 appendResult11 = (float2(ase_grabScreenPosNorm.r , ase_grabScreenPosNorm.g));
				float2 uv_TextureSample2 = i.ase_texcoord2.xy * _TextureSample2_ST.xy + _TextureSample2_ST.zw;
				float4 tex2DNode109 = tex2D( _TextureSample2, uv_TextureSample2 );
				float2 appendResult111 = (float2(tex2DNode109.r , tex2DNode109.g));
				float2 lerpResult107 = lerp( appendResult11 , appendResult111 , uv116.w);
				float4 screenColor2 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,lerpResult107);
				float3 temp_cast_0 = (screenColor2.r).xxx;
				float3 desaturateInitialColor80 = temp_cast_0;
				float desaturateDot80 = dot( desaturateInitialColor80, float3( 0.299, 0.587, 0.114 ));
				float3 desaturateVar80 = lerp( desaturateInitialColor80, desaturateDot80.xxx, 1.0 );
				float3 temp_output_64_0 = ( desaturateVar80 * (-1.0 + (uv116.x - -10.0) * (1.0 - -1.0) / (10.0 - -10.0)) );
				float2 appendResult26 = (float2(_Vector0.x , _Vector0.y));
				float2 temp_output_18_0 = (appendResult11*2.0 + -1.0);
				float2 break21 = temp_output_18_0;
				float2 appendResult22 = (float2(length( temp_output_18_0 ) , atan2( break21.y , break21.x )));
				float2 appendResult41 = (float2(_Vector1.x , _Vector1.y));
				float2 panner24 = ( 1.0 * _Time.y * appendResult26 + (appendResult22*appendResult41 + 0.0));
				float4 tex2DNode23 = tex2D( _TextureSample0, panner24 );
				float temp_output_57_0 = ( _Float3 + pow( tex2D( _mask, appendResult11 ).r , _Float2 ) );
				float temp_output_73_0 = ( tex2DNode23.r + temp_output_57_0 );
				float smoothstepResult38 = smoothstep( (-1.0 + (uv116.z - -10.0) * (1.0 - -1.0) / (10.0 - -10.0)) , (-1.0 + (uv116.y - -10.0) * (1.0 - -1.0) / (10.0 - -10.0)) , (( temp_output_64_0 * temp_output_73_0 )).x);
				float4 lerpResult75 = lerp( color78 , color79 , ( 1.0 - smoothstepResult38 ));
				float4 appendResult116 = (float4((lerpResult75).rgb , i.ase_color.a));
				
				
				finalColor = appendResult116;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=17500
-2041.6;23.2;1985;1100;2116.057;1637.04;1.973355;True;True
Node;AmplifyShaderEditor.GrabScreenPosition;67;-3419.145,-762.0606;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;11;-3106.078,-584.9385;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;18;-1936,336;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;21;-2036.422,680.8941;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.Vector2Node;40;-1283.916,596.5151;Inherit;False;Property;_Vector1;放射线贴图缩放;4;0;Create;False;0;0;False;0;1,6.57;0.06,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SamplerNode;109;-3209.288,-328.7228;Inherit;True;Property;_TextureSample2;扭曲贴图;11;0;Create;False;0;0;False;0;-1;None;79b2e17c439502c4d93d0c5510165838;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LengthOpNode;17;-1552.841,304.1431;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ATan2OpNode;19;-1645.725,539.8282;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;16;-2700.282,163.2043;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;22;-1277.954,314.9256;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;25;-1262.366,792.195;Inherit;False;Property;_Vector0;流动速度;3;0;Create;False;0;0;False;0;10,0;1,0.1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;111;-2816.224,-359.4727;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;41;-1003.316,595.8151;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;52;-224.7484,953.0853;Inherit;False;Property;_Float2;遮罩强度;6;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;31;-821.0928,271.5873;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;5,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;26;-823.782,652.4106;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;46;-611.0243,723.9108;Inherit;True;Property;_mask;放射线遮罩;5;0;Create;False;0;0;False;0;-1;7605196420d204945843c4c794c58361;60d224affeaecf84ead5a8b24c6c9995;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;107;-2272.59,-546.405;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;24;-599.352,386.2432;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;56;-30.74841,591.0853;Inherit;False;Property;_Float3;遮罩开关;7;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;51;-39.74841,827.4636;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;2;-1719.921,-497.3667;Inherit;False;Global;_GrabScreen0;Grab Screen 0;0;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;23;-347.8381,371.043;Inherit;True;Property;_TextureSample0;放射线贴图;2;0;Create;False;0;0;False;0;-1;1763184fee992fa478d54a0c32a8ca57;137630b98fb8ca14994287aeddeb8b75;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;57;256.0123,670.0785;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;66;-1499.018,-334.1515;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-10;False;2;FLOAT;10;False;3;FLOAT;-1;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DesaturateOpNode;80;-1541.901,-705.4384;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;73;859.3972,279.0999;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-1217.358,-455.3559;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;36;-907.6321,-539.6689;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TFHCRemapNode;61;-1102.109,-159.2054;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-10;False;2;FLOAT;10;False;3;FLOAT;-1;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;83;-706.3533,-660.5046;Inherit;False;True;False;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;62;-1020.75,93.46899;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-10;False;2;FLOAT;10;False;3;FLOAT;-1;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;38;-451.5155,-421.395;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;37;-201.8701,-416.2794;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;79;-448.1121,-843.5229;Inherit;False;Constant;_Color2;Color 2;11;0;Create;True;0;0;False;0;1,1,1,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;78;-382.7777,-1057.449;Inherit;False;Constant;_Color1;Color 1;11;0;Create;True;0;0;False;0;0,0,0,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;75;365.6972,-956.4678;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexColorNode;114;411.8103,-654.3096;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;115;745.3073,-902.9523;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;65;-2405.986,-55.33972;Inherit;False;Property;_Float4;屏幕黑白强度;8;0;Create;False;0;0;False;0;1;0.99;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;7;-2479.841,263.5187;Inherit;False;Property;_Float1;黑白闪正负值;1;0;Create;False;0;0;False;0;0;0.19;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;87;-841.0977,-382.5771;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;81;-1865.533,-727.8128;Inherit;True;Property;_TextureSample1;Texture Sample 1;10;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;70;-2496.787,386.232;Inherit;False;Property;_Float5;屏幕黑白强度/黑白范围/正负值;9;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-2480.646,112.8418;Inherit;False;Property;_Float0;黑白闪范围;0;0;Create;False;0;0;False;0;0.5431729;-0.04;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;12;-2071.441,-227.9829;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;834.2484,543.0908;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;116;824.2415,-569.4554;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1132.93,-438.8889;Float;False;True;-1;2;ASEMaterialInspector;100;1;screen_BWFlash_particle;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;2;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;11;0;67;1
WireConnection;11;1;67;2
WireConnection;18;0;11;0
WireConnection;21;0;18;0
WireConnection;17;0;18;0
WireConnection;19;0;21;1
WireConnection;19;1;21;0
WireConnection;22;0;17;0
WireConnection;22;1;19;0
WireConnection;111;0;109;1
WireConnection;111;1;109;2
WireConnection;41;0;40;1
WireConnection;41;1;40;2
WireConnection;31;0;22;0
WireConnection;31;1;41;0
WireConnection;26;0;25;1
WireConnection;26;1;25;2
WireConnection;46;1;11;0
WireConnection;107;0;11;0
WireConnection;107;1;111;0
WireConnection;107;2;16;4
WireConnection;24;0;31;0
WireConnection;24;2;26;0
WireConnection;51;0;46;1
WireConnection;51;1;52;0
WireConnection;2;0;107;0
WireConnection;23;1;24;0
WireConnection;57;0;56;0
WireConnection;57;1;51;0
WireConnection;66;0;16;1
WireConnection;80;0;2;1
WireConnection;73;0;23;1
WireConnection;73;1;57;0
WireConnection;64;0;80;0
WireConnection;64;1;66;0
WireConnection;36;0;64;0
WireConnection;36;1;73;0
WireConnection;61;0;16;2
WireConnection;83;0;36;0
WireConnection;62;0;16;3
WireConnection;38;0;83;0
WireConnection;38;1;62;0
WireConnection;38;2;61;0
WireConnection;37;0;38;0
WireConnection;75;0;78;0
WireConnection;75;1;79;0
WireConnection;75;2;37;0
WireConnection;115;0;75;0
WireConnection;87;0;64;0
WireConnection;87;1;73;0
WireConnection;81;1;67;0
WireConnection;47;0;23;1
WireConnection;47;1;57;0
WireConnection;116;0;115;0
WireConnection;116;3;114;4
WireConnection;1;0;116;0
ASEEND*/
//CHKSM=47D3FF608F16FF14355222E8F9BCD0A3E608721A
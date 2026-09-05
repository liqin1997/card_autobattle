// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_screendistorted"
{
	Properties
	{
		_mask("mask", 2D) = "white" {}
		_TextureSample0("扰动贴图", 2D) = "white" {}
		_Vector0("扭曲速度", Vector) = (0,0,0,0)
		_TextureSample1("扭曲贴图", 2D) = "white" {}
		_mask_power("遮罩强度", Float) = 0
		_Vector4("扭曲贴图缩放", Vector) = (1,1,0,0)
		_Vector3("扭曲贴图偏移", Vector) = (0,0,0,0)
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
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
			};

			ASE_DECLARE_SCREENSPACE_TEXTURE( _CameraOpaqueTexture )
			uniform sampler2D _TextureSample0;
			uniform float2 _Vector0;
			uniform float2 _Vector4;
			uniform float2 _Vector3;
			uniform sampler2D _TextureSample1;
			uniform sampler2D _mask;
			uniform float4 _mask_ST;
			uniform float _mask_power;
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
				o.ase_texcoord2 = screenPos;
				
				o.ase_color = v.color;
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_texcoord1 = v.ase_texcoord1;
				
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
				float3 appendResult105 = (float3(i.ase_color.r , i.ase_color.g , i.ase_color.b));
				float2 appendResult35 = (float2(_Vector0.x , _Vector0.y));
				float2 uv0114 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult130 = (float2(_Vector4.x , _Vector4.y));
				float2 appendResult129 = (float2(_Vector3.x , _Vector3.y));
				float2 panner31 = ( 1.0 * _Time.y * appendResult35 + (uv0114*appendResult130 + appendResult129));
				float4 uv130 = i.ase_texcoord1;
				uv130.xy = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float4 screenPos = i.ase_texcoord2;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float2 appendResult133 = (float2(uv130.x , uv130.y));
				float4 tex2DNode100 = tex2D( _TextureSample1, appendResult133 );
				float2 appendResult101 = (float2(tex2DNode100.r , tex2DNode100.g));
				float2 lerpResult99 = lerp( ( ( (-0.5 + (tex2D( _TextureSample0, panner31 ).r - 0.0) * (0.5 - -0.5) / (1.0 - 0.0)) * uv130.z ) + (ase_grabScreenPosNorm).xy ) , appendResult101 , uv130.w);
				float4 screenColor97 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,lerpResult99);
				float2 uv_mask = i.ase_texcoord.xy * _mask_ST.xy + _mask_ST.zw;
				float4 appendResult9 = (float4((( float4( appendResult105 , 0.0 ) * screenColor97 )).rgb , ( ( tex2D( _mask, uv_mask ).r * _mask_power ) * screenColor97.a * i.ase_color.a )));
				
				
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
-2041.6;102.4;1957;995;5216.6;2206.061;2.693643;True;True
Node;AmplifyShaderEditor.CommentaryNode;75;-2865.776,-1106.25;Inherit;False;1424.997;546.7424;Comment;6;35;32;37;31;36;131;扭曲;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector2Node;128;-3271.076,-952.1295;Inherit;False;Property;_Vector4;扭曲贴图缩放;5;0;Create;False;0;0;False;0;1,1;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;127;-3276.032,-677.6563;Inherit;False;Property;_Vector3;扭曲贴图偏移;6;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;130;-3019.916,-1075.821;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;129;-3028.616,-808.801;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;114;-3563.738,-1193.814;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;36;-2909.889,-784.7509;Inherit;False;Property;_Vector0;扭曲速度;2;0;Create;False;0;0;False;0;0,0;0.2,0.2;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;35;-2778.752,-925.2592;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;131;-2680.327,-1098.559;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;31;-2407.977,-1033.435;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;30;-3352.805,249.1493;Inherit;True;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;32;-2197.442,-1180.126;Inherit;True;Property;_TextureSample0;扰动贴图;1;0;Create;False;0;0;False;0;-1;None;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GrabScreenPosition;120;-2816.873,-488.5502;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;133;-2889.66,405.793;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;148;-1859.33,-1222.798;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-0.5;False;4;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;113;-2506.235,-546.1649;Inherit;True;True;True;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;37;-1883.587,-859.3592;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;100;-2112.158,449.564;Inherit;True;Property;_TextureSample1;扭曲贴图;3;0;Create;False;0;0;False;0;-1;None;0787732b67fbd0f43a9bbfaad73f5f9a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;77;-2805.042,-266.062;Inherit;False;1153.639;708.1528;Comment;1;101;自定义顶点流;1,1,1,1;0;0
Node;AmplifyShaderEditor.DynamicAppendNode;101;-2043.516,177.7394;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;39;-1885.192,-566.048;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;73;-750.2542,-20.50261;Inherit;False;679.0322;576.3525;comment;3;6;67;68;遮罩;1,1,1,1;0;0
Node;AmplifyShaderEditor.LerpOp;99;-1504.851,-496.634;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.VertexColorNode;104;-1352.672,-973.6489;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenColorNode;97;-1007.684,-427.6277;Inherit;False;Global;_GrabScreen0;Grab Screen 0;7;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;105;-1044.672,-965.6489;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;68;-421.3445,440.4497;Inherit;False;Property;_mask_power;遮罩强度;4;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;6;-700.2541,29.49736;Inherit;True;Property;_mask;mask;0;0;Create;True;0;0;False;0;-1;None;05b2a1c3e0dafdd48ad0a8453cc5de6c;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;67;-236.8218,59.40158;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;106;-965.6724,-816.6489;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;65;-138.6075,-360.4448;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;103;-806.0765,-531.6631;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;117;-1819.247,42.16671;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;9;18.37844,-779.2313;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TFHCRemapNode;118;-1731.218,222.3313;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;119;-1587.58,-143.8398;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;634.1335,-457.3372;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_screendistorted;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;False;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;130;0;128;1
WireConnection;130;1;128;2
WireConnection;129;0;127;1
WireConnection;129;1;127;2
WireConnection;35;0;36;1
WireConnection;35;1;36;2
WireConnection;131;0;114;0
WireConnection;131;1;130;0
WireConnection;131;2;129;0
WireConnection;31;0;131;0
WireConnection;31;2;35;0
WireConnection;32;1;31;0
WireConnection;133;0;30;1
WireConnection;133;1;30;2
WireConnection;148;0;32;1
WireConnection;113;0;120;0
WireConnection;37;0;148;0
WireConnection;37;1;30;3
WireConnection;100;1;133;0
WireConnection;101;0;100;1
WireConnection;101;1;100;2
WireConnection;39;0;37;0
WireConnection;39;1;113;0
WireConnection;99;0;39;0
WireConnection;99;1;101;0
WireConnection;99;2;30;4
WireConnection;97;0;99;0
WireConnection;105;0;104;1
WireConnection;105;1;104;2
WireConnection;105;2;104;3
WireConnection;67;0;6;1
WireConnection;67;1;68;0
WireConnection;106;0;105;0
WireConnection;106;1;97;0
WireConnection;65;0;67;0
WireConnection;65;1;97;4
WireConnection;65;2;104;4
WireConnection;103;0;106;0
WireConnection;117;0;99;0
WireConnection;9;0;103;0
WireConnection;9;3;65;0
WireConnection;118;0;117;1
WireConnection;119;0;117;0
WireConnection;119;1;118;0
WireConnection;1;0;9;0
ASEEND*/
//CHKSM=3F0EB76C7641FE671997A9EF5121B56636B3327E
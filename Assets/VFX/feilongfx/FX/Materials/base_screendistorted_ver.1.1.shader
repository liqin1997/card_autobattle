// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_screendistorted_ver.1.1"
{
	Properties
	{
		_mask("mask", 2D) = "white" {}
		_mask_power("遮罩强度", Float) = 0
		_Float0("遮罩启用屏幕中心UV", Float) = 0
		_Float2("启用遮罩菲涅尔", Float) = 0
		_Vector1("菲涅尔 Bias Scale Power", Vector) = (0,1,5,0)
		_TextureSample1("扭曲贴图", 2D) = "white" {}
		_Vector6("扭曲贴图缩放", Vector) = (1,1,0,0)
		_Vector5("扭曲贴图偏移", Vector) = (0,0,0,0)
		_Vector2("扭曲贴图速度", Vector) = (0,0,0,0)
		_TextureSample0("扰动贴图", 2D) = "white" {}
		_Vector0("扰动速度", Vector) = (0,0,0,0)
		_Vector4("扰动贴图缩放", Vector) = (1,1,0,0)
		_Vector3("扰动贴图偏移", Vector) = (0,0,0,0)
		_TextureSample2("扰动遮罩", 2D) = "white" {}
		_Float4("不透明度", Float) = 1
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
				float3 ase_normal : NORMAL;
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
				float4 ase_texcoord4 : TEXCOORD4;
			};

			ASE_DECLARE_SCREENSPACE_TEXTURE( _CameraOpaqueTexture )
			uniform sampler2D _TextureSample0;
			uniform float2 _Vector0;
			uniform float2 _Vector4;
			uniform float2 _Vector3;
			uniform sampler2D _TextureSample2;
			uniform float4 _TextureSample2_ST;
			uniform sampler2D _TextureSample1;
			uniform float2 _Vector2;
			uniform float _Float0;
			uniform float2 _Vector6;
			uniform float2 _Vector5;
			uniform sampler2D _mask;
			uniform float _mask_power;
			uniform float3 _Vector1;
			uniform float _Float2;
			uniform float _Float4;
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
				float3 ase_worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.ase_texcoord3.xyz = ase_worldPos;
				float3 ase_worldNormal = UnityObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord4.xyz = ase_worldNormal;
				
				o.ase_color = v.color;
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_texcoord2 = v.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				o.ase_texcoord3.w = 0;
				o.ase_texcoord4.w = 0;
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
				float4 screenPos = i.ase_texcoord;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float2 temp_output_154_0 = ( ( (ase_grabScreenPosNorm).xy + 0.0 ) * 1.0 );
				float2 appendResult130 = (float2(_Vector4.x , _Vector4.y));
				float2 appendResult129 = (float2(_Vector3.x , _Vector3.y));
				float2 panner31 = ( 1.0 * _Time.y * appendResult35 + (temp_output_154_0*appendResult130 + appendResult129));
				float2 uv_TextureSample2 = i.ase_texcoord1.xy * _TextureSample2_ST.xy + _TextureSample2_ST.zw;
				float4 uv130 = i.ase_texcoord2;
				uv130.xy = i.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_37_0 = ( tex2D( _TextureSample0, panner31 ).r * tex2D( _TextureSample2, uv_TextureSample2 ).r * uv130.z );
				float2 appendResult171 = (float2(_Vector2.x , _Vector2.y));
				float2 uv0152 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 lerpResult156 = lerp( uv0152 , temp_output_154_0 , _Float0);
				float2 appendResult176 = (float2(_Vector6.x , _Vector6.y));
				float2 appendResult173 = (float2(_Vector5.x , _Vector5.y));
				float2 panner170 = ( 1.0 * _Time.y * appendResult171 + (lerpResult156*appendResult176 + appendResult173));
				float4 tex2DNode100 = tex2D( _TextureSample1, panner170 );
				float2 appendResult101 = (float2(tex2DNode100.r , tex2DNode100.g));
				float2 lerpResult149 = lerp( ( temp_output_37_0 + temp_output_154_0 ) , appendResult101 , uv130.y);
				float4 screenColor97 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_CameraOpaqueTexture,lerpResult149);
				float3 appendResult167 = (float3(screenColor97.r , screenColor97.g , screenColor97.b));
				float3 ase_worldPos = i.ase_texcoord3.xyz;
				float3 ase_worldViewDir = UnityWorldSpaceViewDir(ase_worldPos);
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 ase_worldNormal = i.ase_texcoord4.xyz;
				float fresnelNdotV158 = dot( ase_worldNormal, ase_worldViewDir );
				float fresnelNode158 = ( _Vector1.x + _Vector1.y * pow( 1.0 - fresnelNdotV158, _Vector1.z ) );
				float lerpResult164 = lerp( 1.0 , ( 1.0 - fresnelNode158 ) , _Float2);
				float4 appendResult9 = (float4((( appendResult105 * appendResult167 )).xyz , ( ( ( tex2D( _mask, lerpResult156 ).r * _mask_power * lerpResult164 ) * i.ase_color.a ) * _Float4 )));
				
				
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
-2022.4;108.8;1957;1094;3903.172;1189.791;2.083457;True;True
Node;AmplifyShaderEditor.GrabScreenPosition;120;-3955.03,-392.2839;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;75;-2865.776,-1106.25;Inherit;False;1424.997;546.7424;Comment;6;35;37;31;36;153;151;扭曲;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector2Node;127;-3275.032,-677.6563;Inherit;False;Property;_Vector3;扰动贴图偏移;12;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;128;-3271.076,-952.1295;Inherit;False;Property;_Vector4;扰动贴图缩放;11;0;Create;False;0;0;False;0;1,1;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ComponentMaskNode;113;-3640.384,-344.2404;Inherit;True;True;True;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;174;-2854.862,1133.784;Inherit;False;Property;_Vector5;扭曲贴图偏移;7;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;157;-1584.045,298.8263;Inherit;False;Property;_Float0;遮罩启用屏幕中心UV;2;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;154;-3559.716,-829.0022;Inherit;False;ConstantBiasScale;-1;;1;63208df05c83e8e49a48ffbdce2e43a0;0;3;3;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;129;-3028.616,-808.801;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;36;-2855.34,-728.7664;Inherit;False;Property;_Vector0;扰动速度;10;0;Create;False;0;0;False;0;0,0;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;130;-3019.916,-1075.821;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;175;-2850.906,859.3113;Inherit;False;Property;_Vector6;扭曲贴图缩放;6;0;Create;False;0;0;False;0;1,1;2,2;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;152;-3392.068,17.77921;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;156;-1367.847,-77.45429;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;173;-2608.446,1002.64;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;35;-2738.558,-900.8557;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;176;-2599.746,735.6196;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;131;-2639.344,-1393.024;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;172;-2435.17,1082.674;Inherit;False;Property;_Vector2;扭曲贴图速度;8;0;Create;False;0;0;False;0;0,0;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.PannerNode;31;-2407.977,-1033.435;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;171;-2318.388,910.585;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;177;-2219.174,418.4168;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;153;-2580.666,-813.4232;Inherit;True;Property;_TextureSample2;扰动遮罩;13;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;170;-1987.806,778.0056;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;32;-2228.1,-1313.58;Inherit;True;Property;_TextureSample0;扰动贴图;9;0;Create;False;0;0;False;0;-1;None;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;30;-3390.66,-270.0049;Inherit;True;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldNormalVector;160;-1098.506,541.8643;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;100;-1947.538,390.7588;Inherit;True;Property;_TextureSample1;扭曲贴图;5;0;Create;False;0;0;False;0;-1;None;fd159ed7d9bfc8649ac65105cb972b88;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;77;-2805.042,-266.062;Inherit;False;1153.639;708.1528;Comment;1;101;自定义顶点流;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector3Node;163;-990.8589,824.8494;Inherit;False;Property;_Vector1;菲涅尔 Bias Scale Power;4;0;Create;False;0;0;False;0;0,1,5;0,2,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;159;-1085.101,718.5757;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;37;-2034.77,-958.8748;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;101;-1876.179,98.18304;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FresnelNode;158;-637.7885,634.1862;Inherit;True;Standard;WorldNormal;ViewDir;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;151;-1707.525,-644.2817;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;73;-750.2542,-20.50261;Inherit;False;679.0322;576.3525;comment;4;6;67;68;165;遮罩;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;166;-249.2123,720.5979;Inherit;False;Property;_Float2;启用遮罩菲涅尔;3;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;165;-339.3983,479.0875;Inherit;False;Constant;_Float1;Float 1;10;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;168;-424.1794,956.3902;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;149;-1581.557,-369.5098;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;6;-700.2541,29.49736;Inherit;True;Property;_mask;mask;0;0;Create;True;0;0;False;0;-1;None;a9246aca51a3c5e46aac806c16a872a9;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;104;-1352.672,-973.6489;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenColorNode;97;-1238.873,-677.9964;Inherit;False;Global;_GrabScreen0;Grab Screen 0;7;0;Create;True;0;0;False;0;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;164;-76.59827,505.2875;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;68;-516.4031,367.3278;Inherit;False;Property;_mask_power;遮罩强度;1;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;67;-371.7966,5.86018;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;105;-1044.672,-965.6489;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;167;-998.9157,-715.165;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;106;-776.2959,-837.6908;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;65;-163.5251,-603.668;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;180;-131.8776,-297.7498;Inherit;False;Property;_Float4;不透明度;14;0;Create;False;0;0;False;0;1;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;182;140.1193,-553.823;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;103;-603.8507,-767.5247;Inherit;False;True;True;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;155;-2016.424,-530.7454;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;9;242.9154,-880.7951;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;634.1335,-457.3372;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_screendistorted_ver.1.1;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;151;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;False;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;113;0;120;0
WireConnection;154;3;113;0
WireConnection;129;0;127;1
WireConnection;129;1;127;2
WireConnection;130;0;128;1
WireConnection;130;1;128;2
WireConnection;156;0;152;0
WireConnection;156;1;154;0
WireConnection;156;2;157;0
WireConnection;173;0;174;1
WireConnection;173;1;174;2
WireConnection;35;0;36;1
WireConnection;35;1;36;2
WireConnection;176;0;175;1
WireConnection;176;1;175;2
WireConnection;131;0;154;0
WireConnection;131;1;130;0
WireConnection;131;2;129;0
WireConnection;31;0;131;0
WireConnection;31;2;35;0
WireConnection;171;0;172;1
WireConnection;171;1;172;2
WireConnection;177;0;156;0
WireConnection;177;1;176;0
WireConnection;177;2;173;0
WireConnection;170;0;177;0
WireConnection;170;2;171;0
WireConnection;32;1;31;0
WireConnection;100;1;170;0
WireConnection;37;0;32;1
WireConnection;37;1;153;1
WireConnection;37;2;30;3
WireConnection;101;0;100;1
WireConnection;101;1;100;2
WireConnection;158;0;160;0
WireConnection;158;4;159;0
WireConnection;158;1;163;1
WireConnection;158;2;163;2
WireConnection;158;3;163;3
WireConnection;151;0;37;0
WireConnection;151;1;154;0
WireConnection;168;0;158;0
WireConnection;149;0;151;0
WireConnection;149;1;101;0
WireConnection;149;2;30;2
WireConnection;6;1;156;0
WireConnection;97;0;149;0
WireConnection;164;0;165;0
WireConnection;164;1;168;0
WireConnection;164;2;166;0
WireConnection;67;0;6;1
WireConnection;67;1;68;0
WireConnection;67;2;164;0
WireConnection;105;0;104;1
WireConnection;105;1;104;2
WireConnection;105;2;104;3
WireConnection;167;0;97;1
WireConnection;167;1;97;2
WireConnection;167;2;97;3
WireConnection;106;0;105;0
WireConnection;106;1;167;0
WireConnection;65;0;67;0
WireConnection;65;1;104;4
WireConnection;182;0;65;0
WireConnection;182;1;180;0
WireConnection;103;0;106;0
WireConnection;155;0;154;0
WireConnection;155;1;37;0
WireConnection;155;2;30;3
WireConnection;9;0;103;0
WireConnection;9;3;182;0
WireConnection;1;0;9;0
ASEEND*/
//CHKSM=575DF813A85523FB54D3A172DC3B6D60EB810CBC
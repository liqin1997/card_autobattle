// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_uv_distortion_traiAB"
{
	Properties
	{
		_TextureSample0("主纹理", 2D) = "white" {}
		_Vector2("主纹理缩放", Vector) = (1,1,0,0)
		_Vector3("主纹理速度", Vector) = (0,0,0,0)
		_TextureSample1("扭曲贴图", 2D) = "white" {}
		_TextureSample2("溶解贴图", 2D) = "white" {}
		_Float2("溶解贴图强度", Float) = 1
		_smooth_step("smooth_step", Float) = 0
		_Float3("step on", Float) = 0
		_Vector4("溶解贴图速度", Vector) = (0,0,0,0)
		_Vector5("溶解贴图缩放", Vector) = (1,1,0,0)
		_TextureSample3("遮罩", 2D) = "white" {}
		_Float0("遮罩强度", Float) = 0
		_Color0("主颜色", Color) = (0,0,0,0)
		_TextureSample4("扰动贴图", 2D) = "white" {}
		_Float1("扰动强度", Float) = 0
		_Vector0("扰动速度", Vector) = (0,0,0,0)
		_Vector1("扰动贴图缩放", Vector) = (0,0,0,0)
		float02("扭曲/溶解", Vector) = (0,0,0,0)
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
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
			};

			uniform float4 _Color0;
			uniform sampler2D _TextureSample0;
			uniform sampler2D _TextureSample4;
			uniform float4 _Vector0;
			uniform float4 _Vector1;
			uniform float _Float1;
			uniform float4 _Vector3;
			uniform float4 _Vector2;
			uniform sampler2D _TextureSample1;
			uniform float4 _TextureSample1_ST;
			uniform float2 float02;
			uniform float _smooth_step;
			uniform sampler2D _TextureSample2;
			uniform float4 _Vector4;
			uniform float4 _Vector5;
			uniform float _Float2;
			uniform float _Float3;
			uniform sampler2D _TextureSample3;
			uniform float _Float0;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_color = v.color;
				
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
				float3 appendResult35 = (float3(_Color0.r , _Color0.g , _Color0.b));
				float2 appendResult51 = (float2(_Vector0.x , _Vector0.y));
				float2 uv03 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult54 = (float2(_Vector1.x , _Vector1.y));
				float2 panner45 = ( 1.0 * _Time.y * appendResult51 + (uv03*appendResult54 + 0.0));
				float2 appendResult66 = (float2(_Vector3.x , _Vector3.y));
				float2 appendResult62 = (float2(_Vector2.x , _Vector2.y));
				float2 panner64 = ( 1.0 * _Time.y * appendResult66 + (uv03*appendResult62 + 0.0));
				float2 uv_TextureSample1 = i.ase_texcoord.xy * _TextureSample1_ST.xy + _TextureSample1_ST.zw;
				float4 tex2DNode6 = tex2D( _TextureSample1, uv_TextureSample1 );
				float2 appendResult7 = (float2(tex2DNode6.r , tex2DNode6.g));
				float2 lerpResult5 = lerp( panner64 , appendResult7 , float02.x);
				float4 tex2DNode2 = tex2D( _TextureSample0, ( ( tex2D( _TextureSample4, panner45 ).r * _Float1 ) + lerpResult5 ) );
				float3 appendResult25 = (float3(tex2DNode2.r , tex2DNode2.g , tex2DNode2.b));
				float3 appendResult41 = (float3(i.ase_color.r , i.ase_color.g , i.ase_color.b));
				float temp_output_33_0 = (0.0 + (float02.y - 0.0) * (1.0 - 0.0) / (2.0 - 0.0));
				float2 appendResult70 = (float2(_Vector4.x , _Vector4.y));
				float2 appendResult67 = (float2(_Vector5.x , _Vector5.y));
				float2 panner69 = ( 1.0 * _Time.y * appendResult70 + (lerpResult5*appendResult67 + 0.0));
				float temp_output_80_0 = pow( tex2D( _TextureSample2, panner69 ).r , _Float2 );
				float smoothstepResult29 = smoothstep( _smooth_step , temp_output_33_0 , temp_output_80_0);
				float lerpResult84 = lerp( smoothstepResult29 , step( temp_output_33_0 , temp_output_80_0 ) , _Float3);
				float2 uv055 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float4 appendResult13 = (float4((( appendResult35 * appendResult25 * appendResult41 )).xyz , ( ( _Color0.a * ( tex2DNode2.a * lerpResult84 ) * i.ase_color.a ) * saturate( pow( tex2D( _TextureSample3, uv055 ).r , _Float0 ) ) )));
				
				
				finalColor = appendResult13;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	Fallback "0"
}
/*ASEBEGIN
Version=17500
-2013.6;304;1957;1131;3263.092;1356.95;2.58261;True;True
Node;AmplifyShaderEditor.Vector4Node;63;-3322.222,-171.2015;Inherit;False;Property;_Vector2;主纹理缩放;1;0;Create;False;0;0;False;0;1,1,0,0;0.1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;62;-3052.267,-276.3712;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;3;-3451.679,-381.7503;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;65;-2814.672,-228.3939;Inherit;False;Property;_Vector3;主纹理速度;2;0;Create;False;0;0;False;0;0,0,0,0;5,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;61;-2816.885,-403.5969;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;66;-2597.952,-214.0902;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;6;-2434.127,-122.4142;Inherit;True;Property;_TextureSample1;扭曲贴图;3;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;52;-2566.251,-826.481;Inherit;False;Property;_Vector1;扰动贴图缩放;16;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;7;-2079.804,-59.40182;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;64;-2486.005,-449.5232;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;72;-1921.449,2.018446;Inherit;False;Property;_Vector5;溶解贴图缩放;9;0;Create;False;0;0;False;0;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;82;-2641.54,12.8865;Inherit;False;Property;float02;扭曲/溶解;17;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;54;-2368,-816;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;67;-1759.395,-131.7512;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;71;-1456.8,-49.97393;Inherit;False;Property;_Vector4;溶解贴图速度;8;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;50;-2032.362,-685.6816;Inherit;False;Property;_Vector0;扰动速度;15;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;5;-1955.219,-439.386;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;51;-1886.188,-669.0648;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;70;-1284.279,-66.87024;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;68;-1488.913,-255.077;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;44;-2032,-912;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;45;-1774.241,-904.4977;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;69;-1163.232,-251.6033;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;10;-905.4048,-424.3296;Inherit;True;Property;_TextureSample2;溶解贴图;4;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;47;-1581.241,-945.4977;Inherit;True;Property;_TextureSample4;扰动贴图;13;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;75;-969.5681,-88.52612;Inherit;False;Property;_Float2;溶解贴图强度;5;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-1521.723,-626.2183;Inherit;False;Property;_Float1;扰动强度;14;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;-1348.323,-698.2183;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;33;-1000.324,89.48222;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;2;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;80;-768.3857,-174.5552;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;76;-647.726,60.26944;Inherit;False;Property;_smooth_step;smooth_step;6;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;85;-740.2279,301.3541;Inherit;False;Property;_Float3;step on;7;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;83;-485.1346,232.7699;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;55;-973.4907,948.4377;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;29;-493.6068,-159.0667;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;46;-1142.415,-514.9407;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;84;-280.2279,20.35413;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;27;-441.7237,806.2068;Inherit;True;Property;_TextureSample3;遮罩;10;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;43;-110.1139,890.0868;Inherit;False;Property;_Float0;遮罩强度;11;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;34;-1056.621,-1208.267;Inherit;False;Property;_Color0;主颜色;12;0;Create;False;0;0;False;0;0,0,0,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;2;-1007.625,-785.6756;Inherit;True;Property;_TextureSample0;主纹理;0;0;Create;False;0;0;False;0;-1;None;6b05c93c3ee83754dae468830b3550f0;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;39;-916.2667,-1425.065;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;41;-587.9363,-1371.179;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PowerNode;58;30.69934,714.2786;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;35;-728.291,-1158.14;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;25;-636.1005,-813.2957;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;-355.5408,-395.83;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;60;454.3283,580.6997;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;-368.632,-997.7346;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;-37.04632,-401.4506;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;59;254.1886,-160.4271;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;12;-212.3898,-688.4211;Inherit;False;True;True;True;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;81;-1446.386,-475.0552;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;4;-2682.046,192.0057;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;13;298.1675,-658.352;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;621.333,-272.5865;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_uv_distortion_traiAB;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;0;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;62;0;63;1
WireConnection;62;1;63;2
WireConnection;61;0;3;0
WireConnection;61;1;62;0
WireConnection;66;0;65;1
WireConnection;66;1;65;2
WireConnection;7;0;6;1
WireConnection;7;1;6;2
WireConnection;64;0;61;0
WireConnection;64;2;66;0
WireConnection;54;0;52;1
WireConnection;54;1;52;2
WireConnection;67;0;72;1
WireConnection;67;1;72;2
WireConnection;5;0;64;0
WireConnection;5;1;7;0
WireConnection;5;2;82;1
WireConnection;51;0;50;1
WireConnection;51;1;50;2
WireConnection;70;0;71;1
WireConnection;70;1;71;2
WireConnection;68;0;5;0
WireConnection;68;1;67;0
WireConnection;44;0;3;0
WireConnection;44;1;54;0
WireConnection;45;0;44;0
WireConnection;45;2;51;0
WireConnection;69;0;68;0
WireConnection;69;2;70;0
WireConnection;10;1;69;0
WireConnection;47;1;45;0
WireConnection;49;0;47;1
WireConnection;49;1;48;0
WireConnection;33;0;82;2
WireConnection;80;0;10;1
WireConnection;80;1;75;0
WireConnection;83;0;33;0
WireConnection;83;1;80;0
WireConnection;29;0;80;0
WireConnection;29;1;76;0
WireConnection;29;2;33;0
WireConnection;46;0;49;0
WireConnection;46;1;5;0
WireConnection;84;0;29;0
WireConnection;84;1;83;0
WireConnection;84;2;85;0
WireConnection;27;1;55;0
WireConnection;2;1;46;0
WireConnection;41;0;39;1
WireConnection;41;1;39;2
WireConnection;41;2;39;3
WireConnection;58;0;27;1
WireConnection;58;1;43;0
WireConnection;35;0;34;1
WireConnection;35;1;34;2
WireConnection;35;2;34;3
WireConnection;25;0;2;1
WireConnection;25;1;2;2
WireConnection;25;2;2;3
WireConnection;26;0;2;4
WireConnection;26;1;84;0
WireConnection;60;0;58;0
WireConnection;40;0;35;0
WireConnection;40;1;25;0
WireConnection;40;2;41;0
WireConnection;28;0;34;4
WireConnection;28;1;26;0
WireConnection;28;2;39;4
WireConnection;59;0;28;0
WireConnection;59;1;60;0
WireConnection;12;0;40;0
WireConnection;13;0;12;0
WireConnection;13;3;59;0
WireConnection;1;0;13;0
ASEEND*/
//CHKSM=CEF856CE648168E70852F6F09BD0FD6E2F88D33A
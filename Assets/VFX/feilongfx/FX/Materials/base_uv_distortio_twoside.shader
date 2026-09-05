// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_uv_distortio_twoside"
{
	Properties
	{
		_TextureSample0("主纹理", 2D) = "white" {}
		_Vector2("主纹理缩放", Vector) = (1,1,0,0)
		_Vector3("主纹理速度", Vector) = (0,0,0,0)
		_TextureSample1("扭曲贴图", 2D) = "white" {}
		_TextureSample2("溶解贴图", 2D) = "white" {}
		_Float2("溶解贴图强度", Float) = 1
		_Float3("smoothstep/step", Float) = 1
		_smooth_step("smooth_step", Float) = 0
		_Vector4("溶解贴图速度", Vector) = (0,0,0,0)
		_Vector5("溶解贴图缩放", Vector) = (1,1,0,0)
		_TextureSample3("遮罩", 2D) = "white" {}
		_Float0("遮罩强度", Float) = 0
		_Color0("主颜色", Color) = (0,0,0,0)
		_TextureSample4("扰动贴图", 2D) = "white" {}
		_Float1("扰动强度", Float) = 0
		_Vector0("扰动速度", Vector) = (0,0,0,0)
		_Vector1("扰动贴图缩放", Vector) = (0,0,0,0)
		vertex01("启用溶解贴图单独流动", Float) = 1
		vertex2("启用扰动影响溶解贴图", Float) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

	}
	
	SubShader
	{
		
		
		Tags
		{
			"RenderType"="Transparent"
			"Queue"="Transparent"
			"RenderPipeline"="UniversalPipeline"
		}
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
			uniform sampler2D _TextureSample2;
			uniform float4 _Vector4;
			uniform float vertex01;
			uniform float4 _Vector5;
			uniform float vertex2;
			uniform float _Float2;
			uniform float _smooth_step;
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
				o.ase_texcoord1 = v.ase_texcoord1;
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
				float temp_output_49_0 = ( tex2D( _TextureSample4, panner45 ).r * _Float1 );
				float2 appendResult66 = (float2(_Vector3.x , _Vector3.y));
				float2 appendResult62 = (float2(_Vector2.x , _Vector2.y));
				float2 panner64 = ( 1.0 * _Time.y * appendResult66 + (uv03*appendResult62 + 0.0));
				float2 uv_TextureSample1 = i.ase_texcoord.xy * _TextureSample1_ST.xy + _TextureSample1_ST.zw;
				float4 tex2DNode6 = tex2D( _TextureSample1, uv_TextureSample1 );
				float2 appendResult7 = (float2(tex2DNode6.r , tex2DNode6.g));
				float4 uv14 = i.ase_texcoord1;
				uv14.xy = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 lerpResult5 = lerp( panner64 , appendResult7 , uv14.x);
				float4 tex2DNode2 = tex2D( _TextureSample0, ( temp_output_49_0 + lerpResult5 ) );
				float3 appendResult25 = (float3(tex2DNode2.r , tex2DNode2.g , tex2DNode2.b));
				float3 appendResult41 = (float3(i.ase_color.r , i.ase_color.g , i.ase_color.b));
				float temp_output_33_0 = (0.0 + (uv14.y - 0.0) * (1.0 - 0.0) / (2.0 - 0.0));
				float2 appendResult70 = (float2(_Vector4.x , _Vector4.y));
				float2 lerpResult84 = lerp( uv03 , lerpResult5 , vertex01);
				float2 appendResult67 = (float2(_Vector5.x , _Vector5.y));
				float2 panner69 = ( 1.0 * _Time.y * appendResult70 + (lerpResult84*appendResult67 + 0.0));
				float2 lerpResult86 = lerp( ( temp_output_49_0 + panner69 ) , panner69 , vertex2);
				float temp_output_80_0 = pow( tex2D( _TextureSample2, lerpResult86 ).r , _Float2 );
				float smoothstepResult29 = smoothstep( _smooth_step , temp_output_33_0 , temp_output_80_0);
				float lerpResult82 = lerp( step( temp_output_33_0 , temp_output_80_0 ) , smoothstepResult29 , _Float3);
				float2 uv055 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float4 appendResult13 = (float4((( appendResult35 * appendResult25 * appendResult41 )).xyz , ( ( _Color0.a * ( tex2DNode2.a * lerpResult82 ) * i.ase_color.a ) * saturate( pow( tex2D( _TextureSample3, uv055 ).r , _Float0 ) ) )));
				
				
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
-2041.6;0.8;1985;1122;4122.907;1204.593;1.7813;True;True
Node;AmplifyShaderEditor.Vector4Node;63;-3322.222,-171.2015;Inherit;False;Property;_Vector2;主纹理缩放;1;0;Create;False;0;0;False;0;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;62;-3052.267,-276.3712;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;3;-3451.679,-381.7503;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;65;-2814.672,-228.3939;Inherit;False;Property;_Vector3;主纹理速度;2;0;Create;False;0;0;False;0;0,0,0,0;1,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;6;-2431.179,-129.9504;Inherit;True;Property;_TextureSample1;扭曲贴图;3;0;Create;False;0;0;False;0;-1;None;1ee2155ebc7acdd469a932f74ee1b951;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;61;-2816.885,-403.5969;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;66;-2597.952,-214.0902;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;52;-2566.251,-826.481;Inherit;False;Property;_Vector1;扰动贴图缩放;16;0;Create;False;0;0;False;0;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;64;-2486.005,-449.5232;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;7;-2123.215,-142.5051;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;54;-2368,-816;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;4;-2787.193,187.7125;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;50;-2032.362,-685.6816;Inherit;False;Property;_Vector0;扰动速度;15;0;Create;False;0;0;False;0;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;72;-2514.947,421.5713;Inherit;False;Property;_Vector5;溶解贴图缩放;9;0;Create;False;0;0;False;0;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;5;-2105.188,-470.6293;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;85;-2114.193,7.394458;Inherit;False;Property;vertex01;启用溶解贴图单独流动;17;0;Create;False;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;51;-1886.188,-669.0648;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;44;-2032,-912;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;45;-1774.241,-904.4977;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;84;-1727.101,-350.954;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;67;-2063.2,131.7878;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;71;-2124.325,440.7203;Inherit;False;Property;_Vector4;溶解贴图速度;8;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;70;-1825.735,299.8792;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-1521.723,-626.2183;Inherit;False;Property;_Float1;扰动强度;14;0;Create;False;0;0;False;0;0;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;47;-1581.241,-945.4977;Inherit;True;Property;_TextureSample4;扰动贴图;13;0;Create;False;0;0;False;0;-1;None;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;68;-1681.958,-132.0465;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;-1348.323,-698.2183;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;69;-1635.461,44.36013;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;88;-1375.587,166.5311;Inherit;False;Property;vertex2;启用扰动影响溶解贴图;18;0;Create;False;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;87;-1343.871,-294.1532;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;86;-1092.118,-154.3946;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;10;-905.4048,-424.3296;Inherit;True;Property;_TextureSample2;溶解贴图;4;0;Create;False;0;0;False;0;-1;None;c96440ba11315e14581a6d0536bd31e0;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;75;-345.7018,79.26993;Inherit;False;Property;_Float2;溶解贴图强度;5;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;33;-1048.935,245.8338;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;2;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;80;-491.1091,-78.13374;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;76;124.1403,323.0656;Inherit;False;Property;_smooth_step;smooth_step;7;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;83;236.8955,179.5546;Inherit;False;Property;_Float3;smoothstep/step;6;0;Create;False;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;46;-1180.107,-541.465;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;55;-683.8347,534.0281;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;29;47.25946,109.7294;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;81;-257.6943,-124.82;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;82;316.8955,-3.445403;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;43;179.5419,475.6772;Inherit;False;Property;_Float0;遮罩强度;11;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;27;-152.068,391.7973;Inherit;True;Property;_TextureSample3;遮罩;10;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;2;-1007.625,-785.6756;Inherit;True;Property;_TextureSample0;主纹理;0;0;Create;False;0;0;False;0;-1;None;c73c5ae93a486b04782680a4a61c33ba;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;39;-916.2667,-1425.065;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;34;-1056.621,-1208.267;Inherit;False;Property;_Color0;主颜色;12;0;Create;False;0;0;False;0;0,0,0,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;58;320.3551,299.869;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;25;-636.1005,-813.2957;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;-259.5408,-396.83;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;35;-728.291,-1158.14;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;41;-587.9363,-1371.179;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;60;659.1281,295.931;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;-37.04632,-401.4506;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;-368.632,-997.7346;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;12;-212.3898,-688.4211;Inherit;False;True;True;True;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;59;574.7784,-105.0525;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;13;298.1675,-658.352;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;621.333,-272.5865;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_uv_distortio_twoside;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;2;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;0;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;62;0;63;1
WireConnection;62;1;63;2
WireConnection;61;0;3;0
WireConnection;61;1;62;0
WireConnection;66;0;65;1
WireConnection;66;1;65;2
WireConnection;64;0;61;0
WireConnection;64;2;66;0
WireConnection;7;0;6;1
WireConnection;7;1;6;2
WireConnection;54;0;52;1
WireConnection;54;1;52;2
WireConnection;5;0;64;0
WireConnection;5;1;7;0
WireConnection;5;2;4;1
WireConnection;51;0;50;1
WireConnection;51;1;50;2
WireConnection;44;0;3;0
WireConnection;44;1;54;0
WireConnection;45;0;44;0
WireConnection;45;2;51;0
WireConnection;84;0;3;0
WireConnection;84;1;5;0
WireConnection;84;2;85;0
WireConnection;67;0;72;1
WireConnection;67;1;72;2
WireConnection;70;0;71;1
WireConnection;70;1;71;2
WireConnection;47;1;45;0
WireConnection;68;0;84;0
WireConnection;68;1;67;0
WireConnection;49;0;47;1
WireConnection;49;1;48;0
WireConnection;69;0;68;0
WireConnection;69;2;70;0
WireConnection;87;0;49;0
WireConnection;87;1;69;0
WireConnection;86;0;87;0
WireConnection;86;1;69;0
WireConnection;86;2;88;0
WireConnection;10;1;86;0
WireConnection;33;0;4;2
WireConnection;80;0;10;1
WireConnection;80;1;75;0
WireConnection;46;0;49;0
WireConnection;46;1;5;0
WireConnection;29;0;80;0
WireConnection;29;1;76;0
WireConnection;29;2;33;0
WireConnection;81;0;33;0
WireConnection;81;1;80;0
WireConnection;82;0;81;0
WireConnection;82;1;29;0
WireConnection;82;2;83;0
WireConnection;27;1;55;0
WireConnection;2;1;46;0
WireConnection;58;0;27;1
WireConnection;58;1;43;0
WireConnection;25;0;2;1
WireConnection;25;1;2;2
WireConnection;25;2;2;3
WireConnection;26;0;2;4
WireConnection;26;1;82;0
WireConnection;35;0;34;1
WireConnection;35;1;34;2
WireConnection;35;2;34;3
WireConnection;41;0;39;1
WireConnection;41;1;39;2
WireConnection;41;2;39;3
WireConnection;60;0;58;0
WireConnection;28;0;34;4
WireConnection;28;1;26;0
WireConnection;28;2;39;4
WireConnection;40;0;35;0
WireConnection;40;1;25;0
WireConnection;40;2;41;0
WireConnection;12;0;40;0
WireConnection;59;0;28;0
WireConnection;59;1;60;0
WireConnection;13;0;12;0
WireConnection;13;3;59;0
WireConnection;1;0;13;0
ASEEND*/
//CHKSM=70721686BB162F3096D57726A2CBEC32D43BD042

// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_uv_distortion_vertex_z_off"
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
		_TextureSample5("顶点偏移贴图", 2D) = "white" {}
		_Vector7("置换贴图缩放", Vector) = (1,1,0,0)
		vertexmap("置换贴图速度", Vector) = (0,0,0,0)
		_Vector6("xyz偏移强度", Vector) = (0,0,0,0)
		_Float4("整体偏移强度", Float) = 0
		_Float5("各方向偏移", Float) = 0
		_Color2("分层色彩外", Color) = (1,0,0,0)
		_Color1("分层色彩中", Color) = (1,0.8772963,0,0)
		_Color3("分层色彩内", Color) = (0.3268521,1,0,0)
		_Float9("启用分层色彩", Float) = 0
		_Vector8("分层色彩间距", Vector) = (0,0,0,0)
		_Vector9("扭曲/溶解", Vector) = (0,0,0,0)
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
				float3 ase_normal : NORMAL;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
			};

			uniform float3 _Vector6;
			uniform sampler2D _TextureSample5;
			uniform float4 vertexmap;
			uniform float4 _Vector7;
			uniform float _Float4;
			uniform float _Float5;
			uniform float4 _Color0;
			uniform float4 _Color2;
			uniform float4 _Color1;
			uniform sampler2D _TextureSample0;
			uniform sampler2D _TextureSample4;
			uniform float4 _Vector0;
			uniform float4 _Vector1;
			uniform float _Float1;
			uniform float4 _Vector3;
			uniform float4 _Vector2;
			uniform sampler2D _TextureSample1;
			uniform float4 _TextureSample1_ST;
			uniform float2 _Vector9;
			uniform float4 _Color3;
			uniform float2 _Vector8;
			uniform float _Float9;
			uniform sampler2D _TextureSample2;
			uniform float4 _Vector4;
			uniform float4 _Vector5;
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

				float2 appendResult94 = (float2(vertexmap.x , vertexmap.y));
				float2 uv091 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult90 = (float2(_Vector7.x , _Vector7.y));
				float2 panner95 = ( 1.0 * _Time.y * appendResult94 + (uv091*appendResult90 + 0.0));
				float4 tex2DNode87 = tex2Dlod( _TextureSample5, float4( panner95, 0, 0.0) );
				float3 normalizeResult181 = normalize( v.ase_normal );
				float3 lerpResult153 = lerp( ( _Vector6 * tex2DNode87.r ) , ( ( ( 1.0 - tex2DNode87.r ) * _Float4 ) * normalizeResult181 ) , _Float5);
				
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_color = v.color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = lerpResult153;
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
				float2 lerpResult5 = lerp( panner64 , appendResult7 , _Vector9.x);
				float4 tex2DNode2 = tex2D( _TextureSample0, ( ( tex2D( _TextureSample4, panner45 ).r * _Float1 ) + lerpResult5 ) );
				float smoothstepResult161 = smoothstep( 0.0 , 1.0 , tex2DNode2.r);
				float4 lerpResult167 = lerp( _Color2 , _Color1 , smoothstepResult161);
				float smoothstepResult162 = smoothstep( ( 0.0 + _Vector8.x ) , _Vector8.y , tex2DNode2.r);
				float4 lerpResult170 = lerp( lerpResult167 , _Color3 , smoothstepResult162);
				float4 lerpResult176 = lerp( float4( appendResult35 , 0.0 ) , lerpResult170 , _Float9);
				float3 appendResult41 = (float3(i.ase_color.r , i.ase_color.g , i.ase_color.b));
				float3 appendResult25 = (float3(tex2DNode2.r , tex2DNode2.g , tex2DNode2.b));
				float3 temp_cast_2 = (1.0).xxx;
				float3 lerpResult177 = lerp( appendResult25 , temp_cast_2 , _Float9);
				float temp_output_33_0 = (0.0 + (_Vector9.y - 0.0) * (1.0 - 0.0) / (2.0 - 0.0));
				float2 appendResult70 = (float2(_Vector4.x , _Vector4.y));
				float2 appendResult67 = (float2(_Vector5.x , _Vector5.y));
				float2 panner69 = ( 1.0 * _Time.y * appendResult70 + (lerpResult5*appendResult67 + 0.0));
				float temp_output_80_0 = pow( tex2D( _TextureSample2, panner69 ).r , _Float2 );
				float smoothstepResult29 = smoothstep( _smooth_step , temp_output_33_0 , temp_output_80_0);
				float lerpResult82 = lerp( step( temp_output_33_0 , temp_output_80_0 ) , smoothstepResult29 , _Float3);
				float2 uv055 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float4 appendResult13 = (float4((( lerpResult176 * float4( appendResult41 , 0.0 ) * float4( lerpResult177 , 0.0 ) )).rgba.rgb , ( ( _Color0.a * ( tex2DNode2.a * lerpResult82 ) * i.ase_color.a ) * saturate( pow( tex2D( _TextureSample3, uv055 ).r , _Float0 ) ) )));
				
				
				finalColor = appendResult13;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=17500
-2041.6;45.6;1985;1079;6114.167;3409.193;5.08256;True;True
Node;AmplifyShaderEditor.Vector4Node;63;-3322.222,-171.2015;Inherit;False;Property;_Vector2;主纹理缩放;1;0;Create;False;0;0;False;0;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;52;-2566.251,-826.481;Inherit;False;Property;_Vector1;扰动贴图缩放;16;0;Create;False;0;0;False;0;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;62;-3052.267,-276.3712;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;65;-2814.672,-228.3939;Inherit;False;Property;_Vector3;主纹理速度;2;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;3;-3451.679,-381.7503;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;50;-2032.362,-685.6816;Inherit;False;Property;_Vector0;扰动速度;15;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;54;-2368,-816;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;44;-2032,-912;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;61;-2816.885,-403.5969;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;51;-1886.188,-669.0648;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;66;-2597.952,-214.0902;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;6;-2431.179,-129.9504;Inherit;True;Property;_TextureSample1;扭曲贴图;3;0;Create;False;0;0;False;0;-1;None;1ee2155ebc7acdd469a932f74ee1b951;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;7;-2123.215,-142.5051;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;45;-1774.241,-904.4977;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;182;-2415.177,325.4957;Inherit;False;Property;_Vector9;扭曲/溶解;28;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.PannerNode;64;-2486.005,-449.5232;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;72;-1921.449,2.018446;Inherit;False;Property;_Vector5;溶解贴图缩放;9;0;Create;False;0;0;False;0;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;5;-1955.219,-439.386;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;67;-1759.395,-131.7512;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-1521.723,-626.2183;Inherit;False;Property;_Float1;扰动强度;14;0;Create;False;0;0;False;0;0;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;71;-1456.8,-49.97393;Inherit;False;Property;_Vector4;溶解贴图速度;8;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;47;-1581.241,-945.4977;Inherit;True;Property;_TextureSample4;扰动贴图;13;0;Create;False;0;0;False;0;-1;None;de36b2cbe9c6b0140995721620a393d6;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;68;-1488.913,-255.077;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;70;-1284.279,-66.87024;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;-1348.323,-698.2183;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;46;-1142.415,-514.9407;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;69;-1163.232,-251.6033;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;96;-822.1532,920.4554;Inherit;False;Property;_Vector7;置换贴图缩放;18;0;Create;False;0;0;False;0;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;2;-1007.625,-785.6756;Inherit;True;Property;_TextureSample0;主纹理;0;0;Create;False;0;0;False;0;-1;None;e34cb767a1a167643bea74691086b950;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;90;-552.1984,815.2857;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;91;-951.6102,709.9066;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;92;-314.6032,863.263;Inherit;False;Property;vertexmap;置换贴图速度;19;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;173;-1275.5,-2047.614;Inherit;False;Constant;vertex11;分层色彩间距;24;0;Create;False;0;0;False;0;0;0.24;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;75;-969.5681,-88.52612;Inherit;False;Property;_Float2;溶解贴图强度;5;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;180;-1268.931,-1886.405;Inherit;False;Property;_Vector8;分层色彩间距;27;0;Create;False;0;0;False;0;0,0;0.6,1.05;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SamplerNode;10;-905.4048,-424.3296;Inherit;True;Property;_TextureSample2;溶解贴图;4;0;Create;False;0;0;False;0;-1;None;4d063b83542f6d749aafe52a1453b739;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;161;-908.8499,-2121.977;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0.2;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;33;-1108.324,88.48222;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;2;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;80;-794.3857,-190.5552;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;169;-1162.759,-2307.772;Inherit;False;Property;_Color2;分层色彩外;23;0;Create;False;0;0;False;0;1,0,0,0;0.2792537,0,0.3018868,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;94;-97.88293,877.5667;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;93;-316.8161,688.06;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;76;-499.726,155.2694;Inherit;False;Property;_smooth_step;smooth_step;7;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;174;-718.0845,-1895.15;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;168;-830.9307,-2488.143;Inherit;False;Property;_Color1;分层色彩中;24;0;Create;False;0;0;False;0;1,0.8772963,0,0;1,0.2684524,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;95;14.06409,642.1337;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;167;-530.0421,-2153.946;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;55;-1307.701,366.2319;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;83;-386.9709,11.75854;Inherit;False;Property;_Float3;smoothstep/step;6;0;Create;False;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;81;-560.9709,-237.2415;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;172;-378.6642,-2444.047;Inherit;False;Property;_Color3;分层色彩内;25;0;Create;False;0;0;False;0;0.3268521,1,0,0;1,0.9186074,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;29;-576.6068,-58.0667;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;34;-1594.691,-1336.908;Inherit;False;Property;_Color0;主颜色;12;0;Create;False;0;0;False;0;0,0,0,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;162;-495.3754,-1864.701;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0.4;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;87;152.5742,230.9897;Inherit;True;Property;_TextureSample5;顶点偏移贴图;17;0;Create;False;0;0;False;0;-1;None;e34cb767a1a167643bea74691086b950;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;170;-66.39577,-2240.264;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;27;-775.9343,224.0011;Inherit;True;Property;_TextureSample3;遮罩;10;0;Create;False;0;0;False;0;-1;None;ed1899300c6eef1438a29327561be274;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;25;-604.1005,-716.2957;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;179;-523.012,-1313.509;Inherit;False;Property;_Float9;启用分层色彩;26;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;82;-306.9709,-171.2415;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;178;-329.412,-855.9083;Inherit;False;Constant;_Float8;Float 8;26;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;35;-1187.299,-1590.798;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;43;-444.3245,307.881;Inherit;False;Property;_Float0;遮罩强度;11;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;39;-987.2333,-1226.359;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;151;382.9361,537.2143;Inherit;False;Property;_Float4;整体偏移强度;21;0;Create;False;0;0;False;0;0;0.46;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;152;503.6966,244.7294;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;149;715.7105,491.123;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;176;-313.5188,-1470.983;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;58;-303.5113,132.0728;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;177;-175.0792,-1051.557;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;41;-657.1284,-1138.763;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;-412.6024,-445.4496;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;-115.9911,-1230.288;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;60;35.26182,128.1348;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;147;568.4423,-212.7305;Inherit;False;Property;_Vector6;xyz偏移强度;20;0;Create;False;0;0;False;0;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;26.69037,-540.6753;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;150;743.8373,166.606;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;181;1005.657,410.5696;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;154;1042.845,-219.2662;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;144;1071.747,128.7911;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;12;5.367925,-706.0338;Inherit;False;True;True;True;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;59;254.1886,-160.4271;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;155;1439.747,153.5966;Inherit;False;Property;_Float5;各方向偏移;22;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;13;298.1675,-658.352;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LerpOp;153;1399.041,-47.91849;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;4;-2739.1,169.6794;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;125;1323.838,-393.6763;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_uv_distortion_vertex_z_off;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;0;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;62;0;63;1
WireConnection;62;1;63;2
WireConnection;54;0;52;1
WireConnection;54;1;52;2
WireConnection;44;0;3;0
WireConnection;44;1;54;0
WireConnection;61;0;3;0
WireConnection;61;1;62;0
WireConnection;51;0;50;1
WireConnection;51;1;50;2
WireConnection;66;0;65;1
WireConnection;66;1;65;2
WireConnection;7;0;6;1
WireConnection;7;1;6;2
WireConnection;45;0;44;0
WireConnection;45;2;51;0
WireConnection;64;0;61;0
WireConnection;64;2;66;0
WireConnection;5;0;64;0
WireConnection;5;1;7;0
WireConnection;5;2;182;1
WireConnection;67;0;72;1
WireConnection;67;1;72;2
WireConnection;47;1;45;0
WireConnection;68;0;5;0
WireConnection;68;1;67;0
WireConnection;70;0;71;1
WireConnection;70;1;71;2
WireConnection;49;0;47;1
WireConnection;49;1;48;0
WireConnection;46;0;49;0
WireConnection;46;1;5;0
WireConnection;69;0;68;0
WireConnection;69;2;70;0
WireConnection;2;1;46;0
WireConnection;90;0;96;1
WireConnection;90;1;96;2
WireConnection;10;1;69;0
WireConnection;161;0;2;1
WireConnection;161;1;173;0
WireConnection;33;0;182;2
WireConnection;80;0;10;1
WireConnection;80;1;75;0
WireConnection;94;0;92;1
WireConnection;94;1;92;2
WireConnection;93;0;91;0
WireConnection;93;1;90;0
WireConnection;174;0;173;0
WireConnection;174;1;180;1
WireConnection;95;0;93;0
WireConnection;95;2;94;0
WireConnection;167;0;169;0
WireConnection;167;1;168;0
WireConnection;167;2;161;0
WireConnection;81;0;33;0
WireConnection;81;1;80;0
WireConnection;29;0;80;0
WireConnection;29;1;76;0
WireConnection;29;2;33;0
WireConnection;162;0;2;1
WireConnection;162;1;174;0
WireConnection;162;2;180;2
WireConnection;87;1;95;0
WireConnection;170;0;167;0
WireConnection;170;1;172;0
WireConnection;170;2;162;0
WireConnection;27;1;55;0
WireConnection;25;0;2;1
WireConnection;25;1;2;2
WireConnection;25;2;2;3
WireConnection;82;0;81;0
WireConnection;82;1;29;0
WireConnection;82;2;83;0
WireConnection;35;0;34;1
WireConnection;35;1;34;2
WireConnection;35;2;34;3
WireConnection;152;0;87;1
WireConnection;176;0;35;0
WireConnection;176;1;170;0
WireConnection;176;2;179;0
WireConnection;58;0;27;1
WireConnection;58;1;43;0
WireConnection;177;0;25;0
WireConnection;177;1;178;0
WireConnection;177;2;179;0
WireConnection;41;0;39;1
WireConnection;41;1;39;2
WireConnection;41;2;39;3
WireConnection;26;0;2;4
WireConnection;26;1;82;0
WireConnection;40;0;176;0
WireConnection;40;1;41;0
WireConnection;40;2;177;0
WireConnection;60;0;58;0
WireConnection;28;0;34;4
WireConnection;28;1;26;0
WireConnection;28;2;39;4
WireConnection;150;0;152;0
WireConnection;150;1;151;0
WireConnection;181;0;149;0
WireConnection;154;0;147;0
WireConnection;154;1;87;1
WireConnection;144;0;150;0
WireConnection;144;1;181;0
WireConnection;12;0;40;0
WireConnection;59;0;28;0
WireConnection;59;1;60;0
WireConnection;13;0;12;0
WireConnection;13;3;59;0
WireConnection;153;0;154;0
WireConnection;153;1;144;0
WireConnection;153;2;155;0
WireConnection;125;0;13;0
WireConnection;125;1;153;0
ASEEND*/
//CHKSM=798B57981676E41D05C7CBD76900ABA498F16273
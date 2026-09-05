// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_warning"
{
	Properties
	{
		_Float5("预警角度(Float5)", Range( 0 , 360)) = 0
		_Float8("关闭默认预警图案", Float) = 0
		_Float4("光边强度", Float) = 0
		[HDR]_Color2("预警图案颜色", Color) = (1,0,0,1)
		[HDR]_Color1("光边颜色", Color) = (1,0,0,1)
		_Float2("底色强度", Range( 0 , 10)) = 0
		_Float7("预警滚动速度", Float) = 0
		_Float6("默认预警图案宽度", Float) = 57.68
		[HDR]_Color0("主颜色", Color) = (0,0,0,0)
		_TextureSample0("预警图案贴图", 2D) = "white" {}
		_Vector2("预警图片缩放", Vector) = (0,0,0,0)
		_Vector3("预警图片滚动速度", Vector) = (0,0,0,0)
		_TextureSample1("扰动贴图", 2D) = "white" {}
		_Vector5("扰动贴图缩放", Vector) = (0,0,0,0)
		_Vector4("扰动贴图滚动速度", Vector) = (0,0,0,0)
		_Float9("扰动强度", Float) = 0
		_TextureSample2("遮罩贴图", 2D) = "white" {}
		_Float11("遮罩强度", Float) = 0
		[Enum(Add,1,AlphaBlend,10)]_Float12("混合模式", Float) = 0

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" "Queue"="Transparent"  "RenderPipeline"="UniversalPipeline" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend One [_Float12]
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
			};

			uniform float _Float12;
			uniform float4 _Color0;
			uniform float _Float5;
			uniform float _Float7;
			uniform float _Float6;
			uniform sampler2D _TextureSample0;
			uniform float2 _Vector3;
			uniform float4 _Vector2;
			uniform sampler2D _TextureSample1;
			uniform float2 _Vector4;
			uniform float4 _Vector5;
			uniform float _Float9;
			uniform float _Float8;
			uniform float _Float4;
			uniform float _Float2;
			uniform float4 _Color1;
			uniform float4 _Color2;
			uniform sampler2D _TextureSample2;
			uniform float _Float11;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord.xy = v.ase_texcoord.xy;
				
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
				float2 uv02 = i.ase_texcoord.xy * float2( 2,2 ) + float2( -1,-1 );
				float2 appendResult6 = (float2(uv02.x , uv02.y));
				float temp_output_4_0 = length( appendResult6 );
				float temp_output_8_0 = atan2( uv02.x , uv02.y );
				float temp_output_11_0 = ( temp_output_8_0 / UNITY_PI );
				float2 _Vector0 = float2(0.5,0.5);
				float temp_output_13_0 = (temp_output_11_0*_Vector0.x + _Vector0.y);
				float temp_output_80_0 = (0.0 + (_Float5 - 0.0) * (1.0 - 0.0) / (180.0 - 0.0));
				float temp_output_73_0 = (1.0 + (temp_output_80_0 - 0.0) * (0.75 - 1.0) / (1.0 - 0.0));
				float2 _Vector1 = float2(-0.5,0.5);
				float temp_output_24_0 = (temp_output_11_0*_Vector1.x + _Vector1.y);
				float temp_output_49_0 = ( ( 1.0 - temp_output_4_0 ) * ( 1.0 - ( step( temp_output_13_0 , temp_output_73_0 ) * step( temp_output_24_0 , temp_output_73_0 ) ) ) );
				float mulTime91 = _Time.y * _Float7;
				float2 appendResult115 = (float2(temp_output_4_0 , temp_output_8_0));
				float2 appendResult127 = (float2(_Vector2.x , _Vector2.y));
				float2 appendResult128 = (float2(_Vector2.z , _Vector2.w));
				float2 panner116 = ( 1.0 * _Time.y * _Vector3 + (appendResult115*appendResult127 + appendResult128));
				float2 appendResult146 = (float2(_Vector5.x , _Vector5.y));
				float2 appendResult147 = (float2(_Vector5.z , _Vector5.w));
				float2 panner148 = ( 1.0 * _Time.y * _Vector4 + (appendResult115*appendResult146 + appendResult147));
				float2 temp_cast_0 = (( tex2D( _TextureSample1, panner148 ).r * 1.0 )).xx;
				float2 lerpResult151 = lerp( panner116 , temp_cast_0 , _Float9);
				float lerpResult141 = lerp( ( pow( frac( ( ( temp_output_4_0 / 0.15 ) - mulTime91 ) ) , _Float6 ) * temp_output_49_0 ) , ( tex2D( _TextureSample0, lerpResult151 ).r * temp_output_49_0 ) , _Float8);
				float temp_output_74_0 = (0.0 + (temp_output_80_0 - 0.0) * (0.25 - 0.0) / (1.0 - 0.0));
				float temp_output_66_0 = pow( frac( ( temp_output_24_0 - temp_output_74_0 ) ) , _Float4 );
				float temp_output_70_0 = ( 0.0 + temp_output_66_0 + pow( frac( ( temp_output_13_0 - temp_output_74_0 ) ) , _Float4 ) );
				float temp_output_101_0 = saturate( ( ( temp_output_49_0 * saturate( ( lerpResult141 + temp_output_70_0 ) ) ) + pow( temp_output_49_0 , _Float2 ) ) );
				float4 lerpResult191 = lerp( ( _Color0 * temp_output_101_0 ) , ( temp_output_70_0 * _Color1 ) , temp_output_70_0);
				float4 lerpResult193 = lerp( lerpResult191 , ( lerpResult141 * _Color2 ) , saturate( lerpResult141 ));
				
				
				finalColor = ( lerpResult193 * temp_output_101_0 * ( tex2D( _TextureSample2, appendResult115 ).r * _Float11 ) * _Color0.a );
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
-2041.6;0.8;1957;1122;1472.784;-423.6522;1;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;2;-1567.489,-77.15533;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;2,2;False;1;FLOAT2;-1,-1;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;6;-1162.748,-225.5978;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ATan2OpNode;8;-1206.601,152.4221;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;4;-926.3683,-519.031;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;150;-663.408,-1848.109;Inherit;False;Property;_Vector5;扰动贴图缩放;13;0;Create;False;0;0;False;0;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;115;-1321.219,-1536.794;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;146;-467.4081,-1927.109;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PiNode;12;-1045.785,381.5825;Inherit;True;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;147;-457.4081,-1772.109;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;158;-798.2253,-1931.676;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;75;-961.7668,930.8396;Inherit;False;Property;_Float5;预警角度(Float5);0;0;Create;False;0;0;False;0;0;198;0;360;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;149;-173.408,-1906.109;Inherit;False;Property;_Vector4;扰动贴图滚动速度;14;0;Create;False;0;0;False;0;0,0;-1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector4Node;126;-625.9253,-1300.03;Inherit;False;Property;_Vector2;预警图片缩放;10;0;Create;False;0;0;False;0;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;80;-468.0478,935.1197;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;180;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;14;-800.601,303.4221;Inherit;False;Constant;_Vector0;Vector 0;0;0;Create;True;0;0;False;0;0.5,0.5;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;25;-807.6013,663.9285;Inherit;False;Constant;_Vector1;Vector 1;0;0;Create;True;0;0;False;0;-0.5,0.5;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ScaleAndOffsetNode;145;-215.5959,-2074.365;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;11;-862.601,-11.57794;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;88;168.0903,-870.5305;Inherit;False;Constant;_Float0;Float 0;0;0;Create;True;0;0;False;0;0.15;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;92;387.0903,-724.5305;Inherit;False;Property;_Float7;预警滚动速度;6;0;Create;False;0;0;False;0;0;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;128;-419.9253,-1224.03;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;13;-435.6823,-42.47142;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;73;-37.24175,246.1709;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1;False;4;FLOAT;0.75;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;24;-483.5555,352.0604;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;127;-429.9253,-1379.03;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;148;120.9802,-2093.938;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;152;382.8754,-2030.557;Inherit;True;Property;_TextureSample1;扰动贴图;12;0;Create;False;0;0;False;0;-1;None;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;129;-135.9253,-1358.03;Inherit;False;Property;_Vector3;预警图片滚动速度;11;0;Create;False;0;0;False;0;0,0;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleDivideOpNode;83;379.2803,-1089.144;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;91;550.0903,-775.5305;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;46;830.3026,605.0369;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;118;-178.1131,-1526.286;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;156;382.8754,-1673.057;Inherit;False;Constant;_Float1;Float 1;11;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;44;887.9294,272.3537;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;89;681.0903,-961.5305;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;116;248.1627,-1553.659;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;1097.109,473.2154;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;157;649.3754,-1563.857;Inherit;False;Property;_Float9;扰动强度;15;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;74;-211.8087,1420.7;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;0.25;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;155;546.9753,-1788.057;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;77;12.00313,906.2889;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;86;951.0903,-716.5305;Inherit;False;Property;_Float6;默认预警图案宽度;7;0;Create;False;0;0;False;0;57.68;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;81;911.3049,-1023.638;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;151;810.5752,-1834.257;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;35;527.4031,-514.4979;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;62;164.7532,1543.157;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;48;1508.297,406.6103;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;57;385.7988,1563.979;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;122;954.4282,-1655.167;Inherit;True;Property;_TextureSample0;预警图案贴图;9;0;Create;False;0;0;False;0;-1;None;f39bb9c22752d3f43bc035affa182603;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FractNode;76;376.6602,924.7176;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;1703.68,-167.9587;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;85;1215.09,-804.5305;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;67;740.1879,1355.235;Inherit;False;Property;_Float4;光边强度;2;0;Create;False;0;0;False;0;0;60;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;97;1721.285,-951.1682;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;161;2154.221,-552.6195;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;78;985.4411,958.5034;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;143;2009.527,207.4721;Inherit;False;Property;_Float8;关闭默认预警图案;1;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;66;1090.668,1543.35;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;70;2144.696,685.6514;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;141;2485.038,-609.3666;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;98;2823.828,156.4982;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;110;2670.266,632.5534;Inherit;False;Property;_Float2;底色强度;5;0;Create;False;0;0;False;0;0;2.06;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;100;3056.666,176.603;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;99;3159.533,-88.64326;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;188;2895.01,530.7069;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;107;3406.322,124.0093;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;112;3257.853,-1431.253;Inherit;False;Property;_Color0;主颜色;8;1;[HDR];Create;False;0;0;False;0;0,0,0,0;1.414214,0.0776431,0.03882155,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;190;3181.939,932.9323;Inherit;False;Property;_Color1;光边颜色;4;1;[HDR];Create;False;0;0;False;0;1,0,0,1;1,0.04794633,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;101;3580.466,-211.0846;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;180;-502.5302,-2487.656;Inherit;True;Property;_TextureSample2;遮罩贴图;16;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;189;3460.224,752.1763;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;137;3752.014,-643.5759;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;195;4065.974,-689.6794;Inherit;False;Property;_Color2;预警图案颜色;3;1;[HDR];Create;False;0;0;False;0;1,0,0,1;3.56487,0.07465696,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;182;-120.7859,-2305.703;Inherit;False;Property;_Float11;遮罩强度;17;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;181;1100.884,-2418.086;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;194;4344.26,-870.4354;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;197;3449.525,-465.0474;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;191;3866.39,172.9194;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;183;2434.791,-1714.47;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;193;4393.966,-502.7822;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;69;1452.995,1029.952;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;68;1596.995,897.9523;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;184;4497.165,-267.7209;Inherit;False;Property;_Float12;混合模式;18;1;[Enum];Create;False;2;Add;1;AlphaBlend;10;0;True;0;0;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;109;3043.253,332.6445;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;186;2321.154,2.700377;Inherit;False;Constant;_Float13;Float 13;17;0;Create;True;0;0;False;0;0.2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;192;4623.635,1.970788;Inherit;True;4;4;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;61;-65.26917,1671.717;Inherit;False;Constant;_Float3;Float 3;0;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;179;-363.9778,-132.237;Inherit;False;Constant;_Float10;Float 10;13;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;5070.87,-216.3267;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_warning;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;4;1;False;-1;1;True;184;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;0;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;6;0;2;1
WireConnection;6;1;2;2
WireConnection;8;0;2;1
WireConnection;8;1;2;2
WireConnection;4;0;6;0
WireConnection;115;0;4;0
WireConnection;115;1;8;0
WireConnection;146;0;150;1
WireConnection;146;1;150;2
WireConnection;147;0;150;3
WireConnection;147;1;150;4
WireConnection;158;0;115;0
WireConnection;80;0;75;0
WireConnection;145;0;158;0
WireConnection;145;1;146;0
WireConnection;145;2;147;0
WireConnection;11;0;8;0
WireConnection;11;1;12;0
WireConnection;128;0;126;3
WireConnection;128;1;126;4
WireConnection;13;0;11;0
WireConnection;13;1;14;1
WireConnection;13;2;14;2
WireConnection;73;0;80;0
WireConnection;24;0;11;0
WireConnection;24;1;25;1
WireConnection;24;2;25;2
WireConnection;127;0;126;1
WireConnection;127;1;126;2
WireConnection;148;0;145;0
WireConnection;148;2;149;0
WireConnection;152;1;148;0
WireConnection;83;0;4;0
WireConnection;83;1;88;0
WireConnection;91;0;92;0
WireConnection;46;0;24;0
WireConnection;46;1;73;0
WireConnection;118;0;115;0
WireConnection;118;1;127;0
WireConnection;118;2;128;0
WireConnection;44;0;13;0
WireConnection;44;1;73;0
WireConnection;89;0;83;0
WireConnection;89;1;91;0
WireConnection;116;0;118;0
WireConnection;116;2;129;0
WireConnection;47;0;44;0
WireConnection;47;1;46;0
WireConnection;74;0;80;0
WireConnection;155;0;152;1
WireConnection;155;1;156;0
WireConnection;77;0;13;0
WireConnection;77;1;74;0
WireConnection;81;0;89;0
WireConnection;151;0;116;0
WireConnection;151;1;155;0
WireConnection;151;2;157;0
WireConnection;35;0;4;0
WireConnection;62;0;24;0
WireConnection;62;1;74;0
WireConnection;48;0;47;0
WireConnection;57;0;62;0
WireConnection;122;1;151;0
WireConnection;76;0;77;0
WireConnection;49;0;35;0
WireConnection;49;1;48;0
WireConnection;85;0;81;0
WireConnection;85;1;86;0
WireConnection;97;0;85;0
WireConnection;97;1;49;0
WireConnection;161;0;122;1
WireConnection;161;1;49;0
WireConnection;78;0;76;0
WireConnection;78;1;67;0
WireConnection;66;0;57;0
WireConnection;66;1;67;0
WireConnection;70;1;66;0
WireConnection;70;2;78;0
WireConnection;141;0;97;0
WireConnection;141;1;161;0
WireConnection;141;2;143;0
WireConnection;98;0;141;0
WireConnection;98;1;70;0
WireConnection;100;0;98;0
WireConnection;99;0;49;0
WireConnection;99;1;100;0
WireConnection;188;0;49;0
WireConnection;188;1;110;0
WireConnection;107;0;99;0
WireConnection;107;1;188;0
WireConnection;101;0;107;0
WireConnection;180;1;115;0
WireConnection;189;0;70;0
WireConnection;189;1;190;0
WireConnection;137;0;112;0
WireConnection;137;1;101;0
WireConnection;181;0;180;1
WireConnection;181;1;182;0
WireConnection;194;0;141;0
WireConnection;194;1;195;0
WireConnection;197;0;141;0
WireConnection;191;0;137;0
WireConnection;191;1;189;0
WireConnection;191;2;70;0
WireConnection;183;0;181;0
WireConnection;193;0;191;0
WireConnection;193;1;194;0
WireConnection;193;2;197;0
WireConnection;69;0;66;0
WireConnection;68;0;69;0
WireConnection;192;0;193;0
WireConnection;192;1;101;0
WireConnection;192;2;183;0
WireConnection;192;3;112;4
WireConnection;1;0;192;0
ASEEND*/
//CHKSM=02E8F51BE11AEEEF1F6294DD5CD7FA04F9293C28
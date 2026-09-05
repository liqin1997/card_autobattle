// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "screen_graound"
{
	Properties
	{
		_MAIN_STAR_TEX("MAIN_STAR_TEX", 2D) = "white" {}
		_mainpanner_UVXYTIMEZ("main panner_UV/XY TIME/Z", Vector) = (0,0,0,0)
		_main_scaleoffset("main_scale offset", Vector) = (0,0,0,0)
		_DISSLOVE_TEX("DISSLOVE_TEX", 2D) = "white" {}
		_DISSLOVE_SCALE("DISSLOVE_SCALE", Float) = 0
		_POWER("POWER", Float) = 0
		_MAX("MAX", Float) = 0
		_MIN("MIN", Range( -3 , 2)) = 0
		_STAR_NOISE("STAR_NOISE", 2D) = "white" {}
		_STAR_NOISE_SPEED("STAR_NOISE_SPEED", Vector) = (0,0,0,0)
		_starnoisepower("star noise power", Float) = 0
		_star_color("star_color", Color) = (0,0,0,0)
		_gradient_overlay_tex("gradient_overlay_tex", 2D) = "white" {}
		_gradient_scale("gradient_scale", Vector) = (0,0,0,0)

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque"  "RenderPipeline"="UniversalPipeline" }
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
				
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_texcoord : TEXCOORD0;
			};

			uniform sampler2D _gradient_overlay_tex;
			uniform float4 _gradient_scale;
			uniform sampler2D _MAIN_STAR_TEX;
			uniform float4 _mainpanner_UVXYTIMEZ;
			uniform float4 _main_scaleoffset;
			uniform sampler2D _STAR_NOISE;
			uniform float4 _STAR_NOISE_SPEED;
			uniform float _starnoisepower;
			uniform float4 _star_color;
			uniform float _MIN;
			uniform float _MAX;
			uniform sampler2D _DISSLOVE_TEX;
			uniform float _DISSLOVE_SCALE;
			uniform float _POWER;

			
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
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 appendResult4 = (float2(ase_screenPosNorm.x , ase_screenPosNorm.y));
				float2 appendResult74 = (float2(_gradient_scale.x , _gradient_scale.y));
				float mulTime21 = _Time.y * _mainpanner_UVXYTIMEZ.z;
				float2 appendResult19 = (float2(_mainpanner_UVXYTIMEZ.x , _mainpanner_UVXYTIMEZ.y));
				float2 appendResult28 = (float2(_main_scaleoffset.x , _main_scaleoffset.y));
				float2 appendResult29 = (float2(_main_scaleoffset.z , _main_scaleoffset.w));
				float2 temp_output_26_0 = (appendResult4*appendResult28 + appendResult29);
				float2 panner11 = ( ( mulTime21 + _mainpanner_UVXYTIMEZ.w ) * appendResult19 + temp_output_26_0);
				float mulTime61 = _Time.y * _STAR_NOISE_SPEED.z;
				float2 appendResult81 = (float2(_STAR_NOISE_SPEED.x , _STAR_NOISE_SPEED.y));
				float2 panner63 = ( ( mulTime61 + _STAR_NOISE_SPEED.w ) * appendResult81 + temp_output_26_0);
				float4 temp_output_71_0 = ( saturate( tex2D( _gradient_overlay_tex, (appendResult4*appendResult74 + float2( 0,0 )) ) ) + ( ( tex2D( _MAIN_STAR_TEX, panner11 ) * ( tex2D( _STAR_NOISE, panner63 ) * _starnoisepower ) ) * _star_color ) );
				float4 _Vector0 = float4(2,2,0.5,0.5);
				float2 appendResult44 = (float2(( _DISSLOVE_SCALE + _Vector0.x ) , ( _DISSLOVE_SCALE + _Vector0.y )));
				float2 appendResult45 = (float2(_Vector0.z , _Vector0.w));
				float smoothstepResult55 = smoothstep( _MIN , _MAX , tex2D( _DISSLOVE_TEX, (( appendResult4 + float2( -0.5,-0.5 ) )*appendResult44 + appendResult45) ).r);
				float4 temp_cast_1 = (( smoothstepResult55 * _POWER )).xxxx;
				float4 lerpResult79 = lerp( temp_output_71_0 , temp_cast_1 , 1.0);
				float4 appendResult41 = (float4(temp_output_71_0.rgb , lerpResult79.r));
				
				
				finalColor = appendResult41;
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
-28;227.2;1957;973;3401.008;746.3303;2.410439;True;True
Node;AmplifyShaderEditor.ScreenPosInputsNode;3;-3225.408,-61.99485;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;60;-1997.613,591.0865;Inherit;False;Property;_STAR_NOISE_SPEED;STAR_NOISE_SPEED;9;0;Create;True;0;0;False;0;0,0,0,0;-0.5,-0.5,1,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;27;-2206.365,-112.3814;Inherit;False;Property;_main_scaleoffset;main_scale offset;2;0;Create;True;0;0;False;0;0,0,0,0;2,2,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;29;-2000,-48;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;28;-1984,-160;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;4;-2700.906,-330.2805;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;61;-1603.208,656.0639;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;18;-2155.218,192.8988;Inherit;False;Property;_mainpanner_UVXYTIMEZ;main panner_UV/XY TIME/Z;1;0;Create;True;0;0;False;0;0,0,0,0;0.2,0.2,1,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;21;-1746.501,179.9591;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;81;-1707.762,484.7135;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;26;-1728,-288;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;52;-3062.268,1102.179;Inherit;False;Property;_DISSLOVE_SCALE;DISSLOVE_SCALE;4;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;46;-3079.3,1260.685;Inherit;False;Constant;_Vector0;Vector 0;3;0;Create;True;0;0;False;0;2,2,0.5,0.5;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;62;-1427.565,688.6755;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;63;-1395.888,253.8564;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;22;-1545.416,215.751;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;54;-2791.346,1231.381;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;53;-2788.346,1132.381;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;73;-2137.205,-462.1426;Inherit;False;Property;_gradient_scale;gradient_scale;13;0;Create;True;0;0;False;0;0,0,0,0;1,1.79,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;19;-1815.024,17.9416;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;49;-2452.205,166.0084;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;-0.5,-0.5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;44;-2525.671,1175.407;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;45;-2652.559,1329.919;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;65;-885.7291,322.3632;Inherit;False;Property;_starnoisepower;star noise power;10;0;Create;True;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;11;-1513.739,-219.0681;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;74;-1972.44,-581.7612;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;58;-1124.812,59.27369;Inherit;True;Property;_STAR_NOISE;STAR_NOISE;8;0;Create;True;0;0;False;0;-1;None;dd93ece84d407cd44931653f592c0cb4;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;43;-2430.969,939.2657;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;75;-1716.44,-709.7612;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;5;-1134.433,-252.4554;Inherit;True;Property;_MAIN_STAR_TEX;MAIN_STAR_TEX;0;0;Create;True;0;0;False;0;-1;None;14ea6f7c106e34e4182c27282e6e79f7;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-756.7291,128.3632;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;69;-423.5423,24.24233;Inherit;False;Property;_star_color;star_color;11;0;Create;True;0;0;False;0;0,0,0,0;0,1,0.9709249,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;56;-2026.718,1363.764;Inherit;False;Property;_MIN;MIN;7;0;Create;True;0;0;False;0;0;-3;-3;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;59;-619.7352,-104.5185;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;57;-2027.593,1553.656;Inherit;False;Property;_MAX;MAX;6;0;Create;True;0;0;False;0;0;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;32;-1913.811,1055.797;Inherit;True;Property;_DISSLOVE_TEX;DISSLOVE_TEX;3;0;Create;True;0;0;False;0;-1;None;60d224affeaecf84ead5a8b24c6c9995;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;70;-1325.763,-681.6451;Inherit;True;Property;_gradient_overlay_tex;gradient_overlay_tex;12;0;Create;True;0;0;False;0;-1;None;3ce3763a241850846814c77bac63d99d;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;72;-609.9514,-703.4457;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;66;-442.7293,-349.7361;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;55;-1384.295,1276.31;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-1306.768,1535.352;Inherit;False;Property;_POWER;POWER;5;0;Create;True;0;0;False;0;0;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;80;-1039.76,1090.577;Inherit;False;Constant;_Float1;Float 1;15;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;71;-133.2514,-653.5458;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;-981.4129,1251.338;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;79;-815.6517,867.3887;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;41;40.35846,-27.66054;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;372,-8;Float;False;True;-1;2;ASEMaterialInspector;100;1;screen_graound;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;RenderType=Opaque=RenderType;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;0;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;29;0;27;3
WireConnection;29;1;27;4
WireConnection;28;0;27;1
WireConnection;28;1;27;2
WireConnection;4;0;3;1
WireConnection;4;1;3;2
WireConnection;61;0;60;3
WireConnection;21;0;18;3
WireConnection;81;0;60;1
WireConnection;81;1;60;2
WireConnection;26;0;4;0
WireConnection;26;1;28;0
WireConnection;26;2;29;0
WireConnection;62;0;61;0
WireConnection;62;1;60;4
WireConnection;63;0;26;0
WireConnection;63;2;81;0
WireConnection;63;1;62;0
WireConnection;22;0;21;0
WireConnection;22;1;18;4
WireConnection;54;0;52;0
WireConnection;54;1;46;2
WireConnection;53;0;52;0
WireConnection;53;1;46;1
WireConnection;19;0;18;1
WireConnection;19;1;18;2
WireConnection;49;0;4;0
WireConnection;44;0;53;0
WireConnection;44;1;54;0
WireConnection;45;0;46;3
WireConnection;45;1;46;4
WireConnection;11;0;26;0
WireConnection;11;2;19;0
WireConnection;11;1;22;0
WireConnection;74;0;73;1
WireConnection;74;1;73;2
WireConnection;58;1;63;0
WireConnection;43;0;49;0
WireConnection;43;1;44;0
WireConnection;43;2;45;0
WireConnection;75;0;4;0
WireConnection;75;1;74;0
WireConnection;5;1;11;0
WireConnection;64;0;58;0
WireConnection;64;1;65;0
WireConnection;59;0;5;0
WireConnection;59;1;64;0
WireConnection;32;1;43;0
WireConnection;70;1;75;0
WireConnection;72;0;70;0
WireConnection;66;0;59;0
WireConnection;66;1;69;0
WireConnection;55;0;32;1
WireConnection;55;1;56;0
WireConnection;55;2;57;0
WireConnection;71;0;72;0
WireConnection;71;1;66;0
WireConnection;47;0;55;0
WireConnection;47;1;48;0
WireConnection;79;0;71;0
WireConnection;79;1;47;0
WireConnection;79;2;80;0
WireConnection;41;0;71;0
WireConnection;41;3;79;0
WireConnection;1;0;41;0
ASEEND*/
//CHKSM=CA9A1A8C8D042B328CC7BB04647E4B473DD6C983
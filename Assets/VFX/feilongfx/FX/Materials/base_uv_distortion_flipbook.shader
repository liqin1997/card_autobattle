// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_uv_distortion_flipbook"
{
	Properties
	{
		_TextureSample0("主纹理", 2D) = "white" {}
		_Vector4("主纹理速度", Vector) = (0,0,0,0)
		_Vector9("主纹理缩放", Vector) = (1,1,0,0)
		_Vector5("行/列/速度/时间", Vector) = (1,1,1,1)
		_TextureSample1("扭曲贴图", 2D) = "white" {}
		_TextureSample2("溶解贴图", 2D) = "white" {}
		_Float3("溶解阈值", Float) = -0.38
		_TextureSample3("遮罩", 2D) = "white" {}
		_Float0("遮罩强度", Float) = 0
		_Color0("主颜色", Color) = (0,0,0,0)
		_TextureSample4("扰动贴图", 2D) = "white" {}
		_Float1("扰动强度", Float) = 0
		_Vector0("扰动速度", Vector) = (0,0,0,0)
		_Vector1("扰动贴图缩放", Vector) = (0,0,0,0)
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
			uniform float4 _Vector4;
			uniform sampler2D _TextureSample4;
			uniform float4 _Vector0;
			uniform float4 _Vector9;
			uniform float4 _Vector1;
			uniform float _Float1;
			uniform sampler2D _TextureSample1;
			uniform float4 _TextureSample1_ST;
			uniform float4 _Vector5;
			uniform float _Float3;
			uniform sampler2D _TextureSample2;
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
				float2 appendResult83 = (float2(_Vector4.x , _Vector4.y));
				float2 appendResult51 = (float2(_Vector0.x , _Vector0.y));
				float2 uv03 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult169 = (float2(_Vector9.x , _Vector9.y));
				float2 appendResult171 = (float2(_Vector9.z , _Vector9.w));
				float2 temp_output_167_0 = (uv03*appendResult169 + appendResult171);
				float2 appendResult54 = (float2(_Vector1.x , _Vector1.y));
				float2 panner45 = ( 1.0 * _Time.y * appendResult51 + (temp_output_167_0*appendResult54 + 0.0));
				float2 uv_TextureSample1 = i.ase_texcoord.xy * _TextureSample1_ST.xy + _TextureSample1_ST.zw;
				float4 tex2DNode6 = tex2D( _TextureSample1, uv_TextureSample1 );
				float2 appendResult7 = (float2(tex2DNode6.r , tex2DNode6.g));
				float4 uv14 = i.ase_texcoord1;
				uv14.xy = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 lerpResult5 = lerp( temp_output_167_0 , appendResult7 , uv14.x);
				float mulTime75 = _Time.y * _Vector5.w;
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles80 = _Vector5.x * _Vector5.y;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset80 = 1.0f / _Vector5.x;
				float fbrowsoffset80 = 1.0f / _Vector5.y;
				// Speed of animation
				float fbspeed80 = mulTime75 * _Vector5.z;
				// UV Tiling (col and row offset)
				float2 fbtiling80 = float2(fbcolsoffset80, fbrowsoffset80);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex80 = round( fmod( fbspeed80 + 0.0, fbtotaltiles80) );
				fbcurrenttileindex80 += ( fbcurrenttileindex80 < 0) ? fbtotaltiles80 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox80 = round ( fmod ( fbcurrenttileindex80, _Vector5.x ) );
				// Multiply Offset X by coloffset
				float fboffsetx80 = fblinearindextox80 * fbcolsoffset80;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy80 = round( fmod( ( fbcurrenttileindex80 - fblinearindextox80 ) / _Vector5.x, _Vector5.y ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy80 = (int)(_Vector5.y-1) - fblinearindextoy80;
				// Multiply Offset Y by rowoffset
				float fboffsety80 = fblinearindextoy80 * fbrowsoffset80;
				// UV Offset
				float2 fboffset80 = float2(fboffsetx80, fboffsety80);
				// Flipbook UV
				half2 fbuv80 = ( ( tex2D( _TextureSample4, panner45 ).r * _Float1 ) + lerpResult5 ) * fbtiling80 + fboffset80;
				// *** END Flipbook UV Animation vars ***
				float2 panner84 = ( 1.0 * _Time.y * appendResult83 + fbuv80);
				float4 tex2DNode2 = tex2D( _TextureSample0, panner84 );
				float3 appendResult25 = (float3(tex2DNode2.r , tex2DNode2.g , tex2DNode2.b));
				float3 appendResult41 = (float3(i.ase_color.r , i.ase_color.g , i.ase_color.b));
				float smoothstepResult29 = smoothstep( _Float3 , (0.0 + (uv14.y - 0.0) * (5.0 - 0.0) / (1.0 - 0.0)) , tex2D( _TextureSample2, lerpResult5 ).r);
				float2 uv055 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float4 appendResult13 = (float4((( appendResult35 * appendResult25 * appendResult41 )).xyz , ( ( _Color0.a * ( tex2DNode2.a * smoothstepResult29 ) * i.ase_color.a ) * saturate( pow( tex2D( _TextureSample3, uv055 ).r , _Float0 ) ) )));
				
				
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
-2041.6;52.8;1957;1070;1531.864;385.7587;1;True;True
Node;AmplifyShaderEditor.Vector4Node;170;-3629.448,-248.9553;Inherit;False;Property;_Vector9;主纹理缩放;2;0;Create;False;0;0;False;0;1,1,0,0;1,1.45,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;52;-2989.216,-803.4938;Inherit;False;Property;_Vector1;扰动贴图缩放;13;0;Create;False;0;0;False;0;0,0,0,0;2,2,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;169;-3384.448,-272.9553;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;171;-3438.448,-155.9553;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;3;-3690.251,-402.5257;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;54;-2793.216,-806.4938;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;50;-2455.327,-662.6944;Inherit;False;Property;_Vector0;扰动速度;12;0;Create;False;0;0;False;0;0,0,0,0;0,-1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;167;-3189.142,-468.2104;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;44;-2590.952,-990.1855;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;51;-2309.153,-646.0776;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;6;-3279.455,-112.8858;Inherit;True;Property;_TextureSample1;扭曲贴图;4;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;45;-2336.531,-929.2814;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;4;-2932.343,92.67486;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;47;-2107.927,-985.8005;Inherit;True;Property;_TextureSample4;扰动贴图;10;0;Create;False;0;0;False;0;-1;None;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;48;-1944.688,-603.2311;Inherit;False;Property;_Float1;扰动强度;11;0;Create;False;0;0;False;0;0;0.04;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;7;-2876.962,-187.5714;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;5;-2397.705,-388.5162;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;-1692.955,-822.778;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;46;-1626.48,-532.8552;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;85;-1738.238,-2242.378;Inherit;False;Property;_Vector5;行/列/速度/时间;3;0;Create;False;0;0;False;0;1,1,1,1;1,1,1,1;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;75;-1492.35,-2115.234;Inherit;True;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;82;-1151.346,-1815.826;Inherit;False;Property;_Vector4;主纹理速度;1;0;Create;False;0;0;False;0;0,0,0,0;0,0.5,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;81;-1233.221,-1983.979;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCFlipBookUVAnimation;80;-1158.507,-2322.15;Inherit;False;0;0;6;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;4;FLOAT;0;False;5;FLOAT;0;False;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;83;-891.2727,-1701.658;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;10;-746.4205,-53.19138;Inherit;True;Property;_TextureSample2;溶解贴图;5;0;Create;False;0;0;False;0;-1;None;2f67131bd8bcd5540badff1422fbbf7b;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;93;-364.1004,45.36816;Inherit;False;Property;_Float3;溶解阈值;6;0;Create;False;0;0;False;0;-0.38;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;55;-748.812,573.2278;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;84;-988.4248,-1849.442;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;33;-479.6067,159.9786;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;2;-666.2205,-1658.953;Inherit;True;Property;_TextureSample0;主纹理;0;0;Create;False;0;0;False;0;-1;None;df211b66145ae7a42a656ac109fcdca5;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;29;-196.7415,3.370368;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;34;-811.5154,-2009.495;Inherit;False;Property;_Color0;主颜色;9;0;Create;False;0;0;False;0;0,0,0,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;27;-217.0451,430.9971;Inherit;True;Property;_TextureSample3;遮罩;7;0;Create;False;0;0;False;0;-1;None;35df857e018518246838a3d010d8d37e;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;43;114.5647,514.877;Inherit;False;Property;_Float0;遮罩强度;8;0;Create;False;0;0;False;0;0;-0.04;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;39;-671.1613,-2226.293;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;41;-342.8308,-2172.407;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PowerNode;58;255.3779,339.0688;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;25;-342.6959,-1659.373;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;35;-483.1856,-1959.368;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;326.9207,-258.605;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;60;594.151,335.1308;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;569.385,-245.3926;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;-123.5266,-1798.963;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;59;813.0778,46.5689;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;12;84.46465,-1610.397;Inherit;False;True;True;True;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;13;595.022,-1580.328;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1083.351,-344.2171;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_uv_distortion_flipbook;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;0;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;169;0;170;1
WireConnection;169;1;170;2
WireConnection;171;0;170;3
WireConnection;171;1;170;4
WireConnection;54;0;52;1
WireConnection;54;1;52;2
WireConnection;167;0;3;0
WireConnection;167;1;169;0
WireConnection;167;2;171;0
WireConnection;44;0;167;0
WireConnection;44;1;54;0
WireConnection;51;0;50;1
WireConnection;51;1;50;2
WireConnection;45;0;44;0
WireConnection;45;2;51;0
WireConnection;47;1;45;0
WireConnection;7;0;6;1
WireConnection;7;1;6;2
WireConnection;5;0;167;0
WireConnection;5;1;7;0
WireConnection;5;2;4;1
WireConnection;49;0;47;1
WireConnection;49;1;48;0
WireConnection;46;0;49;0
WireConnection;46;1;5;0
WireConnection;75;0;85;4
WireConnection;81;0;46;0
WireConnection;80;0;81;0
WireConnection;80;1;85;1
WireConnection;80;2;85;2
WireConnection;80;3;85;3
WireConnection;80;5;75;0
WireConnection;83;0;82;1
WireConnection;83;1;82;2
WireConnection;10;1;5;0
WireConnection;84;0;80;0
WireConnection;84;2;83;0
WireConnection;33;0;4;2
WireConnection;2;1;84;0
WireConnection;29;0;10;1
WireConnection;29;1;93;0
WireConnection;29;2;33;0
WireConnection;27;1;55;0
WireConnection;41;0;39;1
WireConnection;41;1;39;2
WireConnection;41;2;39;3
WireConnection;58;0;27;1
WireConnection;58;1;43;0
WireConnection;25;0;2;1
WireConnection;25;1;2;2
WireConnection;25;2;2;3
WireConnection;35;0;34;1
WireConnection;35;1;34;2
WireConnection;35;2;34;3
WireConnection;26;0;2;4
WireConnection;26;1;29;0
WireConnection;60;0;58;0
WireConnection;28;0;34;4
WireConnection;28;1;26;0
WireConnection;28;2;39;4
WireConnection;40;0;35;0
WireConnection;40;1;25;0
WireConnection;40;2;41;0
WireConnection;59;0;28;0
WireConnection;59;1;60;0
WireConnection;12;0;40;0
WireConnection;13;0;12;0
WireConnection;13;3;59;0
WireConnection;1;0;13;0
ASEEND*/
//CHKSM=C83BA418340C42FFF62B5970F03E66315336F831
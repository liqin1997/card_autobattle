// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Base_Pixel"
{
	Properties
	{
		_TextureSample0("主贴图", 2D) = "white" {}
		_Vector1("主贴图缩放偏移", Vector) = (1,1,0,0)
		_Vector2("主贴图速度", Vector) = (0,0,0,0)
		_Float2("溶解值", Float) = 1
		_Float0("主贴图像素粒度", Float) = -21
		[HDR]_Color0("主颜色", Color) = (1,1,1,1)
		_TextureSample1("溶解贴图", 2D) = "white" {}
		_Vector0("溶解贴图流动速度", Vector) = (0,0,0,0)
		_Float1("溶解贴图像素粒度", Float) = 7.63
		_Float3("开启custom data", Float) = 0
		[Enum(ADD,1,AlphaBlend,10)]_Float4("混合模式", Float) = 1

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" "Queue"="Transparent"  "RenderPipeline"="UniversalPipeline" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend One One
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

			uniform float _Float4;
			uniform float4 _Color0;
			uniform sampler2D _TextureSample0;
			uniform float2 _Vector2;
			uniform float _Float0;
			uniform float _Float3;
			uniform float4 _Vector1;
			uniform sampler2D _TextureSample1;
			uniform float2 _Vector0;
			uniform float _Float1;
			uniform float _Float2;

			
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
				float3 appendResult56 = (float3(_Color0.r , _Color0.g , _Color0.b));
				float2 uv03 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float4 uv166 = i.ase_texcoord1;
				uv166.xy = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float lerpResult67 = lerp( _Float0 , uv166.x , _Float3);
				float2 appendResult62 = (float2(_Vector1.x , _Vector1.y));
				float2 appendResult63 = (float2(_Vector1.z , _Vector1.w));
				float2 panner64 = ( 1.0 * _Time.y * _Vector2 + (( floor( ( uv03 * lerpResult67 ) ) / lerpResult67 )*appendResult62 + appendResult63));
				float4 tex2DNode2 = tex2D( _TextureSample0, panner64 );
				float4 appendResult57 = (float4(tex2DNode2.r , tex2DNode2.g , tex2DNode2.b , 0.0));
				float3 appendResult74 = (float3(i.ase_color.r , i.ase_color.g , i.ase_color.b));
				float lerpResult68 = lerp( _Float1 , uv166.y , _Float3);
				float2 panner27 = ( 1.0 * _Time.y * _Vector0 + ( floor( ( uv03 * lerpResult68 ) ) / lerpResult68 ));
				float lerpResult69 = lerp( _Float2 , uv166.z , _Float3);
				float temp_output_49_0 = ( ( _Color0.a * tex2DNode2.a * i.ase_color.a ) * step( tex2D( _TextureSample1, panner27 ).r , lerpResult69 ) );
				float4 appendResult41 = (float4(( float4( appendResult56 , 0.0 ) * appendResult57 * float4( appendResult74 , 0.0 ) ).xyz , temp_output_49_0));
				
				
				finalColor = ( appendResult41 * tex2DNode2.a * temp_output_49_0 * i.ase_color.a );
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=17500
-2048;0;1985;1131;1841.398;1212.037;1.626553;True;True
Node;AmplifyShaderEditor.RangedFloatNode;70;-2493.753,1123.371;Inherit;False;Property;_Float3;开启custom data;9;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;66;-2791.786,671.5632;Inherit;True;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;8;-2546.845,66.92011;Inherit;False;Property;_Float0;主贴图像素粒度;4;0;Create;False;0;0;False;0;-21;2.7;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;3;-2641.908,-402.8419;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;67;-2323.955,330.9691;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-2286.28,578.4418;Inherit;False;Property;_Float1;溶解贴图像素粒度;8;0;Create;False;0;0;False;0;7.63;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;7;-2051.785,-345.3144;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;68;-2231.262,882.1584;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FloorOpNode;14;-1729.954,-459.7677;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;61;-1603.295,140.0348;Inherit;False;Property;_Vector1;主贴图缩放偏移;1;0;Create;False;0;0;False;0;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;-1927.144,405.9411;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FloorOpNode;29;-1731.626,414.6491;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;9;-1647.551,-143.2476;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;63;-1253.598,131.0681;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;62;-1395.569,-9.408585;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;65;-1050.371,40.70038;Inherit;False;Property;_Vector2;主贴图速度;2;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;59;-1409.094,591.6544;Inherit;False;Property;_Vector0;溶解贴图流动速度;7;0;Create;False;0;0;False;0;0,0;0.2,0.2;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ScaleAndOffsetNode;60;-1263.389,-296.2674;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;28;-1737.664,658.9294;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;27;-1213.168,295.9457;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-1271.743,891.398;Inherit;False;Property;_Float2;溶解值;3;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;64;-843.8672,-215.3706;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;2;-615.3606,-318.4158;Inherit;True;Property;_TextureSample0;主贴图;0;0;Create;False;0;0;False;0;-1;None;d6d5099955b3ddf4e8bbaf42ac715481;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;75;-750.8362,-1085.509;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;34;-998.8611,350.0819;Inherit;True;Property;_TextureSample1;溶解贴图;6;0;Create;False;0;0;False;0;-1;82f4b06147155c54da475b309b9e24fa;6701bfb8e762cd54e96d8dc1a763d942;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;69;-1215.185,1185.643;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;53;-757.4564,-823.2447;Inherit;False;Property;_Color0;主颜色;5;1;[HDR];Create;False;0;0;False;0;1,1,1,1;0.7490196,0.7490196,0.7490196,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;74;-455.8362,-1079.509;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;56;-326.6295,-762.8409;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;57;-333.1296,-635.441;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StepOpNode;52;-391.3557,734.0731;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;55;-184.3341,-256.9591;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;-129.5566,-785.5445;Inherit;True;3;3;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;-86.51358,475.6136;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;41;270.8177,-287.6588;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;72;-2969.891,809.993;Inherit;False;Property;_Float4;混合模式;10;1;[Enum];Create;False;2;ADD;1;AlphaBlend;10;0;True;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;73;527.5465,184.1614;Inherit;True;4;4;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;544.7098,-339.2336;Float;False;True;-1;2;ASEMaterialInspector;100;1;Base_Pixel;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;4;1;False;-1;1;False;72;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;67;0;8;0
WireConnection;67;1;66;1
WireConnection;67;2;70;0
WireConnection;7;0;3;0
WireConnection;7;1;67;0
WireConnection;68;0;31;0
WireConnection;68;1;66;2
WireConnection;68;2;70;0
WireConnection;14;0;7;0
WireConnection;30;0;3;0
WireConnection;30;1;68;0
WireConnection;29;0;30;0
WireConnection;9;0;14;0
WireConnection;9;1;67;0
WireConnection;63;0;61;3
WireConnection;63;1;61;4
WireConnection;62;0;61;1
WireConnection;62;1;61;2
WireConnection;60;0;9;0
WireConnection;60;1;62;0
WireConnection;60;2;63;0
WireConnection;28;0;29;0
WireConnection;28;1;68;0
WireConnection;27;0;28;0
WireConnection;27;2;59;0
WireConnection;64;0;60;0
WireConnection;64;2;65;0
WireConnection;2;1;64;0
WireConnection;34;1;27;0
WireConnection;69;0;45;0
WireConnection;69;1;66;3
WireConnection;69;2;70;0
WireConnection;74;0;75;1
WireConnection;74;1;75;2
WireConnection;74;2;75;3
WireConnection;56;0;53;1
WireConnection;56;1;53;2
WireConnection;56;2;53;3
WireConnection;57;0;2;1
WireConnection;57;1;2;2
WireConnection;57;2;2;3
WireConnection;52;0;34;1
WireConnection;52;1;69;0
WireConnection;55;0;53;4
WireConnection;55;1;2;4
WireConnection;55;2;75;4
WireConnection;54;0;56;0
WireConnection;54;1;57;0
WireConnection;54;2;74;0
WireConnection;49;0;55;0
WireConnection;49;1;52;0
WireConnection;41;0;54;0
WireConnection;41;3;49;0
WireConnection;73;0;41;0
WireConnection;73;1;2;4
WireConnection;73;2;49;0
WireConnection;73;3;75;4
WireConnection;1;0;73;0
ASEEND*/
//CHKSM=2B7DD094BE1DE46E96DA8EE1F3EC8D5BE25674D1
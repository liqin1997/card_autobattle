// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_cartoon_fireEdge control"
{
	Properties
	{
		_Vector0("纹理1tilling/speed", Vector) = (2,1,0,-1)
		_Vector1("纹理2tilling/speed", Vector) = (2,1,0,-0.5)
		_Color0("外颜色", Color) = (0,0,0,0)
		_Color1("中间颜色", Color) = (1,0,0,0)
		_Color3("内部颜色", Color) = (1,0.6284041,0,0)
		_Color2("高光", Color) = (1,0.6284041,0,0)
		_Float3("火焰范围", Range( 0 , 1.5)) = 0.4041452
		_Float8("火焰扭曲程度", Float) = 1.55
		_Float7("边缘强度", Float) = 0.5
		_TextureSample2("mask", 2D) = "white" {}
		_Float4("遮罩强度", Float) = 1
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

			uniform float4 _Color2;
			uniform float4 _Color3;
			uniform float4 _Color1;
			uniform float4 _Color0;
			uniform float4 _Vector0;
			uniform float _Float8;
			uniform float4 _Vector1;
			uniform float _Float3;
			uniform float _Float7;
			uniform sampler2D _TextureSample2;
			uniform float4 _TextureSample2_ST;
			uniform float _Float4;
					float2 voronoihash5( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi5( float2 v, float time, inout float2 id, float smoothness )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mr = 0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash5( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = g - f + o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						 		}
						 	}
						}
						return F1;
					}
			
					float2 voronoihash29( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi29( float2 v, float time, inout float2 id, float smoothness )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mr = 0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash29( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = g - f + o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						 		}
						 	}
						}
						return F1;
					}
			

			
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
				float2 appendResult23 = (float2(_Time.y , 2.0));
				float time5 = appendResult23.x;
				float2 appendResult11 = (float2(_Vector0.z , _Vector0.w));
				float2 appendResult22 = (float2(_Vector0.x , _Vector0.y));
				float2 uv04 = i.ase_texcoord.xy * appendResult22 + float2( 0,0 );
				float2 panner6 = ( 1.0 * _Time.y * appendResult11 + (uv04*1.0 + 0.0));
				float2 coords5 = panner6 * 5.0;
				float2 id5 = 0;
				float voroi5 = voronoi5( coords5, time5,id5, 0 );
				float2 appendResult35 = (float2(_Time.y , 1.2));
				float time29 = appendResult35.x;
				float2 appendResult31 = (float2(_Vector1.z , _Vector1.w));
				float2 appendResult33 = (float2(_Vector1.x , _Vector1.y));
				float2 uv030 = i.ase_texcoord.xy * appendResult33 + float2( 0,0 );
				float2 panner28 = ( 1.0 * _Time.y * appendResult31 + (uv030*1.0 + 0.0));
				float2 coords29 = panner28 * 3.91;
				float2 id29 = 0;
				float voroi29 = voronoi29( coords29, time29,id29, 0 );
				float blendOpSrc38 = ( voroi5 * _Float8 );
				float blendOpDest38 = ( voroi29 * _Float8 );
				float2 uv039 = i.ase_texcoord.xy * float2( 1,1 ) + float2( -0.5,-0.5 );
				float temp_output_48_0 = (1.0 + (length( uv039 ) - 0.0) * (0.0 - 1.0) / (_Float3 - 0.0));
				float2 uv056 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_TextureSample2 = i.ase_texcoord.xy * _TextureSample2_ST.xy + _TextureSample2_ST.zw;
				float temp_output_79_0 = saturate( ( ( ( ( saturate( (( blendOpDest38 > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - blendOpDest38 ) * ( 1.0 - blendOpSrc38 ) ) : ( 2.0 * blendOpDest38 * blendOpSrc38 ) ) )) * temp_output_48_0 ) + ( temp_output_48_0 * ( ( 1.0 - uv056.y ) * _Float7 ) ) ) * ( tex2D( _TextureSample2, uv_TextureSample2 ).r * _Float4 ) ) );
				float4 uv1103 = i.ase_texcoord1;
				uv1103.xy = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_67_0 = ( uv1103.x + uv1103.y );
				float4 lerpResult62 = lerp( _Color1 , _Color0 , step( temp_output_79_0 , temp_output_67_0 ));
				float temp_output_73_0 = ( temp_output_67_0 + uv1103.y );
				float4 lerpResult63 = lerp( _Color3 , lerpResult62 , step( temp_output_79_0 , temp_output_73_0 ));
				float4 lerpResult113 = lerp( _Color2 , lerpResult63 , step( temp_output_79_0 , ( temp_output_73_0 + uv1103.y ) ));
				float4 appendResult77 = (float4((lerpResult113).rgb , ( i.ase_color.a * ( 1.0 - step( temp_output_79_0 , uv1103.x ) ) )));
				
				
				finalColor = appendResult77;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=17500
-2041.6;230.4;1957;893;2307.323;304.1307;1.587589;True;True
Node;AmplifyShaderEditor.Vector4Node;20;-4476.453,-384.1766;Inherit;False;Property;_Vector0;纹理1tilling/speed;0;0;Create;False;0;0;False;0;2,1,0,-1;3,1,0,-2;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;32;-4690.415,621.0383;Inherit;False;Property;_Vector1;纹理2tilling/speed;1;0;Create;False;0;0;False;0;2,1,0,-0.5;3,1,0,-2;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;22;-4114.314,-412.9394;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;33;-4220.476,346.5927;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;4;-3889.861,-530.7692;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;3.29,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;30;-3964.65,325.812;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;3.29,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;31;-3171.533,859.6384;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;27;-3346.343,322.4174;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;37;-2875.577,624.3433;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;7;-3160.24,-488.0341;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;11;-3292.59,-303.7451;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;36;-2831.562,804.6724;Inherit;False;Constant;_Float1;Float 1;0;0;Create;True;0;0;False;0;1.2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;25;-3001.714,-193.8392;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;26;-2983.414,-69.83917;Inherit;False;Constant;_Float0;Float 0;0;0;Create;True;0;0;False;0;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;17;-2761.25,86.14783;Inherit;False;Constant;_Float5;Float 5;0;0;Create;True;0;0;False;0;5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;28;-2877.887,286.5003;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;35;-2539.935,598.168;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;23;-2811.714,-160.8392;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;34;-2561.271,821.742;Inherit;False;Constant;_Float2;Float 2;0;0;Create;True;0;0;False;0;3.91;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;6;-2896.862,-414.0607;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;56;-4463.448,1452.923;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;39;-4100.634,1040.952;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;-0.5,-0.5;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VoronoiNode;5;-2535.769,-327.9218;Inherit;True;0;0;1;0;1;False;1;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;2;FLOAT;0;FLOAT;1
Node;AmplifyShaderEditor.RangedFloatNode;71;-2173.843,521.8359;Inherit;False;Property;_Float8;火焰扭曲程度;10;0;Create;False;0;0;False;0;1.55;2.89;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VoronoiNode;29;-2380.938,375.6922;Inherit;True;0;0;1;0;1;False;1;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;2;FLOAT;0;FLOAT;1
Node;AmplifyShaderEditor.OneMinusNode;58;-4103.343,1486.641;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;42;-3447.46,1071.695;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;69;-3484.638,1775.719;Inherit;False;Property;_Float7;边缘强度;11;0;Create;False;0;0;False;0;0.5;0.93;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;49;-3486.54,1335.749;Inherit;False;Property;_Float3;火焰范围;9;0;Create;False;0;0;False;0;0.4041452;0.53;0;1.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;109;-2033.336,-170.5634;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;70;-1946.603,209.2512;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BlendOpsNode;38;-1755.333,-21.79929;Inherit;True;Overlay;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;117;-3242.345,1537.791;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;48;-3149.222,1116.513;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.45;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;104;-2216.715,1459.527;Inherit;True;Property;_TextureSample2;mask;12;0;Create;False;0;0;False;0;-1;None;da418232ef19edd498c61e47830587b0;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;50;-1828.874,538.3945;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;57;-2629.992,1385.02;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;105;-1914.509,1857.686;Inherit;True;Property;_Float4;遮罩强度;13;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;51;-1709.502,911.9275;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;106;-1846.044,1248.838;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;108;-1470.872,1060.061;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;103;-2090.246,933.598;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;79;-1410.742,839.1028;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;67;-1363.445,1335.968;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;73;-1347.458,1520.391;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;59;-1289.328,24.7487;Inherit;False;Property;_Color0;外颜色;2;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;60;-1242.988,-193.3197;Inherit;False;Property;_Color1;中间颜色;3;0;Create;False;0;0;False;0;1,0,0,0;1,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StepOpNode;64;-1124.645,1179.968;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;62;-951.7092,-16.34049;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StepOpNode;72;-1106.092,1474.172;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;111;-1347.354,1687.82;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;114;-995.4243,-304.1781;Inherit;False;Property;_Color3;内部颜色;4;0;Create;False;0;0;False;0;1,0.6284041,0,0;1,0.6284041,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StepOpNode;53;-1137.317,824.1273;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;110;-1130.263,1752.81;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;61;-869.652,-584.4229;Inherit;False;Property;_Color2;高光;5;0;Create;False;0;0;False;0;1,0.6284041,0,0;1,0.9616297,0.3349057,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;63;-596.5293,-213.4589;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexColorNode;81;-1195.752,332.2599;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;78;-730.3951,864.9838;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;113;-296.9991,-439.1394;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ComponentMaskNode;75;-237.052,-9.771713;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;80;-468.2465,310.1697;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;66;-1750.445,1495.968;Inherit;False;Property;_Float6;外部边宽;6;0;Create;False;0;0;False;0;0.03;0.11;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;88;-3684.781,1298.122;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;74;-1715.438,1629.449;Inherit;False;Property;_Float9;内部宽度;7;0;Create;False;0;0;False;0;0.08;0.23;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;77;-100.3481,167.0521;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;-445.2949,928.5001;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;112;-1658.446,1764.341;Inherit;False;Property;_Float12;中心宽度;8;0;Create;False;0;0;False;0;0.08;0.3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;268.2304,-4.681098;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_cartoon_fireEdge control;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;2;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;22;0;20;1
WireConnection;22;1;20;2
WireConnection;33;0;32;1
WireConnection;33;1;32;2
WireConnection;4;0;22;0
WireConnection;30;0;33;0
WireConnection;31;0;32;3
WireConnection;31;1;32;4
WireConnection;27;0;30;0
WireConnection;7;0;4;0
WireConnection;11;0;20;3
WireConnection;11;1;20;4
WireConnection;28;0;27;0
WireConnection;28;2;31;0
WireConnection;35;0;37;0
WireConnection;35;1;36;0
WireConnection;23;0;25;0
WireConnection;23;1;26;0
WireConnection;6;0;7;0
WireConnection;6;2;11;0
WireConnection;5;0;6;0
WireConnection;5;1;23;0
WireConnection;5;2;17;0
WireConnection;29;0;28;0
WireConnection;29;1;35;0
WireConnection;29;2;34;0
WireConnection;58;0;56;2
WireConnection;42;0;39;0
WireConnection;109;0;5;0
WireConnection;109;1;71;0
WireConnection;70;0;29;0
WireConnection;70;1;71;0
WireConnection;38;0;109;0
WireConnection;38;1;70;0
WireConnection;117;0;58;0
WireConnection;117;1;69;0
WireConnection;48;0;42;0
WireConnection;48;2;49;0
WireConnection;50;0;38;0
WireConnection;50;1;48;0
WireConnection;57;0;48;0
WireConnection;57;1;117;0
WireConnection;51;0;50;0
WireConnection;51;1;57;0
WireConnection;106;0;104;1
WireConnection;106;1;105;0
WireConnection;108;0;51;0
WireConnection;108;1;106;0
WireConnection;79;0;108;0
WireConnection;67;0;103;1
WireConnection;67;1;103;2
WireConnection;73;0;67;0
WireConnection;73;1;103;2
WireConnection;64;0;79;0
WireConnection;64;1;67;0
WireConnection;62;0;60;0
WireConnection;62;1;59;0
WireConnection;62;2;64;0
WireConnection;72;0;79;0
WireConnection;72;1;73;0
WireConnection;111;0;73;0
WireConnection;111;1;103;2
WireConnection;53;0;79;0
WireConnection;53;1;103;1
WireConnection;110;0;79;0
WireConnection;110;1;111;0
WireConnection;63;0;114;0
WireConnection;63;1;62;0
WireConnection;63;2;72;0
WireConnection;78;0;53;0
WireConnection;113;0;61;0
WireConnection;113;1;63;0
WireConnection;113;2;110;0
WireConnection;75;0;113;0
WireConnection;80;0;81;4
WireConnection;80;1;78;0
WireConnection;88;0;39;0
WireConnection;77;0;75;0
WireConnection;77;3;80;0
WireConnection;1;0;77;0
ASEEND*/
//CHKSM=AF5FE1898D5931591FF91DB6B172262869092D81
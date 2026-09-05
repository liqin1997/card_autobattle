// Upgrade NOTE: upgraded instancing buffer 'Star_crack' to new syntax.

// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Star_crack"
{
	Properties
	{
		_TextureSample0("主纹理", 2D) = "white" {}
		_Vector0("主纹理缩放", Vector) = (1,1,0,0)
		_Vector1("主纹理流动速度", Vector) = (0,0,0,0)
		_noise1("极坐标贴图", 2D) = "white" {}
		_scaleoffset("极坐标贴图缩放", Vector) = (0,0,0,0)
		_Vector2("极坐标速度", Vector) = (0,0,0,0)
		_power("power", Float) = 0
		_Float0("外边缘遮罩", Float) = 4
		[HDR]_Color0("外边缘颜色", Color) = (1,1,1,1)
		_TextureSample1("整体溶解贴图", 2D) = "white" {}
		_Vector11("整体溶解贴图缩放/偏移", Vector) = (0,0,0,0)
		_Vector12("整体溶解贴图速度", Vector) = (0,0,0,0)
		_Float5("备注：customs ：星星缩放/外边缘缩放/整体溶解/外边缘溶解", Float) = 0
		_Float6("备注2 customs1 默认数值为1", Float) = 0
		_Float1("备注3：customs 2控制 rotate和Pi值", Float) = 0
		[HDR]_Color1("主颜色", Color) = (1,1,1,1)

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
				float4 ase_texcoord2 : TEXCOORD2;
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
				float4 ase_texcoord3 : TEXCOORD3;
			};

			uniform float _Float6;
			uniform float _Float5;
			uniform float _Float1;
			uniform sampler2D _TextureSample0;
			uniform float2 _Vector1;
			uniform float4 _Vector0;
			uniform float4 _Color1;
			uniform sampler2D _noise1;
			uniform float2 _Vector2;
			uniform half4 _scaleoffset;
			uniform float4 _Color0;
			uniform float _Float0;
			uniform sampler2D _TextureSample1;
			uniform float2 _Vector12;
			uniform float4 _Vector11;
			UNITY_INSTANCING_BUFFER_START(Star_crack)
				UNITY_DEFINE_INSTANCED_PROP(float, _power)
#define _power_arr Star_crack
			UNITY_INSTANCING_BUFFER_END(Star_crack)
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
				
				o.ase_color = v.color;
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_texcoord2 = v.ase_texcoord2;
				o.ase_texcoord3 = v.ase_texcoord1;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
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
				float3 appendResult46 = (float3(i.ase_color.r , i.ase_color.g , i.ase_color.b));
				float2 appendResult44 = (float2(_Vector1));
				float4 screenPos = i.ase_texcoord;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float2 appendResult35 = (float2(ase_grabScreenPosNorm.r , ase_grabScreenPosNorm.g));
				float2 appendResult40 = (float2(_Vector0.x , _Vector0.y));
				float2 appendResult41 = (float2(_Vector0.z , _Vector0.w));
				float2 panner42 = ( 1.0 * _Time.y * appendResult44 + (appendResult35*appendResult40 + appendResult41));
				float4 tex2DNode36 = tex2D( _TextureSample0, panner42 );
				float3 appendResult48 = (float3(tex2DNode36.r , tex2DNode36.g , tex2DNode36.b));
				float3 appendResult193 = (float3(_Color1.r , _Color1.g , _Color1.b));
				float2 appendResult76 = (float2(_Vector2));
				float2 uv052 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float4 uv2189 = i.ase_texcoord2;
				uv2189.xy = i.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float cos59 = cos( ( ( ( 1.0 - length( (uv052*2.0 + -1.0) ) ) * 2.0 * uv2189.x ) * UNITY_PI ) );
				float sin59 = sin( ( ( ( 1.0 - length( (uv052*2.0 + -1.0) ) ) * 2.0 * uv2189.x ) * UNITY_PI ) );
				float2 rotator59 = mul( uv052 - float2( 0.5,0.5 ) , float2x2( cos59 , -sin59 , sin59 , cos59 )) + float2( 0.5,0.5 );
				float2 temp_output_60_0 = (rotator59*2.0 + -1.0);
				float temp_output_66_0 = length( temp_output_60_0 );
				float _power_Instance = UNITY_ACCESS_INSTANCED_PROP(_power_arr, _power);
				float2 break62 = temp_output_60_0;
				float2 appendResult74 = (float2(pow( temp_output_66_0 , _power_Instance ) , ( ( atan2( break62.y , break62.x ) / ( uv2189.y * UNITY_PI ) ) + 0.5 )));
				float2 appendResult72 = (float2(_scaleoffset.x , _scaleoffset.y));
				float2 appendResult73 = (float2(_scaleoffset.z , _scaleoffset.w));
				float2 panner78 = ( 1.0 * _Time.y * appendResult76 + (appendResult74*appendResult72 + appendResult73));
				float4 tex2DNode81 = tex2D( _noise1, panner78 );
				float4 uv1181 = i.ase_texcoord3;
				uv1181.xy = i.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float temp_output_168_0 = step( ( pow( temp_output_66_0 , _Float0 ) * tex2DNode81.r ) , uv1181.w );
				float temp_output_148_0 = ( uv1181.x + 0.1 );
				float2 uv0125 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float smoothstepResult152 = smoothstep( temp_output_148_0 , uv1181.y , length( (uv0125*2.0 + float2( -1,0 )) ));
				float smoothstepResult153 = smoothstep( temp_output_148_0 , uv1181.y , length( (uv0125*2.0 + float2( -1,-2 )) ));
				float smoothstepResult154 = smoothstep( temp_output_148_0 , uv1181.y , length( (uv0125*2.0 + float2( 0,-1 )) ));
				float smoothstepResult155 = smoothstep( temp_output_148_0 , uv1181.y , length( (uv0125*2.0 + float2( -2,-1 )) ));
				float temp_output_151_0 = saturate( ( saturate( (-1.0 + (( smoothstepResult152 + smoothstepResult153 ) - 0.0) * (0.0 - -1.0) / (1.0 - 0.0)) ) + saturate( (-1.0 + (( smoothstepResult154 + smoothstepResult155 ) - 0.0) * (0.0 - -1.0) / (1.0 - 0.0)) ) ) );
				float2 uv010 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float smoothstepResult161 = smoothstep( uv1181.x , 1.05 , length( (uv010*2.0 + float2( 0,-1 )) ));
				float smoothstepResult163 = smoothstep( uv1181.x , 1.05 , length( (uv010*2.0 + float2( -2,-1 )) ));
				float smoothstepResult159 = smoothstep( uv1181.x , 1.05 , length( (uv010*2.0 + float2( -1,0 )) ));
				float smoothstepResult160 = smoothstep( uv1181.x , 1.05 , length( (uv010*2.0 + float2( -1,-2 )) ));
				float4 lerpResult156 = lerp( float4( ( appendResult46 * appendResult48 * appendResult193 ) , 0.0 ) , ( tex2DNode81 * _Color0 ) , ( temp_output_168_0 * saturate( ( temp_output_151_0 - saturate( ( saturate( (-1.0 + (( smoothstepResult161 + smoothstepResult163 ) - 0.0) * (0.0 - -1.0) / (1.0 - 0.0)) ) + saturate( (-1.0 + (( smoothstepResult159 + smoothstepResult160 ) - 0.0) * (0.0 - -1.0) / (1.0 - 0.0)) ) ) ) ) ) ));
				float2 uv0164 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult177 = (float2(_Vector11.x , _Vector11.y));
				float2 appendResult178 = (float2(_Vector11.z , _Vector11.w));
				float2 panner179 = ( 1.0 * _Time.y * _Vector12 + (uv0164*appendResult177 + appendResult178));
				float4 appendResult50 = (float4(lerpResult156.rgb , ( i.ase_color.a * ( temp_output_168_0 * temp_output_151_0 ) * tex2DNode36.a * step( tex2D( _TextureSample1, panner179 ).r , uv1181.z ) * _Color1.a )));
				
				
				finalColor = appendResult50;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=17500
0;34.4;1957;1089;310.2173;2327.816;1.750152;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;52;-4108.807,-262.8266;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;53;-4287.404,92.86628;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LengthOpNode;54;-3968.902,88.13486;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;56;-3689.38,81.97358;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;189;-3918.111,562.7783;Inherit;False;2;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;57;-3474.442,182.5035;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;2;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PiNode;58;-3446.269,-46.93006;Inherit;False;1;0;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;59;-3508.481,-214.4562;Inherit;False;3;0;FLOAT2;0.5,0.5;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;12;-1620.536,1125.161;Inherit;False;Constant;_Vector4;Vector 4;14;0;Create;True;0;0;False;0;-1,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;27;-1855.536,1659.962;Inherit;False;Constant;_Vector3;Vector 3;14;0;Create;True;0;0;False;0;-1,-2;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;9;-1129.456,2388.831;Inherit;False;Constant;_Vector9;Vector 9;14;0;Create;True;0;0;False;0;-2,-1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;125;-1198.343,2981.376;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;124;-1219.301,3673.139;Inherit;False;Constant;_Vector5;Vector 5;14;0;Create;True;0;0;False;0;-1,-2;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;7;-878.4553,2018.831;Inherit;False;Constant;_Vector8;Vector 8;14;0;Create;True;0;0;False;0;0,-1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;129;-984.3013,3138.338;Inherit;False;Constant;_Vector6;Vector 6;14;0;Create;True;0;0;False;0;-1,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;123;-951.1273,4314.324;Inherit;False;Constant;_Vector7;Vector 7;14;0;Create;True;0;0;False;0;-2,-1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;181;-2687.831,1925.005;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;60;-3190.454,-262.9902;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;128;-700.1266,3944.324;Inherit;False;Constant;_Vector10;Vector 10;14;0;Create;True;0;0;False;0;0,-1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;10;-1834.578,968.199;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;130;-513.1265,3754.324;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT2;-12,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;13;-1431.538,936.1609;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT2;-12,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;131;-795.303,2949.338;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT2;-12,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;62;-2975.454,-47.99015;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ScaleAndOffsetNode;14;-691.4553,1828.831;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT2;-12,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;26;-1847.48,1325.907;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT2;-12,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;182;-2305.289,2909.749;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;147;-1178.545,3354.177;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT2;-12,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;8;-889.7197,2196.359;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT2;-12,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;132;-714.1266,4127.323;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT2;-12,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LengthOpNode;134;-704.3005,3240.338;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;4;-598.4553,2120.831;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;5;-413.4555,1839.831;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;11;-1142.535,848.6609;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;135;-249.3031,3836.207;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;2;-1350.882,1289.24;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ATan2OpNode;63;-2754.865,-17.86106;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PiNode;64;-2708.454,245.0098;Inherit;False;1;0;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;126;-502.5274,2830.395;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;133;-420.1265,4046.324;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;148;-1649.7,3453.758;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;154;19.84962,3631.789;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;-0.5;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;152;-120.2155,2860.689;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0.1;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;159;-371.1354,1030.325;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1.05;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;153;-220.3303,3299.409;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;-0.5;False;2;FLOAT;1.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;66;-2897.174,-318.3425;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;160;-420.1416,1407.347;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1.05;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;155;-101.4372,4216.171;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;-0.5;False;2;FLOAT;1.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;163;-193.8291,2132.465;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1.05;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;65;-2415.453,13.00988;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;67;-2592.715,-131.532;Inherit;False;InstancedProperty;_power;power;7;0;Create;True;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;161;-163.7209,1636.403;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1.05;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;70;-2524.254,-276.6532;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;69;-2191.453,13.00988;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;22;86.20345,1917.704;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;68;-1987.041,149.7276;Half;False;Property;_scaleoffset;极坐标贴图缩放;4;0;Create;False;0;0;False;0;0,0,0,0;0.5,5,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;17;-75.30442,1322.441;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;143;264.5323,3843.197;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;138;103.0243,3247.934;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;73;-1673.98,203.4114;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;20;255.7402,1314.576;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;144;522.9404,3920.743;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GrabScreenPosition;34;-1552.656,-1508.328;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;139;434.069,3240.069;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;21;344.6116,1995.25;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;38;-1327.821,-1223.237;Inherit;False;Property;_Vector0;主纹理缩放;1;0;Create;False;0;0;False;0;1,1,0,0;3,3,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;72;-1789.98,5.411366;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;74;-2080.247,-203.7551;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;101;-1352.305,67.87628;Inherit;False;Property;_Vector2;极坐标速度;5;0;Create;False;0;0;False;0;0,0;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ScaleAndOffsetNode;77;-1498.502,-296.9566;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;140;858.9098,3620.933;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;41;-1084.707,-979.6525;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;76;-1136.916,-30.41395;Inherit;False;FLOAT2;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;43;-573.7069,-1201.653;Inherit;False;Property;_Vector1;主纹理流动速度;2;0;Create;False;0;0;False;0;0,0;-1,-1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;35;-1217.408,-1480.144;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;40;-1111.313,-1224.831;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;176;4.532354,-873.7258;Inherit;False;Property;_Vector11;整体溶解贴图缩放/偏移;12;0;Create;False;0;0;False;0;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;24;648.7427,1637.734;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;145;799.5704,3851.181;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;23;621.2417,1925.688;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;78;-935.4039,-119.8759;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;37;-829.5972,-1353.559;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;149;1072.915,3796.885;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;106;-523.971,-270.9158;Inherit;False;Property;_Float0;外边缘遮罩;9;0;Create;False;0;0;False;0;4;0.4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;178;346.4096,-731.647;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;177;359.7295,-827.8462;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;164;141.6841,-1114.496;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;44;-365.707,-1196.652;Inherit;False;FLOAT2;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;25;1131.114,675.6816;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;175;584.1879,-1009.004;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;42;-169.307,-1351.653;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PowerNode;105;-309.2181,-479.4734;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;173;1486.151,682.066;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;180;646.69,-803.1367;Inherit;False;Property;_Vector12;整体溶解贴图速度;13;0;Create;False;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SamplerNode;81;-714.1218,-131.5811;Inherit;True;Property;_noise1;极坐标贴图;3;0;Create;False;0;0;False;0;-1;None;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;151;1295.164,3013.773;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;186;-1739.328,738.0186;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;36;147.6216,-1361.795;Inherit;True;Property;_TextureSample0;主纹理;0;0;Create;False;0;0;False;0;-1;None;29d02448a5a93b54f9eb0dd88261be5f;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;192;423.0532,-1955.524;Inherit;False;Property;_Color1;主颜色;17;1;[HDR];Create;False;0;0;False;0;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;45;311.4968,-1774.87;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;150;1793.114,768.9445;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;179;898.4451,-910.7253;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;170;26.27514,-18.878;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;184;-1823.522,665.6267;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;168;233.3,150.5059;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;165;1070.329,-1207.568;Inherit;True;Property;_TextureSample1;整体溶解贴图;11;0;Create;False;0;0;False;0;-1;None;809e95bf413fd1b4b836bf1c87a8813c;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;46;664.5472,-1743.898;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;158;1897.723,350.7655;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;118;392.8067,-73.34193;Inherit;False;Property;_Color0;外边缘颜色;10;1;[HDR];Create;False;0;0;False;0;1,1,1,1;0,2.678483,3.732132,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;185;803.8717,352.1493;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;193;715.5071,-1898.999;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;48;654.5125,-1507.369;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;963.2333,-1567.612;Inherit;True;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StepOpNode;166;1531.363,-1155.459;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;117;891.8507,-246.5419;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;171;1869.969,-369.6925;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;172;1931.883,-683.6167;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;156;2136.919,-1227.561;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;51;1916.711,-1596.169;Inherit;True;5;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;18;421.0345,2278.116;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;146;599.3632,4203.609;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;50;2158.297,-1568.297;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;187;2828.593,-877.8971;Inherit;False;Property;_Float5;备注：customs ：星星缩放/外边缘缩放/整体溶解/外边缘溶解;14;0;Create;False;0;0;True;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;162;182.1221,1608.503;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1.05;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;55;-3579.869,463.6467;Inherit;False;InstancedProperty;_rotator;rotator;8;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;188;2835.656,-761.2929;Inherit;False;Property;_Float6;备注2 customs1 默认数值为1;15;0;Create;False;0;0;True;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;190;2845.927,-620.918;Inherit;False;Property;_Float1;备注3：customs 2控制 rotate和Pi值;16;0;Create;False;0;0;True;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;61;-3086.256,277.4412;Inherit;False;InstancedProperty;_pi;pi;6;0;Create;True;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;2955.885,-1044.581;Float;False;True;-1;2;ASEMaterialInspector;100;1;Star_crack;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;53;0;52;0
WireConnection;54;0;53;0
WireConnection;56;0;54;0
WireConnection;57;0;56;0
WireConnection;57;2;189;1
WireConnection;58;0;57;0
WireConnection;59;0;52;0
WireConnection;59;2;58;0
WireConnection;60;0;59;0
WireConnection;130;0;125;0
WireConnection;130;2;128;0
WireConnection;13;0;10;0
WireConnection;13;2;12;0
WireConnection;131;0;125;0
WireConnection;131;2;129;0
WireConnection;62;0;60;0
WireConnection;14;0;10;0
WireConnection;14;2;7;0
WireConnection;26;0;10;0
WireConnection;26;2;27;0
WireConnection;182;0;181;1
WireConnection;147;0;125;0
WireConnection;147;2;124;0
WireConnection;8;0;10;0
WireConnection;8;2;9;0
WireConnection;132;0;125;0
WireConnection;132;2;123;0
WireConnection;134;0;147;0
WireConnection;4;0;8;0
WireConnection;5;0;14;0
WireConnection;11;0;13;0
WireConnection;135;0;130;0
WireConnection;2;0;26;0
WireConnection;63;0;62;1
WireConnection;63;1;62;0
WireConnection;64;0;189;2
WireConnection;126;0;131;0
WireConnection;133;0;132;0
WireConnection;148;0;182;0
WireConnection;154;0;135;0
WireConnection;154;1;148;0
WireConnection;154;2;181;2
WireConnection;152;0;126;0
WireConnection;152;1;148;0
WireConnection;152;2;181;2
WireConnection;159;0;11;0
WireConnection;159;1;181;1
WireConnection;153;0;134;0
WireConnection;153;1;148;0
WireConnection;153;2;181;2
WireConnection;66;0;60;0
WireConnection;160;0;2;0
WireConnection;160;1;181;1
WireConnection;155;0;133;0
WireConnection;155;1;148;0
WireConnection;155;2;181;2
WireConnection;163;0;4;0
WireConnection;163;1;181;1
WireConnection;65;0;63;0
WireConnection;65;1;64;0
WireConnection;161;0;5;0
WireConnection;161;1;181;1
WireConnection;70;0;66;0
WireConnection;70;1;67;0
WireConnection;69;0;65;0
WireConnection;22;0;161;0
WireConnection;22;1;163;0
WireConnection;17;0;159;0
WireConnection;17;1;160;0
WireConnection;143;0;154;0
WireConnection;143;1;155;0
WireConnection;138;0;152;0
WireConnection;138;1;153;0
WireConnection;73;0;68;3
WireConnection;73;1;68;4
WireConnection;20;0;17;0
WireConnection;144;0;143;0
WireConnection;139;0;138;0
WireConnection;21;0;22;0
WireConnection;72;0;68;1
WireConnection;72;1;68;2
WireConnection;74;0;70;0
WireConnection;74;1;69;0
WireConnection;77;0;74;0
WireConnection;77;1;72;0
WireConnection;77;2;73;0
WireConnection;140;0;139;0
WireConnection;41;0;38;3
WireConnection;41;1;38;4
WireConnection;76;0;101;0
WireConnection;35;0;34;1
WireConnection;35;1;34;2
WireConnection;40;0;38;1
WireConnection;40;1;38;2
WireConnection;24;0;20;0
WireConnection;145;0;144;0
WireConnection;23;0;21;0
WireConnection;78;0;77;0
WireConnection;78;2;76;0
WireConnection;37;0;35;0
WireConnection;37;1;40;0
WireConnection;37;2;41;0
WireConnection;149;0;140;0
WireConnection;149;1;145;0
WireConnection;178;0;176;3
WireConnection;178;1;176;4
WireConnection;177;0;176;1
WireConnection;177;1;176;2
WireConnection;44;0;43;0
WireConnection;25;0;23;0
WireConnection;25;1;24;0
WireConnection;175;0;164;0
WireConnection;175;1;177;0
WireConnection;175;2;178;0
WireConnection;42;0;37;0
WireConnection;42;2;44;0
WireConnection;105;0;66;0
WireConnection;105;1;106;0
WireConnection;173;0;25;0
WireConnection;81;1;78;0
WireConnection;151;0;149;0
WireConnection;186;0;181;4
WireConnection;36;1;42;0
WireConnection;150;0;151;0
WireConnection;150;1;173;0
WireConnection;179;0;175;0
WireConnection;179;2;180;0
WireConnection;170;0;105;0
WireConnection;170;1;81;1
WireConnection;184;0;181;3
WireConnection;168;0;170;0
WireConnection;168;1;186;0
WireConnection;165;1;179;0
WireConnection;46;0;45;1
WireConnection;46;1;45;2
WireConnection;46;2;45;3
WireConnection;158;0;150;0
WireConnection;185;0;184;0
WireConnection;193;0;192;1
WireConnection;193;1;192;2
WireConnection;193;2;192;3
WireConnection;48;0;36;1
WireConnection;48;1;36;2
WireConnection;48;2;36;3
WireConnection;49;0;46;0
WireConnection;49;1;48;0
WireConnection;49;2;193;0
WireConnection;166;0;165;1
WireConnection;166;1;185;0
WireConnection;117;0;81;0
WireConnection;117;1;118;0
WireConnection;171;0;168;0
WireConnection;171;1;158;0
WireConnection;172;0;168;0
WireConnection;172;1;151;0
WireConnection;156;0;49;0
WireConnection;156;1;117;0
WireConnection;156;2;171;0
WireConnection;51;0;45;4
WireConnection;51;1;172;0
WireConnection;51;2;36;4
WireConnection;51;3;166;0
WireConnection;51;4;192;4
WireConnection;50;0;156;0
WireConnection;50;3;51;0
WireConnection;1;0;50;0
ASEEND*/
//CHKSM=642D94D87133593F68167E9D19BA7782F0833486
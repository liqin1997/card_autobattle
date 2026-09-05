// Upgrade NOTE: upgraded instancing buffer 'UV' to new syntax.

// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "UV"
{
	Properties
	{
		_maintexture("main texture", 2D) = "white" {}
		_noise("noise", 2D) = "white" {}
		_noise_intensity("noise_intensity", Range( 0 , 1)) = 0
		_scaleoffset("scaleoffset", Vector) = (1,1,0,0)
		_pi("pi", Range( 0 , 2)) = 2
		_power("power", Range( -1 , 1)) = 1
		_rotator("rotator", Range( 0 , 2)) = 0
		_spped_x("spped_x", Float) = 1
		_speedy("speed y", Float) = 1
		_MASK("MASK", 2D) = "white" {}
		_mask_power("mask_power", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Transparent" "Queue"="Transparent"  "RenderPipeline"="UniversalPipeline" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha
		AlphaToMask Off
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
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform sampler2D _maintexture;
			uniform sampler2D _noise;
			uniform float _spped_x;
			uniform float _speedy;
			uniform sampler2D _MASK;
			uniform float _mask_power;
			UNITY_INSTANCING_BUFFER_START(UV)
				UNITY_DEFINE_INSTANCED_PROP(half4, _scaleoffset)
#define _scaleoffset_arr UV
				UNITY_DEFINE_INSTANCED_PROP(float4, _MASK_ST)
#define _MASK_ST_arr UV
				UNITY_DEFINE_INSTANCED_PROP(float, _rotator)
#define _rotator_arr UV
				UNITY_DEFINE_INSTANCED_PROP(float, _power)
#define _power_arr UV
				UNITY_DEFINE_INSTANCED_PROP(float, _pi)
#define _pi_arr UV
				UNITY_DEFINE_INSTANCED_PROP(float, _noise_intensity)
#define _noise_intensity_arr UV
			UNITY_INSTANCING_BUFFER_END(UV)

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				
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

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				float2 texCoord4 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult41 = (float2(_spped_x , _speedy));
				float2 texCoord15 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float _rotator_Instance = UNITY_ACCESS_INSTANCED_PROP(_rotator_arr, _rotator);
				float cos39 = cos( ( ( ( 1.0 - length( (texCoord15*2.0 + -1.0) ) ) * 2.0 * _rotator_Instance ) * UNITY_PI ) );
				float sin39 = sin( ( ( ( 1.0 - length( (texCoord15*2.0 + -1.0) ) ) * 2.0 * _rotator_Instance ) * UNITY_PI ) );
				float2 rotator39 = mul( texCoord15 - float2( 0.5,0.5 ) , float2x2( cos39 , -sin39 , sin39 , cos39 )) + float2( 0.5,0.5 );
				float2 temp_output_21_0 = (rotator39*2.0 + -1.0);
				float _power_Instance = UNITY_ACCESS_INSTANCED_PROP(_power_arr, _power);
				float2 break22 = temp_output_21_0;
				float _pi_Instance = UNITY_ACCESS_INSTANCED_PROP(_pi_arr, _pi);
				float2 appendResult27 = (float2(pow( length( temp_output_21_0 ) , _power_Instance ) , ( ( atan2( break22.y , break22.x ) / ( _pi_Instance * UNITY_PI ) ) + 0.5 )));
				half4 _scaleoffset_Instance = UNITY_ACCESS_INSTANCED_PROP(_scaleoffset_arr, _scaleoffset);
				float2 appendResult32 = (float2(_scaleoffset_Instance.x , _scaleoffset_Instance.y));
				float2 appendResult33 = (float2(_scaleoffset_Instance.z , _scaleoffset_Instance.w));
				float2 panner8 = ( 1.0 * _Time.y * appendResult41 + (appendResult27*appendResult32 + appendResult33));
				float2 temp_cast_0 = (tex2D( _noise, panner8 ).r).xx;
				float _noise_intensity_Instance = UNITY_ACCESS_INSTANCED_PROP(_noise_intensity_arr, _noise_intensity);
				float2 lerpResult6 = lerp( texCoord4 , temp_cast_0 , _noise_intensity_Instance);
				float4 tex2DNode2 = tex2D( _maintexture, lerpResult6 );
				float4 _MASK_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_MASK_ST_arr, _MASK_ST);
				float2 uv_MASK = i.ase_texcoord1.xy * _MASK_ST_Instance.xy + _MASK_ST_Instance.zw;
				float4 appendResult53 = (float4((tex2DNode2).rgb , ( tex2DNode2.a * tex2D( _MASK, uv_MASK ).r * _mask_power )));
				
				
				finalColor = appendResult53;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18935
0;49.6;1957;1075;4449.36;293.4903;1.204818;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;15;-3987.885,84.65462;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;46;-4166.482,440.3474;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LengthOpNode;47;-3847.98,435.616;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;49;-3458.947,811.1278;Inherit;False;InstancedProperty;_rotator;rotator;6;0;Create;True;0;0;0;False;0;False;0;0;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;48;-3568.458,429.4547;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;50;-3353.52,529.9847;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;2;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PiNode;44;-3325.347,300.5511;Inherit;False;1;0;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;39;-3387.559,133.025;Inherit;False;3;0;FLOAT2;0.5,0.5;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;21;-3069.532,84.49097;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;34;-2712.931,691.1011;Inherit;False;InstancedProperty;_pi;pi;4;0;Create;True;0;0;0;False;0;False;2;2;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;22;-2854.532,299.491;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ATan2OpNode;29;-2633.943,329.6201;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PiNode;25;-2587.532,592.4909;Inherit;False;1;0;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;24;-2294.531,360.491;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;16;-2776.252,29.13867;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;37;-2471.793,215.9492;Inherit;False;InstancedProperty;_power;power;5;0;Create;True;0;0;0;False;0;False;1;1;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;31;-1826.058,478.8925;Half;False;InstancedProperty;_scaleoffset;scaleoffset;3;0;Create;True;0;0;0;False;0;False;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;26;-2070.531,360.491;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;36;-2403.332,70.828;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;42;-1241.994,397.0672;Inherit;False;Property;_spped_x;spped_x;7;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;32;-1736.058,350.8925;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;33;-1553.058,550.8925;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;27;-1959.325,143.7261;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;43;-1247.994,509.0672;Inherit;False;Property;_speedy;speed y;8;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;41;-1015.994,317.0672;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;13;-1646.744,-26.22024;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;8;-814.4819,227.6052;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;4;-692,-98.5;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;12;-489.0341,521.6717;Inherit;True;InstancedProperty;_noise_intensity;noise_intensity;2;0;Create;True;0;0;0;False;0;False;0;0.21;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;3;-593.2,215.9;Inherit;True;Property;_noise;noise;1;0;Create;True;0;0;0;False;0;False;-1;None;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;6;-166.9675,2.125179;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;2;80,-265.5;Inherit;True;Property;_maintexture;main texture;0;0;Create;True;0;0;0;False;0;False;-1;None;84d2065fb5a7631498e52c89d8241193;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;56;437.9124,385.6409;Inherit;False;Property;_mask_power;mask_power;10;0;Create;True;0;0;0;False;0;False;0;1.14;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;51;196.9124,106.1409;Inherit;True;Property;_MASK;MASK;9;0;Create;True;0;0;0;False;0;False;-1;None;95ef4804fe0be4c999ddaa383536cde8;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;54;472.9124,-242.8591;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;55;579.9124,62.64087;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;53;761.9124,-260.8591;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1030.064,-258.3763;Float;False;True;-1;2;ASEMaterialInspector;100;1;UV;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;46;0;15;0
WireConnection;47;0;46;0
WireConnection;48;0;47;0
WireConnection;50;0;48;0
WireConnection;50;2;49;0
WireConnection;44;0;50;0
WireConnection;39;0;15;0
WireConnection;39;2;44;0
WireConnection;21;0;39;0
WireConnection;22;0;21;0
WireConnection;29;0;22;1
WireConnection;29;1;22;0
WireConnection;25;0;34;0
WireConnection;24;0;29;0
WireConnection;24;1;25;0
WireConnection;16;0;21;0
WireConnection;26;0;24;0
WireConnection;36;0;16;0
WireConnection;36;1;37;0
WireConnection;32;0;31;1
WireConnection;32;1;31;2
WireConnection;33;0;31;3
WireConnection;33;1;31;4
WireConnection;27;0;36;0
WireConnection;27;1;26;0
WireConnection;41;0;42;0
WireConnection;41;1;43;0
WireConnection;13;0;27;0
WireConnection;13;1;32;0
WireConnection;13;2;33;0
WireConnection;8;0;13;0
WireConnection;8;2;41;0
WireConnection;3;1;8;0
WireConnection;6;0;4;0
WireConnection;6;1;3;1
WireConnection;6;2;12;0
WireConnection;2;1;6;0
WireConnection;54;0;2;0
WireConnection;55;0;2;4
WireConnection;55;1;51;1
WireConnection;55;2;56;0
WireConnection;53;0;54;0
WireConnection;53;3;55;0
WireConnection;1;0;53;0
ASEEND*/
//CHKSM=81F14FBBDFFBE9B4F3D2B05084607AA74158B116
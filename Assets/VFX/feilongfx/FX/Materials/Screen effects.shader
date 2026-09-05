// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Screen effects"
{
	Properties
	{
		_Main_tex("Main_tex", 2D) = "white" {}
		_mask_tex("mask_tex", 2D) = "white" {}
		_alpha("alpha", Float) = 1
		_mask_scale("mask_scale", Float) = 1
		_Scale("Scale", Float) = 1
		_Color("Color", Color) = (0,0,0,0)
		_offset("offset", Vector) = (1,1,0,0)
		_Vector0("Vector 0", Vector) = (1,1,0,0)
		_panner("panner", Vector) = (1,1,0,0)
		_RGB_MASK("RGB_MASK", Vector) = (0,0,0,0)
		_pi("pi", Float) = 0
		[Enum(off,0,on,1)]_int_0("int_0", Float) = 0

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" "Queue"="Transparent"  "RenderPipeline"="UniversalPipeline" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha
		AlphaToMask Off
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

			uniform sampler2D _Main_tex;
			uniform float4 _panner;
			uniform float _pi;
			uniform float _int_0;
			uniform float4 _offset;
			uniform float4 _Color;
			uniform float _Scale;
			uniform sampler2D _mask_tex;
			uniform float4 _Vector0;
			uniform float _mask_scale;
			uniform float4 _RGB_MASK;
			uniform float _alpha;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float4 ase_clipPos = UnityObjectToClipPos(v.vertex);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord1 = screenPos;
				
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
				float mulTime18 = _Time.y * _panner.z;
				float2 appendResult17 = (float2(_panner.x , _panner.y));
				float4 screenPos = i.ase_texcoord1;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 appendResult10 = (float2(ase_screenPosNorm.x , ase_screenPosNorm.y));
				float2 appendResult35 = (float2(ase_screenPosNorm.x , ase_screenPosNorm.y));
				float2 temp_output_38_0 = (appendResult35*2.0 + -1.0);
				float2 break40 = temp_output_38_0;
				float2 appendResult43 = (float2(length( temp_output_38_0 ) , ( atan2( break40.y , break40.x ) * _pi )));
				float2 lerpResult51 = lerp( appendResult10 , appendResult43 , _int_0);
				float2 appendResult14 = (float2(_offset.x , _offset.y));
				float2 appendResult15 = (float2(_offset.z , _offset.w));
				float2 panner11 = ( ( mulTime18 + _panner.w ) * appendResult17 + (lerpResult51*appendResult14 + appendResult15));
				float4 tex2DNode2 = tex2D( _Main_tex, panner11 );
				float2 appendResult29 = (float2(_Vector0.x , _Vector0.y));
				float2 appendResult31 = (float2(_Vector0.z , _Vector0.w));
				float4 appendResult6 = (float4(( tex2DNode2 * _Color * _Scale ).rgb , ( ( tex2D( _mask_tex, (appendResult10*appendResult29 + appendResult31) ).g * _mask_scale ) * ( ( _RGB_MASK.x * tex2DNode2.r ) + ( _RGB_MASK.y * tex2DNode2.g ) + ( _RGB_MASK.z * tex2DNode2.b ) + ( _RGB_MASK.w * tex2DNode2.a ) ) * _alpha )));
				
				
				finalColor = appendResult6;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18935
0;11.2;1957;1118;1072.41;246.5643;1;True;True
Node;AmplifyShaderEditor.ScreenPosInputsNode;8;-3552.364,-437.8615;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;35;-3507.071,-72.68401;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;38;-3220.551,-59.43404;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;40;-3494.107,282.5122;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;45;-3212.249,592.0694;Inherit;False;Property;_pi;pi;10;0;Create;True;0;0;0;False;0;False;0;1.27;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ATan2OpNode;41;-3315.846,289.239;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;44;-3026.026,317.481;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;37;-2786.669,-43.73812;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;10;-2361.939,-299.5381;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;13;-1888.93,-33.19323;Inherit;False;Property;_offset;offset;6;0;Create;True;0;0;0;False;0;False;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;52;-2211.097,-594.3404;Inherit;False;Property;_int_0;int_0;11;1;[Enum];Create;True;0;2;off;0;on;1;0;True;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;43;-2694.703,302.9042;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;16;-1390.908,-69.8902;Inherit;False;Property;_panner;panner;8;0;Create;True;0;0;0;False;0;False;1,1,0,0;3,2,-1.5,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;15;-1696.158,81.80672;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;18;-1176.908,-6.890198;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;51;-1947.197,-515.0402;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;14;-1712.158,-77.19323;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;17;-1164.908,-109.8902;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;30;-1308.167,945.3932;Inherit;False;Property;_Vector0;Vector 0;7;0;Create;True;0;0;0;False;0;False;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;12;-1373.158,-321.1933;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;19;-1006.908,17.1098;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;11;-971.998,-313.1724;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;29;-1131.395,901.3932;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;31;-1115.395,1060.393;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;28;-895.3954,764.3931;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;26;-498.834,372.6694;Inherit;False;Property;_RGB_MASK;RGB_MASK;9;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,1;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;2;-740.9999,-91.30001;Inherit;True;Property;_Main_tex;Main_tex;0;0;Create;True;0;0;0;False;0;False;-1;None;87d4b0a20e0c3fa479f2918c36245aac;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;-238.934,281.1695;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;22;-242.934,410.1695;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-238.934,167.1695;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;32;-619.5527,751.2968;Inherit;True;Property;_mask_tex;mask_tex;1;0;Create;True;0;0;0;False;0;False;-1;None;774583b1081b6464486986fd8e317014;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;33;-451.8254,1009.699;Inherit;False;Property;_mask_scale;mask_scale;3;0;Create;True;0;0;0;False;0;False;1;0.34;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;23;-249.934,531.1695;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;24;-6.93396,265.1695;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;5;-643.1,283.7001;Inherit;False;Property;_Scale;Scale;4;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;-23.92539,729.7989;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;7;120.1001,1034.4;Inherit;False;Property;_alpha;alpha;2;0;Create;True;0;0;0;False;0;False;1;1.54;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;4;-703.8998,109.0999;Inherit;False;Property;_Color;Color;5;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0.7134724,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;3;-370.6001,-48.7;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;48;241.0808,313.5232;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;6;167.2,-48.59999;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;499.6,-6.8;Float;False;True;-1;2;ASEMaterialInspector;100;1;Screen effects;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;2;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;35;0;8;1
WireConnection;35;1;8;2
WireConnection;38;0;35;0
WireConnection;40;0;38;0
WireConnection;41;0;40;1
WireConnection;41;1;40;0
WireConnection;44;0;41;0
WireConnection;44;1;45;0
WireConnection;37;0;38;0
WireConnection;10;0;8;1
WireConnection;10;1;8;2
WireConnection;43;0;37;0
WireConnection;43;1;44;0
WireConnection;15;0;13;3
WireConnection;15;1;13;4
WireConnection;18;0;16;3
WireConnection;51;0;10;0
WireConnection;51;1;43;0
WireConnection;51;2;52;0
WireConnection;14;0;13;1
WireConnection;14;1;13;2
WireConnection;17;0;16;1
WireConnection;17;1;16;2
WireConnection;12;0;51;0
WireConnection;12;1;14;0
WireConnection;12;2;15;0
WireConnection;19;0;18;0
WireConnection;19;1;16;4
WireConnection;11;0;12;0
WireConnection;11;2;17;0
WireConnection;11;1;19;0
WireConnection;29;0;30;1
WireConnection;29;1;30;2
WireConnection;31;0;30;3
WireConnection;31;1;30;4
WireConnection;28;0;10;0
WireConnection;28;1;29;0
WireConnection;28;2;31;0
WireConnection;2;1;11;0
WireConnection;21;0;26;2
WireConnection;21;1;2;2
WireConnection;22;0;26;3
WireConnection;22;1;2;3
WireConnection;20;0;26;1
WireConnection;20;1;2;1
WireConnection;32;1;28;0
WireConnection;23;0;26;4
WireConnection;23;1;2;4
WireConnection;24;0;20;0
WireConnection;24;1;21;0
WireConnection;24;2;22;0
WireConnection;24;3;23;0
WireConnection;34;0;32;2
WireConnection;34;1;33;0
WireConnection;3;0;2;0
WireConnection;3;1;4;0
WireConnection;3;2;5;0
WireConnection;48;0;34;0
WireConnection;48;1;24;0
WireConnection;48;2;7;0
WireConnection;6;0;3;0
WireConnection;6;3;48;0
WireConnection;1;0;6;0
ASEEND*/
//CHKSM=137D762C4D178050BBA9F10A0D205407EE67D7A4
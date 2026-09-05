// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_trail_add"
{
	Properties
	{
		_TextureSample0("主纹理", 2D) = "white" {}
		_scale("缩放", Vector) = (1,1,0,0)
		_scale1("缩放", Vector) = (1,1,0,0)
		_offset("偏移", Vector) = (0,0,0,0)
		_offset1("偏移", Vector) = (0,0,0,0)
		_speed_time("速度与时间", Vector) = (1,1,1,0)
		_speed_time1("速度与时间", Vector) = (1,1,1,0)
		_TextureSample1("遮罩", 2D) = "white" {}
		[HDR]_Color0("主颜色", Color) = (1,1,1,1)
		_Float0("遮罩强度", Float) = 0
		_TextureSample2("Texture Sample 2", 2D) = "white" {}
		[Enum(vertexoff,0,vertexon,1)]_vertex_offon("vertex_off/on", Float) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" "Queue"="Transparent"  "RenderPipeline"="UniversalPipeline" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend One One
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
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_FRAG_COLOR


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
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform sampler2D _TextureSample2;
			uniform float4 _speed_time1;
			uniform float2 _scale1;
			uniform float2 _offset1;
			uniform float _vertex_offon;
			uniform float4 _Color0;
			uniform sampler2D _TextureSample0;
			uniform float4 _speed_time;
			uniform float2 _scale;
			uniform float2 _offset;
			uniform sampler2D _TextureSample1;
			uniform float4 _TextureSample1_ST;
			uniform float _Float0;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float3 temp_cast_0 = (0.0).xxx;
				float mulTime63 = _Time.y * _speed_time1.z;
				float2 appendResult66 = (float2(mulTime63 , _speed_time1.w));
				float2 appendResult67 = (float2(_speed_time1.x , _speed_time1.y));
				float2 texCoord62 = v.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult64 = (float2(_scale1.x , _scale1.y));
				float2 appendResult65 = (float2(_offset1.x , _offset1.y));
				float2 panner69 = ( appendResult66.x * appendResult67 + (texCoord62*appendResult64 + appendResult65));
				float3 appendResult51 = (float3(v.vertex.xyz.x , ( v.vertex.xyz.y + tex2Dlod( _TextureSample2, float4( panner69, 0, 0.0) ).r ) , v.vertex.xyz.z));
				float3 lerpResult75 = lerp( temp_cast_0 , appendResult51 , _vertex_offon);
				
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_color = v.color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = lerpResult75;
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
				float mulTime13 = _Time.y * _speed_time.z;
				float2 appendResult10 = (float2(mulTime13 , _speed_time.w));
				float2 appendResult8 = (float2(_speed_time.x , _speed_time.y));
				float2 texCoord2 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult17 = (float2(_scale.x , _scale.y));
				float2 appendResult18 = (float2(_offset.x , _offset.y));
				float2 panner5 = ( appendResult10.x * appendResult8 + (texCoord2*appendResult17 + appendResult18));
				float2 uv_TextureSample1 = i.ase_texcoord1.xy * _TextureSample1_ST.xy + _TextureSample1_ST.zw;
				float4 temp_output_28_0 = ( _Color0 * ( tex2D( _TextureSample0, panner5 ).a * ( tex2D( _TextureSample1, uv_TextureSample1 ) * _Float0 ) ) * i.ase_color * i.ase_color.a );
				
				
				finalColor = temp_output_28_0;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18935
0;23.2;1957;1100;1639.462;781.5531;1;True;True
Node;AmplifyShaderEditor.Vector2Node;59;-2688.207,-1421.167;Inherit;False;Property;_scale1;缩放;2;0;Create;False;0;0;0;False;0;False;1,1;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector4Node;61;-2220.659,-783.6044;Inherit;False;Property;_speed_time1;速度与时间;6;0;Create;False;0;0;0;False;0;False;1,1,1,0;1,1,1,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;60;-2677.868,-1081.134;Inherit;False;Property;_offset1;偏移;4;0;Create;False;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;15;-2763.494,-181.2307;Inherit;False;Property;_scale;缩放;1;0;Create;False;0;0;0;False;0;False;1,1;1,0.82;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;64;-2387.231,-1330.415;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;62;-2503.99,-1602.483;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;9;-2295.947,456.3317;Inherit;False;Property;_speed_time;速度与时间;5;0;Create;False;0;0;0;False;0;False;1,1,1,0;0.3,0,1,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;16;-2753.155,158.8025;Inherit;False;Property;_offset;偏移;3;0;Create;False;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DynamicAppendNode;65;-2426.289,-1096.067;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;63;-2020.776,-906.5219;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;68;-2035.71,-1541.787;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;67;-2047.198,-1104.109;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;2;-2579.277,-362.5472;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;66;-1786.428,-889.2902;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;13;-2096.064,333.4142;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;18;-2501.576,143.8687;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;17;-2462.518,-90.47855;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;6;-2110.998,-301.8507;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;8;-2122.486,135.8274;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;10;-1861.716,350.6459;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;69;-1737.334,-1301.501;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;5;-1812.622,-61.56448;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;30;-1049.081,434.317;Inherit;False;Property;_Float0;遮罩强度;9;0;Create;False;0;0;0;False;0;False;0;0.75;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;19;-1387.975,301.2198;Inherit;True;Property;_TextureSample1;遮罩;7;0;Create;False;0;0;0;False;0;False;-1;396f38a210576e54e859be3bfc253e2d;3cf3aaba8417bc844b9eff51e27f422a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;58;-1498.557,-1193.011;Inherit;True;Property;_TextureSample2;Texture Sample 2;10;0;Create;True;0;0;0;False;0;False;-1;None;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PosVertexDataNode;44;-1269.509,-1520.011;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;3;-1394.771,-138.1761;Inherit;True;Property;_TextureSample0;主纹理;0;0;Create;False;0;0;0;False;0;False;-1;6642966ef7e3a3a43ba4dc63f940cf31;93528b6bc01c80c4ea25089f150ef884;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-971.0812,238.317;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;56;-916.2688,-1367.219;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;-988.7539,-67.71588;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexColorNode;31;-1124.19,-487.5928;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;76;-585.8999,-480.0455;Inherit;False;Constant;_Float1;Float 1;11;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;51;-472.846,-1363.743;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;77;-500.1071,-318.9227;Inherit;False;Property;_vertex_offon;vertex_off/on;11;1;[Enum];Create;True;0;2;vertexoff;0;vertexon;1;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;27;-864.7539,-512.7159;Inherit;False;Property;_Color0;主颜色;8;1;[HDR];Create;False;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;73;-665.9948,216.2142;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;72;-448.895,104.4142;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;-712.3538,-106.3159;Inherit;True;4;4;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;75;-287.718,-542.8207;Inherit;True;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;74;-217.4949,168.1142;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;-49,-52;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_trail_add;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;4;1;False;-1;1;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;2;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;64;0;59;1
WireConnection;64;1;59;2
WireConnection;65;0;60;1
WireConnection;65;1;60;2
WireConnection;63;0;61;3
WireConnection;68;0;62;0
WireConnection;68;1;64;0
WireConnection;68;2;65;0
WireConnection;67;0;61;1
WireConnection;67;1;61;2
WireConnection;66;0;63;0
WireConnection;66;1;61;4
WireConnection;13;0;9;3
WireConnection;18;0;16;1
WireConnection;18;1;16;2
WireConnection;17;0;15;1
WireConnection;17;1;15;2
WireConnection;6;0;2;0
WireConnection;6;1;17;0
WireConnection;6;2;18;0
WireConnection;8;0;9;1
WireConnection;8;1;9;2
WireConnection;10;0;13;0
WireConnection;10;1;9;4
WireConnection;69;0;68;0
WireConnection;69;2;67;0
WireConnection;69;1;66;0
WireConnection;5;0;6;0
WireConnection;5;2;8;0
WireConnection;5;1;10;0
WireConnection;58;1;69;0
WireConnection;3;1;5;0
WireConnection;29;0;19;0
WireConnection;29;1;30;0
WireConnection;56;0;44;2
WireConnection;56;1;58;1
WireConnection;24;0;3;4
WireConnection;24;1;29;0
WireConnection;51;0;44;1
WireConnection;51;1;56;0
WireConnection;51;2;44;3
WireConnection;72;0;28;0
WireConnection;28;0;27;0
WireConnection;28;1;24;0
WireConnection;28;2;31;0
WireConnection;28;3;31;4
WireConnection;75;0;76;0
WireConnection;75;1;51;0
WireConnection;75;2;77;0
WireConnection;74;0;72;0
WireConnection;1;0;28;0
WireConnection;1;1;75;0
ASEEND*/
//CHKSM=1C3AD636AAC32FA0472BB5EB52817AC13773B1A4
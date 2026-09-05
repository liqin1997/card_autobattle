// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_flow_only_particle_zwrite"
{
	Properties
	{
		_maintex("maintex", 2D) = "white" {}
		_main_tex_speed_time("main_tex_speed_time", Vector) = (0,0,0,0)
		_maibtex_scale("maibtex_scale", Vector) = (0,0,0,0)
		_main_tex_offest("main_tex_offest", Vector) = (0,0,0,0)
		_mask("mask", 2D) = "white" {}
		_mask_speed_time("mask_speed_time", Vector) = (0,0,0,0)
		_maskscale("mask scale", Vector) = (0,0,0,0)
		_maskoffset("mask offset", Vector) = (0,0,0,0)

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque"  "RenderPipeline"="UniversalPipeline" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend One One
		Cull Off
		ColorMask RGBA
		ZWrite On
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
				float4 ase_color : COLOR;
			};

			uniform sampler2D _maintex;
			uniform float4 _main_tex_speed_time;
			uniform float2 _maibtex_scale;
			uniform float2 _main_tex_offest;
			uniform sampler2D _mask;
			uniform float4 _mask_speed_time;
			uniform float2 _maskscale;
			uniform float2 _maskoffset;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord.xy = v.ase_texcoord.xy;
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
				float mulTime16 = _Time.y * _main_tex_speed_time.z;
				float2 appendResult13 = (float2(mulTime16 , _main_tex_speed_time.w));
				float2 appendResult14 = (float2(_main_tex_speed_time.x , _main_tex_speed_time.y));
				float2 uv02 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult8 = (float2(_maibtex_scale.x , _maibtex_scale.y));
				float2 appendResult10 = (float2(_main_tex_offest.x , _main_tex_offest.y));
				float2 panner3 = ( appendResult13.x * appendResult14 + (uv02*appendResult8 + appendResult10));
				float4 tex2DNode5 = tex2D( _maintex, panner3 );
				float4 appendResult33 = (float4(tex2DNode5.r , tex2DNode5.g , tex2DNode5.b , 0.0));
				float mulTime24 = _Time.y * _mask_speed_time.z;
				float2 appendResult25 = (float2(mulTime24 , _mask_speed_time.w));
				float2 appendResult26 = (float2(_mask_speed_time.x , _mask_speed_time.y));
				float2 uv017 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult19 = (float2(_maskscale.x , _maskscale.y));
				float2 appendResult20 = (float2(_maskoffset.x , _maskoffset.y));
				float2 panner23 = ( appendResult25.x * appendResult26 + (uv017*appendResult19 + appendResult20));
				float4 appendResult51 = (float4(i.ase_color.r , i.ase_color.g , i.ase_color.b , 0.0));
				
				
				finalColor = ( appendResult33 * ( tex2DNode5.a * tex2D( _mask, panner23 ).r * i.ase_color.a ) * appendResult51 );
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
0;12;1957;1111;1918.556;789.6064;1.92265;True;True
Node;AmplifyShaderEditor.Vector2Node;11;-1425.018,333.5841;Inherit;False;Property;_main_tex_offest;main_tex_offest;3;0;Create;True;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;9;-1402.089,172.0868;Inherit;False;Property;_maibtex_scale;maibtex_scale;2;0;Create;True;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector4Node;12;-993.9797,165.5651;Inherit;False;Property;_main_tex_speed_time;main_tex_speed_time;1;0;Create;True;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;22;-1475.681,879.5167;Inherit;False;Property;_maskoffset;mask offset;7;0;Create;True;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector4Node;27;-1027.628,700.5598;Inherit;False;Property;_mask_speed_time;mask_speed_time;5;0;Create;True;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;21;-1452.752,718.0195;Inherit;False;Property;_maskscale;mask scale;6;0;Create;True;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleTimeNode;24;-855.6814,756.5168;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;19;-1229.151,695.9195;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;20;-1243.681,858.5167;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;17;-1405.846,530.1847;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;10;-1193.018,312.5841;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;8;-1178.488,149.9868;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;16;-729.0179,216.5841;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;2;-1376.378,-46.02723;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;4;-1011.365,-18.41565;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;13;-533.0179,253.5841;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;14;-737.2877,90.83197;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;18;-1062.028,527.517;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;26;-814.9513,637.7646;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;25;-641.6814,805.5167;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;3;-615.3655,-64.41565;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;23;-662.0289,498.517;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;7;-390.4884,353.8868;Inherit;True;Property;_mask;mask;4;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;5;-380.3655,-59.41565;Inherit;True;Property;_maintex;maintex;0;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;37;-34.93627,-314.8427;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;33;6.215277,-104.0744;Inherit;True;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-0.189198,116.6218;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;51;217.1568,-284.163;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;35;306.1369,-75.36118;Inherit;True;3;3;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1024.028,-199.6349;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_flow_only_particle_zwrite;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;4;1;False;-1;1;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;2;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;RenderType=Opaque=RenderType;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;0;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;24;0;27;3
WireConnection;19;0;21;1
WireConnection;19;1;21;2
WireConnection;20;0;22;1
WireConnection;20;1;22;2
WireConnection;10;0;11;1
WireConnection;10;1;11;2
WireConnection;8;0;9;1
WireConnection;8;1;9;2
WireConnection;16;0;12;3
WireConnection;4;0;2;0
WireConnection;4;1;8;0
WireConnection;4;2;10;0
WireConnection;13;0;16;0
WireConnection;13;1;12;4
WireConnection;14;0;12;1
WireConnection;14;1;12;2
WireConnection;18;0;17;0
WireConnection;18;1;19;0
WireConnection;18;2;20;0
WireConnection;26;0;27;1
WireConnection;26;1;27;2
WireConnection;25;0;24;0
WireConnection;25;1;27;4
WireConnection;3;0;4;0
WireConnection;3;2;14;0
WireConnection;3;1;13;0
WireConnection;23;0;18;0
WireConnection;23;2;26;0
WireConnection;23;1;25;0
WireConnection;7;1;23;0
WireConnection;5;1;3;0
WireConnection;33;0;5;1
WireConnection;33;1;5;2
WireConnection;33;2;5;3
WireConnection;31;0;5;4
WireConnection;31;1;7;1
WireConnection;31;2;37;4
WireConnection;51;0;37;1
WireConnection;51;1;37;2
WireConnection;51;2;37;3
WireConnection;35;0;33;0
WireConnection;35;1;31;0
WireConnection;35;2;51;0
WireConnection;1;0;35;0
ASEEND*/
//CHKSM=3014E8F4B782AFBC27D56CAF26DF24F4D86F891C
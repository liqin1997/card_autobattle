// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_flow_only_particle_alpha_blend"
{
	Properties
	{
		_maintex("maintex", 2D) = "white" {}
		_main_tex_speed_time("main_tex_speed_time", Vector) = (0,0,1,0)
		_maibtex_scale("maibtex_scale", Vector) = (1,1,0,0)
		_main_tex_offest("main_tex_offest", Vector) = (0,0,0,0)
		_mask("mask", 2D) = "white" {}
		_mask_speed_time("mask_speed_time", Vector) = (0,0,1,0)
		_maskscale("mask scale", Vector) = (1,1,0,0)
		_maskoffset("mask offset", Vector) = (0,0,0,0)

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

				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_color = v.color;
				
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
				float mulTime16 = _Time.y * _main_tex_speed_time.z;
				float2 appendResult13 = (float2(mulTime16 , _main_tex_speed_time.w));
				float2 appendResult14 = (float2(_main_tex_speed_time.x , _main_tex_speed_time.y));
				float2 texCoord2 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult8 = (float2(_maibtex_scale.x , _maibtex_scale.y));
				float2 appendResult10 = (float2(_main_tex_offest.x , _main_tex_offest.y));
				float2 panner3 = ( appendResult13.x * appendResult14 + (texCoord2*appendResult8 + appendResult10));
				float4 tex2DNode5 = tex2D( _maintex, panner3 );
				float4 appendResult33 = (float4(tex2DNode5.r , tex2DNode5.g , tex2DNode5.b , 0.0));
				float4 appendResult51 = (float4(i.ase_color.r , i.ase_color.g , i.ase_color.b , 0.0));
				float mulTime24 = _Time.y * _mask_speed_time.z;
				float2 appendResult25 = (float2(mulTime24 , _mask_speed_time.w));
				float2 appendResult26 = (float2(_mask_speed_time.x , _mask_speed_time.y));
				float2 texCoord17 = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult19 = (float2(_maskscale.x , _maskscale.y));
				float2 appendResult20 = (float2(_maskoffset.x , _maskoffset.y));
				float2 panner23 = ( appendResult25.x * appendResult26 + (texCoord17*appendResult19 + appendResult20));
				float4 appendResult54 = (float4((( appendResult33 * appendResult51 )).xyzw.xyz , ( tex2DNode5.a * tex2D( _mask, panner23 ).r * i.ase_color.a )));
				
				
				finalColor = appendResult54;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18935
0;311.2;1957;808;1028.213;480.0067;1.421067;True;True
Node;AmplifyShaderEditor.Vector2Node;11;-1425.018,333.5841;Inherit;False;Property;_main_tex_offest;main_tex_offest;3;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;9;-1402.089,172.0868;Inherit;False;Property;_maibtex_scale;maibtex_scale;2;0;Create;True;0;0;0;False;0;False;1,1;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector4Node;12;-993.9797,165.5651;Inherit;False;Property;_main_tex_speed_time;main_tex_speed_time;1;0;Create;True;0;0;0;False;0;False;0,0,1,0;0,0,1,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;16;-729.0179,216.5841;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;8;-1178.488,149.9868;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;10;-1193.018,312.5841;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;2;-1376.378,-46.02723;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;13;-533.0179,253.5841;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;4;-1011.365,-18.41565;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;14;-737.2877,90.83197;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;22;-1475.681,879.5167;Inherit;False;Property;_maskoffset;mask offset;7;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;21;-1452.752,718.0195;Inherit;False;Property;_maskscale;mask scale;6;0;Create;True;0;0;0;False;0;False;1,1;1,1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector4Node;27;-1027.628,700.5598;Inherit;False;Property;_mask_speed_time;mask_speed_time;5;0;Create;True;0;0;0;False;0;False;0,0,1,0;0,0,1,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;17;-1405.846,530.1847;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;24;-855.6814,756.5168;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;3;-615.3655,-64.41565;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;19;-1229.151,695.9195;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;20;-1243.681,858.5167;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;25;-641.6814,805.5167;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;18;-1062.028,527.517;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;26;-814.9513,637.7646;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;5;-406.2085,-126.177;Inherit;True;Property;_maintex;maintex;0;0;Create;True;0;0;0;False;0;False;-1;None;3c6f67e7554f3a543a0d33d991f2ed80;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;37;-97.39048,-452.6726;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;23;-662.0289,498.517;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;51;165.4706,-406.9178;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;33;-35.77981,-179.4502;Inherit;True;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SamplerNode;7;-390.4884,353.8868;Inherit;True;Property;_mask;mask;4;0;Create;True;0;0;0;False;0;False;-1;None;05b2a1c3e0dafdd48ad0a8453cc5de6c;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;35;329.2774,-208.0846;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;70.87938,157.5401;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;52;536.3822,-322.2682;Inherit;False;True;True;True;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;54;708.3314,-90.63424;Inherit;True;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1024.028,-199.6349;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_flow_only_particle_alpha_blend;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;16;0;12;3
WireConnection;8;0;9;1
WireConnection;8;1;9;2
WireConnection;10;0;11;1
WireConnection;10;1;11;2
WireConnection;13;0;16;0
WireConnection;13;1;12;4
WireConnection;4;0;2;0
WireConnection;4;1;8;0
WireConnection;4;2;10;0
WireConnection;14;0;12;1
WireConnection;14;1;12;2
WireConnection;24;0;27;3
WireConnection;3;0;4;0
WireConnection;3;2;14;0
WireConnection;3;1;13;0
WireConnection;19;0;21;1
WireConnection;19;1;21;2
WireConnection;20;0;22;1
WireConnection;20;1;22;2
WireConnection;25;0;24;0
WireConnection;25;1;27;4
WireConnection;18;0;17;0
WireConnection;18;1;19;0
WireConnection;18;2;20;0
WireConnection;26;0;27;1
WireConnection;26;1;27;2
WireConnection;5;1;3;0
WireConnection;23;0;18;0
WireConnection;23;2;26;0
WireConnection;23;1;25;0
WireConnection;51;0;37;1
WireConnection;51;1;37;2
WireConnection;51;2;37;3
WireConnection;33;0;5;1
WireConnection;33;1;5;2
WireConnection;33;2;5;3
WireConnection;7;1;23;0
WireConnection;35;0;33;0
WireConnection;35;1;51;0
WireConnection;31;0;5;4
WireConnection;31;1;7;1
WireConnection;31;2;37;4
WireConnection;52;0;35;0
WireConnection;54;0;52;0
WireConnection;54;3;31;0
WireConnection;1;0;54;0
ASEEND*/
//CHKSM=CEA8F74083B0E41E0C16405EEAE1F0C658F3A280
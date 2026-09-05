// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "fresnel"
{
	Properties
	{
		_eage_scale("eage_scale", Float) = 0
		_tex_power("tex_power", Float) = 0
		_TextureSample0("Texture Sample 0", 2D) = "white" {}
		_eage_color("eage_color", Color) = (0,0.1795305,0.7924528,0)
		_speed_and_time("speed_and_time", Vector) = (0,0,0,0)
		_screen_color("screen_color", Color) = (1,1,1,1)
		_scale_offset("scale_offset", Vector) = (1,1,0,0)
		_power("power", Float) = 1
		_maincolor("maincolor", Color) = (1,1,1,1)
		_inside_edge_power("inside_edge_power", Float) = 1
		_smooth_step("smooth_step", Vector) = (0,0,0,0)
		_Color0("Color 0", Color) = (1,1,1,1)
		_inside_color("inside_color", Color) = (1,1,1,1)
		_inside_power2("inside_power2", Vector) = (0,1,1,0)
		_dissolve("dissolve", Float) = 1

	}
	
	SubShader
	{
		LOD 0

		Tags { "RenderType"="Opaque"  "RenderPipeline"="UniversalPipeline" }
		
		Pass
		{
            Tags { "LightMode"="SRPDefaultUnlit" }
			Tags { "Queue"="Transparent" }
			Name "First"
			CGINCLUDE
			#pragma target 3.0
			ENDCG
			Blend SrcAlpha OneMinusSrcAlpha
			AlphaToMask Off
			Cull Back
			ColorMask RGBA
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
			#define ASE_NEEDS_FRAG_POSITION


			struct appdata
			{
				float4 vertex : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				float3 ase_normal : NORMAL;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
			};

			uniform sampler2D _TextureSample0;
			uniform float4 _speed_and_time;
			uniform float4 _scale_offset;
			uniform float _tex_power;
			uniform float4 _screen_color;
			uniform float4 _maincolor;
			uniform float _power;
			uniform float _inside_edge_power;
			uniform float2 _smooth_step;
			uniform float4 _Color0;
			uniform float4 _inside_power2;
			uniform float4 _inside_color;
			uniform float _dissolve;
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
				float4 ase_clipPos = UnityObjectToClipPos(v.vertex);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord = screenPos;
				float3 ase_worldNormal = UnityObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord1.xyz = ase_worldNormal;
				float3 ase_worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.ase_texcoord2.xyz = ase_worldPos;
				
				o.ase_texcoord3 = v.vertex;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.w = 0;
				o.ase_texcoord2.w = 0;
				
				v.vertex.xyz +=  float3(0,0,0) ;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				fixed4 finalColor;
				float mulTime57 = _Time.y * _speed_and_time.z;
				float2 appendResult52 = (float2(_speed_and_time.x , _speed_and_time.y));
				float4 screenPos = i.ase_texcoord;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float2 appendResult46 = (float2(ase_grabScreenPosNorm.r , ase_grabScreenPosNorm.g));
				float2 appendResult49 = (float2(_scale_offset.x , _scale_offset.y));
				float2 appendResult50 = (float2(_scale_offset.z , _scale_offset.w));
				float2 panner55 = ( mulTime57 * appendResult52 + (appendResult46*appendResult49 + appendResult50));
				float3 ase_worldNormal = i.ase_texcoord1.xyz;
				float3 ase_worldPos = i.ase_texcoord2.xyz;
				float3 ase_worldViewDir = UnityWorldSpaceViewDir(ase_worldPos);
				ase_worldViewDir = normalize(ase_worldViewDir);
				float dotResult17 = dot( ase_worldNormal , ase_worldViewDir );
				float temp_output_19_0 = ( 1.0 - saturate( dotResult17 ) );
				float4 lerpResult62 = lerp( ( tex2D( _TextureSample0, panner55 ) * _tex_power * _screen_color ) , _maincolor , pow( temp_output_19_0 , _power ));
				float smoothstepResult74 = smoothstep( _smooth_step.x , _smooth_step.y , ( i.ase_texcoord3.xyz.y + 0.81 ));
				float smoothstepResult82 = smoothstep( _inside_power2.x , _inside_power2.y , temp_output_19_0);
				float temp_output_95_0 = ( i.ase_texcoord3.xyz.y + _dissolve );
				float4 appendResult59 = (float4(( lerpResult62 + ( temp_output_19_0 * _inside_edge_power * smoothstepResult74 * _Color0 ) + ( smoothstepResult82 * _inside_color * _inside_power2.z ) ).rgb , temp_output_95_0));
				
				
				finalColor = appendResult59;
				return finalColor;
			}
			ENDCG
		}

		
		Pass
		{
			Name "Second"
			
			CGINCLUDE
			#pragma target 3.0
			ENDCG
			Blend One One
			AlphaToMask Off
			Cull Front
			ColorMask RGBA
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			

			struct appdata
			{
				float4 vertex : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				float3 ase_normal : NORMAL;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_texcoord : TEXCOORD0;
			};

			uniform float _eage_scale;
			uniform float _dissolve;
			uniform float4 _eage_color;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.ase_texcoord = v.vertex;
				
				v.vertex.xyz += ( _eage_scale * v.ase_normal );
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				fixed4 finalColor;
				float temp_output_95_0 = ( i.ase_texcoord.xyz.y + _dissolve );
				
				
				finalColor = ( temp_output_95_0 * _eage_color );
				return finalColor;
			}
			ENDCG
		}
		
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18935
160.8;67.2;1957;950;3779.176;1357.542;3.027757;True;True
Node;AmplifyShaderEditor.PosVertexDataNode;96;116.8334,-482.4656;Inherit;True;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;92;-76.4082,-252.3254;Inherit;False;Property;_dissolve;dissolve;16;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;95;372.4149,-353.1837;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0.81;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;78;-2208.603,-1592.28;Inherit;False;1915.536;1393.289;Comment;19;55;66;54;43;50;65;61;63;64;46;45;52;48;57;49;47;56;58;98;;1,1,1,1;0;0
Node;AmplifyShaderEditor.NormalVertexDataNode;20;-364.0984,629.4494;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;22;-271.5736,272.5314;Inherit;True;Property;_eage_scale;eage_scale;0;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;77;-2123.153,-144.2386;Inherit;False;1224.553;793.1438;Comment;9;68;72;71;70;75;74;73;69;76;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;42;-3499.303,-267.9428;Inherit;False;1143.172;497.8378;Comment;5;19;17;18;8;12;菲涅尔;1,1,1,1;0;0
Node;AmplifyShaderEditor.ColorNode;25;-73.3586,86.21811;Inherit;False;Property;_eage_color;eage_color;3;0;Create;True;0;0;0;False;0;False;0,0.1795305,0.7924528,0;0,0.1795305,0.7924528,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;69;-1430.002,533.9052;Inherit;False;Property;_inside_edge_power;inside_edge_power;11;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;18;-2811.892,-146.2782;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;12;-3362.781,-217.9428;Inherit;True;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;52;-1850.547,-880.0133;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SmoothstepOpNode;82;-1606.179,917.6671;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;67;-245.915,-891.9041;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PannerNode;55;-1309.547,-1072.346;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;50;-1851.603,-1003.099;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;80;-1218.544,909.2479;Inherit;True;3;3;0;FLOAT;0;False;1;COLOR;1,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;70;-1731.966,493.06;Inherit;False;Property;_Float2;Float 2;8;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;72;-1615.892,300.6467;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;19;-2554.132,-190.0419;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;56;-542.8145,-992.8164;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;49;-1850.603,-1106.099;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;163.2324,472.682;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector4Node;54;-2111.547,-732.0133;Inherit;False;Property;_speed_and_time;speed_and_time;4;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-1310.839,-589.6968;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;66;-1544.241,-313.9911;Inherit;False;Property;_Float0;Float 0;10;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;63;-1650.731,-591.1556;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;65;-1846.205,-354.8363;Inherit;False;Property;_power;power;7;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;97;757.0234,-495.1706;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;73;-1821.248,-94.23861;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0.81;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;46;-1844.603,-1214.099;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DotProductOpNode;17;-3040.892,-151.2782;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;83;-1522.133,710.172;Inherit;False;Property;_inside_color;inside_color;14;0;Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GrabScreenPosition;45;-2158.603,-1233.099;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;62;-129.2422,-1202.376;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;59;399.969,-810.1452;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;71;-1134.6,254.1995;Inherit;True;4;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;61;-526.0668,-1381.627;Inherit;False;Property;_maincolor;maincolor;9;0;Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;57;-1663.814,-782.8164;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;8;-3308.099,39.11715;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SmoothstepOpNode;74;-1468.002,-30.03471;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;84;-1906.266,1036.187;Inherit;False;Property;_inside_power2;inside_power2;15;0;Create;True;0;0;0;False;0;False;0,1,1,0;0,1,1,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;94;491.6144,75.52753;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector4Node;48;-2103.603,-1033.099;Inherit;False;Property;_scale_offset;scale_offset;6;0;Create;True;0;0;0;False;0;False;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;76;-1774.002,160.9653;Inherit;False;Property;_smooth_step;smooth_step;12;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ColorNode;75;-1173.149,22.27311;Inherit;False;Property;_Color0;Color 0;13;0;Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;58;-967.6349,-1542.28;Inherit;False;Property;_screen_color;screen_color;5;0;Create;True;0;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;43;-977.8199,-1114.893;Inherit;True;Property;_TextureSample0;Texture Sample 0;2;0;Create;True;0;0;0;False;0;False;-1;None;61eaf7b2d52c71443990eb594ae78c47;True;1;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;98;-1053.342,-928.6383;Inherit;False;Property;_tex_power;tex_power;1;0;Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;47;-1554.603,-1212.099;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PosVertexDataNode;68;-2069.702,-83.33502;Inherit;True;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;23;633.785,-774.7229;Float;False;True;-1;2;ASEMaterialInspector;0;9;fresnel;003dfa9c16768d048b74f75c088119d8;True;First;0;0;First;2;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;RenderType=Opaque=RenderType;False;False;0;True;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;Queue=Transparent=Queue=0;True;2;False;0;;0;0;Standard;0;0;2;True;True;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;24;1013.5,266.7813;Float;False;False;-1;2;ASEMaterialInspector;0;9;New Amplify Shader;003dfa9c16768d048b74f75c088119d8;True;Second;0;1;Second;2;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;RenderType=Opaque=RenderType;False;False;0;True;True;4;1;False;-1;1;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;1;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;True;2;False;0;;0;0;Standard;0;False;0
WireConnection;95;0;96;2
WireConnection;95;1;92;0
WireConnection;18;0;17;0
WireConnection;52;0;54;1
WireConnection;52;1;54;2
WireConnection;82;0;19;0
WireConnection;82;1;84;1
WireConnection;82;2;84;2
WireConnection;67;0;62;0
WireConnection;67;1;71;0
WireConnection;67;2;80;0
WireConnection;55;0;47;0
WireConnection;55;2;52;0
WireConnection;55;1;57;0
WireConnection;50;0;48;3
WireConnection;50;1;48;4
WireConnection;80;0;82;0
WireConnection;80;1;83;0
WireConnection;80;2;84;3
WireConnection;72;1;70;0
WireConnection;19;0;18;0
WireConnection;56;0;43;0
WireConnection;56;1;98;0
WireConnection;56;2;58;0
WireConnection;49;0;48;1
WireConnection;49;1;48;2
WireConnection;21;0;22;0
WireConnection;21;1;20;0
WireConnection;64;1;66;0
WireConnection;63;0;19;0
WireConnection;63;1;65;0
WireConnection;97;0;95;0
WireConnection;73;0;68;2
WireConnection;46;0;45;1
WireConnection;46;1;45;2
WireConnection;17;0;12;0
WireConnection;17;1;8;0
WireConnection;62;0;56;0
WireConnection;62;1;61;0
WireConnection;62;2;63;0
WireConnection;59;0;67;0
WireConnection;59;3;95;0
WireConnection;71;0;19;0
WireConnection;71;1;69;0
WireConnection;71;2;74;0
WireConnection;71;3;75;0
WireConnection;57;0;54;3
WireConnection;74;0;73;0
WireConnection;74;1;76;1
WireConnection;74;2;76;2
WireConnection;94;0;95;0
WireConnection;94;1;25;0
WireConnection;43;1;55;0
WireConnection;47;0;46;0
WireConnection;47;1;49;0
WireConnection;47;2;50;0
WireConnection;23;0;59;0
WireConnection;24;0;94;0
WireConnection;24;1;21;0
ASEEND*/
//CHKSM=B0B26D6504020B058E8A976E68469DB575B1A80C
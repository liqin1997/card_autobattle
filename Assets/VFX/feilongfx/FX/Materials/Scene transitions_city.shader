// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Scene transitions_city"
{
	Properties
	{
		_Float0("缩放值", Range( 0 , 1)) = 0
		_Color0("主颜色", Color) = (1,0,0,1)
		_Float2("边缘硬度", Range( 0 , 1)) = 0.1076065

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
			};

			uniform float4 _Color0;
			uniform float _Float2;
			uniform float _Float0;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord.xy = v.ase_texcoord.xy;
				
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
				float3 appendResult13 = (float3(_Color0.r , _Color0.g , _Color0.b));
				float2 uv02 = i.ase_texcoord.xy * float2( 1,1 ) + float2( -0.5,-0.5 );
				float smoothstepResult8 = smoothstep( ( 0.2 - _Float2 ) , 0.2 , pow( length( uv02 ) , (0.0 + (_Float0 - 0.0) * (11.0 - 0.0) / (1.0 - 0.0)) ));
				float4 appendResult14 = (float4((appendResult13).xyz , smoothstepResult8));
				
				
				finalColor = appendResult14;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=17500
0;0;1957;1131;1764.131;832.1412;1.337538;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;2;-1479.616,-105.4357;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;-0.5,-0.5;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;6;-1508.166,172.5281;Inherit;False;Property;_Float0;缩放值;0;0;Create;False;0;0;False;0;0;0.1565481;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;3;-1106.616,-127.4357;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;9;-1011.533,231.4846;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;11;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;11;-561.1031,-591.0921;Inherit;False;Property;_Color0;主颜色;1;0;Create;False;0;0;False;0;1,0,0,1;1,0,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;17;-795.3715,304.2866;Inherit;False;Property;_Float2;边缘硬度;3;0;Create;False;0;0;False;0;0.1076065;0.1076065;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;15;-818.7917,148.9463;Inherit;False;Constant;_Float1;最大值;2;0;Create;False;0;0;False;0;0.2;0.2;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;7;-816.1661,-115.4719;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;13;-262.9836,-517.2219;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;16;-477.8851,188.0824;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;12;-90.17992,-467.0956;Inherit;False;True;True;True;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;8;-385.8523,-79.39684;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;14;202.663,-344.4182;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;416.7071,-348.343;Float;False;True;-1;2;ASEMaterialInspector;100;1;Scene transitions_city;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;3;0;2;0
WireConnection;9;0;6;0
WireConnection;7;0;3;0
WireConnection;7;1;9;0
WireConnection;13;0;11;1
WireConnection;13;1;11;2
WireConnection;13;2;11;3
WireConnection;16;0;15;0
WireConnection;16;1;17;0
WireConnection;12;0;13;0
WireConnection;8;0;7;0
WireConnection;8;1;16;0
WireConnection;8;2;15;0
WireConnection;14;0;12;0
WireConnection;14;3;8;0
WireConnection;0;0;14;0
ASEEND*/
//CHKSM=9202D3A51B9C2711126CBBCFC1FFB4663BAD6576
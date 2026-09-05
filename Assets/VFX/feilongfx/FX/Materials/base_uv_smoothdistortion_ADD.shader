// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "base_uv_smoothdistortion_ADD"
{
	Properties
	{
		_TextureSample0("主纹理", 2D) = "white" {}
		_Vector2("主纹理缩放", Vector) = (1,1,0,0)
		_Vector3("主纹理速度", Vector) = (0,0,0,0)
		_TextureSample1("扭曲贴图", 2D) = "white" {}
		_TextureSample2("溶解贴图", 2D) = "white" {}
		_Float2("溶解贴图强度 默认0.8", Float) = 1
		_Vector4("溶解贴图速度", Vector) = (0,0,0,0)
		_Vector5("溶解贴图缩放", Vector) = (1,1,0,0)
		_TextureSample3("遮罩", 2D) = "white" {}
		_Float0("遮罩强度", Float) = 0
		[HDR]_Color0("主颜色", Color) = (1,1,1,1)
		_TextureSample4("扰动贴图", 2D) = "white" {}
		_Float1("扰动强度", Float) = 0
		_Vector0("扰动速度", Vector) = (0,0,0,0)
		_Vector1("扰动贴图缩放", Vector) = (0,0,0,0)
		vertex01("启用溶解贴图单独流动", Float) = 1
		vertex2("启用扰动影响溶解贴图", Float) = 1
		[HDR]_Color1("边缘颜色", Color) = (1,0,0,1)
		_Float7("smoothstep 默认0.01", Float) = 0.01
		[HDR]_Color2("辉光颜色", Color) = (0,0,0,0)
		_Float12("辉光强度", Float) = 0
		_Float11("辉光范围", Float) = 0.5
		_Float13("软边缘遮罩开关", Float) = 0
		_TextureSample5("扭曲溶解贴图遮罩", 2D) = "white" {}
		_Vector7("扭曲溶解遮罩贴图速度", Vector) = (0,0,0,0)
		_Vector6("扭曲溶解遮罩贴图缩放", Vector) = (1,1,0,0)
		_Vector8("扭曲/溶解/偏移XY/（非Custom情况下））", Vector) = (0,0,0,0)
		_Float55("关闭Custom Data", Float) = 0
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
				float4 ase_texcoord2 : TEXCOORD2;
				float3 ase_normal : NORMAL;
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
				float4 ase_texcoord4 : TEXCOORD4;
			};

			uniform sampler2D _TextureSample0;
			uniform sampler2D _TextureSample4;
			uniform float4 _Vector0;
			uniform float4 _Vector1;
			uniform float _Float1;
			uniform sampler2D _TextureSample5;
			uniform float4 _Vector7;
			uniform float4 _Vector6;
			uniform float4 _Vector3;
			uniform float4 _Vector2;
			uniform float4 _Vector8;
			uniform float _Float55;
			uniform sampler2D _TextureSample1;
			uniform float4 _TextureSample1_ST;
			uniform float4 _Color0;
			uniform sampler2D _TextureSample3;
			uniform float _Float0;
			uniform float _Float7;
			uniform sampler2D _TextureSample2;
			uniform float4 _Vector4;
			uniform float vertex01;
			uniform float4 _Vector5;
			uniform float vertex2;
			uniform float _Float2;
			uniform float4 _Color1;
			uniform float _Float11;
			uniform float4 _Color2;
			uniform float _Float12;
			uniform float _Float13;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float3 ase_worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.ase_texcoord3.xyz = ase_worldPos;
				float3 ase_worldNormal = UnityObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord4.xyz = ase_worldNormal;
				
				o.ase_color = v.color;
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_texcoord2 = v.ase_texcoord2;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				o.ase_texcoord3.w = 0;
				o.ase_texcoord4.w = 0;
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
				float2 appendResult51 = (float2(_Vector0.x , _Vector0.y));
				float2 uv03 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult54 = (float2(_Vector1.x , _Vector1.y));
				float2 panner45 = ( 1.0 * _Time.y * appendResult51 + (uv03*appendResult54 + 0.0));
				float2 appendResult215 = (float2(_Vector7.x , _Vector7.y));
				float2 appendResult213 = (float2(_Vector6.x , _Vector6.y));
				float2 panner217 = ( 1.0 * _Time.y * appendResult215 + (uv03*appendResult213 + 0.0));
				float4 tex2DNode211 = tex2D( _TextureSample5, panner217 );
				float temp_output_49_0 = ( tex2D( _TextureSample4, panner45 ).r * _Float1 * tex2DNode211.r );
				float2 appendResult66 = (float2(_Vector3.x , _Vector3.y));
				float2 appendResult62 = (float2(_Vector2.x , _Vector2.y));
				float4 uv14 = i.ase_texcoord1;
				uv14.xy = i.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 appendResult218 = (float2(uv14.z , uv14.w));
				float2 appendResult227 = (float2(_Vector8.z , _Vector8.w));
				float2 lerpResult224 = lerp( appendResult218 , appendResult227 , _Float55);
				float2 panner64 = ( 1.0 * _Time.y * appendResult66 + (uv03*appendResult62 + lerpResult224));
				float2 uv_TextureSample1 = i.ase_texcoord.xy * _TextureSample1_ST.xy + _TextureSample1_ST.zw;
				float4 tex2DNode6 = tex2D( _TextureSample1, uv_TextureSample1 );
				float2 appendResult7 = (float2(tex2DNode6.r , tex2DNode6.g));
				float lerpResult221 = lerp( uv14.x , _Vector8.x , _Float55);
				float2 lerpResult5 = lerp( panner64 , appendResult7 , lerpResult221);
				float4 tex2DNode2 = tex2D( _TextureSample0, ( temp_output_49_0 + lerpResult5 ) );
				float2 uv055 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float lerpResult222 = lerp( uv14.y , _Vector8.y , _Float55);
				float2 appendResult70 = (float2(_Vector4.x , _Vector4.y));
				float2 lerpResult84 = lerp( uv03 , lerpResult5 , vertex01);
				float2 appendResult67 = (float2(_Vector5.x , _Vector5.y));
				float2 panner69 = ( 1.0 * _Time.y * appendResult70 + (lerpResult84*appendResult67 + 0.0));
				float2 lerpResult86 = lerp( ( temp_output_49_0 + panner69 ) , panner69 , vertex2);
				float4 tex2DNode10 = tex2D( _TextureSample2, lerpResult86 );
				float temp_output_124_0 = ( tex2DNode10.r * _Float2 * tex2DNode211.r );
				float smoothstepResult110 = smoothstep( ( _Float7 - (0.5 + (lerpResult222 - 0.0) * (-0.09 - 0.5) / (1.0 - 0.0)) ) , lerpResult222 , temp_output_124_0);
				float4 temp_output_59_0 = ( ( i.ase_color * tex2DNode2 * _Color0 ) * saturate( pow( tex2D( _TextureSample3, uv055 ).r , _Float0 ) ) * smoothstepResult110 * i.ase_color.a * tex2DNode2.a * _Color0.a );
				float4 uv2206 = i.ase_texcoord2;
				uv2206.xy = i.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float4 appendResult207 = (float4(uv2206.x , uv2206.y , uv2206.z , uv2206.w));
				float4 BaseColor200 = saturate( ( temp_output_59_0 + ( appendResult207 * _Color1 * ( smoothstepResult110 - step( lerpResult222 , temp_output_124_0 ) ) ) ) );
				float4 temp_cast_3 = (_Float11).xxxx;
				float4 temp_cast_4 = (1.0).xxxx;
				float4 break148 = BaseColor200;
				float4 appendResult149 = (float4(break148.r , break148.g , break148.b , 0.0));
				float4 break162 = BaseColor200;
				float temp_output_151_0 = ( ( break162.r * 0.2125 ) + ( break162.g * 0.7154 ) + ( break162.b * 0.0721 ) );
				float4 appendResult140 = (float4(temp_output_151_0 , temp_output_151_0 , temp_output_151_0 , 0.0));
				float4 lerpResult147 = lerp( appendResult149 , appendResult140 , 1.0);
				float4 smoothstepResult155 = smoothstep( temp_cast_3 , temp_cast_4 , saturate( lerpResult147 ));
				float4 lerpResult176 = lerp( BaseColor200 , ( ( smoothstepResult155 * _Color2 ) + BaseColor200 ) , _Float12);
				float4 bloom198 = lerpResult176;
				float3 ase_worldPos = i.ase_texcoord3.xyz;
				float3 ase_worldViewDir = UnityWorldSpaceViewDir(ase_worldPos);
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 ase_worldNormal = i.ase_texcoord4.xyz;
				float fresnelNdotV126 = dot( ase_worldNormal, ase_worldViewDir );
				float fresnelNode126 = ( 0.0 + 1.16 * pow( 1.0 - fresnelNdotV126, 1.55 ) );
				float4 lerpResult190 = lerp( temp_output_59_0 , ( temp_output_59_0 * ( 1.0 - fresnelNode126 ) ) , _Float13);
				
				
				finalColor = ( bloom198 * lerpResult190 );
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
0;0;1957;1131;4595.328;-66.90431;1.3;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;4;-3962.355,266.7595;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;226;-3824.732,687.2089;Inherit;False;Property;_Vector8;扭曲/溶解/偏移XY/（非Custom情况下））;26;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;227;-3595.103,1046.711;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;225;-3723.47,1254.076;Inherit;False;Property;_Float55;关闭Custom Data;27;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;63;-3681.952,-212.7088;Inherit;False;Property;_Vector2;主纹理缩放;1;0;Create;False;0;0;False;0;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;218;-3486.164,218.4376;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;224;-3147.117,1213.089;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;65;-3039.504,-221.476;Inherit;False;Property;_Vector3;主纹理速度;2;0;Create;False;0;0;False;0;0,0,0,0;-1,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;3;-4104.989,-586.9521;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;62;-3351.466,-324.7963;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;212;-3252.673,-774.5635;Inherit;False;Property;_Vector6;扭曲溶解遮罩贴图缩放;25;0;Create;False;0;0;False;0;1,1,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;61;-2816.824,-582.9971;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;52;-2758.177,-1319.626;Inherit;False;Property;_Vector1;扰动贴图缩放;14;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;66;-2597.952,-214.0902;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;6;-2549.974,-104.853;Inherit;True;Property;_TextureSample1;扭曲贴图;3;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;54;-2559.926,-1309.145;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;214;-2697.763,-766.4268;Inherit;False;Property;_Vector7;扭曲溶解遮罩贴图速度;24;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;7;-2231.97,-267.9921;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;213;-2879.359,-804.404;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;221;-3023.959,417.8715;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;50;-2307.172,-1212.661;Inherit;False;Property;_Vector0;扰动速度;13;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;64;-2486.005,-449.5232;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;44;-2223.926,-1405.145;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;5;-2023.464,-554.373;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;72;-2514.947,421.5713;Inherit;False;Property;_Vector5;溶解贴图缩放;7;0;Create;False;0;0;False;0;1,1,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;85;-2114.193,7.394458;Inherit;False;Property;vertex01;启用溶解贴图单独流动;15;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;51;-2078.114,-1162.21;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;216;-2833.261,-992.4658;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;215;-2421.043,-717.123;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;186;717.6949,1070.466;Inherit;False;1757.669;882.8823;遮罩模块;5;27;43;60;58;55;;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector4Node;71;-2124.325,440.7203;Inherit;False;Property;_Vector4;溶解贴图速度;6;0;Create;False;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;217;-2309.096,-952.556;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;45;-1966.168,-1397.643;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;67;-2063.2,131.7878;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;84;-1727.101,-350.954;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;70;-1825.735,299.8792;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;47;-1773.168,-1438.643;Inherit;True;Property;_TextureSample4;扰动贴图;11;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;68;-1681.958,-132.0465;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;211;-1775.017,-922.7966;Inherit;True;Property;_TextureSample5;扭曲溶解贴图遮罩;23;0;Create;False;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;48;-1655.005,-1140.688;Inherit;False;Property;_Float1;扰动强度;12;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;55;809.9679,1691.1;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;43;1673.344,1632.749;Inherit;False;Property;_Float0;遮罩强度;9;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;-1460.28,-1172.704;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;69;-1635.461,44.36013;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;27;1341.735,1548.869;Inherit;True;Property;_TextureSample3;遮罩;8;0;Create;False;0;0;False;0;-1;None;d67d989311b0bc447b5cd79ddb2930c4;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;88;-1375.587,166.5311;Inherit;False;Property;vertex2;启用扰动影响溶解贴图;16;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;87;-1343.871,-294.1532;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PowerNode;58;1727.62,1235.161;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;222;-2956.476,756.3071;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;86;-1092.118,-154.3946;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;60;2157.965,1365.326;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;185;1971.326,1027.236;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;112;-1190.954,955.3194;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.5;False;4;FLOAT;-0.09;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;75;-1132.477,229.5736;Inherit;False;Property;_Float2;溶解贴图强度 默认0.8;5;0;Create;False;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;10;-1056.405,-480.3296;Inherit;True;Property;_TextureSample2;溶解贴图;4;0;Create;False;0;0;False;0;-1;ab55cf0c3f866c648a33ac7834f612b3;3c2220205bf33b74e91fb46cd5858af1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;111;-1077.115,1266.532;Inherit;False;Property;_Float7;smoothstep 默认0.01;18;0;Create;False;0;0;False;0;0.01;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;113;-753.9758,1066.143;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;46;-1360.195,-902.2112;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;184;1331.404,945.5433;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;124;-829.5878,-17.28682;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;81;-609.5538,-90.68706;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;183;1187.348,243.9549;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;2;-938.625,-808.6756;Inherit;True;Property;_TextureSample0;主纹理;0;0;Create;False;0;0;False;0;-1;3903f265ecb904a93b58e45db099cb32;c139f269c5d636e46b73ad3b08a7cf4b;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;110;-520.8853,562.1877;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;34;-807.621,-1216.267;Inherit;False;Property;_Color0;主颜色;10;1;[HDR];Create;False;0;0;False;0;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;206;-386.3755,-212.2337;Inherit;False;2;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;39;-776.2667,-1424.065;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;207;-35.08614,-245.9005;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ColorNode;102;-67.90331,-10.03277;Inherit;False;Property;_Color1;边缘颜色;17;1;[HDR];Create;False;0;0;False;1;;1,0,0,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;116;43.49934,481.5797;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;182;355.4928,128.6783;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;-85.8804,-1040.933;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;59;217.4174,-871.3657;Inherit;True;6;6;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;210;388.4882,-254.908;Inherit;False;3;3;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;220;570.0983,-470.439;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;173;-539.2998,-3164.459;Inherit;False;2641.356;1228.017;辉光模块;11;166;164;165;155;171;176;177;178;201;203;204;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SaturateNode;123;694.6761,-834.5172;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;178;-384.1067,-3120.436;Inherit;False;1312.532;1070.775;去饱和度;17;150;154;156;153;147;140;149;151;148;143;142;141;146;145;162;144;202;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;200;1271.847,-754.3672;Inherit;False;BaseColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;202;-223.6655,-2222.656;Inherit;False;200;BaseColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;146;-267.6722,-2689.394;Inherit;False;Constant;_Float8;Float 8;22;0;Create;True;0;0;False;0;0.0721;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;162;144.2561,-2247.52;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;144;-261.034,-2972.051;Inherit;False;Constant;_Float4;Float 4;22;0;Create;True;0;0;False;0;0.2125;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;145;-244.8989,-2812.575;Inherit;False;Constant;_Float6;Float 6;22;0;Create;True;0;0;False;0;0.7154;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;142;29.66761,-2857.235;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;143;15.19048,-2743.621;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;141;-41.71801,-2936.44;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;201;-498.7786,-2411.796;Inherit;False;200;BaseColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;197;1765.396,-308.5705;Inherit;False;1535.8;983.0171;软边缘模块;11;126;189;196;128;195;131;187;188;130;129;192;;1,1,1,1;0;0
Node;AmplifyShaderEditor.BreakToComponentsNode;148;-240.5371,-2448.738;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleAddOpNode;151;111.02,-3113.632;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;129;2384.918,277.9953;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;130;2364.907,434.0115;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;149;97.46284,-2417.738;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;150;281.4628,-2420.738;Inherit;False;Constant;_Float9;饱和度;24;0;Create;False;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;140;400.9338,-2772.965;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LerpOp;147;459.463,-2590.739;Inherit;True;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FresnelNode;126;2796.333,230.2669;Inherit;True;Standard;WorldNormal;ViewDir;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1.16;False;3;FLOAT;1.55;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;188;2341.561,224.8456;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;153;754.8596,-2175.368;Inherit;False;Constant;_Float10;Float 10;22;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;156;694.6547,-2324.334;Inherit;False;Property;_Float11;辉光范围;21;0;Create;False;0;0;False;0;0.5;0.34;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;154;730.7246,-2503.883;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SmoothstepOpNode;155;955.1174,-2675.283;Inherit;True;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT4;1,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WireNode;187;1975.343,242.354;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;166;1047.827,-2321.808;Inherit;False;Property;_Color2;辉光颜色;19;1;[HDR];Create;False;0;0;False;0;0,0,0,0;2,2,2,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;203;1315.25,-2336.568;Inherit;False;200;BaseColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;165;1233.69,-2478.737;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WireNode;180;987.2093,-131.2352;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;131;2011.278,33.55865;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;128;2377.301,-43.86302;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;164;1586.712,-2850.816;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WireNode;171;1758.011,-2065.187;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;177;1540.114,-2028.624;Inherit;False;Property;_Float12;辉光强度;20;0;Create;False;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;196;2590.247,-86.3622;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;204;1525.884,-2145.28;Inherit;False;200;BaseColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;195;1860.247,-114.3622;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;176;1814.458,-2084.263;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;198;2158.828,-2052.896;Inherit;False;bloom;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;192;2170.476,-174.4135;Inherit;False;Property;_Float13;软边缘遮罩开关;22;0;Create;False;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;191;1123.371,-214.3134;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;189;1870.354,-195.5545;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;199;1637.238,-880.6547;Inherit;False;198;bloom;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LerpOp;190;1843.94,-489.4319;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;223;-3064.854,982.8834;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;219;1828.775,-733.3973;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.PowerNode;80;-1023.515,-15.57392;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;13;2031.826,-789.4402;Inherit;True;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;2292.545,-676.2434;Float;False;True;-1;2;ASEMaterialInspector;100;1;base_uv_smoothdistortion_ADD;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;4;1;False;-1;1;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;2;RenderType=Opaque=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;0;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;227;0;226;3
WireConnection;227;1;226;4
WireConnection;218;0;4;3
WireConnection;218;1;4;4
WireConnection;224;0;218;0
WireConnection;224;1;227;0
WireConnection;224;2;225;0
WireConnection;62;0;63;1
WireConnection;62;1;63;2
WireConnection;61;0;3;0
WireConnection;61;1;62;0
WireConnection;61;2;224;0
WireConnection;66;0;65;1
WireConnection;66;1;65;2
WireConnection;54;0;52;1
WireConnection;54;1;52;2
WireConnection;7;0;6;1
WireConnection;7;1;6;2
WireConnection;213;0;212;1
WireConnection;213;1;212;2
WireConnection;221;0;4;1
WireConnection;221;1;226;1
WireConnection;221;2;225;0
WireConnection;64;0;61;0
WireConnection;64;2;66;0
WireConnection;44;0;3;0
WireConnection;44;1;54;0
WireConnection;5;0;64;0
WireConnection;5;1;7;0
WireConnection;5;2;221;0
WireConnection;51;0;50;1
WireConnection;51;1;50;2
WireConnection;216;0;3;0
WireConnection;216;1;213;0
WireConnection;215;0;214;1
WireConnection;215;1;214;2
WireConnection;217;0;216;0
WireConnection;217;2;215;0
WireConnection;45;0;44;0
WireConnection;45;2;51;0
WireConnection;67;0;72;1
WireConnection;67;1;72;2
WireConnection;84;0;3;0
WireConnection;84;1;5;0
WireConnection;84;2;85;0
WireConnection;70;0;71;1
WireConnection;70;1;71;2
WireConnection;47;1;45;0
WireConnection;68;0;84;0
WireConnection;68;1;67;0
WireConnection;211;1;217;0
WireConnection;49;0;47;1
WireConnection;49;1;48;0
WireConnection;49;2;211;1
WireConnection;69;0;68;0
WireConnection;69;2;70;0
WireConnection;27;1;55;0
WireConnection;87;0;49;0
WireConnection;87;1;69;0
WireConnection;58;0;27;1
WireConnection;58;1;43;0
WireConnection;222;0;4;2
WireConnection;222;1;226;2
WireConnection;222;2;225;0
WireConnection;86;0;87;0
WireConnection;86;1;69;0
WireConnection;86;2;88;0
WireConnection;60;0;58;0
WireConnection;185;0;60;0
WireConnection;112;0;222;0
WireConnection;10;1;86;0
WireConnection;113;0;111;0
WireConnection;113;1;112;0
WireConnection;46;0;49;0
WireConnection;46;1;5;0
WireConnection;184;0;185;0
WireConnection;124;0;10;1
WireConnection;124;1;75;0
WireConnection;124;2;211;1
WireConnection;81;0;222;0
WireConnection;81;1;124;0
WireConnection;183;0;184;0
WireConnection;2;1;46;0
WireConnection;110;0;124;0
WireConnection;110;1;113;0
WireConnection;110;2;222;0
WireConnection;207;0;206;1
WireConnection;207;1;206;2
WireConnection;207;2;206;3
WireConnection;207;3;206;4
WireConnection;116;0;110;0
WireConnection;116;1;81;0
WireConnection;182;0;183;0
WireConnection;40;0;39;0
WireConnection;40;1;2;0
WireConnection;40;2;34;0
WireConnection;59;0;40;0
WireConnection;59;1;182;0
WireConnection;59;2;110;0
WireConnection;59;3;39;4
WireConnection;59;4;2;4
WireConnection;59;5;34;4
WireConnection;210;0;207;0
WireConnection;210;1;102;0
WireConnection;210;2;116;0
WireConnection;220;0;59;0
WireConnection;220;1;210;0
WireConnection;123;0;220;0
WireConnection;200;0;123;0
WireConnection;162;0;202;0
WireConnection;142;0;162;1
WireConnection;142;1;145;0
WireConnection;143;0;162;2
WireConnection;143;1;146;0
WireConnection;141;0;162;0
WireConnection;141;1;144;0
WireConnection;148;0;201;0
WireConnection;151;0;141;0
WireConnection;151;1;142;0
WireConnection;151;2;143;0
WireConnection;149;0;148;0
WireConnection;149;1;148;1
WireConnection;149;2;148;2
WireConnection;140;0;151;0
WireConnection;140;1;151;0
WireConnection;140;2;151;0
WireConnection;147;0;149;0
WireConnection;147;1;140;0
WireConnection;147;2;150;0
WireConnection;126;0;129;0
WireConnection;126;4;130;0
WireConnection;188;0;126;0
WireConnection;154;0;147;0
WireConnection;155;0;154;0
WireConnection;155;1;156;0
WireConnection;155;2;153;0
WireConnection;187;0;188;0
WireConnection;165;0;155;0
WireConnection;165;1;166;0
WireConnection;180;0;59;0
WireConnection;131;0;187;0
WireConnection;128;0;180;0
WireConnection;128;1;131;0
WireConnection;164;0;165;0
WireConnection;164;1;203;0
WireConnection;171;0;164;0
WireConnection;196;0;128;0
WireConnection;195;0;196;0
WireConnection;176;0;204;0
WireConnection;176;1;171;0
WireConnection;176;2;177;0
WireConnection;198;0;176;0
WireConnection;191;0;59;0
WireConnection;189;0;195;0
WireConnection;190;0;191;0
WireConnection;190;1;189;0
WireConnection;190;2;192;0
WireConnection;223;1;4;2
WireConnection;223;2;225;0
WireConnection;219;0;199;0
WireConnection;219;1;190;0
WireConnection;80;0;10;1
WireConnection;80;1;75;0
WireConnection;1;0;219;0
ASEEND*/
//CHKSM=DA6688208FF07CF1F48F5DC0A955943A519C076E
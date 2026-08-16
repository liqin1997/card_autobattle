Shader "Spine/Skeleton_Absorbable" {
	Properties {

		_Cutoff ("Shadow alpha cutoff", Range(0,1)) = 0.1
		_Alpha("Alpha", Range(0,1)) = 1
		_Attract_Pos   ("Attract Position", Vector) = (0, 0, 0, 0)
		_Attract_Range ("Attract Range", Float) = 1
		_Attract_Rate ("Attract Range", Range(0, 1)) = 1
		[NoScaleOffset] _MainTex ("Main Texture", 2D) = "black" {}
		[Toggle(_STRAIGHT_ALPHA_INPUT)] _StraightAlphaInput("Straight Alpha Texture", Int) = 0
		[HideInInspector] _StencilRef("Stencil Reference", Float) = 1.0
		[HideInInspector][Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil Comparison", Float) = 8 // Set to Always as default

		// Outline properties are drawn via custom editor.
		[HideInInspector] _OutlineWidth("Outline Width", Range(0,8)) = 3.0
		[HideInInspector] _OutlineColor("Outline Color", Color) = (1,1,0,1)
		[HideInInspector] _OutlineReferenceTexWidth("Reference Texture Width", Int) = 1024
		[HideInInspector] _ThresholdEnd("Outline Threshold", Range(0,1)) = 0.25
		[HideInInspector] _OutlineSmoothness("Outline Smoothness", Range(0,1)) = 1.0
		[HideInInspector][MaterialToggle(_USE8NEIGHBOURHOOD_ON)] _Use8Neighbourhood("Sample 8 Neighbours", Float) = 1
		[HideInInspector] _OutlineMipLevel("Outline Mip Level", Range(0,3)) = 0
	}

	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="False" "RenderType"="Transparent" }

		Fog { Mode Off }
		Cull Off

		Pass {

            ColorMask A
			Blend One OneMinusSrcAlpha
			CGPROGRAM
			#pragma shader_feature _ _STRAIGHT_ALPHA_INPUT
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			fixed _Alpha;
			float4 _Attract_Pos;
		    float _Attract_Range;
		    float _Attract_Rate;
		    
			struct VertexInput {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 vertexColor : COLOR;
			};

			struct VertexOutput {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 vertexColor : COLOR;
			};

            float4 attract (in float4 v)
		    {
			float3 wldpos = mul(unity_ObjectToWorld, v).xyz;
			float dist = distance(wldpos, _Attract_Pos.xyz);
			float3 newWldpos = wldpos;
			newWldpos.xyz += normalize(_Attract_Pos.xyz - newWldpos.xyz) * (_Attract_Range - dist)*_Attract_Rate;
				if (dot((wldpos - _Attract_Pos.xyz), (_Attract_Pos.xyz - newWldpos)) > 0)
					newWldpos.xyz = _Attract_Pos.xyz;
			return mul(unity_WorldToObject, float4(newWldpos, 1.0));
		    }
            
			VertexOutput vert (VertexInput v) {
				VertexOutput o;
				o.pos = UnityObjectToClipPos(attract(v.vertex));
				o.uv = v.uv;
				o.vertexColor = v.vertexColor;
               
				return o;
			}

			fixed4 frag (VertexOutput i) : SV_Target {
				fixed4 texColor = tex2D(_MainTex, i.uv);

				#if defined(_STRAIGHT_ALPHA_INPUT)
				texColor.rgb *= texColor.a;
				#endif
				texColor *= i.vertexColor;
                texColor.a = _Alpha * texColor.a;
				return texColor;
			}
			ENDCG
		}
		
		// Second Pass: Now render color (RGB) channel
		ColorMask RGBA
		Blend One OneMinusSrcAlpha

		CGPROGRAM
		#pragma surface surf Lambert alpha vertex:vert
		#pragma shader_feature _ _STRAIGHT_ALPHA_INPUT
		#include "UnityCG.cginc"
		sampler2D _MainTex;
		fixed _Alpha;
		float4 _Attract_Pos;
		float _Attract_Range;
		float _Attract_Rate;

		struct Input {
			float4 color:COLOR;
			float2 uv_MainTex;
		};

        float4 attract (in float4 v)
		{
			float3 wldpos = mul(unity_ObjectToWorld, v).xyz;
			float dist = distance(wldpos, _Attract_Pos.xyz);
			float3 newWldpos = wldpos;
			newWldpos.xyz += normalize(_Attract_Pos.xyz - newWldpos.xyz) * (_Attract_Range - dist)*_Attract_Rate;
				if (dot((wldpos - _Attract_Pos.xyz), (_Attract_Pos.xyz - newWldpos)) > 0)
					newWldpos.xyz = _Attract_Pos.xyz;
			return mul(unity_WorldToObject, float4(newWldpos, 1.0));
		}
		
		void vert (inout appdata_full v)
		{
			v.vertex = attract(v.vertex);
		}

		void surf(Input IN, inout SurfaceOutput o) {
			float4 texColor = tex2D(_MainTex, IN.uv_MainTex);

			#if defined(_STRAIGHT_ALPHA_INPUT)
			texColor.rgb *= texColor.a;
			#endif
			texColor *= IN.color;
			o.Albedo = texColor.rgb;
			o.Alpha = _Alpha;
		}
		ENDCG
	}
	CustomEditor "SpineShaderWithOutlineGUI"
}

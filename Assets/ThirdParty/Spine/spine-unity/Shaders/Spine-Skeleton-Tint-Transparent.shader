// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Spine/Skeleton Tint
// - Two color tint
// - unlit
// - Premultiplied alpha blending (Optional straight alpha input)
// - No depth, no backface culling, no fog.

Shader "Spine/Skeleton Tint Transparent" {
	Properties {
		_Color ("Tint Color", Color) = (1,1,1,1)
		_Black ("Black Point", Color) = (0,0,0,0)
		[NoScaleOffset] _MainTex ("MainTex", 2D) = "black" {}
		[Toggle(_STRAIGHT_ALPHA_INPUT)] _StraightAlphaInput("Straight Alpha Texture", Int) = 0
		_Cutoff("Shadow alpha cutoff", Range(0,1)) = 0.1
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

		// First Pass: Only render alpha (A) channel
		Pass {
			ColorMask A
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			fixed4 _Color;

			float4 vert(float4 vertex:POSITION) : SV_POSITION {
				return UnityObjectToClipPos(vertex);
			}

			fixed4 frag() : SV_Target {
				return _Color;
			}

			ENDCG
		}

		// Second Pass: Now render color (RGB) channel
		ColorMask RGB
		Blend SrcAlpha OneMinusSrcAlpha

		CGPROGRAM
		#pragma surface surf Lambert alpha
		#pragma shader_feature _ _STRAIGHT_ALPHA_INPUT

		sampler2D _MainTex;
		fixed4 _Color;

		struct Input {
			float4 color:COLOR;
			float2 uv_MainTex;
		};

		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		ENDCG
	}

	Fallback "Legacy Shaders/Transparent/Diffuse"

}

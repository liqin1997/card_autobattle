Shader "Spine/Skeleton Alpha" {
	Properties {
		_FillColor ("FillColor", Color) = (1,1,1,1)
		_FillPhase ("FillPhase", Range(0, 1)) = 0
        _Alpha ("Alpha", Range(0, 1)) = 0
		_Cutoff ("Shadow alpha cutoff", Range(0,1)) = 0.1
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
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }

		Fog { Mode Off }
		Cull Off
		ZWrite Off
		Blend One OneMinusSrcAlpha
		Lighting Off

		Stencil {
			Ref[_StencilRef]
			Comp[_StencilComp]
			Pass Keep
		}

		Pass {
			Name "Normal"

			CGPROGRAM
			#pragma shader_feature _ _STRAIGHT_ALPHA_INPUT
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			float4 _FillColor;
			float _FillPhase;
            fixed4 _FogColor;
            float _FogStart;
            float _FogAlpha;
            float _Alpha;
			struct VertexInput {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 vertexColor : COLOR;
			};

			struct VertexOutput {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 vertexColor : COLOR;
				float fogWeight : TEXCOORD3;
			};

			VertexOutput vert (VertexInput v) {
				VertexOutput o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.vertexColor = v.vertexColor * _Alpha;

                float4 scrPos = ComputeScreenPos(o.pos);
				float2 screenPosition = (scrPos.xy/scrPos.w);

                // 计算雾化系数
                o.fogWeight = saturate((_FogStart - screenPosition.y)/(_FogStart - 1) * _FogAlpha);
               
				return o;
			}

			float4 frag (VertexOutput i) : SV_Target {
				float4 texColor = tex2D(_MainTex, i.uv);
				float finalAlpha = texColor.a * i.vertexColor.a;

				#if defined(_STRAIGHT_ALPHA_INPUT)
				texColor.rgb *= texColor.a;
				#endif
				texColor *= i.vertexColor;
				texColor.rgb = lerp(texColor.rgb, (_FillColor.rgb * finalAlpha), _FillPhase);
                texColor.rgb = lerp(texColor.rgb, texColor.rgb * _FogColor.rgb * texColor.a, i.fogWeight);
				return texColor;
			}
			ENDCG
		}
	}
	CustomEditor "SpineShaderWithOutlineGUI"
}

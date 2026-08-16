// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// - Unlit
// - Premultiplied Alpha Blending (Optional straight alpha input)
// - Double-sided, no depth

Shader "Spine/Skeleton All In One" {
	Properties {
	    
		_FillColor ("FillColor", Color) = (1,1,1,1)
		_FillPhase ("FillPhase", Range(0, 1)) = 0

		_Attract_Pos   ("Attract Position", Vector) = (0, 0, 0, 0)
		_Attract_Range ("Attract Range", Float) = 0
		_Attract_Rate ("Attract Rate", Range(0, 1)) = 0
		_WaveSpd ("Wave Spd", Float) = 0
		_WaveLength ("Wave Length", Float) = 0
		_WaveStrength ("Wave Strength", Float) = 0
		[NoScaleOffset] _MainTex ("MainTex", 2D) = "white" {}
		
		[Toggle(_STRAIGHT_ALPHA_INPUT)] _StraightAlphaInput("Straight Alpha Texture", Int) = 0
		[HideInInspector] _StencilRef("Stencil Reference", Float) = 1.0
		[HideInInspector][Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil Comparison", Float) = 8 // Set to Always as default

		// Outline properties are drawn via custom editor.
        //[MaterialToggle(OUTLINE_ON)] _UseOutline("Use outline", Float) = 0
        _OutlineAlpha ("Outline Alpha", Range(0, 1)) = 0
		_OutlineWidth("Outline Width", Range(0,8)) = 3.0
		_OutlineColor("Outline Color", Color) = (1,1,0,1)
		_OutlineReferenceTexWidth("Reference Texture Width", Int) = 1024
		_ThresholdEnd("Outline Threshold", Range(0,1)) = 0.25
		_OutlineSmoothness("Outline Smoothness", Range(0,1)) = 1.0
		[MaterialToggle(_USE8NEIGHBOURHOOD_ON)] _Use8Neighbourhood("Sample 8 Neighbours", Float) = 1
		_OutlineMipLevel("Outline Mip Level", Range(0,3)) = 0
	}
	SubShader {

		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
		Blend One OneMinusSrcAlpha
		Cull Off
		ZWrite Off
		Lighting Off
		Stencil {
			Ref[_StencilRef]
			Comp[_StencilComp]
			Pass Keep
		}
		
	    Pass {
			Name "Outline"
			CGPROGRAM
			#pragma multi_compile_local __ _USE8NEIGHBOURHOOD_ON
			//#pragma multi_compile_local __ OUTLINE_ON
			#pragma vertex vertOutline
			#pragma fragment fragOutline
            
            #include "UnityCG.cginc"
            
            #ifdef SKELETON_GRAPHIC
            #include "UnityUI.cginc"
            #endif
            
            sampler2D _MainTex;
            
            //#ifdef OUTLINE_ON
            float _OutlineAlpha;
            float _OutlineWidth;
            float4 _OutlineColor;
            float4 _MainTex_TexelSize;
            float _ThresholdEnd;
            float _OutlineSmoothness;
            float _OutlineMipLevel;
            int _OutlineReferenceTexWidth;
            //#endif
            
            float4 _Attract_Pos;
            float _Attract_Range;
            float _Attract_Rate;
            
            float _WaveLength;
            float _WaveStrength;
            float _WaveSpd;
            
            #ifdef SKELETON_GRAPHIC
            float4 _ClipRect;
            #endif
            
            struct VertexInput {
            	float4 vertex : POSITION;
            	float2 uv : TEXCOORD0;
            	float4 vertexColor : COLOR;
            	UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct VertexOutput {
            	float4 pos : SV_POSITION;
            	float2 uv : TEXCOORD0;
            	float vertexColorAlpha : COLOR;
            #ifdef SKELETON_GRAPHIC
            	float4 worldPosition : TEXCOORD1;
            #endif
            	UNITY_VERTEX_OUTPUT_STEREO
            };
            
            float4 attract (in float4 v)
		    {
		        v.y += sin(_Time.y * _WaveSpd + v.x * _WaveLength) * _WaveStrength * _Attract_Rate;
			    float3 wldpos = mul(unity_ObjectToWorld, v).xyz;
			    float dist = distance(wldpos, _Attract_Pos.xyz);
			    float3 newWldpos = wldpos;
			    newWldpos.xyz += normalize(_Attract_Pos.xyz - newWldpos.xyz) * (_Attract_Range - dist)*_Attract_Rate;
				if (dot((wldpos - _Attract_Pos.xyz), (_Attract_Pos.xyz - newWldpos)) > 0)
					newWldpos.xyz = _Attract_Pos.xyz;
			    return mul(unity_WorldToObject, float4(newWldpos, 1.0));
		    }
            
            #ifdef SKELETON_GRAPHIC
            
            VertexOutput vertOutlineGraphic(VertexInput v) {
            	VertexOutput o;
            
            	UNITY_SETUP_INSTANCE_ID(v);
            	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

            	o.worldPosition = attract(v.vertex);
            	o.pos = UnityObjectToClipPos(o.worldPosition);
            	o.uv = v.uv;
            
            #ifdef UNITY_HALF_TEXEL_OFFSET
            	o.pos.xy += (_ScreenParams.zw - 1.0) * float2(-1, 1);
            #endif
            	o.vertexColorAlpha = v.vertexColor.a;
            
            	return o;
            }
            
            #else // !SKELETON_GRAPHIC

            VertexOutput vertOutline(VertexInput v) {
            	VertexOutput o;
            
            	UNITY_SETUP_INSTANCE_ID(v);
            	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

            	o.pos = UnityObjectToClipPos(attract(v.vertex));
            	o.uv = v.uv;
            	o.vertexColorAlpha = v.vertexColor.a;
            
            	return o;
            }
            #endif
            
            float4 fragOutline(VertexOutput i) : SV_Target {
            
            	float4 texColor = fixed4(0,0,0,0);
            //#ifdef OUTLINE_ON
            	float outlineWidthCompensated = _OutlineWidth / (_OutlineReferenceTexWidth * _MainTex_TexelSize.x);
            	float xOffset = _MainTex_TexelSize.x * outlineWidthCompensated;
            	float yOffset = _MainTex_TexelSize.y * outlineWidthCompensated;
            	float xOffsetDiagonal = _MainTex_TexelSize.x * outlineWidthCompensated * 0.7;
            	float yOffsetDiagonal = _MainTex_TexelSize.y * outlineWidthCompensated * 0.7;
            
            	float pixelCenter = tex2D(_MainTex, i.uv).a;
            
            	float4 uvCenterWithLod = float4(i.uv, 0, _OutlineMipLevel);
            	float pixelTop = tex2Dlod(_MainTex, uvCenterWithLod + float4(0,  yOffset, 0, 0)).a;
            	float pixelBottom = tex2Dlod(_MainTex, uvCenterWithLod + float4(0, -yOffset, 0, 0)).a;
            	float pixelLeft = tex2Dlod(_MainTex, uvCenterWithLod + float4(-xOffset, 0, 0, 0)).a;
            	float pixelRight = tex2Dlod(_MainTex, uvCenterWithLod + float4(xOffset, 0, 0, 0)).a;
            #if _USE8NEIGHBOURHOOD_ON
            	float numSamples = 8;
            	float pixelTopLeft = tex2Dlod(_MainTex, uvCenterWithLod + float4(-xOffsetDiagonal, yOffsetDiagonal, 0, 0)).a;
            	float pixelTopRight = tex2Dlod(_MainTex, uvCenterWithLod + float4(xOffsetDiagonal, yOffsetDiagonal, 0, 0)).a;
            	float pixelBottomLeft = tex2Dlod(_MainTex, uvCenterWithLod + float4(-xOffsetDiagonal, -yOffsetDiagonal, 0, 0)).a;
            	float pixelBottomRight = tex2Dlod(_MainTex, uvCenterWithLod + float4(xOffsetDiagonal, -yOffsetDiagonal, 0, 0)).a;
            	float average = (pixelTop + pixelBottom + pixelLeft + pixelRight +
            		pixelTopLeft + pixelTopRight + pixelBottomLeft + pixelBottomRight)
            		* i.vertexColorAlpha / numSamples;
            #else // 4 neighbourhood
            	float numSamples = 1;
            	float average = (pixelTop + pixelBottom + pixelLeft + pixelRight) * i.vertexColorAlpha / numSamples;
            #endif
            
            	float thresholdStart = _ThresholdEnd * (1.0 - _OutlineSmoothness);
            	float outlineAlpha = saturate((average - thresholdStart) / (_ThresholdEnd - thresholdStart)) - pixelCenter;
            	texColor.rgba = lerp(texColor, _OutlineColor, outlineAlpha * _OutlineAlpha);
            
            #ifdef SKELETON_GRAPHIC
            	texColor *= UnityGet2DClipping(i.worldPosition.xy, _ClipRect);
            #endif
            //#endif //OUTLINE_ON
            	return texColor;
            }
            ENDCG
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
            float4 _Attract_Pos;
		    float _Attract_Range;
		    float _Attract_Rate;
            float _WaveLength;
            float _WaveStrength;
            float _WaveSpd;
            
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

            float4 attract (in float4 v)
		    {
		        v.y += sin(_Time.y * _WaveSpd + v.x * _WaveLength) * _WaveStrength * _Attract_Rate;
			    float3 wldpos = mul(unity_ObjectToWorld, v).xyz;
			    float dist = distance(wldpos, _Attract_Pos.xyz);
			    float3 newWldpos = wldpos;
			    newWldpos.xyz += normalize(_Attract_Pos.xyz - newWldpos.xyz) * (_Attract_Range - dist)*_Attract_Rate;
				if (dot((wldpos - _Attract_Pos.xyz), (_Attract_Pos.xyz - newWldpos)) > 0)
					newWldpos.xyz = _Attract_Pos.xyz;
			    return mul(unity_WorldToObject, float4(newWldpos, 1.0));
		    }
		    
			VertexOutput vert (VertexInput v) {
				VertexOutput o = (VertexOutput)0;
				o.uv = v.uv;
				o.vertexColor = v.vertexColor;
				o.pos = UnityObjectToClipPos(attract(v.vertex));
				
				float4 scrPos = ComputeScreenPos(o.pos);
				float2 screenPosition = (scrPos.xy/scrPos.w);

                // 计算雾化系数
                o.fogWeight = saturate((_FogStart - screenPosition.y)/(_FogStart - 1) * _FogAlpha);
				return o;
			}

			float4 frag (VertexOutput i) : SV_Target {
				float4 rawColor = tex2D(_MainTex,i.uv);
				
				float finalAlpha = (rawColor.a * i.vertexColor.a);

				#if defined(_STRAIGHT_ALPHA_INPUT)
				rawColor.rgb *= rawColor.a;
				#endif

				float3 finalColor = lerp((rawColor.rgb * i.vertexColor.rgb), _FogColor.rgb * finalAlpha, i.fogWeight); // make sure to PMA _FillColor.
				finalColor = lerp(finalColor, (_FillColor.rgb * finalAlpha), _FillPhase);
				
				return fixed4(finalColor, finalAlpha);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}

// - Unlit
// - Premultiplied Alpha Blending (Optional straight alpha input)
// - Double-sided, no depth

Shader "Spine/Skeleton Fill"
{
    Properties
    {
        _FillColor ("FillColor", Color) = (1,1,1,1)
        _FillPhase ("FillPhase", Range(0, 1)) = 0
        _EffectTex("Effect Tex", 2D) = "black" {}
        _EffectParam ("Effect Spd: xy; Size: zw,", Vector) = (0, 0, 0, 0)
        _EffectColor("Effect Color", Color) = (0,0,0,0)
        [NoScaleOffset] _MainTex ("MainTex", 2D) = "white" {}
        _Cutoff ("Shadow alpha cutoff", Range(0,1)) = 0.1
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
    SubShader
    {
        Tags
        {
            "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane"
        }
        Blend One OneMinusSrcAlpha
        Cull Off
        ZWrite Off
        Lighting Off

        Stencil
        {
            Ref[_StencilRef]
            Comp[_StencilComp]
            Pass Keep
        }

        Pass
        {
            Name "Normal"

            CGPROGRAM
            #pragma shader_feature _ _STRAIGHT_ALPHA_INPUT
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "CGIncludes/Spine-Common.cginc"
            sampler2D _MainTex;
            float4 _FillColor;
            float _FillPhase;
            fixed4 _FogColor;
            float _FogStart;
            float _FogAlpha;
            sampler2D _EffectTex;
            float4 _EffectParam;
            float4 _EffectColor;

            struct VertexInput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            struct VertexOutput
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR;
                float fogWeight : TEXCOORD3;
                float2 screenPos : TEXCOORD4;
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.uv = v.uv;
                o.vertexColor = PMAGammaToTargetSpace(v.vertexColor);
                o.pos = UnityObjectToClipPos(v.vertex);

                float4 scrPos = ComputeScreenPos(o.pos);
                o.screenPos = (scrPos.xy / scrPos.w);

                // 计算雾化系数
                o.fogWeight = saturate((_FogStart - o.screenPos.y) / (_FogStart - 1) * _FogAlpha);
                return o;
            }

            float4 frag(VertexOutput i) : SV_Target
            {
                float4 rawColor = tex2D(_MainTex, i.uv);
                float finalAlpha = (rawColor.a * i.vertexColor.a);

                #if defined(_STRAIGHT_ALPHA_INPUT)
				rawColor.rgb *= rawColor.a;
                #endif

                float3 finalColor = lerp((rawColor.rgb * i.vertexColor.rgb), _FogColor.rgb * finalAlpha, i.fogWeight);
                // make sure to PMA _FillColor.
                finalColor = lerp(finalColor, (_FillColor.rgb * finalAlpha), _FillPhase);

                //计算流光宽度uv坐标越少，则获取白色流光图白色区域越大，就等于流光长度
                float2 uv = i.uv / _EffectParam.zw;
                //流光图y轴偏移
                uv.y += _Time.y * _EffectParam.y;
                //流光图x轴偏移
                uv.x += _Time.y * _EffectParam.x;
                fixed light = tex2D(_EffectTex, uv).b;

                finalColor = lerp(finalColor, finalColor + light * _EffectColor.rgb * finalAlpha, _EffectColor.a);
                return fixed4(finalColor, finalAlpha);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
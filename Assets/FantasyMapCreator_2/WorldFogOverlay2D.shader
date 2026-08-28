Shader "Custom/URP2D/WorldFogOverlay2D"
{
    Properties
    {
        [MainColor] _FogColor ("Fog Color", Color) = (0.055, 0.075, 0.11, 1)
        _FogMask ("Fog Mask (White=Fog, Black=Clear)", 2D) = "white" {}
        _NoiseTex ("Noise Tex", 2D) = "white" {}
        _BaseAlpha ("Base Alpha", Range(0,1)) = 0.88
        _NoiseScale ("Noise Scale", Float) = 2.0
        _NoiseStrength ("Noise Strength", Range(0,1)) = 0.25
        _FogSpeedX ("Fog Speed X", Float) = 0.01
        _FogSpeedY ("Fog Speed Y", Float) = 0.006
        _MaskThreshold ("Mask Threshold", Range(0,1)) = 0.5
        _EdgeSoftness ("Edge Softness", Range(0.001,0.5)) = 0.08
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "IgnoreProjector"="True"
            "CanUseSpriteAtlas"="True"
        }

        Pass
        {
            Name "Universal2D"
            Tags { "LightMode"="Universal2D" }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uvFog : TEXCOORD0;
                float2 uvNoise : TEXCOORD1;
                float4 color : COLOR;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _FogColor;
                float4 _FogMask_ST;
                float4 _NoiseTex_ST;
                float _BaseAlpha;
                float _NoiseScale;
                float _NoiseStrength;
                float _FogSpeedX;
                float _FogSpeedY;
                float _MaskThreshold;
                float _EdgeSoftness;
            CBUFFER_END

            TEXTURE2D(_FogMask);
            SAMPLER(sampler_FogMask);
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uvFog = TRANSFORM_TEX(IN.uv, _FogMask);
                OUT.uvNoise = TRANSFORM_TEX(IN.uv, _NoiseTex);
                OUT.color = IN.color;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float mask = SAMPLE_TEXTURE2D(_FogMask, sampler_FogMask, IN.uvFog).r;
                float2 flow = float2(_FogSpeedX, _FogSpeedY) * _Time.y;
                float2 noiseUV1 = IN.uvNoise * _NoiseScale + flow;
                float2 noiseUV2 = IN.uvNoise * (_NoiseScale * 0.63) - flow * 0.47;
                float noise1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV1).r;
                float noise2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV2).r;
                float noise = saturate(noise1 * 0.65 + noise2 * 0.35);
                float fogArea = smoothstep(_MaskThreshold - _EdgeSoftness,
                    _MaskThreshold + _EdgeSoftness, mask);
                float noiseAlpha = lerp(1.0 - _NoiseStrength, 1.0, noise);
                float finalAlpha = fogArea * _BaseAlpha * noiseAlpha * _FogColor.a * IN.color.a;
                return half4(_FogColor.rgb * IN.color.rgb, finalAlpha);
            }
            ENDHLSL
        }
    }
}

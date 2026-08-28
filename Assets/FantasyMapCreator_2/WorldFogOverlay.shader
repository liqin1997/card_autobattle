Shader "Game/URP2D/WorldMapFog"
{
    Properties
    {
        [Header(Fog)]
        _FogColor ("Fog Color", Color) = (0.055, 0.075, 0.11, 1)
        _FogAlpha ("Fog Alpha", Range(0, 1)) = 0.92

        [Header(Mask)]
        _FogMask ("Fog Mask  White=Fog Black=Clear", 2D) = "white" {}
        _MaskThreshold ("Mask Threshold", Range(0, 1)) = 0.5
        _EdgeSoftness ("Edge Softness", Range(0.001, 0.5)) = 0.08

        [Header(Noise)]
        _NoiseTex ("Noise Texture", 2D) = "gray" {}
        _NoiseScale ("Noise Scale", Float) = 3.0
        _NoiseStrength ("Noise Strength", Range(0, 1)) = 0.18

        _NoiseSpeedX ("Noise Speed X", Float) = 0.015
        _NoiseSpeedY ("Noise Speed Y", Float) = 0.008

        [Header(Edge Distortion)]
        _EdgeNoiseStrength ("Edge Noise Strength", Range(0, 0.5)) = 0.08

        [Header(Edge Glow)]
        _EdgeColor ("Edge Color", Color) = (0.06, 0.35, 0.45, 1)
        _EdgeGlowStrength ("Edge Glow Strength", Range(0, 2)) = 0.35
        _EdgeGlowWidth ("Edge Glow Width", Range(0.001, 0.5)) = 0.08
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "IgnoreProjector" = "True"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off
        ZTest LEqual

        // =========================================================
        // URP 2D Renderer
        // =========================================================
        Pass
        {
            Name "Universal2D"
            Tags
            {
                "LightMode" = "Universal2D"
            }

            HLSLPROGRAM

            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float4 color      : COLOR;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float4 color      : COLOR;
            };

            TEXTURE2D(_FogMask);
            SAMPLER(sampler_FogMask);

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            CBUFFER_START(UnityPerMaterial)

                float4 _FogColor;

                float _FogAlpha;

                float _MaskThreshold;
                float _EdgeSoftness;

                float _NoiseScale;
                float _NoiseStrength;

                float _NoiseSpeedX;
                float _NoiseSpeedY;

                float _EdgeNoiseStrength;

                float4 _EdgeColor;
                float _EdgeGlowStrength;
                float _EdgeGlowWidth;

            CBUFFER_END


            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionCS =
                    TransformObjectToHClip(IN.positionOS.xyz);

                OUT.uv = IN.uv;
                OUT.color = IN.color;

                return OUT;
            }


            float SampleNoise(float2 uv)
            {
                float2 timeOffset =
                    float2(
                        _NoiseSpeedX,
                        _NoiseSpeedY
                    ) * _Time.y;


                // 第一层大范围噪声
                float noiseA =
                    SAMPLE_TEXTURE2D(
                        _NoiseTex,
                        sampler_NoiseTex,
                        uv * _NoiseScale + timeOffset
                    ).r;


                // 第二层反方向移动
                float noiseB =
                    SAMPLE_TEXTURE2D(
                        _NoiseTex,
                        sampler_NoiseTex,
                        uv * (_NoiseScale * 0.63)
                        - timeOffset * 0.72
                    ).r;


                return noiseA * 0.65 + noiseB * 0.35;
            }


            half4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.uv;


                // -------------------------------------------------
                // Noise
                // -------------------------------------------------

                float noise =
                    SampleNoise(uv);


                float centeredNoise =
                    noise - 0.5;


                // -------------------------------------------------
                // Fog Mask
                //
                // White = Fog
                // Black = Clear
                // -------------------------------------------------

                float mask =
                    SAMPLE_TEXTURE2D(
                        _FogMask,
                        sampler_FogMask,
                        uv
                    ).r;


                // Noise 只轻微扰动边缘
                float distortedMask =
                    mask +
                    centeredNoise *
                    _EdgeNoiseStrength;


                // -------------------------------------------------
                // Soft Fog Edge
                // -------------------------------------------------

                float fogArea =
                    smoothstep(
                        _MaskThreshold - _EdgeSoftness,
                        _MaskThreshold + _EdgeSoftness,
                        distortedMask
                    );


                // -------------------------------------------------
                // Fog内部轻微明暗变化
                // -------------------------------------------------

                float fogNoise =
                    lerp(
                        1.0 - _NoiseStrength,
                        1.0,
                        noise
                    );


                float fogAlpha =
                    fogArea *
                    _FogAlpha *
                    fogNoise *
                    IN.color.a;


                // -------------------------------------------------
                // Edge Glow
                //
                // 只在 Fog / Clear 交界附近出现
                // -------------------------------------------------

                float edgeDistance =
                    abs(
                        distortedMask -
                        _MaskThreshold
                    );


                float edge =
                    1.0 -
                    smoothstep(
                        0.0,
                        _EdgeGlowWidth,
                        edgeDistance
                    );


                // 避免整个灰色区域全部发光
                edge *= saturate(mask * 4.0);


                // -------------------------------------------------
                // Final Color
                // -------------------------------------------------

                float3 finalColor =
                    _FogColor.rgb;


                finalColor +=
                    _EdgeColor.rgb *
                    edge *
                    _EdgeGlowStrength;


                return half4(
                    finalColor,
                    saturate(
                        fogAlpha +
                        edge *
                        _EdgeColor.a *
                        _EdgeGlowStrength
                    )
                );
            }

            ENDHLSL
        }


        // =========================================================
        // Fallback
        //
        // 有些 UI / Renderer Feature / URP版本
        // 会使用 SRPDefaultUnlit
        // =========================================================
        Pass
        {
            Name "SRPDefaultUnlit"

            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }

            HLSLPROGRAM

            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float4 color      : COLOR;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float4 color      : COLOR;
            };

            TEXTURE2D(_FogMask);
            SAMPLER(sampler_FogMask);

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);


            CBUFFER_START(UnityPerMaterial)

                float4 _FogColor;

                float _FogAlpha;

                float _MaskThreshold;
                float _EdgeSoftness;

                float _NoiseScale;
                float _NoiseStrength;

                float _NoiseSpeedX;
                float _NoiseSpeedY;

                float _EdgeNoiseStrength;

                float4 _EdgeColor;
                float _EdgeGlowStrength;
                float _EdgeGlowWidth;

            CBUFFER_END


            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionCS =
                    TransformObjectToHClip(
                        IN.positionOS.xyz
                    );

                OUT.uv = IN.uv;
                OUT.color = IN.color;

                return OUT;
            }


            float SampleNoise(float2 uv)
            {
                float2 timeOffset =
                    float2(
                        _NoiseSpeedX,
                        _NoiseSpeedY
                    ) * _Time.y;


                float noiseA =
                    SAMPLE_TEXTURE2D(
                        _NoiseTex,
                        sampler_NoiseTex,
                        uv * _NoiseScale + timeOffset
                    ).r;


                float noiseB =
                    SAMPLE_TEXTURE2D(
                        _NoiseTex,
                        sampler_NoiseTex,
                        uv * (_NoiseScale * 0.63)
                        - timeOffset * 0.72
                    ).r;


                return noiseA * 0.65
                     + noiseB * 0.35;
            }


            half4 frag(Varyings IN) : SV_Target
            {
                float2 uv =
                    IN.uv;


                float noise =
                    SampleNoise(uv);


                float centeredNoise =
                    noise - 0.5;


                float mask =
                    SAMPLE_TEXTURE2D(
                        _FogMask,
                        sampler_FogMask,
                        uv
                    ).r;


                float distortedMask =
                    mask +
                    centeredNoise *
                    _EdgeNoiseStrength;


                float fogArea =
                    smoothstep(
                        _MaskThreshold - _EdgeSoftness,
                        _MaskThreshold + _EdgeSoftness,
                        distortedMask
                    );


                float fogNoise =
                    lerp(
                        1.0 - _NoiseStrength,
                        1.0,
                        noise
                    );


                float fogAlpha =
                    fogArea *
                    _FogAlpha *
                    fogNoise *
                    IN.color.a;


                float edgeDistance =
                    abs(
                        distortedMask -
                        _MaskThreshold
                    );


                float edge =
                    1.0 -
                    smoothstep(
                        0.0,
                        _EdgeGlowWidth,
                        edgeDistance
                    );


                edge *=
                    saturate(mask * 4.0);


                float3 finalColor =
                    _FogColor.rgb;


                finalColor +=
                    _EdgeColor.rgb *
                    edge *
                    _EdgeGlowStrength;


                return half4(
                    finalColor,
                    saturate(
                        fogAlpha +
                        edge *
                        _EdgeColor.a *
                        _EdgeGlowStrength
                    )
                );
            }

            ENDHLSL
        }
    }

    FallBack Off
}
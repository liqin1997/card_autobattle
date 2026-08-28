Shader "CardFX/GoldenCard"
{
    Properties
    {
        [PerRendererData] _MainTex ("Raw", 2D) = "white" {}
        [HideInInspector] _Color ("Tint", Color) = (1,1,1,1)
        _MaskTex ("Mask", 2D) = "white" {}

        [Toggle] _DistortEnabled ("Distort", Float) = 0
        _DisturbAmpX ("DisturbAmpX", Range(-1, 1)) = 0.02
        _DisturbAmpY ("DisturbAmpY", Range(-1, 1)) = 0.02
        _DistortTex ("Tex", 2D) = "gray" {}
        [HDR] _DistortColor ("Col", Color) = (1,1,1,1)
        _DistortAngle ("Angle", Range(-180, 180)) = 0
        [Toggle] _DistortPolar ("Polar", Float) = 0
        _DistortPanX ("PanX", Float) = 0.2
        _DistortPanY ("PanY", Float) = 0.1
        _DistortRotV ("RotV", Float) = 0
        _DistortSpiral ("Spiral", Float) = 0
        _DistortFlashV ("FlashV", Float) = 0
        [Enum(R,0,G,1,B,2,A,3)] _DistortChannel ("Channel", Float) = 0
        [Enum(Additive,0,Screen,1,Multiply,2,Alpha,3)] _DistortBlendMode ("BlendMode", Float) = 0

        [Toggle] _Effect1Enabled ("Effect 1", Float) = 0
        _Effect1Tex ("Tex", 2D) = "black" {}
        [HDR] _Effect1Color ("Col", Color) = (1,1,1,1)
        _Effect1Angle ("Angle", Range(-180, 180)) = 0
        [Toggle] _Effect1Polar ("Polar", Float) = 0
        _Effect1PanX ("PanX", Float) = 0
        _Effect1PanY ("PanY", Float) = 0
        _Effect1RotV ("RotV", Float) = 0
        _Effect1Spiral ("Spiral", Float) = 0
        _Effect1FlashV ("FlashV", Float) = 0
        [Enum(R,0,G,1,B,2,A,3)] _Effect1Channel ("Channel", Float) = 0
        [Enum(Additive,0,Screen,1,Multiply,2,Alpha,3)] _Effect1BlendMode ("BlendMode", Float) = 0

        [Toggle] _Effect2Enabled ("Effect 2", Float) = 0
        _Effect2Tex ("Tex", 2D) = "black" {}
        [HDR] _Effect2Color ("Col", Color) = (1,1,1,1)
        _Effect2Angle ("Angle", Range(-180, 180)) = 0
        [Toggle] _Effect2Polar ("Polar", Float) = 0
        _Effect2PanX ("PanX", Float) = 0
        _Effect2PanY ("PanY", Float) = 0
        _Effect2RotV ("RotV", Float) = 0
        _Effect2Spiral ("Spiral", Float) = 0
        _Effect2FlashV ("FlashV", Float) = 0
        [Enum(R,0,G,1,B,2,A,3)] _Effect2Channel ("Channel", Float) = 0
        [Enum(Additive,0,Screen,1,Multiply,2,Alpha,3)] _Effect2BlendMode ("BlendMode", Float) = 0

        [Toggle] _Effect3Enabled ("Effect 3", Float) = 0
        _Effect3Tex ("Tex", 2D) = "black" {}
        [HDR] _Effect3Color ("Col", Color) = (1,1,1,1)
        _Effect3Angle ("Angle", Range(-180, 180)) = 0
        [Toggle] _Effect3Polar ("Polar", Float) = 0
        _Effect3PanX ("PanX", Float) = 0
        _Effect3PanY ("PanY", Float) = 0
        _Effect3RotV ("RotV", Float) = 0
        _Effect3Spiral ("Spiral", Float) = 0
        _Effect3FlashV ("FlashV", Float) = 0
        [Enum(R,0,G,1,B,2,A,3)] _Effect3Channel ("Channel", Float) = 0
        [Enum(Additive,0,Screen,1,Multiply,2,Alpha,3)] _Effect3BlendMode ("BlendMode", Float) = 0

        [Toggle] _Effect4Enabled ("Effect 4", Float) = 0
        _Effect4Tex ("Tex", 2D) = "black" {}
        [HDR] _Effect4Color ("Col", Color) = (1,1,1,1)
        _Effect4Angle ("Angle", Range(-180, 180)) = 0
        [Toggle] _Effect4Polar ("Polar", Float) = 0
        _Effect4PanX ("PanX", Float) = 0
        _Effect4PanY ("PanY", Float) = 0
        _Effect4RotV ("RotV", Float) = 0
        _Effect4Spiral ("Spiral", Float) = 0
        _Effect4FlashV ("FlashV", Float) = 0
        [Enum(R,0,G,1,B,2,A,3)] _Effect4Channel ("Channel", Float) = 0
        [Enum(Additive,0,Screen,1,Multiply,2,Alpha,3)] _Effect4BlendMode ("BlendMode", Float) = 0

        [Toggle] _StormEnabled ("Storm Timing", Float) = 0
        _StormPeriod ("Strike Period", Range(1, 12)) = 4.5
        _StormDuration ("Strike Duration", Range(0.25, 2)) = 0.9
        _StormPhase ("Phase", Float) = 0
        _StormCloudStrength ("Cloud Flash Strength", Range(0, 2)) = 1
        _StormIdleMinimum ("Idle Lightning Minimum", Range(0, 1)) = 0.06
        _StormIdleSharpness ("Idle Flicker Sharpness", Range(1, 12)) = 5
        _StormRevealSoftness ("Strike Reveal Softness", Range(0.001, 0.15)) = 0.025

        _AnimationSpeed ("Animation Speed", Float) = 1
        _TimeOffset ("Time Offset", Float) = 0
        [Toggle] _UseUV1 ("Use Local UV1", Float) = 0

        [HideInInspector] _StencilComp ("Stencil Comparison", Float) = 8
        [HideInInspector] _Stencil ("Stencil ID", Float) = 0
        [HideInInspector] _StencilOp ("Stencil Operation", Float) = 0
        [HideInInspector] _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [HideInInspector] _StencilReadMask ("Stencil Read Mask", Float) = 255
        [HideInInspector] _ColorMask ("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use UI Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
            "RenderPipeline"="UniversalPipeline"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "GoldenCard"

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #define CARD_FX_PI 3.14159265359
            #define CARD_FX_TWO_PI 6.28318530718

            struct appdata_t
            {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                float2 localUv : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 rawUv : TEXCOORD0;
                float2 effectUv : TEXCOORD1;
                float4 worldPosition : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _TextureSampleAdd;
            fixed4 _Color;

            sampler2D _MaskTex;
            float4 _MaskTex_ST;

            sampler2D _DistortTex;
            float4 _DistortTex_ST;
            float _DistortEnabled;
            float _DisturbAmpX;
            float _DisturbAmpY;
            float4 _DistortColor;
            float _DistortAngle;
            float _DistortPolar;
            float _DistortPanX;
            float _DistortPanY;
            float _DistortRotV;
            float _DistortSpiral;
            float _DistortFlashV;
            float _DistortChannel;
            float _DistortBlendMode;

            sampler2D _Effect1Tex;
            float4 _Effect1Tex_ST;
            float _Effect1Enabled;
            float4 _Effect1Color;
            float _Effect1Angle;
            float _Effect1Polar;
            float _Effect1PanX;
            float _Effect1PanY;
            float _Effect1RotV;
            float _Effect1Spiral;
            float _Effect1FlashV;
            float _Effect1Channel;
            float _Effect1BlendMode;

            sampler2D _Effect2Tex;
            float4 _Effect2Tex_ST;
            float _Effect2Enabled;
            float4 _Effect2Color;
            float _Effect2Angle;
            float _Effect2Polar;
            float _Effect2PanX;
            float _Effect2PanY;
            float _Effect2RotV;
            float _Effect2Spiral;
            float _Effect2FlashV;
            float _Effect2Channel;
            float _Effect2BlendMode;

            sampler2D _Effect3Tex;
            float4 _Effect3Tex_ST;
            float _Effect3Enabled;
            float4 _Effect3Color;
            float _Effect3Angle;
            float _Effect3Polar;
            float _Effect3PanX;
            float _Effect3PanY;
            float _Effect3RotV;
            float _Effect3Spiral;
            float _Effect3FlashV;
            float _Effect3Channel;
            float _Effect3BlendMode;

            sampler2D _Effect4Tex;
            float4 _Effect4Tex_ST;
            float _Effect4Enabled;
            float4 _Effect4Color;
            float _Effect4Angle;
            float _Effect4Polar;
            float _Effect4PanX;
            float _Effect4PanY;
            float _Effect4RotV;
            float _Effect4Spiral;
            float _Effect4FlashV;
            float _Effect4Channel;
            float _Effect4BlendMode;

            float _StormEnabled;
            float _StormPeriod;
            float _StormDuration;
            float _StormPhase;
            float _StormCloudStrength;
            float _StormIdleMinimum;
            float _StormIdleSharpness;
            float _StormRevealSoftness;

            float _AnimationSpeed;
            float _TimeOffset;
            float _UseUV1;
            float4 _ClipRect;

            v2f vert(appdata_t input)
            {
                v2f output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.worldPosition = input.vertex;
                output.vertex = UnityObjectToClipPos(input.vertex);
                output.rawUv = TRANSFORM_TEX(input.texcoord, _MainTex);
                output.effectUv = lerp(input.texcoord, input.localUv, saturate(_UseUV1));
                output.color = input.color * _Color;
                return output;
            }

            float2 Rotate2D(float2 value, float radians)
            {
                float sineValue;
                float cosineValue;
                sincos(radians, sineValue, cosineValue);
                return float2(
                    value.x * cosineValue - value.y * sineValue,
                    value.x * sineValue + value.y * cosineValue);
            }

            float2 BuildEffectUV(
                float2 uv,
                float4 textureST,
                float angle,
                float polar,
                float panX,
                float panY,
                float rotationVelocity,
                float spiral,
                float animationTime)
            {
                float animatedAngle = radians(angle) + animationTime * rotationVelocity * CARD_FX_TWO_PI;
                float2 centered = Rotate2D(uv - 0.5, animatedAngle);
                float2 cartesianUv = centered + 0.5;

                float radius = length(centered) * 2.0;
                float polarAngle = atan2(centered.y, centered.x) / CARD_FX_TWO_PI + 0.5;
                polarAngle += radius * spiral;
                float2 polarUv = float2(polarAngle, radius);

                float2 transformedUv = lerp(cartesianUv, polarUv, saturate(polar));
                transformedUv = transformedUv * textureST.xy + textureST.zw;
                transformedUv += float2(panX, panY) * animationTime;
                return transformedUv;
            }

            float SelectMaskChannel(float4 maskSample, float channel)
            {
                float4 distances = abs(channel - float4(0.0, 1.0, 2.0, 3.0));
                float4 weights = 1.0 - step(0.5, distances);
                return dot(maskSample, weights);
            }

            float FlashMultiplier(float velocity, float animationTime)
            {
                float pulse = 0.5 + 0.5 * sin(animationTime * abs(velocity) * CARD_FX_TWO_PI);
                return lerp(1.0, pulse, step(0.0001, abs(velocity)));
            }

            float StormPulse(float value, float center, float halfWidth)
            {
                float pulse = saturate(1.0 - abs(value - center) / max(halfWidth, 0.0001));
                return pulse * pulse * (3.0 - 2.0 * pulse);
            }

            void BuildStormSignals(
                float animationTime,
                float2 uv,
                out float cloudFlash,
                out float idleLightning,
                out float strikeLightning,
                out float strikeDistort)
            {
                float period = max(_StormPeriod, 0.25);
                float duration = min(max(_StormDuration, 0.1), period);
                float eventTime = frac((animationTime + _StormPhase) / period) * period;
                float eventActive = 1.0 - step(duration, eventTime);

                float idleNoise = 0.52
                    + 0.28 * sin(animationTime * 10.73 + sin(animationTime * 1.37) * 1.6)
                    + 0.20 * sin(animationTime * 17.19 + 2.1);
                idleLightning = lerp(
                    _StormIdleMinimum,
                    1.0,
                    pow(saturate(idleNoise), max(_StormIdleSharpness, 1.0)));

                float firstFlash = StormPulse(eventTime, duration * 0.22, duration * 0.22);
                float secondFlash = StormPulse(eventTime, duration * 0.62, duration * 0.16);
                float strikeBody = smoothstep(0.0, duration * 0.12, eventTime)
                    * (1.0 - smoothstep(duration * 0.68, duration, eventTime));

                float revealProgress = saturate((eventTime - duration * 0.035) / max(duration * 0.34, 0.001));
                float revealCutoff = 1.0 - revealProgress;
                float verticalReveal = smoothstep(
                    revealCutoff - _StormRevealSoftness,
                    revealCutoff + _StormRevealSoftness,
                    uv.y);

                cloudFlash = eventActive
                    * saturate(max(firstFlash * 1.15, secondFlash) * _StormCloudStrength);
                strikeLightning = eventActive * verticalReveal
                    * saturate(max(firstFlash, secondFlash) * 1.15 + strikeBody * 0.28);
                strikeDistort = strikeLightning;
                idleLightning *= 1.0 - saturate(cloudFlash * 0.65);
            }

            float3 BlendEffect(float3 baseColor, float3 effectColor, float amount, float blendMode)
            {
                amount = saturate(amount);
                float3 additive = baseColor + effectColor * amount;
                float3 screen = 1.0 - (1.0 - baseColor) * (1.0 - effectColor * amount);
                float3 multiply = lerp(baseColor, baseColor * effectColor, amount);
                float3 alphaBlend = lerp(baseColor, effectColor, amount);

                if (blendMode < 0.5)
                    return additive;
                if (blendMode < 1.5)
                    return screen;
                if (blendMode < 2.5)
                    return multiply;
                return alphaBlend;
            }

            float3 ApplyEffectLayer(
                float3 baseColor,
                sampler2D effectTexture,
                float4 textureST,
                float4 effectTint,
                float enabled,
                float angle,
                float polar,
                float panX,
                float panY,
                float rotationVelocity,
                float spiral,
                float flashVelocity,
                float timingMultiplier,
                float channel,
                float blendMode,
                float2 sourceUv,
                float4 maskSample,
                float animationTime)
            {
                float2 effectUv = BuildEffectUV(
                    sourceUv,
                    textureST,
                    angle,
                    polar,
                    panX,
                    panY,
                    rotationVelocity,
                    spiral,
                    animationTime);

                fixed4 textureSample = tex2D(effectTexture, effectUv);
                float maskAmount = SelectMaskChannel(maskSample, channel);
                float luminanceMask = max(textureSample.r, max(textureSample.g, textureSample.b));
                float amount = enabled * maskAmount * textureSample.a * luminanceMask;
                amount *= effectTint.a * timingMultiplier;
                float3 tintedEffect = textureSample.rgb * effectTint.rgb;
                return BlendEffect(baseColor, tintedEffect, amount, blendMode);
            }

            fixed4 frag(v2f input) : SV_Target
            {
                float animationTime = _Time.y * _AnimationSpeed + _TimeOffset;
                float2 sourceUv = input.effectUv;
                float4 maskSample = tex2D(_MaskTex, TRANSFORM_TEX(sourceUv, _MaskTex));

                float stormCloud;
                float stormIdle;
                float stormStrike;
                float stormDistort;
                BuildStormSignals(
                    animationTime,
                    sourceUv,
                    stormCloud,
                    stormIdle,
                    stormStrike,
                    stormDistort);

                float4 regularTiming = float4(
                    FlashMultiplier(_Effect1FlashV, animationTime),
                    FlashMultiplier(_Effect2FlashV, animationTime),
                    FlashMultiplier(_Effect3FlashV, animationTime),
                    FlashMultiplier(_Effect4FlashV, animationTime));
                float4 stormTiming = float4(1.0, stormCloud, stormIdle, stormStrike);
                float4 effectTiming = lerp(regularTiming, stormTiming, step(0.5, _StormEnabled));

                float2 rawUv = input.rawUv;
                if (_DistortEnabled > 0.5)
                {
                    float2 distortUv = BuildEffectUV(
                        sourceUv,
                        _DistortTex_ST,
                        _DistortAngle,
                        _DistortPolar,
                        _DistortPanX,
                        _DistortPanY,
                        _DistortRotV,
                        _DistortSpiral,
                        animationTime);

                    float4 disturbSample = tex2D(_DistortTex, distortUv) * _DistortColor;
                    float disturbMask = SelectMaskChannel(maskSample, _DistortChannel);
                    float regularDistort = FlashMultiplier(_DistortFlashV, animationTime);
                    float flash = lerp(regularDistort, stormDistort, step(0.5, _StormEnabled));
                    float2 disturbVector = disturbSample.rg * 2.0 - 1.0;
                    rawUv += disturbVector * float2(_DisturbAmpX, _DisturbAmpY) * disturbMask * flash;
                }

                fixed4 rawColor = (tex2D(_MainTex, rawUv) + _TextureSampleAdd) * input.color;
                float3 finalRgb = rawColor.rgb;

                finalRgb = ApplyEffectLayer(finalRgb, _Effect1Tex, _Effect1Tex_ST, _Effect1Color,
                    _Effect1Enabled, _Effect1Angle, _Effect1Polar, _Effect1PanX, _Effect1PanY,
                    _Effect1RotV, _Effect1Spiral, _Effect1FlashV, effectTiming.x, _Effect1Channel,
                    _Effect1BlendMode, sourceUv, maskSample, animationTime);

                finalRgb = ApplyEffectLayer(finalRgb, _Effect2Tex, _Effect2Tex_ST, _Effect2Color,
                    _Effect2Enabled, _Effect2Angle, _Effect2Polar, _Effect2PanX, _Effect2PanY,
                    _Effect2RotV, _Effect2Spiral, _Effect2FlashV, effectTiming.y, _Effect2Channel,
                    _Effect2BlendMode, sourceUv, maskSample, animationTime);

                finalRgb = ApplyEffectLayer(finalRgb, _Effect3Tex, _Effect3Tex_ST, _Effect3Color,
                    _Effect3Enabled, _Effect3Angle, _Effect3Polar, _Effect3PanX, _Effect3PanY,
                    _Effect3RotV, _Effect3Spiral, _Effect3FlashV, effectTiming.z, _Effect3Channel,
                    _Effect3BlendMode, sourceUv, maskSample, animationTime);

                finalRgb = ApplyEffectLayer(finalRgb, _Effect4Tex, _Effect4Tex_ST, _Effect4Color,
                    _Effect4Enabled, _Effect4Angle, _Effect4Polar, _Effect4PanX, _Effect4PanY,
                    _Effect4RotV, _Effect4Spiral, _Effect4FlashV, effectTiming.w, _Effect4Channel,
                    _Effect4BlendMode, sourceUv, maskSample, animationTime);

                fixed4 finalColor = fixed4(finalRgb, rawColor.a);

                #ifdef UNITY_UI_CLIP_RECT
                finalColor.a *= UnityGet2DClipping(input.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip(finalColor.a - 0.001);
                #endif

                return finalColor;
            }
            ENDCG
        }
    }

    CustomEditor "CardFxShaderGUI"
}

Shader "UI/CardCooldownFrontAdditive"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _NoiseTex ("Packed Noise (R:Distort G:Flow B:Spark)", 2D) = "gray" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _Progress ("Cooldown Progress", Range(0,1)) = 0
        _FlashProgress ("Completion Flash Position", Range(0,1)) = 1
        _CoreColor ("White-hot Core", Color) = (0.88,1,0.96,1)
        _GlowColor ("Front Glow", Color) = (0.12,1,0.68,0.9)
        _FlowColor ("Following Flow", Color) = (0.06,0.92,0.72,0.75)
        _ReadyColor ("Near-ready Spark", Color) = (1,1,0.82,1)
        _CorePixels ("Core Radius (Screen Pixels)", Range(0.35,2.0)) = 0.72
        _InnerPixels ("Inner Glow Radius (Screen Pixels)", Range(1.0,8.0)) = 2.8
        _GlowAbovePixels ("Outer Glow Above (Screen Pixels)", Range(2.0,24.0)) = 6.5
        _GlowBelowPixels ("Outer Glow Below (Screen Pixels)", Range(4.0,36.0)) = 15.0
        _LineIntensity ("White Core Intensity", Range(0.2,3.0)) = 1.35
        _TrailHeight ("Flow Trail Height", Range(0.03,0.35)) = 0.13
        _HeadHeight ("Flow Head Height", Range(0.01,0.18)) = 0.065
        _FlowTiling ("Flow Tiling", Vector) = (0.85,3.2,0,0)
        _RiseSpeed ("Texture Rise Speed", Float) = 0.85
        _Distortion ("Micro Distortion", Range(0,0.025)) = 0.002
        _GlowStrength ("Glow Strength", Range(0,4)) = 1.15
        _PhaseOffset ("Per-card Phase", Range(0,1)) = 0
        _TriggerFlash ("Trigger Flash", Range(0,1)) = 0

        [HideInInspector] _StencilComp ("Stencil Comparison", Float) = 8
        [HideInInspector] _Stencil ("Stencil ID", Float) = 0
        [HideInInspector] _StencilOp ("Stencil Operation", Float) = 0
        [HideInInspector] _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [HideInInspector] _StencilReadMask ("Stencil Read Mask", Float) = 255
        [HideInInspector] _ColorMask ("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent+20"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
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
        Blend One One
        ColorMask [_ColorMask]

        Pass
        {
            Name "CardCooldownFrontAdditive"

            CGPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #define TAU 6.28318530718

            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            fixed4 _TextureSampleAdd;
            fixed4 _Color;
            fixed4 _CoreColor;
            fixed4 _GlowColor;
            fixed4 _FlowColor;
            fixed4 _ReadyColor;
            float4 _ClipRect;
            float4 _FlowTiling;
            float _Progress;
            float _FlashProgress;
            float _CorePixels;
            float _InnerPixels;
            float _GlowAbovePixels;
            float _GlowBelowPixels;
            float _LineIntensity;
            float _TrailHeight;
            float _HeadHeight;
            float _RiseSpeed;
            float _Distortion;
            float _GlowStrength;
            float _PhaseOffset;
            float _TriggerFlash;

            v2f vert(appdata_t input)
            {
                v2f output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.worldPosition = input.vertex;
                output.vertex = UnityObjectToClipPos(output.worldPosition);
                output.texcoord = input.texcoord;
                output.color = input.color * _Color;
                return output;
            }

            float SoftBand(float distanceValue, float width, float feather)
            {
                return 1.0 - smoothstep(width, width + feather, abs(distanceValue));
            }

            float CrossSpark(float2 delta, float feather)
            {
                float horizontal = SoftBand(delta.y, 0.0035, feather * 1.25)
                    * (1.0 - smoothstep(0.025, 0.105, abs(delta.x)));
                float vertical = SoftBand(delta.x, 0.006, feather * 1.8)
                    * (1.0 - smoothstep(0.022, 0.115, abs(delta.y)));
                float hotPoint = 1.0 - smoothstep(0.0, 0.022, length(delta * float2(1.0, 1.45)));
                return saturate(max(horizontal, vertical) + hotPoint);
            }

            float RisingWisp(
                float2 uv,
                float localY,
                float center,
                float phase,
                float noiseValue,
                float time,
                float feather)
            {
                float bend = sin(localY * 24.0 + time * 1.55 + phase) * 0.018;
                bend += sin(localY * 53.0 - time * 0.72 + phase * 1.71) * 0.006;
                bend += (noiseValue - 0.5) * 0.007;
                float ribbon = 1.0 - smoothstep(
                    0.003,
                    0.015 + feather * 1.5,
                    abs(uv.x - center - bend));
                float breakup = 0.42 + 0.58 * saturate(
                    0.5 + 0.5 * sin(localY * 57.0 - time * 4.2 + phase + noiseValue * 2.4));
                return ribbon * breakup;
            }

            half4 frag(v2f input) : SV_Target
            {
                float2 uv = input.texcoord;
                float localY = uv.y - _Progress;
                float time = _Time.y;
                float phase = _PhaseOffset * TAU;
                float pixelStepY = max(fwidth(uv.y), 0.00001);
                float feather = pixelStepY * 1.25;

                // Sampling in front-local Y is the key: the texture field travels with the rising line.
                float2 flowUvA = float2(
                    uv.x * _FlowTiling.x + _PhaseOffset + time * 0.075,
                    localY * _FlowTiling.y - time * _RiseSpeed);
                float2 flowUvB = float2(
                    uv.x * (_FlowTiling.x * 1.73) - time * 0.045 + _PhaseOffset * 2.13,
                    localY * (_FlowTiling.y * 0.68) - time * (_RiseSpeed * 1.37));
                fixed4 noiseA = tex2D(_NoiseTex, flowUvA);
                fixed4 noiseB = tex2D(_NoiseTex, flowUvB);

                // Noise only gives the core a sub-pixel shimmer; it must not turn into a thick rope.
                float microDistortion = ((noiseA.r * 0.7 + noiseB.r * 0.3) - 0.5) * _Distortion;
                float lineDistance = localY + microDistortion;
                float distancePixels = abs(lineDistance) / pixelStepY;
                float coreRatio = distancePixels / max(_CorePixels, 0.25);
                float innerRatio = distancePixels / max(_InnerPixels, 0.5);
                float core = exp2(-coreRatio * coreRatio);
                float inner = exp2(-innerRatio * innerRatio);
                float side = smoothstep(-pixelStepY * 1.5, pixelStepY * 1.5, localY);
                float glowRadiusPixels = lerp(_GlowBelowPixels, _GlowAbovePixels, side);
                float glowRatio = distancePixels / max(glowRadiusPixels, 0.5);
                float halo = exp2(-glowRatio * glowRatio);

                float belowFront = 1.0 - smoothstep(-0.003, 0.008, localY);
                float trailFade = smoothstep(-_TrailHeight, -0.006, localY) * belowFront;
                float aboveFront = smoothstep(-0.004, 0.008, localY)
                    * (1.0 - smoothstep(0.0, _HeadHeight, localY));
                float streamWindow = saturate(trailFade + aboveFront * 0.52);

                float risingBands = 0.5 + 0.5 * sin(
                    localY * 38.0 - time * (_RiseSpeed * 7.2) + noiseA.r * 3.2 + phase);
                float texturedFlow = pow(saturate(noiseA.g * 0.82 + noiseB.g * 0.58 - 0.24), 1.75);
                float wisps = texturedFlow * (0.48 + risingBands * 0.52) * streamWindow;

                // A one-dimensional noise lookup produces vertical, animated light shafts around the front.
                float columnNoise = tex2D(_NoiseTex, float2(
                    uv.x * 0.75 + time * 0.055 + _PhaseOffset,
                    0.37 + _PhaseOffset * 0.19)).g;
                float shafts = pow(saturate(columnNoise * 1.32 - 0.16), 2.65)
                    * streamWindow
                    * (0.58 + risingBands * 0.42);

                float wispPhase = phase + time * 0.38;
                float gateA = pow(saturate(0.5 + 0.5 * sin(time * 6.1 + phase)), 5.0);
                float gateB = pow(saturate(0.5 + 0.5 * sin(time * 7.7 + phase + 1.8)), 6.0);
                float gateC = pow(saturate(0.5 + 0.5 * sin(time * 5.3 + phase + 3.6)), 5.0);
                float gateD = pow(saturate(0.5 + 0.5 * sin(time * 8.4 + phase + 5.1)), 6.0);
                float ribbons = RisingWisp(uv, localY, 0.16 + sin(phase) * 0.025,
                    wispPhase, noiseA.r, time, feather) * gateA;
                ribbons += RisingWisp(uv, localY, 0.39 + cos(phase * 1.31) * 0.035,
                    wispPhase + 1.7, noiseB.r, time, feather) * gateB;
                ribbons += RisingWisp(uv, localY, 0.64 + sin(phase * 0.77) * 0.030,
                    wispPhase + 3.5, noiseA.g, time, feather) * gateC;
                ribbons += RisingWisp(uv, localY, 0.84 + cos(phase * 1.17) * 0.022,
                    wispPhase + 5.1, noiseB.g, time, feather) * gateD;
                ribbons *= streamWindow * (0.62 + risingBands * 0.38);

                float ready = smoothstep(0.72, 0.985, _Progress);
                float sparkleClock = time * 1.18 + _PhaseOffset * 2.31;
                float sparkleCycle = frac(sparkleClock);
                float sparkleSeed = floor(sparkleClock);
                float sparkleX = frac(sin(sparkleSeed * 12.9898 + phase * 3.17) * 43758.5453);
                float sparklePulse = 1.0 - smoothstep(0.045, 0.18, abs(sparkleCycle - 0.16));
                float sparkle = CrossSpark(float2(uv.x - sparkleX, lineDistance), feather)
                    * sparklePulse
                    * (0.42 + ready * 0.78);

                float readyGain = 1.0 + ready * 0.28;
                float flashDistance = uv.y - _FlashProgress;
                float flashBand = _TriggerFlash * SoftBand(flashDistance, 0.14, 0.09);
                float flashStar = _TriggerFlash
                    * CrossSpark(float2(uv.x - 0.5, flashDistance), feather)
                    * (0.65 + _TriggerFlash * 0.35);
                float flowAmount = (wisps * 0.12 + shafts * 0.10 + ribbons * 1.20) * readyGain;
                float lineVariation = lerp(0.94, 1.06, noiseA.r);
                float glowAmount = (inner * 0.62 + halo * 0.24) * _GlowStrength * readyGain;
                float coreAmount = core * _LineIntensity * lineVariation * (1.0 + ready * 0.18);

                half3 rgb = _GlowColor.rgb * glowAmount * _GlowColor.a;
                rgb += _FlowColor.rgb * flowAmount * _FlowColor.a;
                rgb += _CoreColor.rgb * coreAmount * _CoreColor.a;
                rgb += _ReadyColor.rgb * (sparkle + flashBand * 0.72 + flashStar * 1.25) * _ReadyColor.a;

                fixed4 source = (tex2D(_MainTex, uv) + _TextureSampleAdd) * input.color;
                float coverage = source.a;

                #ifdef UNITY_UI_CLIP_RECT
                coverage *= UnityGet2DClipping(input.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip(coverage - 0.001);
                #endif

                return half4(rgb * coverage, 0.0);
            }
            ENDCG
        }
    }
}

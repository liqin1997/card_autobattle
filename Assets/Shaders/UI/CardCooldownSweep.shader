Shader "UI/CardCooldownSweep"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _NoiseTex ("Packed Noise (R:Dissolve G:Flow B:Spark)", 2D) = "gray" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _Progress ("Cooldown Progress", Range(0,1)) = 0
        _DarkColor ("Unready Dark", Color) = (0.02,0.04,0.06,0.55)
        _EnergyColor ("Charged Energy", Color) = (0.05,0.85,1,0.16)
        _EdgeColor ("Front Edge", Color) = (0.35,1,1,0.95)
        _ReadyColor ("Near Ready", Color) = (1,0.92,0.48,0.85)
        _UnreadyBrightness ("Unready Brightness", Range(0.1,1)) = 0.52
        _UnreadySaturation ("Unready Saturation", Range(0,1)) = 0.28
        _ChargedBrightness ("Charged Brightness", Range(0.5,1.5)) = 1.02
        _NoiseScale ("Noise Scale", Float) = 3.2
        _NoiseStrength ("Boundary Noise", Range(0,0.12)) = 0.005
        _FlowSpeed ("Flow Speed", Float) = 0.32
        _EdgeWidth ("Edge Width", Range(0.002,0.15)) = 0.006
        _Softness ("Edge Softness", Range(0.001,0.08)) = 0.004
        _DissolveStrength ("Dissolve Strength", Range(0,1)) = 0.24
        _GlowStrength ("Glow Strength", Range(0,4)) = 0.42
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
            "Queue"="Transparent"
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
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "CardCooldownSweep"

            CGPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

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
            fixed4 _DarkColor;
            fixed4 _EnergyColor;
            fixed4 _EdgeColor;
            fixed4 _ReadyColor;
            float4 _ClipRect;
            float _Progress;
            float _NoiseScale;
            float _NoiseStrength;
            float _FlowSpeed;
            float _EdgeWidth;
            float _Softness;
            float _DissolveStrength;
            float _GlowStrength;
            float _TriggerFlash;
            float _UnreadyBrightness;
            float _UnreadySaturation;
            float _ChargedBrightness;

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

            fixed4 frag(v2f input) : SV_Target
            {
                float2 uv = input.texcoord;
                float time = _Time.y * _FlowSpeed;
                float2 noiseUvA = uv * _NoiseScale + float2(time * 0.37, -time);
                float2 noiseUvB = uv * (_NoiseScale * 1.73) + float2(-time * 0.61, time * 0.43);
                fixed4 noiseA = tex2D(_NoiseTex, noiseUvA);
                fixed4 noiseB = tex2D(_NoiseTex, noiseUvB);

                float boundaryNoise = ((noiseA.r * 0.68 + noiseB.r * 0.32) - 0.5) * _NoiseStrength;
                float signedDistance = _Progress - uv.y + boundaryNoise;
                float chargedMask = smoothstep(-_Softness, _Softness, signedDistance);
                float unreadyMask = 1.0 - chargedMask;

                float edgeDistance = abs(signedDistance);
                float edge = 1.0 - smoothstep(_EdgeWidth, _EdgeWidth + _Softness, edgeDistance);
                float dissolve = lerp(1.0, smoothstep(0.20, 0.82, noiseA.r + edge * 0.34), _DissolveStrength);
                edge *= dissolve;

                float flowBand = 0.5 + 0.5 * sin((uv.x * 7.0 + uv.y * 2.2 - time * 3.4 + noiseA.g * 1.8) * 6.2831853);
                float flowEnergy = saturate(0.54 + flowBand * 0.08 + noiseB.g * 0.10);
                float sparks = pow(saturate(noiseA.b * 1.16), 7.0) * edge;
                float readyBoost = smoothstep(0.72, 1.0, _Progress);
                float edgeBoost = _GlowStrength * (1.0 + readyBoost * 1.65);

                fixed4 source = (tex2D(_MainTex, uv) + _TextureSampleAdd) * input.color;
                float luminance = dot(source.rgb, float3(0.2126, 0.7152, 0.0722));
                float3 unready = lerp(luminance.xxx, source.rgb, _UnreadySaturation);
                unready *= _UnreadyBrightness;
                unready = lerp(unready, unready * _DarkColor.rgb, _DarkColor.a * 0.34);

                float3 charged = source.rgb * _ChargedBrightness;
                float energyAmount = _EnergyColor.a * flowEnergy * (0.42 + readyBoost * 0.52);
                charged = lerp(charged, charged * (0.82 + _EnergyColor.rgb * 0.52), energyAmount);
                charged += _EnergyColor.rgb * energyAmount * 0.10;

                float sparkAmount = sparks * (0.30 + readyBoost * 0.72) * _EdgeColor.a;
                float flashAmount = _TriggerFlash * (0.12 + noiseB.b * 0.10);
                float3 rgb = lerp(unready, charged, chargedMask);
                rgb += _EdgeColor.rgb * edge * edgeBoost * _EdgeColor.a * 0.16;
                rgb += _ReadyColor.rgb * (sparkAmount + flashAmount) * 0.18;

                fixed4 output = fixed4(saturate(rgb), source.a);

                #ifdef UNITY_UI_CLIP_RECT
                output.a *= UnityGet2DClipping(input.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip(output.a - 0.001);
                #endif

                return output;
            }
            ENDCG
        }
    }
}

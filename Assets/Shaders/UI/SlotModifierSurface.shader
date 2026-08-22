Shader "UI/SlotModifierSurface"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _MaskTex ("Outline Control Mask", 2D) = "white" {}
        _NoiseTex ("Packed Distortion Noise", 2D) = "gray" {}
        _PrimaryColor ("Primary", Color) = (1,.25,.05,1)
        _SecondaryColor ("Secondary", Color) = (1,.75,.15,1)
        _Pattern ("Pattern", Range(0,6)) = 1
        _Active ("Active", Range(0,1)) = 1
        _OutlineIntensity ("Outline Intensity", Range(0,2)) = 1
        _GlowIntensity ("Glow Intensity", Range(0,2)) = .55
        _PatternIntensity ("Pattern Intensity", Range(0,2)) = .7
        _Distortion ("Edge Distortion", Range(0,.04)) = .008
        _NoiseScale ("Noise Scale", Range(.25,8)) = 2.2
        _NoiseSpeed ("Noise Speed", Vector) = (0,0,0,0)
        _Seed ("Per Slot Seed", Range(0,1)) = 0

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
            Name "SlotModifierSurface"

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
                float2 uv : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            sampler2D _MaskTex;
            sampler2D _NoiseTex;
            fixed4 _TextureSampleAdd;
            fixed4 _Color;
            fixed4 _PrimaryColor;
            fixed4 _SecondaryColor;
            float4 _ClipRect;
            float4 _NoiseSpeed;
            float _Pattern;
            float _Active;
            float _OutlineIntensity;
            float _GlowIntensity;
            float _PatternIntensity;
            float _Distortion;
            float _NoiseScale;
            float _Seed;

            v2f vert(appdata_t input)
            {
                v2f output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.worldPosition = input.vertex;
                output.vertex = UnityObjectToClipPos(input.vertex);
                output.uv = input.texcoord;
                output.color = input.color * _Color;
                return output;
            }

            float PatternMask(float2 uv, float pattern, fixed4 noise)
            {
                float2 p = uv - .5;
                float result;
                if (pattern < 1.5)
                {
                    float flame = sin((uv.x + noise.r * .08) * 27 + uv.y * 7);
                    result = smoothstep(.74, .96, flame * noise.b);
                }
                else if (pattern < 2.5)
                {
                    float slash = abs(frac((uv.x + uv.y * .42 + noise.g * .025) * 8) - .5);
                    result = 1 - smoothstep(.035, .10, slash);
                }
                else if (pattern < 3.5)
                {
                    float rings = abs(frac(length(p * float2(1.55, 1)) * 9 + noise.r * .06) - .5);
                    result = 1 - smoothstep(.05, .15, rings);
                }
                else if (pattern < 4.5)
                {
                    float2 grid = abs(frac((uv + noise.rg * .015) * float2(7,5)) - .5);
                    result = 1 - smoothstep(.035, .10, min(grid.x, grid.y));
                }
                else if (pattern < 5.5)
                {
                    float cells = noise.b * noise.g;
                    result = smoothstep(.54, .82, cells);
                }
                else
                {
                    float2 circuit = abs(frac((uv + noise.gr * .012) * float2(9,6)) - .5);
                    result = (1 - smoothstep(.025, .08, min(circuit.x, circuit.y))) * step(.5, noise.b);
                }
                return saturate(result);
            }

            fixed4 frag(v2f input) : SV_Target
            {
                fixed4 sprite = (tex2D(_MainTex, input.uv) + _TextureSampleAdd) * input.color;

                // The packed texture is intentionally sampled in local UV space. With speed=(0,0)
                // the look is fully static; animation can be enabled later without changing the prefab.
                float2 phase = float2(_Seed, frac(_Seed * 1.731));
                float2 noiseUV = input.uv * _NoiseScale + phase + _Time.y * _NoiseSpeed.xy;
                fixed4 noise = tex2D(_NoiseTex, noiseUV);
                float2 warp = (noise.rg * 2 - 1) * _Distortion;
                fixed4 mask = tex2D(_MaskTex, input.uv + warp);

                // R: outer rounded shape, G: inner cutout, B: soft halo, A: edge accent mask.
                float outline = saturate(mask.r - mask.g);
                float halo = mask.b;
                float accentMask = mask.a;
                float breakup = lerp(.68, 1.18, noise.b);
                outline *= breakup;

                float motif = PatternMask(input.uv, _Pattern, noise) * accentMask;
                float active = lerp(.26, 1, _Active);
                float outlineAlpha = outline * _OutlineIntensity;
                float haloAlpha = halo * _GlowIntensity;
                float motifAlpha = motif * _PatternIntensity * (.35 + .65 * noise.a);

                fixed3 rgb = _PrimaryColor.rgb * (outlineAlpha + haloAlpha * .48);
                rgb += _SecondaryColor.rgb * (motifAlpha + outline * noise.a * .28);
                float alpha = saturate(outlineAlpha * .94 + haloAlpha * .34 + motifAlpha * .52);

                fixed4 output = fixed4(rgb * active, alpha * active * sprite.a);

                #ifdef UNITY_UI_CLIP_RECT
                output.a *= UnityGet2DClipping(input.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip(output.a - .001);
                #endif

                return output;
            }
            ENDCG
        }
    }
}

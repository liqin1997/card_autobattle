// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Mobile/Particles/Alpha Blended Distort"
{
    Properties
    {
        _TintColor("Tint Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _MainTex("Particle Texture", 2D) = "white" {}
        _DistortNormalMap("NormalMap", 2D) = "bump" {}
        _Distortion("Distortion", Float) = 0.5
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" }

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off

        Pass
        {
            Name "UnlitDistortion"
            Tags { "LightMode"="SRPDefaultUnlit" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_particles
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_DistortNormalMap); SAMPLER(sampler_DistortNormalMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _DistortNormalMap_ST;
                half4 _TintColor;
                float _Distortion;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                half4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uvMain : TEXCOORD0;
                float2 uvNormal : TEXCOORD1;
                half4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uvMain = input.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                output.uvNormal = input.uv * _DistortNormalMap_ST.xy + _DistortNormalMap_ST.zw;
                output.color = input.color;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half3 normal = UnpackNormal(SAMPLE_TEXTURE2D(_DistortNormalMap, sampler_DistortNormalMap, input.uvNormal));
                float2 screenUV = GetNormalizedScreenSpaceUV(input.positionHCS);
                screenUV += normal.xy * (_Distortion * 0.01);
                half3 sceneColor = SampleSceneColor(saturate(screenUV));
                half4 particle = 2.0h * input.color * _TintColor * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uvMain);
                return half4(sceneColor, particle.a);
            }
            ENDHLSL
        }
    }
}

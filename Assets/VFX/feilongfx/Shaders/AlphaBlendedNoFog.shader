Shader "Mobile/Particles/Alpha Blended No Fog" {
Properties {
    _MainTex ("Particle Texture", 2D) = "white" {}
    _TintColor ("Tint Color", Color) = (1, 1, 1, 1)
}

SubShader {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "RenderPipeline"="UniversalPipeline" }
    Blend SrcAlpha OneMinusSrcAlpha
    Cull Off
    ZWrite Off

    Pass {
        Name "Unlit"
        Tags { "LightMode"="SRPDefaultUnlit" }
        HLSLPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_instancing
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _TintColor;
        CBUFFER_END

        struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; half4 color : COLOR; UNITY_VERTEX_INPUT_INSTANCE_ID };
        struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; half4 color : COLOR; UNITY_VERTEX_INPUT_INSTANCE_ID UNITY_VERTEX_OUTPUT_STEREO };

        Varyings vert(Attributes input) {
            Varyings output;
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_TRANSFER_INSTANCE_ID(input, output);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
            output.uv = input.uv * _MainTex_ST.xy + _MainTex_ST.zw;
            output.color = input.color;
            return output;
        }

        half4 frag(Varyings input) : SV_Target {
            UNITY_SETUP_INSTANCE_ID(input);
            half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
            return color * _TintColor * input.color * 2.0h;
        }
        ENDHLSL
    }
}
}

Shader "base_toon"
{
    Properties { _ASEOutlineColor("Outline Color",Color)=(0,0,0,1) _ASEOutlineWidth("Outline Width",Float)=0 _TextureSample0("Texture Sample 0",2D)="white"{} }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
        Pass
        {
            Name "Outline" Tags { "LightMode"="SRPDefaultUnlit" } Cull Front
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct A{float4 positionOS:POSITION;float3 normalOS:NORMAL;}; struct V{float4 positionCS:SV_POSITION;};
            CBUFFER_START(UnityPerMaterial) float4 _ASEOutlineColor; float _ASEOutlineWidth; CBUFFER_END
            V vert(A i){V o;o.positionCS=TransformObjectToHClip(i.positionOS.xyz+i.normalOS*_ASEOutlineWidth);return o;}
            half4 frag(V i):SV_Target{return _ASEOutlineColor;}
            ENDHLSL
        }
        Pass
        {
            Name "Toon" Tags { "LightMode"="UniversalForward" } Cull Back
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            TEXTURE2D(_TextureSample0);SAMPLER(sampler_TextureSample0);
            struct A{float4 positionOS:POSITION;float3 normalOS:NORMAL;float2 uv:TEXCOORD0;}; struct V{float4 positionCS:SV_POSITION;float3 normalWS:TEXCOORD0;float3 viewWS:TEXCOORD1;float2 uv:TEXCOORD2;};
            V vert(A i){V o;VertexPositionInputs p=GetVertexPositionInputs(i.positionOS.xyz);o.positionCS=p.positionCS;o.normalWS=TransformObjectToWorldNormal(i.normalOS);o.viewWS=GetWorldSpaceNormalizeViewDir(p.positionWS);o.uv=i.uv;return o;}
            half4 frag(V i):SV_Target{float f=dot(normalize(i.normalWS),normalize(i.viewWS))*.5+.5;return SAMPLE_TEXTURE2D(_TextureSample0,sampler_TextureSample0,float2(1-f,i.uv.y));}
            ENDHLSL
        }
    }
}

Shader "Base_3D"
{
    Properties
    {
        _Float0("outline_width",Float)=0 _Cutoff("Mask Clip Value",Float)=0.5 [HDR]_outline_color("outline_color",Color)=(1,1,1,1)
        _TextureSample0("MainTex",2D)="white"{} _Vector0("主贴图scale/offset",Vector)=(1,1,0,0) _Vector1("高光贴图scale/offset",Vector)=(1,1,0,0)
        float11("高光贴图流动间隔",Float)=0 _TextureSample1("高光贴图",2D)="white"{} _Float5("关闭假高光",Float)=0 _Vector2("Speed",Vector)=(0,0,0,0)
        _Color0("light_color",Color)=(1,1,1,1) _TextureSample2("溶解贴图",2D)="white"{} _Vector3("溶解贴图scale/offset",Vector)=(1,1,0,0)
        _Vector4("溶解贴图速度",Vector)=(0,0,0,0) _Float1("溶解值",Range(-0.1,1.1))=0.61 _Float2("溶解贴图强度",Float)=1
        _Vector5("Bias/Scale/Power",Vector)=(0,1,5,0) _Vector6("反向/Bias/Scale/Power",Vector)=(0,1,5,0) [HDR]_Color1("菲涅尔颜色",Color)=(0,0,0,0)
        [HDR]_Color2("反向菲涅尔颜色",Color)=(0,0,0,0) _Float3("菲涅尔开关",Float)=0
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="TransparentCutout" "Queue"="AlphaTest" }
        Pass
        {
            Tags { "LightMode"="UniversalForward" } Cull Back ZWrite On
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            TEXTURE2D(_TextureSample0);SAMPLER(sampler_TextureSample0);TEXTURE2D(_TextureSample1);SAMPLER(sampler_TextureSample1);TEXTURE2D(_TextureSample2);SAMPLER(sampler_TextureSample2);
            struct A{float4 positionOS:POSITION;float3 normalOS:NORMAL;float2 uv:TEXCOORD0;float2 uv2:TEXCOORD1;};struct V{float4 positionCS:SV_POSITION;float3 normalWS:TEXCOORD0;float3 viewWS:TEXCOORD1;float2 uv:TEXCOORD2;float2 uv2:TEXCOORD3;};
            CBUFFER_START(UnityPerMaterial) float4 _Vector0,_Vector1,_Vector2,_Color0,_Vector3,_Vector4,_Vector5,_Vector6,_Color1,_Color2,_outline_color;float _Float0,_Cutoff,float11,_Float5,_Float1,_Float2,_Float3;CBUFFER_END
            V vert(A i){V o;VertexPositionInputs p=GetVertexPositionInputs(i.positionOS.xyz);o.positionCS=p.positionCS;o.normalWS=TransformObjectToWorldNormal(i.normalOS);o.viewWS=GetWorldSpaceNormalizeViewDir(p.positionWS);o.uv=i.uv;o.uv2=i.uv2;return o;}
            half4 frag(V i):SV_Target{float2 uv=i.uv*_Vector0.xy+_Vector0.zw;half4 main=SAMPLE_TEXTURE2D(_TextureSample0,sampler_TextureSample0,uv);float2 duv=i.uv2*_Vector3.xy+_Vector3.zw+_Time.y*_Vector4.xy;float mask=(1-step(SAMPLE_TEXTURE2D(_TextureSample2,sampler_TextureSample2,duv).r*_Float2,_Float1))*main.a;clip(mask-_Cutoff);float2 huv=float11*_Vector2.xy+(i.uv.x*_Vector1.xy+_Vector1.zw);half4 hi=SAMPLE_TEXTURE2D(_TextureSample1,sampler_TextureSample1,huv);half3 col=lerp(main.rgb,_Color0.rgb*hi.rgb,hi.a);col=lerp(col,main.rgb,_Float5);float ndv=saturate(dot(normalize(i.normalWS),normalize(i.viewWS)));float f=_Vector5.x+_Vector5.y*pow(1-ndv,_Vector5.z);half3 fcol=lerp(col,_Color1.rgb,f);col=lerp(col,fcol,_Float3);float rf=_Vector6.x+_Vector6.y*pow(1-ndv,_Vector6.z);col=lerp(col,_Color2.rgb,1-rf);return half4(col,1);}
            ENDHLSL
        }
    }
}

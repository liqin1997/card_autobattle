Shader "cry_star_fresnel02"
{
    Properties
    {
        _tex_power("tex_power",Float)=0 _TextureSample0("Texture Sample 0",2D)="white"{} _noise_speed_and_time("noise_speed_and_time",Vector)=(0,0,0,0)
        _speed_and_time("speed_and_time",Vector)=(0,0,0,0) _screen_color("screen_color",Color)=(0,0,0,0) _scale_offset1("scale_offset",Vector)=(0,0,0,0)
        _scale_offset("scale_offset",Vector)=(0,0,0,0) _power("power",Float)=0 _maincolor("maincolor",Color)=(0,0,0,0) _inside_edge_power("inside_edge_power",Float)=0
        _smooth_step("smooth_step",Vector)=(0,0,0,0) _Color0("Color 0",Color)=(0,0,0,0) _inside_color("inside_color",Color)=(0,0,0,0)
        _inside_power2("inside_power2",Vector)=(0,0,0,0) _TextureSample1("Texture Sample 1",2D)="white"{} _flow_glow("flow_glow",Color)=(0,0,0,0)
        _dissolve1("dissolve",Float)=0 _Color1("Color 1",Color)=(1,1,1,0) _Float1("Float 1",Float)=0
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" } Blend SrcAlpha OneMinusSrcAlpha ZWrite Off
        Pass
        {
            Tags { "LightMode"="SRPDefaultUnlit" } Cull Back
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            TEXTURE2D(_TextureSample0);SAMPLER(sampler_TextureSample0);TEXTURE2D(_TextureSample1);SAMPLER(sampler_TextureSample1);
            struct A{float4 positionOS:POSITION;float3 normalOS:NORMAL;float2 uv:TEXCOORD0;float2 uv2:TEXCOORD1;};
            struct V{float4 positionCS:SV_POSITION;float3 normalWS:TEXCOORD0;float3 viewWS:TEXCOORD1;float3 positionOS:TEXCOORD2;float2 uv:TEXCOORD3;float2 uv2:TEXCOORD4;};
            CBUFFER_START(UnityPerMaterial)
            float4 _TextureSample0_ST,_TextureSample1_ST,_noise_speed_and_time,_speed_and_time,_screen_color,_scale_offset1,_scale_offset,_maincolor,_smooth_step,_Color0,_inside_color,_inside_power2,_flow_glow,_Color1;
            float _tex_power,_power,_inside_edge_power,_dissolve1,_Float1;
            CBUFFER_END
            V vert(A i){V o;VertexPositionInputs p=GetVertexPositionInputs(i.positionOS.xyz);o.positionCS=p.positionCS;o.normalWS=TransformObjectToWorldNormal(i.normalOS);o.viewWS=GetWorldSpaceNormalizeViewDir(p.positionWS);o.positionOS=i.positionOS.xyz;o.uv=TRANSFORM_TEX(i.uv,_TextureSample0);o.uv2=TRANSFORM_TEX(i.uv2,_TextureSample1);return o;}
            half4 frag(V i):SV_Target{float e=1-saturate(dot(normalize(i.normalWS),normalize(i.viewWS)));float2 uv=i.uv*_scale_offset.xy+_scale_offset.zw+_Time.y*_speed_and_time.xy*_speed_and_time.z;half4 c=lerp(SAMPLE_TEXTURE2D(_TextureSample0,sampler_TextureSample0,uv)*_tex_power*_screen_color,_maincolor,pow(max(e,1e-4),max(_power,1e-4)));float h=smoothstep(_smooth_step.x,_smooth_step.y,i.positionOS.y+.81);float ins=smoothstep(_inside_power2.x,_inside_power2.y,e);float2 nuv=i.uv2*_scale_offset1.xy+_scale_offset1.zw+_Time.y*_noise_speed_and_time.xy*_noise_speed_and_time.z;c.rgb+=e*_inside_edge_power*h*_Color0.rgb+ins*_inside_color.rgb*_inside_power2.z+_flow_glow.rgb*SAMPLE_TEXTURE2D(_TextureSample1,sampler_TextureSample1,nuv).r;c.a=saturate(1-(i.positionOS.y+_dissolve1));return c;}
            ENDHLSL
        }
    }
}

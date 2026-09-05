Shader "Sprite/Dissolve"
{
    Properties
    {
        _MainTex("Sprite Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)

        _DissolveTex("Dissolve Overlay", 2D) = "white" {}
        _DissolveGradient("Dissolve Gradient", 2D) = "white" {}
        _EmissionColor("Emission Color", color) = (1,0,0,1)
        _EmissionThickness("Emission Thickness", Range(0, 1)) = 0.1
        _DissolvePower("Dissolve Power", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend One OneMinusSrcAlpha

        Pass
        {
            Name "Unlit"
            Tags { "LightMode"="SRPDefaultUnlit" }
            CGPROGRAM
            #pragma vertex SpriteVert_Dissolve
            #pragma fragment SpriteFrag_Dissolve
            #pragma target 2.0
            #pragma multi_compile_instancing
            #pragma multi_compile_local _ PIXELSNAP_ON
            #pragma multi_compile _ ETC1_EXTERNAL_ALPHA
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            sampler2D _DissolveTex;
            float4 _DissolveTex_ST;

            sampler2D _DissolveGradient;
            float4 _DissolveGradient_ST;

            fixed4 _Color;
            
            fixed4 _EmissionColor;
            fixed _EmissionThickness;
            fixed _DissolvePower; //start at 1 then gradually to 0


            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                fixed4 color : COLOR;
            };

            struct v2fExt
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                float2 texcoord2 : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2fExt SpriteVert_Dissolve(appdata IN)
            {
                v2fExt OUT;

                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                
                OUT.vertex = UnityObjectToClipPos(IN.vertex);
                OUT.texcoord = IN.texcoord;
                OUT.color = IN.color * _Color;

                #ifdef PIXELSNAP_ON
				OUT.vertex = UnityPixelSnap(OUT.vertex);
                #endif

                //coord for dissolve to accomodate texture scale/offset
                OUT.texcoord2 = IN.texcoord * _DissolveTex_ST.xy + _DissolveTex_ST.zw;

                return OUT;
            }

            fixed4 SpriteFrag_Dissolve(v2fExt IN) : COLOR
            {
                fixed4 clr = tex2D(_MainTex, IN.texcoord) * IN.color;
                fixed4 gradient = tex2D(_DissolveGradient, IN.texcoord) * IN.color;
                fixed mask = (tex2D(_DissolveTex, IN.texcoord2).r + gradient.r) / 2;

                fixed4 blend = fixed4(0, 0, 0, 0);
                if (mask < _DissolvePower + _EmissionThickness)
                    blend = fixed4(_EmissionColor.r, _EmissionColor.g, _EmissionColor.b, clr.a * _EmissionColor.a);
                if (mask <= _DissolvePower)
                    blend = clr;

                blend.rgb *= blend.a;

                return blend;
            }
            ENDCG
        }
    }
}

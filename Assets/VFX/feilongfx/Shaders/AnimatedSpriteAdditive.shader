Shader "Custom/AnimatedSpriteAdditive (Cutout)"
{
	Properties
	{
		[Header(Texture Sheet)]
		_MainTex("Texture", 2D) = "white" {}
		//_Cutoff("Alpha Cutoff", Range(0,1)) = 0.15
		[Header(Settings)]
		_ColumnsX("Columns (X)", int) = 1
		_RowsY("Rows (Y)", int) = 1
		_AnimationSpeed("Frames Per Seconds", float) = 10
		_FillColor("Fill Color", Color) = (1,1,1,1)
		_FillRate("Fill Rate", Range(0,1)) = 0
	}
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "RenderPipeline"="UniversalPipeline" }
		Blend SrcAlpha One
        Cull Off 
        Lighting Off 
        ZWrite Off 
        Fog { Mode Off }

		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="SRPDefaultUnlit" }
			CGPROGRAM
			#pragma vertex vert 
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
			};

			//float _Cutoff;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			uint _ColumnsX;
			uint _RowsY;
			float _AnimationSpeed;
			fixed4 _FillColor;
			float _FillRate;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				// get single sprite size
				float2 size = float2(1.0f / _ColumnsX, 1.0f / _RowsY);
				uint totalFrames = _ColumnsX * _RowsY;

				// use timer to increment index
				uint index = _Time.y*_AnimationSpeed;

				// wrap x and y indexes
				uint indexX = index % _ColumnsX;
				uint indexY = floor((index % totalFrames) / _ColumnsX);

				// get offsets to our sprite index
				float2 offset = float2(size.x*indexX,-size.y*indexY);

				// get single sprite UV
				float2 newUV = v.uv*size;

				// flip Y (to start 0 from top)
				newUV.y = newUV.y + size.y*(_RowsY - 1);
                o.color = v.color;
				o.uv = newUV + offset;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * i.color;

				// cutout
				//clip(col.a - _Cutoff);
                col.rgb = lerp(col.rgb, _FillColor.rgb, _FillRate);
				return col;
			}
		ENDCG
		}
	}
}

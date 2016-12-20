Shader "Custom/Notes"
{
	Properties
	{
		_MainTex("Base (RGB) Trans (A)", 2D) = "white" {}

	}
	SubShader
	{
		LOD 100

		ZWrite On
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma target 2.0
			
			#include "UnityCG.cginc"




			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _BallHeight;
			int _IsPlayed;
			float _StartTime;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				half ball = step(length(i.uv - .5), .38);
				half3 color = half3(.996, .52, .582);

				half alpha = ball*1. - 2.*sqrt(_StartTime);
				// the square root allows for a faster transition
				color = color + col*_BallHeight;


				return half4(color,alpha);
			}
			ENDCG
		}
	}
}

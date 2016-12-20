Shader "Custom/burst"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "RenderType"="Transparent" }
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha


		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

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
				//fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				half x = i.uv.x - 0.5;
				half y = i.uv.y - 0.5;
				half r = length(i.uv - .5);

				half t1 = 0.3; // Start resonance time
				half t2 = .6; // End resonance time
				half t = _StartTime;
				half T = t - t1;

				half3 col = half3(1., .7, .7);
				half circle = pow( .1 / r, 2. );

				half burst = sin( t / t1 * 3.1415 );
				half resonance = pow( cos(r* (t2-t)*100. ), 3.5);
				resonance *= pow(sin(atan(x / y)), 2.5);

				half effects = step( t, t1 ) * burst; // Burst while t<t1
				effects += step( t, t2 ) * resonance; // Resonance while t<t2

				return half4( col, effects * circle );
			}
			ENDCG
		}
	}
}
Shader "Custom/SwipeShader"
{
	Properties
	{
		_MainTex ( "Texture" , 2D ) = "white" { }		
		_FluxAngle ( "Flux Angle" , Range ( 0 , 1 ) ) = 1
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float2 screenPos : TEXCOORD1;
			};
						
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}
			
			sampler2D _MainTex;
			float2 cue1Pos;
			float2 cue2Pos;
			float2 cue1Size;
			float2 cue2Size;
			const static int N = 20;
			
			float4 particles[N];	// absolute particle position on screen

			// Editor parameters
			fixed _FluxAngle;
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				
				fixed Throw = 0.;
				float2 Point = float2(0,0);
				for (int j = 0; j<N; j++)   {
					Point = particles[j].xy / _ScreenParams;
					if (particles[j].x != 0 && particles[j].y != 0) Throw += .005/length(Point-i.uv);
				}
				
			// Energy hyperbolas drawn on the cues
	
				
				// Get the correct cues' position and size on screen
				cue1Pos  	/=  _ScreenParams;
				cue2Pos  	/=  _ScreenParams;
				// this number depends on screen size
				half2 sizeCorrection = float2 ( _ScreenParams.y / _ScreenParams.x , 1. ) / 23.2;
				cue1Size  	*= sizeCorrection;
				cue2Size  	*= sizeCorrection;	
				float2 corner1 = cue1Pos + cue1Size; // up-right corner
				float2 corner2 = cue2Pos - cue2Size; // left-down corner
				
					
				float2 cueShape = abs ( i.uv - cue1Pos ) < cue1Size;
				float2 cueShape2 = abs ( i.uv - cue2Pos ) < cue2Size;
				fixed2 hyper1 = .004 / abs ( i.uv - corner1 );
				fixed2 hyper2 = .004 / abs ( i.uv - corner2 );
				
			// Timings of hyperbolas' transparency
				half timeHyper1 = saturate ( pow ( 1 - _Time.x + .35 , 5. ) );
				half timeHyper2 = saturate ( pow ( _Time.x - .35 , .5 ) );
				
			// Compose the effects	
				float4 final = Throw + col*(1.-Throw);
				//final += cueShape.x * cueShape.y * ( hyper1.x + hyper1.y ) * timeHyper1;
				//final += cueShape2.x * cueShape2.y *( hyper2.x + hyper2.y )* timeHyper2;
				return final;
			}
			ENDCG
		}
	}
}

Shader "Custom/Notes"
{
	Properties
	{
		_MainTex("Base (RGB) Trans (A)", 2D) = "white" {}
		
		[Header(Frost line properties)]
		_lineXWidth("Horizontal width",Range(0., 20.)) = 2.4
		_lineFlatness("Flatness",Range(-2, 7.)) = -0.71
		_lineYSize("Thickness",Range(0., 20.)) = 10.9
		[Toggle] _showLine("Show",float) = 1
				
		[Header(Frost center properties)]
		_xWidth("Horizontal width (constant)",Range(0., 2.)) = 1
		_flatness("Flatness",Range(0., 2.)) = 1
		_ySize("Vertical size",Range(0., 2.)) = 1
		[Toggle] _showCenter("Show",float) = 1
		
		[Header(Pop)]
		_PopStart("Pop Start Time",Range(0, 1)) = .5
		_PopV1("Speed of boom",Range(1, 3)) = 2.36
		
		[Header(Fade)]		
		_BoomEnd("Fade start time",Range(0, 1)) = 0.5978
		_PopV2("Speed fading out",Range(0., 1.)) = 0.064
		
		
		[Header(Events)]
		[Toggle] _UseTime("Control Time",float) = 0
		_MyTime("Time",Range(0, 1)) = 0
		
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
		
			fixed _UseTime;
			fixed _MyTime;
			fixed _ControlParams;
			fixed _showLine;
			fixed _showCenter;
			
			fixed _lineXWidth;
			fixed _lineFlatness;
			fixed _lineYSize;
			
			fixed _xWidth;
			fixed _flatness;	
			fixed _ySize;			
			
			fixed _PopStart;
			fixed _BoomEnd;
			fixed _PopV1;
			fixed _PopV2;
			
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed distFrom(fixed func, fixed coord)
			{
				return pow( 1. - abs( coord - func ) , 10 );
			}
			
			fixed plot(fixed func, fixed y)
			{	
				fixed plot;
				plot = ( distFrom( func, y ) + ( y < func ) ) * ( y > 0. );
				plot += ( distFrom( -func, y ) + ( y >- func ) ) * ( y < 0.);
				return plot;
			}
			
			fixed between( fixed x, fixed a, fixed b )
			{
				return step( a, x ) * step( x , b );
			}
			
			fixed gaussian (fixed x, fixed xWidth, fixed flatness, fixed ySize)
			{
				fixed gauss = exp( -x * x / xWidth);
				gauss *= .37 * ( flatness / 2. + .5 );
				gauss += ySize - 1.;
				return gauss;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// frost timing and params------------------
				fixed t = _Time.y / 10.;
				if(_UseTime) t = _MyTime;
				
				fixed t1 = t/_PopStart; // t1 in [0,1] while t in [0,.5]	
				
				fixed y = i.uv.y - .5;
				fixed x = i.uv.x - .5;
				
				fixed lineXWidth = smoothstep( .4 , .8 , t1 );
					lineXWidth *= _lineXWidth;
					
				fixed lineFlatness = smoothstep( .4 , .6 , t1 );
					lineFlatness *= (-(_lineFlatness/2.+.5)*2.57)/2. + .5;
					
				fixed lineYSize = smoothstep( .2 , .4 , t1 );
					lineYSize *= 1./(_lineYSize/5. + .8)/3.+.6;
					
				_xWidth *= 0.032;
					
				fixed flatness = smoothstep( .6 , 1. , t1 );
					flatness *= _flatness;
					
				fixed ySize = smoothstep( .4 , .8 , t1 );
					ySize *= ( _ySize / 4. + .75) * .75;				
				
				// frost
				fixed theLine = gaussian( x, lineXWidth, lineFlatness, lineYSize );
				fixed center = gaussian( x, _xWidth, flatness, ySize);
				fixed frost = plot( theLine, y ) * _showLine;
				frost += plot( center, y ) * _showCenter;
				
				
				// pop timing and params--------------------
				
				fixed t2 = ( t - _PopStart ) / ( 1.-_PopStart ); // t2 in [0,1] while t in [.5,1]	
				_BoomEnd = ( _BoomEnd - _PopStart ) / ( 1.-_PopStart );
				t2 *= _PopV1;
				_BoomEnd *= _PopV1;
				if ( t2 > _BoomEnd ) t2 = t2 * _PopV2 + _BoomEnd * ( 1. - _PopV2 / _PopV1 );		
				
				fixed r = 0.7 * sqrt( x * x + y * y );
				fixed pop = step ( 0. , t2 ) ;
				frost *= step ( 0. , t1 );
				
				// pop
				
				pop *= pow ( cos( 20. * ( r - t2 ) ) , 10 ) ;
				pop *= abs ( r - t2 ) < .1 ;
				pop = saturate ( pop ) ;
				
				
				// final color------------------------------------
				fixed ball = ( ( x * x + y * y ) < .25 ) ;
				fixed4 col = fixed4 (.8,.6,.5,1.);
				
				fixed alphaPop = saturate(pow( 1.-(t-.5)*2.,2));
				fixed alphaFrost = saturate(pow( .5-(t-.5)*15.,3));
				
				return ball*(col +frost*alphaFrost + pop*alphaPop);
			
			}
			ENDCG
		}
	}
}

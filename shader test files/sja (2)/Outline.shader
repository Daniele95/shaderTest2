﻿Shader "Outline" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}
		CGINCLUDE
#include "UnityCG.cginc"

		uniform sampler2D _MainTex;
	uniform float4 _MainTex_TexelSize;

	sampler2D _CameraDepthNormalsTexture;

	uniform half4 _Sensitivity;
	uniform half _SampleDistance;
	uniform half4 _BgColor;
	uniform half _BgFade;

	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv[5] : TEXCOORD0;
		//float4 nz : TEXCOORD1;
	};

	v2f vertThin(appdata_img v)
	{
		v2f o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

		float2 uv = v.texcoord.xy;
		o.uv[0] = uv;

#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			uv.y = 1 - uv.y;
#endif

		o.uv[1] = uv;
		o.uv[4] = uv;

		// offsets for two additional samples
		o.uv[2] = uv + float2(-_MainTex_TexelSize.x, -_MainTex_TexelSize.y) * _SampleDistance;
		o.uv[3] = uv + float2(+_MainTex_TexelSize.x, -_MainTex_TexelSize.y) * _SampleDistance;

		/* o.nz.xyz = COMPUTE_VIEW_NORMAL;
		 o.nz.w = COMPUTE_DEPTH_01;*/

		return o;
	}

	// this function checks if two pixel colors are similar enough
	inline half CheckSame(half2 centerNormal, float centerDepth, half4 theSample)
	{
		// difference in normals
		// do not bother decoding normals - there's no need here
		half2 diff = abs(centerNormal - theSample.xy) * _Sensitivity.y;
		int isSameNormal = (diff.x + diff.y) * _Sensitivity.y < 0.1;
		// difference in depth
		float sampleDepth = DecodeFloatRG(theSample.zw);
		float zdiff = abs(centerDepth - sampleDepth);
		// scale the required threshold by the distance
		int isSameDepth = zdiff * _Sensitivity.x < 0.09 * centerDepth;

		// return:
		// 1 - if normals and depth are similar enough
		// 0 - otherwise

		return isSameNormal * isSameDepth ? 1.0 : 0.0;
	}

	half4 fragThin(v2f i) : SV_Target
	{
		half4 original = tex2D(_MainTex, i.uv[0]);

		half4 center = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
		half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);
		half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);

		// encoded normal
		half2 centerNormal = center.xy;
		// decoded depth
		float centerDepth = DecodeFloatRG(center.zw);

		half edge = 1.0;

		edge *= CheckSame(centerNormal, centerDepth, sample1);
		edge *= CheckSame(centerNormal, centerDepth, sample2);

	return edge * lerp(original, _BgColor, _BgFade);
	}

		// fragment shader responsible for the final color
	half4 Outline(v2f i) : SV_Target
	{
		half4 original = tex2D(_MainTex, i.uv[0]);

		half4 center = tex2D(_MainTex, i.uv[1]);
		half4 sample1 = tex2D(_MainTex, i.uv[2]);
		half4 sample2 = tex2D(_MainTex, i.uv[3]);

		// encoded normal
		half2 centerNormal = center.xy;
		// decoded depth
		float centerDepth = DecodeFloatRG(center.zw);

		half edge = 1.0;

		edge *= CheckSame(centerNormal, centerDepth, sample1);
		edge *= CheckSame(centerNormal, centerDepth, sample2);

		int colored = length(original) < 1.01;
		float4 color = original * colored;

		float4 result = edge * lerp(original, _BgColor, _BgFade);
		result *= 1. - colored;

		float4 final = step(0.1, result + color);
		final = result;
		float lengthVar = length(final);
		// b&w + color
		final = float4(lengthVar, lengthVar, lengthVar, lengthVar) + 20*color;
		return final;
	}

		ENDCG

		SubShader {
		Pass{
		ZTest Always Cull Off ZWrite Off
	  CGPROGRAM
	  #pragma vertex vertThin
	  #pragma fragment Outline
	  ENDCG
		}
	}
}

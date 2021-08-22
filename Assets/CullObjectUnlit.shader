Shader "Room720/CullObjectUnlit"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", color) = (1,1,1,1)
		_PlayerAngle ("PlayerNormalizedAngle", Float) = 0
		_ObjectAngle ("ObjectNormalizedAngle", Float) = 0
		_Period ("Period", int) = 1
		[MaterialToggle]_debug ("debug", float) = 0
	}
	SubShader
	{
	Tags { "RenderType"="Opaque" "Queue"="Geometry" }
		LOD 100

		Pass
		{
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define tau (UNITY_PI*2.)
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float2 uv : TEXCOORD0;
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 axisSpacePixelPos : TEXCOORD1;
				nointerpolation float normalizedCameraAngle: TEXCOORD2;
				nointerpolation float3 axisSpaceObjectPos : TEXCOORD3;
				nointerpolation float normalizedObjectAngle: TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _PlayerAngle;
			float _ObjectAngle;
			float4x4 _WorldToAxis;
			int _Period;
			fixed4 _Color;
			float _debug;

			float dotFloatAngles(float a, float b)
			{
				return dot(float2(cos(a * tau), sin(a * tau)), float2(cos(b * tau), sin(b * tau)));
			}

			float getFloatAngle(float3 p)
			{
				return frac(atan2(p.z, p.x) / tau);
			}

			float getNormalizedAngle(float previousNormalizedAngle, float absoluteAngle)
			{
				float normalizeAngleCandidate_m = (floor(frac((previousNormalizedAngle * _Period - 1) / _Period) * _Period) + absoluteAngle) / _Period;
        		float normalizeAngleCandidate_0 = (floor(previousNormalizedAngle * _Period) + absoluteAngle) / _Period;
        		float normalizeAngleCandidate_p = (floor(frac((previousNormalizedAngle * _Period + 1) / _Period) * _Period) + absoluteAngle) / _Period;
        		float dotm = dotFloatAngles(previousNormalizedAngle, normalizeAngleCandidate_m);
        		float dot0 = dotFloatAngles(previousNormalizedAngle, normalizeAngleCandidate_0);
        		float dotp = dotFloatAngles(previousNormalizedAngle, normalizeAngleCandidate_p);
       			 if (dotm > dot0)
					return normalizeAngleCandidate_m;
    		    else if (dot0 > dotp)
					return normalizeAngleCandidate_0;
    		    else
					return normalizeAngleCandidate_p;
			}


			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				float3 worldSpaceCameraPos = _WorldSpaceCameraPos;
				#if defined(USING_STEREO_MATRICES)
					worldSpaceCameraPos = (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) * .5;
				#endif

				float playerAngle = getFloatAngle(mul(_WorldToAxis, float4(worldSpaceCameraPos,1)).xyz);
				o.normalizedCameraAngle = getNormalizedAngle(_PlayerAngle / _Period, playerAngle);

				float3 axisSpaceObjectPos = mul(_WorldToAxis, mul(unity_ObjectToWorld, float4(0, 0, 0, 1))).xyz;

				float objectAngle = getFloatAngle(axisSpaceObjectPos);
				o.normalizedObjectAngle = getNormalizedAngle(_ObjectAngle / _Period, objectAngle);

				o.axisSpaceObjectPos = axisSpaceObjectPos;
				o.axisSpacePixelPos = mul(_WorldToAxis, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.))).xyz;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float ncangle = i.normalizedCameraAngle;
				float noangle = i.normalizedObjectAngle;
				float3 aopos = i.axisSpaceObjectPos;
				float3 appos = i.axisSpacePixelPos;
				fixed4 col = tex2D(_MainTex, i.uv)*_Color;

				float sign = cross(normalize(float3(aopos.x, 0., aopos.z)), normalize(float3(appos.x, 0., appos.z))).y < 0 ? (1) : (-1);
				float absRelAngle = acos(clamp(dot(normalize(float2(aopos.x, aopos.z)), normalize(float2(appos.x, appos.z))), -1, 1)) / tau;
				float npangle = frac((noangle*_Period + sign * absRelAngle) / _Period);

				if (!_debug) clip(tau / 2 - acos(clamp(dotFloatAngles(ncangle, npangle), -1, 1))*_Period);

				return col;
			}
			ENDCG
		}
	}
}

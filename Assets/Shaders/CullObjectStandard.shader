Shader "Room720/CullObjectStandard" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo", 2D) = "white" {}

		_Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
		_Glossiness ("Smoothness", range(0,1)) = 0.0
		_Metallic("Metallic", range(0,1)) = 0.5
		_MetallicGlossMap ("Metallic", 2D) = "white" {}
		[MaterialToggle]_isNormal("Normal map", float) = 0.
		_BumpMap("Normal", 2D) = "white" {}
		_PlayerAngle ("PlayerNormalizedAngle", Float) = 0
		_ObjectAngle ("ObjectNormalizedAngle", Float) = 0
		_Period ("Period", int) = 1
		[MaterialToggle]_debug("debug", float) = 0.
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#define tau (UNITY_PI*2.)
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard addshadow fullforwardshadows vertex:vert
		#pragma shader_feature _NORMALMAP

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
			float3 worldPos;
			float3 axisSpacePixelPos;
			nointerpolation float normalizedCameraAngle;
			nointerpolation float3 axisSpaceObjectPos;
			nointerpolation float normalizedObjectAngle;
		};

		float _isMS;
		float _Metallic;
		float _Glossiness;
		sampler2D _MetallicGlossMap;
		float _isNormal;
		sampler2D _BumpMap;
		fixed4 _Color;
		float _PlayerAngle;
		float _ObjectAngle;
		float4x4 _WorldToAxis;
		int _Period;
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

		void vert(inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);

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
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			fixed4 ms = tex2D(_MetallicGlossMap, IN.uv_MainTex);
			o.Metallic = ms.r * _Metallic;
			o.Smoothness = ms.a * _Glossiness;
			if(_isNormal)o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
			o.Alpha = c.a;

			float ncangle = IN.normalizedCameraAngle;
			float noangle = IN.normalizedObjectAngle;
			float3 aopos = IN.axisSpaceObjectPos;
			float3 appos = IN.axisSpacePixelPos;

			float sign = cross(normalize(float3(aopos.x, 0., aopos.z)), normalize(float3(appos.x, 0., appos.z))).y < 0 ? (1) : (-1);
			float absRelAngle = acos(clamp(dot(normalize(float2(aopos.x, aopos.z)), normalize(float2(appos.x, appos.z))), -1, 1)) / tau;
			float npangle = frac((noangle*_Period + sign * absRelAngle) / _Period);

			if (!_debug) clip(tau / 2 - acos(clamp(dotFloatAngles(ncangle, npangle), -1, 1))*_Period);
		}
		ENDCG
	}
	//FallBack "Diffuse"
	//CustomEditor "CullObjectStandardGUI"
}

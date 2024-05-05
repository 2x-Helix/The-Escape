// Decal Shader: Deferred
// Three Eyed Games

// Based on: Kim, Pope: Screen Space Decals in Warhammer 40,000: Space Marine. SIGGRAPH 2012.
// http://www.popekim.com/2012/10/siggraph-2012-screen-space-decals-in.html

Shader "Decal/Deferred Decal (Decalicious FIT3169)"
{
	Properties
	{
		_MaskTex("Mask", 2D) = "white" {}
		[PerRendererData] _MaskMultiplier("Mask (Multiplier)", Float) = 1.0
		_MaskNormals("Mask Normals?", Float) = 1.0
		[PerRendererData] _LimitTo("Limit To", Float) = 0

		_MainTex("Albedo", 2D) = "white" {}
		[HDR] _Color("Albedo (Multiplier)", Color) = (1,1,1,1)

		_EmissionMap ("Emission", 2D) = "white" {}
		[HDR] _EmissionColor("Emission (Multiplier)", Color) = (1,1,1,1)

		[Normal] _NormalTex ("Normal", 2D) = "bump" {}
		_NormalMultiplier ("Normal (Multiplier)", Float) = 1.0

		_MetallicTex ("Metallic", 2D) = "white" {}
		[Gamma] _MetallicMultiplier ("Metallic (Multiplier)",  Float) = 0

		_RoughnessTex ("Roughness", 2D) = "white" {}
		_RoughnessMultiplier ("Roughness (Multiplier)", Float) = 1

		_DecalBlendMode("Blend Mode", Float) = 0
		_DecalSrcBlend("SrcBlend", Float) = 1.0 // One
		_DecalDstBlend("DstBlend", Float) = 10.0 // OneMinusSrcAlpha
		_NormalBlendMode("Normal Blend Mode", Float) = 0

		_AngleLimit("Angle Limit", Float) = 0.5
	}

	// Use custom GUI for the decal shader
	CustomEditor "ThreeEyedGames.DecalShaderGUI"

	SubShader
	{
		// Use inverted ZTest to avoid clipping problems
		Cull Off
		ZTest GEqual
		ZWrite Off

		// Pass 0: Albedo and emission/lighting
		Pass
		{
			// Blend mode set from script
			Blend [_DecalSrcBlend] [_DecalDstBlend]
			//Blend One OneMinusSrcAlpha // Default
			//Blend One One // Additive
			//Blend DstColor OneMinusSrcAlpha // Multiply

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile ___ UNITY_HDR_ON
			#pragma multi_compile_instancing
			#include "DecaliciousCommon.cginc"

			inline half OneMinusReflectivityFromMetallic(half metallic)
			{
				// We'll need oneMinusReflectivity, so
				//   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
				// store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
				//    1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
				//                  = alpha - metallic * alpha
				half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
				return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
			}

			inline half3 DiffuseAndSpecularFromMetallic(half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
			{
				specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
				oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
				return albedo * oneMinusReflectivity;
			}

			void frag(v2f i, out float4 outAlbedo : SV_Target0, out float4 outEmission : SV_Target1)
			{
				// Common header for all fragment shaders
				DEFERRED_FRAG_HEADER

				// Get normal from GBuffer
				float3 gbuffer_normal = tex2D(_CameraGBufferTexture2, uv) * 2.0f - 1.0f;
				clip(dot(gbuffer_normal, i.decalNormal) - _AngleLimit); // 60 degree clamp

				// Get color from texture and property
				float4 color = tex2D(_MainTex, texUV) * _Color;

				// Get metallic from texture and property
				float metallicVal = tex2D(_MetallicTex, texUV) * _MetallicMultiplier;

				// FIT3169: Albedo should gradually become black as metallic increases
				//color = lerp(color, float4(0, 0, 0, 1), metallicVal);
				//color.a *= mask;

				half3 derivedSpecular;
				half oneMinusReflectivity;
				color.rgb = DiffuseAndSpecularFromMetallic(color.rgb, metallicVal, derivedSpecular, oneMinusReflectivity);
				color.a *= mask;

				// Get emission from texture and property
				float4 emission = tex2D(_EmissionMap, texUV) * _EmissionColor;
				emission.a *= mask;

				// Write albedo, premultiply for proper blending
				outAlbedo = float4(color.rgb * color.a, color.a);

				// Apply light probes and ambient light
				color *= float4(ShadeSH9(float4(gbuffer_normal, 1.0f)), 1.0f);

				// Handle logarithmic encoding in Gamma space
#ifndef UNITY_HDR_ON
				color.rgb = exp2(-color.rgb);
#endif

				// Write emission, premultiply for proper blending
				outEmission = float4(color.rgb * color.a + emission.rgb * emission.a, color.a);
			}
			ENDCG
		}

		// Pass 1: Normals and specular / smoothness
		Pass
		{
			// Manual blending
			Blend Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "DecaliciousCommon.cginc"

			inline half OneMinusReflectivityFromMetallic(half metallic)
			{
				// We'll need oneMinusReflectivity, so
				//   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
				// store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
				//    1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
				//                  = alpha - metallic * alpha
				half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
				return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
			}

			inline half3 DiffuseAndSpecularFromMetallic(half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
			{
				specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
				oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
				return albedo * oneMinusReflectivity;
			}

			void frag(v2f i, out float4 outSpecSmoothness : SV_Target0, out float4 outNormal : SV_Target1)
			{
				DEFERRED_FRAG_HEADER

				// Get normal from GBuffer
				fixed3 gbuffer_normal = tex2D(_CameraGBufferTexture2Copy, uv) * 2.0f - 1.0f;
				clip(dot(gbuffer_normal, i.decalNormal) - _AngleLimit); // 60 degree clamp

				float3 decalBitangent;
				if (_NormalBlendMode == 0)
				{
					// Reorient decal
					i.decalNormal = gbuffer_normal;
					decalBitangent = cross(i.decalTangent, i.decalNormal);
					float3 oldDecalTangent = i.decalTangent;
					i.decalTangent = cross(decalBitangent, i.decalNormal);
					if (dot(oldDecalTangent, i.decalTangent))
						i.decalTangent *= -1;
				}
				else
				{
					decalBitangent = cross(i.decalTangent, i.decalNormal);
				}

				// Get normal from normal map
				float3 normal = UnpackNormal(tex2D(_NormalTex, texUV));
				normal.xy *= _NormalMultiplier;
				normal = mul(normal, half3x3(i.decalTangent, decalBitangent, i.decalNormal));

				// Simple alpha blending of normals
				// TODO: Any more advanced blending feasible in world-space and worthwhile?
				// http://blog.selfshadow.com/publications/blending-in-detail/
				float normalMask = _MaskNormals ? mask : GetMaskMultiplier();
				normal = (1.0f - normalMask) * gbuffer_normal + normalMask * normal;
				normal = normalize(normal);

				// Write normal
				outNormal = float4(normal * 0.5f + 0.5f, 1);

				// Get specular / smoothness from GBuffer (RGB = spec colour, A = smoothness)
				float4 specSmoothnessFromGBuffer = tex2D(_CameraGBufferTexture1Copy, uv);
	
				// Get new values from textures
				float metallicVal = tex2D(_MetallicTex, texUV) * _MetallicMultiplier;
				float4 roughnessVal = tex2D(_RoughnessTex, texUV);
				float smoothnessVal = 1.0f - (roughnessVal.r * _RoughnessMultiplier);
				float3 color = tex2D(_MainTex, texUV) * _Color;

				// FIT3169: Specular should gradually become albedo colour as metallic is increased
				//float3 derivedSpecular = lerp(float3(0.04,0.04,0.04), color, metallicVal);

				// if on metal, black specular results in black appearance (when "draw albedo" is disabled)
				//	 non-metal on metal without albedo is black
				//		don't draw albedo is ignored for metal on metal

				// Derive an RGB specular value from metal and albedo
				half3 derivedSpecular;
				half oneMinusReflectivity;
				DiffuseAndSpecularFromMetallic(color.rgb, metallicVal * _MetallicMultiplier, derivedSpecular, oneMinusReflectivity);
				
				// Write, interpolate between old and new values
				outSpecSmoothness = float4(lerp(specSmoothnessFromGBuffer.xyz, derivedSpecular, mask),
										   lerp(specSmoothnessFromGBuffer.a, smoothnessVal, mask));
				
			}
			ENDCG
		}
	}

	Fallback Off
}

Shader "Custom/CrystalMedium"
{
    Properties
    {
        _Color ("Tint Color", Color) = (0.6, 0.9, 1, 0.5)
        _Distortion ("Refraction Distortion", Range(0,1)) = 0.1
        _FresnelPower ("Fresnel Power", Range(0.5, 5)) = 2
        _FresnelIntensity ("Fresnel Intensity", Range(0,2)) = 1
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalStrength ("Normal Strength", Range(0,2)) = 1
        _Cube ("Reflection Cubemap", Cube) = "" {}
        _ReflectionStrength ("Reflection Strength", Range(0,1)) = 0.3
        _ChromaticAberration ("Chromatic Aberration", Range(0,0.01)) = 0.002
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _CameraOpaqueTexture;
            sampler2D _NormalMap;
            samplerCUBE _Cube;

            float4 _Color;
            float _Distortion;
            float _FresnelPower;
            float _FresnelIntensity;
            float _NormalStrength;
            float _ReflectionStrength;
            float _ChromaticAberration;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldViewDir : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                float2 uv : TEXCOORD4;
                float3 tangent : TEXCOORD5;
                float3 bitangent : TEXCOORD6;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldPos = worldPos;

                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldNormal = worldNormal;

                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBitangent = cross(worldNormal, worldTangent) * v.tangent.w;

                o.tangent = worldTangent;
                o.bitangent = worldBitangent;

                o.worldViewDir = normalize(_WorldSpaceCameraPos - worldPos);
                o.screenPos = ComputeScreenPos(o.pos);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Build tangent space matrix
                float3x3 TBN = float3x3(normalize(i.tangent), normalize(i.bitangent), normalize(i.worldNormal));

                // Normal map
                float3 normalTex = UnpackNormal(tex2D(_NormalMap, i.uv));
                float3 worldNormal = normalize(mul(normalTex, TBN));
                worldNormal = normalize(lerp(i.worldNormal, worldNormal, _NormalStrength));

                // Fresnel term
                float fresnel = pow(1.0 - saturate(dot(worldNormal, i.worldViewDir)), _FresnelPower);
                fresnel *= _FresnelIntensity;

                // Screen UV refraction
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                screenUV += worldNormal.xy * _Distortion;

                // Chromatic aberration: sample R/G/B slightly offset
                fixed4 refrR = tex2D(_CameraOpaqueTexture, screenUV + _ChromaticAberration * worldNormal.xy);
                fixed4 refrG = tex2D(_CameraOpaqueTexture, screenUV);
                fixed4 refrB = tex2D(_CameraOpaqueTexture, screenUV - _ChromaticAberration * worldNormal.xy);
                fixed4 refracted = fixed4(refrR.r, refrG.g, refrB.b, 1);

                // Reflection from cubemap
                float3 reflDir = reflect(-i.worldViewDir, worldNormal);
                fixed4 reflection = texCUBE(_Cube, reflDir);

                // Blend refraction + reflection
                fixed4 col = refracted * (1 - _ReflectionStrength) + reflection * _ReflectionStrength;

                // Tint + fresnel boost
                col.rgb = lerp(col.rgb, _Color.rgb, 0.3);
                col.rgb += fresnel * _Color.rgb;
                col.a = _Color.a;

                return col;
            }
            ENDCG
        }
    }
}

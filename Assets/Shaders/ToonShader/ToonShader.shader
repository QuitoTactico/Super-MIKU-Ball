Shader "My_Shaders/Toon_URP_Shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor ("Texture Color", Color) = (1, 1, 1, 1)
        [Space(10)]
        _MainExposure ("Texture Exposure", Range(0, 1)) = 0.05
        _ToonShaStrength ("Toon (Shadow) Strength", Range(0, 1)) = 0.6
        [Space(10)]
        _FresColor ("Fresnel Color", Color) = (1, 1, 1, 1)
        _FresPower ("Fresnel Power", Range(0.2, 3)) = 0.45
        _FresStrength ("Fresnel Strength", Range(0, 1)) = 0.3
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque"      
            "RenderPipeline"="UniversalRenderPipeline"       
        }
        LOD 100

        Pass
        {
            Tags 
            {
                "LightMode"="UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            //#include "UnityCG.cginc"
            #include "HLSLSupport.cginc" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
                half3 ambient : TEXCOORD4;
                float fogCoord : TEXCOORD5;
            };

            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                float4 _MainTex_ST;
                float4 _MainColor;
                float _MainExposure;
                float _ToonShaStrength;
                float4 _FresColor;
                float _FresPower;
                float _FresStrength;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                // Transform normal and position to world space
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                o.positionWS = TransformObjectToWorld(v.vertex.xyz);
                o.viewDirWS = GetWorldSpaceViewDir(o.positionWS);
                
                // Calculate ambient lighting using spherical harmonics
                o.ambient = SampleSH(o.normalWS);
                
                // Calculate fog
                o.fogCoord = ComputeFogFactor(o.vertex.z);
                
                return o;
            }

            half3 LambertShading(float3 lightCol, float lightInt, float3 normal, float3 lightDir)
            {
                return lightCol * lightInt * max(0, dot(normal, lightDir));
            }

            half FresnelEffect_float(float3 normalWS, float3 viewDirWS, float power)
            {
                return pow((1.0 - saturate(dot(normalize(normalWS), normalize(viewDirWS)))), power);                
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Sample the texture
                half4 col = tex2D(_MainTex, i.uv);
                col *= _MainColor;
                
                // Get main light and shadows
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                
                // Calculate Lambert lighting
                half3 diff = LambertShading(mainLight.color, 1.0, i.normalWS, mainLight.direction);
                half shadow = mainLight.shadowAttenuation;
                half lighting = diff.r * shadow; // Use red component for grayscale
                
                // Toon shading effect
                half3 toonCol = 1 - smoothstep((lighting) - 0.01, (lighting) + 0.01, 0.5);
                half3 diffCol = lerp(lighting, toonCol, _ToonShaStrength) + i.ambient;
                
                // Fresnel effect
                half fresnel = FresnelEffect_float(i.normalWS, i.viewDirWS, _FresPower);
                half4 freCol = 1 - smoothstep(fresnel - 0.05, fresnel + 0.05, 0.9);
                freCol *= _FresColor;
                freCol *= _FresStrength;
                
                // Apply lighting and effects
                diffCol += _MainExposure;     
                col.rgb *= diffCol;
                col.rgb += freCol.rgb;
                
                // Apply fog
                col.rgb = MixFog(col.rgb, i.fogCoord);
                
                return col;
            }
            ENDHLSL
        }
        
        // Shadow casting support
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
}

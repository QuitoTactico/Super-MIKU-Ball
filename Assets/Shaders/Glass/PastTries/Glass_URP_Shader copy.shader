Shader "My_Shaders/Glass_URP_Shader_1"
{
    Properties
    {
        // main glass properties
        _Color("Base Color", Color) = (1, 1, 1, 0.5)
        _RefractionIndex("Refraction Index", Range(1.1, 2.0)) = 1.45
        _ChromaticAberration("Chromatic Aberration", Range(0.001, 0.01)) = 0.003
        _RefractionStrength("Refraction Strength", Range(0, 2)) = 0.6
        _CameraBlend("Camera Blend", Range(0,1)) = 0.9
        _FresnelPower("Fresnel Power", Range(1, 5)) = 2.0
        _FresnelIntensity("Fresnel Intensity", Range(0, 1)) = 0.4
        _SpecularPower("Specular Power", Range(0, 1)) = 0.8
        _ReflectionDetail("Reflection Detail", Range(0, 8)) = 0
        _ReflectionCube("Custom Reflection Probe", Cube) = "" {}
    }
    
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }
        
        Pass
        {
            Name "GlassForward"
            
            // transparency rendering configuration
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            
            // necessary includes for URP
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            // material properties
            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                half _RefractionIndex;
                half _ChromaticAberration;
                half _FresnelPower;
                half _FresnelIntensity;
                half _SpecularPower;
                half _ReflectionDetail;
                half _RefractionStrength;
                half _CameraBlend;
            CBUFFER_END
            
            // custom reflection probe
            TEXTURECUBE(_ReflectionCube);
            SAMPLER(sampler_ReflectionCube);
            // camera color (screen) for refraction / translucency (URP: requires Camera Opaque Texture enabled in Renderer)
            TEXTURE2D(_CameraColorTexture);
            SAMPLER(sampler_CameraColorTexture);
            
            // vertex shader input structure
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };
            
            // vertex shader output / fragment shader input structure
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float2 uv : TEXCOORD3;
            };
            
            // function to calculate simplified refraction
            float3 Refract(in float3 i, in float3 n, in float eta)
            {
                float cosi = dot(-i, n);
                float cost2 = 1.0 - eta * eta * (1.0 - cosi * cosi);
                float3 t = eta * i + ((eta * cosi - sqrt(abs(cost2))) * n);
                return t * (float3)(cost2 > 0);
            }
            
            // function to calculate fresnel effect
            float CalculateFresnel(float3 normal, float3 viewDir, float power)
            {
                float cosTheta = saturate(dot(normalize(normal), normalize(viewDir)));
                return pow(1.0 - cosTheta, power);
            }
            
            // vertex shader
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                // basic transformations
                VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = posInputs.positionCS;
                output.positionWS = posInputs.positionWS;
                
                // normal and view direction in world space
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
                output.normalWS = normalInputs.normalWS;
                output.viewDirWS = GetWorldSpaceViewDir(output.positionWS);
                
                output.uv = input.uv;
                
                return output;
            }
            
            // fragment shader
            half4 frag(Varyings input) : SV_Target
            {
                // normalize vectors
                float3 normal = normalize(input.normalWS);
                float3 viewDir = normalize(input.viewDirWS);
                
                // calculate primary refraction vector (view -> transmitted) using Refract.
                float3 refracted = Refract(normalize(-viewDir), normalize(normal), 1.0 / _RefractionIndex);
                // transform refracted to world-space approximation by reflecting back through normal
                float3 worldRefr = Refract(refracted, normal, 1.0);

                // chromatic aberration: offset the lookup direction slightly per channel
                float3 worldRefrR = worldRefr + _ChromaticAberration;
                float3 worldRefrG = worldRefr;
                float3 worldRefrB = worldRefr - _ChromaticAberration;
                
                // Prefer sampling the screen (what's behind the object) using an offset derived from the refracted direction.
                // This requires the Renderer to have "Opaque Texture" (Camera Opaque Texture) enabled.
                float4 clipPos = input.positionCS;
                float2 screenUV = clipPos.xy / clipPos.w * 0.5 + 0.5;

                // Project worldRefr* vectors to screen offsets by using their XY components divided by Z (approximate)
                // _RefractionStrength now controls the final offset directly (no hidden *0.1 factor).
                float2 offsetScale = _RefractionStrength;
                float2 offsetR = (worldRefrR.xy / max(abs(worldRefrR.z), 1e-5)) * offsetScale;
                float2 offsetG = (worldRefrG.xy / max(abs(worldRefrG.z), 1e-5)) * offsetScale;
                float2 offsetB = (worldRefrB.xy / max(abs(worldRefrB.z), 1e-5)) * offsetScale;

                float2 uvR = clamp(screenUV + offsetR, 0.0, 1.0);
                float2 uvG = clamp(screenUV + offsetG, 0.0, 1.0);
                float2 uvB = clamp(screenUV + offsetB, 0.0, 1.0);

                half3 envColor = 0;
                envColor.r = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, uvR).r;
                envColor.g = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, uvG).g;
                envColor.b = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, uvB).b;

                // If camera texture sampling returns black (possible when not available), approximate with cubemap
                // (blend both so missing camera texture doesn't produce hard black)
                half3 cubeSample;
                cubeSample.r = SAMPLE_TEXTURECUBE_LOD(_ReflectionCube, sampler_ReflectionCube, worldRefrR, _ReflectionDetail).r;
                cubeSample.g = SAMPLE_TEXTURECUBE_LOD(_ReflectionCube, sampler_ReflectionCube, worldRefrG, _ReflectionDetail).g;
                cubeSample.b = SAMPLE_TEXTURECUBE_LOD(_ReflectionCube, sampler_ReflectionCube, worldRefrB, _ReflectionDetail).b;

                // Smoothly mix between camera texture and cubemap using _CameraBlend.
                // If camera texture is not available (returns near-black), the blend will favor the cubemap.
                float cameraLuminance = dot(envColor, float3(0.2126, 0.7152, 0.0722));
                float cameraAvailable = smoothstep(0.001, 0.02, cameraLuminance);
                float useCamera = lerp(0.0, 1.0, _CameraBlend * cameraAvailable);
                float3 finalEnv = lerp(cubeSample, envColor, useCamera);
                
                // calculate fresnel effect
                float fresnel = CalculateFresnel(normal, viewDir, _FresnelPower);
                
                // apply fresnel to environment color
                half3 fresnelColor = fresnel * _FresnelIntensity;
                half3 refractedColor = finalEnv + fresnelColor;
                
                // apply base color
                half3 finalColor = _Color.rgb * refractedColor;
                
                // calculate basic specular
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                float3 halfVec = normalize(lightDir + viewDir);
                float specular = pow(saturate(dot(normal, halfVec)), 32) * _SpecularPower;
                
                // add specular to final color
                finalColor += specular * mainLight.color;
                
                // combine everything with transparency based on fresnel
                float alpha = saturate(_Color.a + fresnel * 0.3);
                
                return half4(finalColor, alpha);
            }
            
            ENDHLSL
        }
    }
    
    // fallback for compatibility
    FallBack "Universal Render Pipeline/Unlit"
}
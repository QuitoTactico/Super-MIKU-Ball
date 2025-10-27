Shader "My_Shaders/Glass_URP_Simple_Modified"
{
    Properties
    {
        // main glass properties
        _Color("Color", Color) = (1, 1, 1, 0.5)
        _RefractionIndex("Refraction Index", Range(1.1, 2.0)) = 1.45
        _ChromaticAberration("Chromatic Aberration", Range(0.001, 0.01)) = 0.003
        _FresnelPower("Fresnel Power", Range(1, 5)) = 2.0
        _FresnelIntensity("Fresnel Exposure", Range(0, 1)) = 0.4
        _SpecularPower("Specular Power", Range(0, 1)) = 0.8
        _ReflectionDetail("Reflection Detail", Range(0, 8)) = 0
        
        // custom reflection probe
        _ReflectionCubemap("Custom Reflection Cubemap", Cube) = "" {}
        [Toggle] _UseCustomReflection("Use Custom Reflection", Float) = 0
        [Toggle] _FlipReflectionY("Flip Reflection Y", Float) = 1
        [Toggle] _DisableRealTimeReflection("Disable Realtime Reflection", Float) = 1
    }
    
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent+10"
            "IgnoreProjector" = "True"
            "DisableBatching" = "True"
        }
        
        Pass
        {
            Name "GlassForward"
            
            // configuración mejorada para evitar z-fighting
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            Offset -1, -1
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            
            // includes necesarios para URP
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            // propiedades del material
            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                half _RefractionIndex;
                half _ChromaticAberration;
                half _FresnelPower;
                half _FresnelIntensity;
                half _SpecularPower;
                half _ReflectionDetail;
                half _UseCustomReflection;
                half _FlipReflectionY;
            CBUFFER_END
            
            // textura del reflection probe personalizado
            TEXTURECUBE(_ReflectionCubemap);
            SAMPLER(sampler_ReflectionCubemap);
            
            // estructura de entrada del vertex shader
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };
            
            // estructura de salida del vertex shader / entrada del fragment shader
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float2 uv : TEXCOORD3;
            };
            
            // función para calcular refracción simplificada
            float3 CalculateRefraction(float3 viewDir, float3 normal, float refractIndex)
            {
                // cálculo básico de refracción usando la ley de Snell
                float cosI = dot(-viewDir, normal);
                float eta = 1.0 / refractIndex;
                float k = 1.0 - eta * eta * (1.0 - cosI * cosI);
                
                // si k < 0, reflexión total interna
                if (k < 0.0)
                    return reflect(viewDir, normal);
                
                return eta * viewDir + (eta * cosI - sqrt(k)) * normal;
            }
            
            // función para calcular reflexión correcta
            float3 CalculateReflection(float3 viewDir, float3 normal)
            {
                return reflect(viewDir, normal);
            }
            
            // función para corregir coordenadas del cubemap si están invertidas
            float3 FixCubemapCoordinates(float3 direction, float flipY)
            {
                // si flipY está activado, invertir la coordenada Y
                if (flipY > 0.5)
                {
                    direction.y = -direction.y;
                }
                return direction;
            }
            
            // función para calcular efecto fresnel
            float CalculateFresnel(float3 normal, float3 viewDir, float power)
            {
                float cosTheta = saturate(dot(normalize(normal), normalize(viewDir)));
                return pow(1.0 - cosTheta, power);
            }
            
            // vertex shader
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                // transformaciones básicas
                VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = posInputs.positionCS;
                output.positionWS = posInputs.positionWS;
                
                // normal y dirección de vista en espacio mundial
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
                output.normalWS = normalInputs.normalWS;
                output.viewDirWS = GetWorldSpaceViewDir(output.positionWS);
                
                output.uv = input.uv;
                
                return output;
            }
            
            // fragment shader
            half4 frag(Varyings input) : SV_Target
            {
                // normalizar vectores de forma estable
                float3 normal = normalize(input.normalWS);
                float3 viewDir = normalize(input.viewDirWS);
                
                // calcular efecto fresnel de forma estable
                float fresnel = CalculateFresnel(normal, viewDir, _FresnelPower);
                fresnel = saturate(fresnel); // estabilizar
                
                // calcular reflexión (lo que se ve en la superficie)
                float3 reflectionDir = CalculateReflection(viewDir, normal);
                
                // calcular refracción para cada canal de color (aberración cromática)
                float3 refractionR = CalculateRefraction(viewDir, normal, _RefractionIndex + _ChromaticAberration);
                float3 refractionG = CalculateRefraction(viewDir, normal, _RefractionIndex);
                float3 refractionB = CalculateRefraction(viewDir, normal, _RefractionIndex - _ChromaticAberration);
                
                // validar que los vectores sean válidos
                reflectionDir = any(isnan(reflectionDir)) ? normal : reflectionDir;
                refractionR = any(isnan(refractionR)) ? reflectionDir : refractionR;
                refractionG = any(isnan(refractionG)) ? reflectionDir : refractionG;
                refractionB = any(isnan(refractionB)) ? reflectionDir : refractionB;
                
                // aplicar corrección de coordenadas
                reflectionDir = FixCubemapCoordinates(reflectionDir, _FlipReflectionY);
                refractionR = FixCubemapCoordinates(refractionR, _FlipReflectionY);
                refractionG = FixCubemapCoordinates(refractionG, _FlipReflectionY);
                refractionB = FixCubemapCoordinates(refractionB, _FlipReflectionY);
                
                // colores base estables
                half3 reflectionColor = half3(0.1, 0.1, 0.1);
                half3 refractionColor = half3(0.2, 0.2, 0.2);
                
                // usar reflection probe personalizado si está disponible
                if (_UseCustomReflection > 0.5)
                {
                    // LOD estable para evitar cambios
                    float stableLOD = clamp(_ReflectionDetail + 1.0, 1.0, 6.0);
                    
                    // samplear reflexión
                    reflectionColor = SAMPLE_TEXTURECUBE_LOD(_ReflectionCubemap, sampler_ReflectionCubemap, reflectionDir, stableLOD).rgb;
                    
                    // samplear refracción con aberración cromática
                    refractionColor.r = SAMPLE_TEXTURECUBE_LOD(_ReflectionCubemap, sampler_ReflectionCubemap, refractionR, stableLOD).r;
                    refractionColor.g = SAMPLE_TEXTURECUBE_LOD(_ReflectionCubemap, sampler_ReflectionCubemap, refractionG, stableLOD).g;
                    refractionColor.b = SAMPLE_TEXTURECUBE_LOD(_ReflectionCubemap, sampler_ReflectionCubemap, refractionB, stableLOD).b;
                }
                else
                {
                    // usar el cubemap por defecto con máxima estabilidad
                    if (unity_SpecCube0_HDR.x > 0.1)
                    {
                        float stableLOD = clamp(_ReflectionDetail + 1.0, 1.0, 6.0);
                        
                        // samplear reflexión sin HDR decoding para estabilidad
                        reflectionColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectionDir, stableLOD).rgb;
                        
                        // samplear refracción con aberración cromática
                        refractionColor.r = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, refractionR, stableLOD).r;
                        refractionColor.g = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, refractionG, stableLOD).g;
                        refractionColor.b = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, refractionB, stableLOD).b;
                    }
                }
                
                // estabilizar los colores
                reflectionColor = clamp(reflectionColor, 0.0, 1.5);
                refractionColor = clamp(refractionColor, 0.0, 1.5);
                
                // mezclar reflexión y refracción usando fresnel estabilizado
                // fresnel alto = más reflexión, fresnel bajo = más refracción
                half3 glassColor = lerp(refractionColor, reflectionColor, fresnel * _FresnelIntensity);
                
                // aplicar color base
                half3 finalColor = _Color.rgb * glassColor;
                
                // calcular especular normal pero estable
                Light mainLight = GetMainLight();
                if (length(mainLight.color) > 0.01)
                {
                    float3 lightDir = normalize(mainLight.direction);
                    float3 halfVec = normalize(lightDir + viewDir);
                    
                    // calcular especular normalmente
                    float NdotH = saturate(dot(normal, halfVec));
                    float specular = pow(NdotH, 32.0) * _SpecularPower;
                    
                    // solo un clamp básico para evitar valores extremos
                    specular = min(specular, 1.0);
                    
                    // añadir especular al color final
                    finalColor += specular * mainLight.color;
                }
                
                // clamp final para máxima estabilidad
                finalColor = clamp(finalColor, 0.0, 1.0);
                
                // transparencia basada en fresnel pero estabilizada
                float alpha = saturate(_Color.a + fresnel * 0.2);
                
                return half4(finalColor, alpha);
            }
            
            ENDHLSL
        }
    }
    
    // fallback para compatibilidad
    FallBack "Universal Render Pipeline/Unlit"
}
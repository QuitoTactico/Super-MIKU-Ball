Shader "My_Shaders/Glass_URP_Simple"
{
    Properties
    {
        // propiedades principales del vidrio
        _Color("color base", Color) = (1, 1, 1, 0.5)
        _RefractionIndex("índice de refracción", Range(1.1, 2.0)) = 1.45
        _ChromaticAberration("aberración cromática", Range(0.001, 0.01)) = 0.003
        _FresnelPower("potencia fresnel", Range(1, 5)) = 2.0
        _FresnelIntensity("intensidad fresnel", Range(0, 1)) = 0.4
        _SpecularPower("potencia especular", Range(0, 1)) = 0.8
        _ReflectionDetail("detalle reflexión", Range(0, 8)) = 0
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
            
            // configuración de renderizado para transparencia
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            
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
            CBUFFER_END
            
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
                // normalizar vectores
                float3 normal = normalize(input.normalWS);
                float3 viewDir = normalize(input.viewDirWS);
                
                // calcular refracción para cada canal de color (aberración cromática)
                float3 refractionR = CalculateRefraction(viewDir, normal, _RefractionIndex + _ChromaticAberration);
                float3 refractionG = CalculateRefraction(viewDir, normal, _RefractionIndex);
                float3 refractionB = CalculateRefraction(viewDir, normal, _RefractionIndex - _ChromaticAberration);
                
                // samplear el cubemap del entorno para cada canal
                half3 envColor;
                envColor.r = DecodeHDREnvironment(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, refractionR, _ReflectionDetail), unity_SpecCube0_HDR).r;
                envColor.g = DecodeHDREnvironment(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, refractionG, _ReflectionDetail), unity_SpecCube0_HDR).g;
                envColor.b = DecodeHDREnvironment(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, refractionB, _ReflectionDetail), unity_SpecCube0_HDR).b;
                
                // calcular efecto fresnel
                float fresnel = CalculateFresnel(normal, viewDir, _FresnelPower);
                
                // aplicar fresnel al color del entorno
                half3 fresnelColor = fresnel * _FresnelIntensity;
                half3 refractedColor = envColor + fresnelColor;
                
                // aplicar color base
                half3 finalColor = _Color.rgb * refractedColor;
                
                // calcular especular básico
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                float3 halfVec = normalize(lightDir + viewDir);
                float specular = pow(saturate(dot(normal, halfVec)), 32) * _SpecularPower;
                
                // añadir especular al color final
                finalColor += specular * mainLight.color;
                
                // combinar todo con transparencia basada en fresnel
                float alpha = saturate(_Color.a + fresnel * 0.3);
                
                return half4(finalColor, alpha);
            }
            
            ENDHLSL
        }
    }
    
    // fallback para compatibilidad
    FallBack "Universal Render Pipeline/Unlit"
}
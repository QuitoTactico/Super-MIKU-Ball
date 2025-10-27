Shader "My_Shaders/BlinnPhongHLSL"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // ambient
        _Ambient ("Ambient Color Intensity", Range(0, 1)) = 1
        _AmbientColor ("Ambient Color", Color) = (0.2, 0.2, 0.2, 1)
        // diffuse
        _LightInt ("Light Intensity", Range(0, 1)) = 1
        // specular
        _SpecularTex ("Specular Texture", 2D) = "black" {}
        _SpecularInt ("Specular Intensity", Range(0, 1)) = 1
        _SpecularPow ("Specular Power", Range(1, 128)) = 64
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
                // this is the first incidence of light in the first pass
                //"LightMode"="ForwardBase"
                "LightMode"="UniversalForward"
            }  

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            //#include "UnityCG.cginc"
            #include "HLSLSupport.cginc" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                //float3 ambient : TEXCOORD1; // ambient con ShadeSH9
                //UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal_world : TEXCOORD1;
                float3 vertex_world : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                float4 _MainTex_ST;
                // ambient
                float _Ambient;
                fixed4 _AmbientColor;
                // diffuse
                float _LightInt;
                float4 _LightColor0; // variable interna de UnityCG.cginc
                // specular
                sampler2D _SpecularTex;
                float _SpecularInt;
                float _SpecularPow;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                // ambient con ShadeSH9
                /* // calcular luz ambiente real usando Spherical Harmonics (ni idea)
                // porque lamentablemente UNITY_LIGHTMODEL_AMBIENT está deprecado
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.ambient = ShadeSH9(half4(worldNormal, 1)) * _Ambient; */
                
                //UNITY_TRANSFER_FOG(o,o.vertex);
                
                // transformar la normal a espacio world
                o.normal_world = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0))).xyz;
                o.vertex_world = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }   

            float3 LambertShading(    
                float3 lightCol,  // Cl
                float lightInt,   // Il
                float3 normal,    // N
                float3 lightDir   // L
            )
            {
                return lightCol * lightInt * max(0, dot(normal, lightDir));
            }

            float3 SpecularShading(
                float3 lightCol,   // Cl
                float specularInt, // Sp
                float3 normal,     // N
                float3 lightDir,   // L
                float3 viewDir,    // V
                float specularPow  // exponent, 2
            )
            {
                float3 h = normalize(lightDir + viewDir); // halfway
                return lightCol * specularInt * pow(max(0, dot(normal, h)), specularPow);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // solo multiplicamos el color ambiente por el multiplicador que le pusimos. y 0.5 para que no quede tan brillante
                //UNITY_LIGHTMODEL_AMBIENT está deprecado
                float3 ambient_color = _AmbientColor.rgb * _Ambient * 0.5;
                // se lo añadimos al rgb que ya tenga ese pixel
                col.rgb += ambient_color;
                // ambient con ShadeSH9
                //col.rgb += i.ambient;
                
                // Cl, (Il), N, L
                Light light = GetMainLight();
                //float3 lightDir = normalize(_WorldSpaceLightPos0.xyz); */
                float3 lightDir = light.direction;
                //fixed3 lightCol = _LightColor0.rgb;
                float3 lightCol = light.color;
                float3 normal = i.normal_world;

                float3 diffuse = LambertShading(lightCol, _LightInt, normal, lightDir);
                // el diffuse termina siendo un multiplicador sobre el color final
                col.rgb *= diffuse;

                float3 viewDir = normalize(_WorldSpaceCameraPos - i.vertex_world);
                fixed3 specCol = tex2D(_SpecularTex, i.uv) * lightCol;
                half3 specular = SpecularShading(specCol, _SpecularInt, normal, lightDir, viewDir, _SpecularPow);

                col.rgb += specular;

                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                
                return col;
            }
            ENDHLSL
        }
    }
}

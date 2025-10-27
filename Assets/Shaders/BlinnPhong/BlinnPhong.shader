Shader "My_Shaders/BlinnPhong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Ambient ("Ambient Color", Range(0, 1)) = 1
        _AmbientColor ("Ambient Color", Color) = (0.2, 0.2, 0.2, 1)
        _LightInt ("Light Intensity", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque"             
        }
        LOD 100

        Pass
        {
            Tags 
            {
                // this is the first incidence of light in the first pass
                "LightMode"="ForwardBase"
            }  

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal_world : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            // ambient
            float _Ambient;
            fixed4 _AmbientColor;
            // diffuse
            float _LightInt;
            float4 _LightColor0;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // ambient con ShadeSH9
                /* // calcular luz ambiente real usando Spherical Harmonics (ni idea)
                // porque lamentablemente UNITY_LIGHTMODEL_AMBIENT está deprecado
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.ambient = ShadeSH9(half4(worldNormal, 1)) * _Ambient; */
                
                UNITY_TRANSFER_FOG(o,o.vertex);
                
                o.normal_world = normalize(mul(unity_ObjectToWorld,    float4(v.normal, 0))).xyz;

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
                fixed3 lightCol = _LightColor0.rgb;
                float3 normal = i.normal_world;
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                half3 diffuse = LambertShading( lightCol, _LightInt, normal, lightDir);

                col.rgb *= diffuse;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                return col;
            }
            ENDCG
        }
    }
}

Shader "Tals/Urp/HotDistort"
{
    Properties
    {
        _DistortTex("DistortTex",2D) = "White" {}
        _DistortContrl("DistortContrlUVSPEED(XY)DistortStrength(Z)",Vector)=(0,0,0,0)
        _MaskTex("MaskTex",2D)="white"{}
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent"  "Queue" = "Transparent" "IgnoreProjector" = " True"} 
        LOD 100

        Blend srcalpha oneMinusSrcalpha
        ZWrite on
        ZTest always
        // ColorMask 0
        Pass
        {
            Tags{"LightMode"="Grabtex"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            CBUFFER_START(UnityPerMaterial)
                float4 _DistortTex_ST;
                float4 _DistortContrl;
            CBUFFER_END 
            TEXTURE2D (_DistortTex);SAMPLER(sampler_DistortTex);
            TEXTURE2D (_GrabTemp);SAMPLER(sampler_GrabTemp);
            TEXTURE2D(_MaskTex);            SAMPLER(sampler_MaskTex);
            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR;
            }; 

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 vertexColor : COLOR;
            }; 


            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv, _DistortTex)+_DistortContrl.xy*_Time.y;
                o.uv.zw =v.uv;

                o.vertexColor = v.vertexColor;
                return o;
            } 

            half4 frag (v2f i) : SV_Target
            {
                float2  screenuv = i.positionCS.xy/_ScreenParams.xy;
                half4 distorttex = SAMPLE_TEXTURE2D(_DistortTex,sampler_DistortTex, i.uv.xy);
                float distort =_DistortContrl.z*0.1;
                screenuv  =lerp(screenuv,screenuv+distorttex.rg,distort*i.vertexColor.a);
                half4 col = SAMPLE_TEXTURE2D(_GrabTemp, sampler_GrabTemp,screenuv);
                half4 maskTex=SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,i.uv.zw);
                col.a*=maskTex.r;

                return col;
            }
            ENDHLSL 
        }
    }
}

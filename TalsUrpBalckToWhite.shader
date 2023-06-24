Shader "Tals/Urp/BalckToWhite"
{
    Properties
    {
        _NoiseTex ("NoiseTex",2D) = "White" {}
        _NoiseTexvalue("DistortContrlUVSPEED(XY)DistortStrength(Z)",Vector)=(0,0,0,0)
        _BWSet("BWSet",range(0,1))=0.5
        // _Blur("_Blur",Float) = 0
        [int]_Iteration("Iteration",range(1,100)) = 1
        _BlurCenterX("_BlurCenterX",Float) = 0.5
        _BlurCenterY("_BlurCenterY",Float) = 0.5
        _BlurRadius("BlurRadius",Range(0,0.2)) = 0.01
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent"  "Queue" = "Transparent" "IgnoreProjector" = " True"} 
        LOD 100
        //  Blend SrcAlpha OneMinusSrcAlpha
        ZWrite on
        ZTest always
        // ColorMask 0
        Pass
        {
            Tags{ "LightMode"="Grabtex" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 

            CBUFFER_START(UnityPerMaterial)
                float _BWSet;
                float _BlurCenterX;
                float _BlurCenterY;
                float _BlurRadius;
                float _Iteration;
                float4 _Color;
                float4 _NoiseTexvalue;
            CBUFFER_END 
            TEXTURE2D ( _NoiseTex);SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_CameraDistortTexture);            SAMPLER(sampler_CameraDistortTexture);
            TEXTURE2D(_GrabTemp);            SAMPLER(sampler_GrabTemp);
            TEXTURE2D(_AfterPostProcessTexture);  SAMPLER(sampler_AfterPostProcessTexture);



            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR;
            }; 

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 vertexColor : COLOR;
            }; 


            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                o.vertexColor = v.vertexColor;
                return o;
            } 
            //径向模糊
            half4 RadialBlur(v2f i)
            {
                float2 blurVector = (float2(_BlurCenterX,_BlurCenterY) - i.uv.xy) * _BlurRadius;
                
                float2  screenuv = i.positionCS.xy/_ScreenParams.xy;
                half4 acumulateColor = half4(0, 0, 0, 0);

                for (int j = 0; j < _Iteration; j ++)
                {              

                    acumulateColor +=  SAMPLE_TEXTURE2D(_GrabTemp, sampler_GrabTemp,screenuv);

                    screenuv+= blurVector;
                }

                return acumulateColor/_Iteration;
            }

            half4 frag (v2f i) : SV_Target
            {
                //【定位uv原点】
                float2 uv0 = i.uv - float2(_BlurCenterX,_BlurCenterY);      //将uv(0.5 , 0.5)移动至原点 ，现在uv的范围是[-0.5 ,0.5]
                //【角度theta】
                float theta = atan2(uv0.y , uv0.x);             //角度,范围(-PI , PI]
                theta = theta / 3.1415927 * 0.5 + 0.5;    //Remap,角度范围(0 ,1]
                //【半径r】有流动效果
                float r = length(uv0) ;
                
                //【计算极坐标uv】
                float2 PolarUV = float2(theta , r)+ _Time.y *_NoiseTexvalue.zw;

                float4 noisetex=     SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex, float2(PolarUV.x*_NoiseTexvalue.x,PolarUV.y*_NoiseTexvalue.y));
                float4 col;
                
                col=RadialBlur(i);
                col=saturate(1-col.r);
                col*=noisetex.r;
                col=step(col.r,_BWSet);
                col*=i.vertexColor*i.vertexColor.a;
                return col;
            }
            ENDHLSL 
        }
    }
}

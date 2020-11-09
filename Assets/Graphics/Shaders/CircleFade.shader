// Based on https://medium.com/@bgolus/progressing-in-circles-13452434fdb9


Shader "CircularBar" {
    Properties {
        _Color ("Color", Color) = (0,0,0,1)
        _MainTex ("MainTex", 2D) = "white" {}

        _OuterRadius ("Outer Radius", Range(0.001,1)) = 0.95
        _InnerRadius ("Inner Radius", Range(0,0.999)) = 0.5

        _ArcAngle ("Angle", Range(-3.14159265359,3.14159265359)) = 0.0
        _ArcRange ("Range", Range(0.002,1)) = 0.75
    }

    SubShader {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "DisableBatching"="True"}

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature USE_OUTLINE
            #pragma shader_feature USE_ARC

            #include "UnityCG.cginc"

            fixed4 _Color;

            half _OuterRadius;
            half _InnerRadius;
            half _ArcAngle;
            half _ArcRange;

            struct v2f {
                float4 pos : SV_POSITION;
                float3 uvMask : TEXCOORD0;
            };

            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uvMask.xy = v.texcoord.xy * 2.0 - 1.0;

                float sinX, cosX;

                // note: there are no protections for very narrow arcs!

                // rotate base masks by arc angle
                float minAngle = _ArcAngle + (1.0 - _ArcRange) * UNITY_PI;
                sincos(minAngle, sinX, cosX);
                float2x2 minRotationMatrix = float2x2(cosX, -sinX, sinX, cosX);
                o.uvMask.xy = mul(o.uvMask.xy, minRotationMatrix);

                // rotated mask for end of arc
                float maxAngle = _ArcRange * (UNITY_PI * 2.0);
                sincos(maxAngle, sinX, cosX);
                float2x2 maxRotationMatrix = float2x2(cosX, -sinX, sinX, cosX);
                o.uvMask.z = -mul(o.uvMask.xy, maxRotationMatrix).x;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // radial gradient for circles
                half radialGrad = length(i.uvMask.xy);

                // accurate derivative length rather than fwidth
                half radialGradDeriv = length(half2(ddx(radialGrad), ddy(radialGrad))) * 0.75;

                // outer and inner circle masks for progress bar
                half outerEdge = _OuterRadius - radialGrad;
                half innerEdge = radialGrad - _InnerRadius;

                // progress bar circle edge mask
                half circleEdge = smoothstep(-radialGradDeriv, radialGradDeriv, min(outerEdge, innerEdge));

                // sharpen masks with screen space derivates
                half vert = i.uvMask.x / fwidth(i.uvMask.x);

                // get arc end
                half arc_max_edge = i.uvMask.z / fwidth(i.uvMask.z) + 0.5;

                // init arc edges for outline
                half arc_outline_min = 0;
                half arc_outline_max = 0;

                // arc masks for circle and outline edge mask
                half circleArcMask = 0;
                half outlineArcMask = 0;

                if ((_ArcRange) < 1.0)
                {
                    // "flip" arc mask depending on if less than 180 degrees
                    if ((_ArcRange) < 0.5)
                    {
                        // arc is wedge
                        circleArcMask = max(vert, arc_max_edge);
                        outlineArcMask = max(arc_outline_min, arc_outline_max);
                    }
                    else
                    {
                        // remove wedge
                        circleArcMask = min(vert, arc_max_edge);
                        outlineArcMask = min(arc_outline_min, arc_outline_max);
                    }

                    // cut out arc wedge from circle edge mask
                    circleEdge = min(circleEdge, 1.0 - saturate(circleArcMask));

                    // hack to prevent color bleed at the starting edge of the progress bar
                    vert -= 0.5;
                }

                // lerp between colors
                fixed4 col = _Color;

                float radial = (radialGrad-_InnerRadius) / (_OuterRadius - _InnerRadius);
                float alpha = clamp(1-radial, 0, 1);

                // apply circle mask as alpha
                col.a *= min(circleEdge, alpha);
                return col;
            }
            ENDCG
        }
    }
}

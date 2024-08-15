Shader "Unlit/SDF_cine" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Position ("Position", Vector) = (0,0,0,0)
        _Rotation ("Rotation", Vector) = (0,0,0,0)
        _GTime ("Time", float) = 0
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "SDFs.cginc"

            struct vertex {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct interpolator {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float3 _Position;
            float4 _Rotation;
            float _GTime;

            float4 map(float3 p) {
                float4 map = float4(0,0,0,10000);

                float4 walkway = float4(1, 1, 1, p.y);
                walkway = colOpIntersection(walkway, float4(1, 1, 1, -p.x - 2));
                walkway = colOpIntersection(walkway, float4(1, 1, 1, p.x - 2));
                map = colOpUnion(map, walkway);

                float4 truss = float4(1, 1, 1, p.y - -1);
                truss = colOpIntersection(truss, float4(1, 1, 1, abs(p.x) - 4));
                truss = colOpIntersection(truss, float4(1, 1, 1, abs(p.z) - 1));
                map = colOpUnion(map, truss);

                float4 sphere = float4(1,0,0,sdfSphere(p, float3(0, 15, 60), 4));
                map = colOpUnion(map, sphere);

                float s = 10;
                float3 id = round(p/s);
                float3  o = float3(
                    sign(p.x-(s*id.x)),
                    sign(p.y-(s*id.y)),
                    sign(p.z-(s*id.z))
                ); // neighbor offset direction

                float dist = abs(_Position.z - 60);

                float s2 = 10 + sin(_GTime)*.3;
                float3 p2 = p - float3(0,15,60);
                s2 = max(pow((20-dist/2),3)/12+4,4);
                float3 id2 = round(p2/s2); // axis-wise percentage for repetition
                float3  o2 = float3(
                    sign(p2.x-(s2*id2.x)),
                    sign(p2.y-(s2*id2.y)),
                    sign(p2.z-(s2*id2.z))
                ); // neighbor offset direction

                for( int k=0; k<2; k++ )
                for( int j=0; j<2; j++ )
                for( int i=0; i<2; i++ )
                {
                    float3 rid = id + float3(i,j,k)*o;
                    float3 r = p - s*rid;
                    float3 rid2 = id2 + float3(i,j,k)*o2;
                    float3 r2 = p2 - s2*rid2;
                    map = colOpUnion(map, (
                        colOpIntersection(
                            float4(1, 1, 1, p.y - -1),
                            colOpIntersection(
                                float4(1, 1, 1, abs(p.x) - 4), 
                                float4(1, 1, 1, abs(r.z) - 1))
                        )
                    ));
                    map = colOpUnion(map, 
                        float4(.3, .3, .3, sdfCube(float3(r2.xy, p2.z), float3(0, 0, 0), 2))
                    );
                }

                float4 wall = float4(1, 1, 1, p.z- -3.);
                map = colOpUnion(map, wall);

                return map;
            }

            float3 calcNormal( in float3 p ) // for function f(p)
            {
                const float h = 0.0001;      // replace by an appropriate value
                #define ZERO 0 // non-constant zero
                float3 n = float3(0,0,0);
                for( int i=ZERO; i<4; i++ ) {
                    float3 e = 0.5773*(2.0*float3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
                    n += e*(map(p+e*h).w).x;
                }
                return normalize(n);
            }

            interpolator vert (vertex v) {
                interpolator o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float shadow(float3 ro, float3 rd, float mint, float maxt, float w) {
                float res = 1.0;
                float t = mint;
                for( int i=0; i<256 && t<maxt; i++ )
                {
                    float h = map(ro + t*rd).w;
                    res = min( res, h/(w*t) );
                    t += clamp(h, 0.005, 0.50);
                    if( res<-1.0 || t>maxt ) break;
                }
                res = max(res,-1.0);
                return 0.25*(1.0+res)*(1.0+res)*(2.0-res);
            }

            float calcAO( in float3 pos, in float3 nor ) {
                float occ = 0.0;
                float sca = 1.0;
                for( int i=0; i<5; i++ )
                {
                    float h = 0.001 + 0.15*float(i)/4.0;
                    float d = map( pos + h*nor ).w;
                    occ += (h-d)*sca;
                    sca *= 0.95;
                }
                return clamp( 1.0 - 1.5*occ, 0.0, 1.0 );    
            }

            float4 frag (interpolator i) : SV_Target {
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv);

                i.uv -= float2(.5,.5);
                
                float3 sky = float3((.2).xxx);
                col = float4(sky,1);

                float3 o = _Position;
                float3 dir = normalize(rotate_vector(float3(i.uv, 1), _Rotation));

                float maxDist = 100;
                float dist = 0;

                float3 r = o;

                for (int i = 0; i < 256; i++) {
                    r = o + dist * dir;
                    float4 inf = map(r);
                    float d = inf.w;
                    dist += d;

                    if (d <= 0.01 || dist >= maxDist) {
                        col = float4(inf.xyz, 1);
                        break;
                    }
                }

                float3 nor = calcNormal( r );
        
                // key light
                float3  lig = normalize( float3(-0.1,  0.6,  -0.3) );
                float3  hal = normalize( lig-dir );
                float shad = shadow( r, lig, 0.01, 3.0, 0.1 );
                float dif = clamp( dot( nor, lig ), 0.0, 1.0 ) * shad;

                float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),16.0)*
                            dif *
                            (0.04 + 0.96*pow( clamp(1.0+dot(hal,dir),0.0,1.0), 5.0 ));

                // col = float4(.8,.8,.8,1);

                col =  float4(4.0 *  dif * (col.xyz), 1);
                col += float4(12.0 * spe * (col.xyz), 0);
                
                // ambient light
                float occ = calcAO( r, nor );
                float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
                col += float4(amb*occ*float3(0.0,0.08,0.1),0);
                
                // fog
                // col *= exp( -0.00005*dist*dist*dist );

                col=lerp(col, float4(sky,1), min(dist/maxDist, 1));

                return col / 4;
            }
            ENDCG
        }
    }
}

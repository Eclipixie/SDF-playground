using System.Drawing;
using UnityEngine;
using UnityEngine.UIElements;

public class Geometry : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}

public static class map {
    public static Vector3 colLerp(Vector3 a, Vector3 b, float t) {
        return (1 - t) * a + t * b;
    }

    public static Vector4 shapeUnion(Vector4 a, Vector4 b) {
        return (a.w < b.w) ? a : b;
    }

    public static Vector4 smoothShapeUnion(Vector4 a, Vector4 b, float k) {
        float h = 1f - Mathf.Min(Mathf.Abs(a.w - b.w) / (4f * k), 1f);
        float w = h * h;
        float m = w * .5f;
        float s = w * k;
        m = (a.w < b.w) ? m : 1 - m;
        s = Mathf.Min(a.w, b.w) - s;

        Vector3 col = colLerp(new Vector3(a.x, a.y, a.z), new Vector3(b.x, b.y, b.z), m);

        return new Vector4(col.x, col.y, col.z, s);
    }

    public static Vector4 shapeSubtraction(Vector4 a, Vector4 b) {
        return new(a.x, a.y, a.z, Mathf.Max(-b.w, a.w));
    }

    public static float sdfSphere(Vector3 v, Vector3 p, float r) => Vector3.Distance(v, p) - r;

    public static float sdfRect(Vector3 v, Vector3 p, Vector3 s) => Mathf.Max(Mathf.Max(
            Mathf.Abs(p.x - v.x) - s.x,
            Mathf.Abs(p.y - v.y) - s.y),
            Mathf.Abs(p.z - v.z) - s.z);

    public static float sdfCube(Vector3 v, Vector3 p, float s) => sdfRect(v, p, new(s, s, s));

    public static Vector3 _PlayerLight;

    public static Vector4 geometry(Vector3 p) {
        // one-off shapes
        Vector4 sphere1 = new(1, 0, 0, sdfSphere(p, new Vector3(-1, 0, 4), 1));
        Vector4 rect1 = new(0, 1, 1, sdfRect(p, new Vector3(1, 0, 5), new Vector3(1, 2, 3)));

        Vector4 sphere2 = new(1, 0, 0, sdfSphere(p, new Vector3(0, 0, 0), 25.858f));
        Vector4 rect2 = new(1, 0, 0, sdfCube(p, new Vector3(0, 0, 0), 20));

        Vector4 sphereOmit = new(1, 0, 0, sdfSphere(p, _PlayerLight, 6));

        Vector4 dist = new(0, 0, 0, float.PositiveInfinity);

        //dist = smoothShapeUnion(sphere1, rect1, 0.5f);

        //dist = shapeUnion(dist, rect1);
        //dist = shapeUnion(dist, Vector4(1, 1, 1, p.y));

        // repeated shapes
        // init
        // init shapes
        Vector4 sphere2Repeated = new(0, 0, 0, float.PositiveInfinity);
        Vector4 cubeRepeated = new(0, 0, 0, float.PositiveInfinity);

        // init values
        float s = 40;
        Vector3 id = (p / s);
        id = new(Mathf.Round(id.x), Mathf.Round(id.y), Mathf.Round(id.z));
        Vector3 o = (p - (s * id));
        o = new(Mathf.Sign(o.x), Mathf.Sign(o.y), Mathf.Sign(o.z));

        // 3d
        for (int k = 0; k < 2; k++)
            for (int j = 0; j < 2; j++)
                for (int i = 0; i < 2; i++) {
                    Vector3 rid = id + new Vector3(o.x * i, o.y * j, o.z * k);
                    Vector3 r = p - s * rid;
                    // apply unions
                    sphere2Repeated = shapeUnion(sphere2Repeated, new Vector4(0, 1, 0,
                        sdfSphere(r, new Vector3(0, 0, 0), 25.858f)));
                    cubeRepeated = shapeUnion(cubeRepeated, new Vector4(0, 1, 0,
                        sdfCube(r, new Vector3(0, 0, 0), 20)));
                }

        Vector4 newShape = shapeSubtraction(cubeRepeated, sphere2Repeated);

        dist = shapeUnion(dist, newShape);

        //dist = shapeSubtraction(dist, sphereOmit);

        return dist;
    }
}

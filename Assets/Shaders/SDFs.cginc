float3 rotate_vector(float3 v, float4 q) {
    float3 u = q.xyz;
    float s = q.w;

    return 2. * dot(u, v) * u
        + (s*s - dot(u, u)) * v
        + 2. * s * cross(u, v);
}

float3 colLerp(float3 a, float3 b, float t) {
    return (1 - t) * a + t * b;
}

float opUnion(float a, float b) {
    return min(a, b);    
}

float opIntersection(float a, float b) {
    return -opUnion(-a, -b);
}

float4 colOpUnion(float4 a, float4 b) {
    return opUnion(a.w, b.w) == a.w ? a : b;
}

float4 colOpIntersection(float4 a, float4 b) {
    return opIntersection(a.w, b.w) == a.w ? a : b;
}

float sdfSphere(float3 view, float3 pos, float rad) {
    return sqrt(
        (view.x - pos.x) * (view.x - pos.x) +
        (view.y - pos.y) * (view.y - pos.y) +
        (view.z - pos.z) * (view.z - pos.z)) - rad;
}

float sdfRect(float3 view, float3 pos, float3 dimensions) {
    float3 q = abs(pos - view) - dimensions;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdfCube(float3 view, float3 pos, float size) {
    return sdfRect(view, pos, float3(size.xxx));
}

float sdfPlane(float3 view, float3 pos) {
    return abs(view.y - pos.y);
}
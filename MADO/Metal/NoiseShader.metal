#include <metal_stdlib>
using namespace metal;

// Random hash function
uint hash(uint x) {
    x ^= x >> 16;
    x *= 0x45d9f3b;
    x ^= x >> 16;
    x *= 0x45d9f3b;
    x ^= x >> 16;
    return x;
}

struct NoiseParams {
    uint seed;
    uint blockSize; // 4 for 4x4 blocks
    float opacity;
};

kernel void noiseKernel(
    texture2d<float, access::write> output [[texture(0)]],
    constant NoiseParams &params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    uint w = output.get_width();
    uint h = output.get_height();
    if (gid.x >= w || gid.y >= h) return;

    uint bx = gid.x / params.blockSize;
    uint by = gid.y / params.blockSize;
    uint blockIdx = by * (w / params.blockSize + 1) + bx;
    uint val = hash(blockIdx ^ params.seed);

    float gray = float(val & 0xFF) / 255.0;
    output.write(float4(gray, gray, gray, params.opacity), gid);
}

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct StimulusParams {
    float2 center;      // normalized 0..1
    float2 size;        // normalized
    float4 color;
    int shapeType;      // 0 = car (rectangle), 1 = truck (wider rectangle)
    float opacity;
};

vertex VertexOut stimulusVertex(
    uint vid [[vertex_id]],
    constant StimulusParams &params [[buffer(0)]]
) {
    // Quad vertices
    float2 positions[4] = {
        float2(-1, -1), float2(1, -1),
        float2(-1, 1), float2(1, 1)
    };

    float2 texCoords[4] = {
        float2(0, 1), float2(1, 1),
        float2(0, 0), float2(1, 0)
    };

    VertexOut out;
    float2 pos = positions[vid];

    // Scale and translate
    pos *= params.size;
    pos += params.center * 2.0 - 1.0;

    out.position = float4(pos, 0, 1);
    out.texCoord = texCoords[vid];
    return out;
}

fragment float4 stimulusFragment(
    VertexOut in [[stage_in]],
    constant StimulusParams &params [[buffer(0)]]
) {
    float2 uv = in.texCoord;

    // Simple shape rendering
    if (params.shapeType == 0) {
        // Car: compact rectangle with rounded indicator
        float2 center = float2(0.5, 0.5);
        float dist = length((uv - center) * float2(1.0, 1.2));
        if (dist < 0.4) {
            return float4(params.color.rgb, params.opacity);
        }
    } else {
        // Truck: wider rectangle
        float2 center = float2(0.5, 0.5);
        float dist = length((uv - center) * float2(0.7, 1.2));
        if (dist < 0.4) {
            return float4(params.color.rgb, params.opacity);
        }
    }

    return float4(0, 0, 0, 0);
}

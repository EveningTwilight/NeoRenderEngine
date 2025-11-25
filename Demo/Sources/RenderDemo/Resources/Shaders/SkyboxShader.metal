#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
};

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 texCoords;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    
    // Remove translation from view matrix
    float4x4 view = uniforms.viewMatrix;
    view[3][0] = 0;
    view[3][1] = 0;
    view[3][2] = 0;
    
    float4 pos = uniforms.projectionMatrix * view * float4(in.position, 1.0);
    
    // Set z to w so that z/w = 1.0 (farthest depth)
    out.position = pos.xyww;
    out.texCoords = in.position;
    
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texturecube<float> skybox [[texture(0)]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    return skybox.sample(textureSampler, in.texCoords);
}

#include <metal_stdlib>
using namespace metal;

struct ShadowUniforms {
    float4x4 lightSpaceMatrix;
    float4x4 modelMatrix;
};

struct VertexIn {
    float3 position [[attribute(0)]];
};

vertex float4 vertex_main(VertexIn in [[stage_in]],
                            constant ShadowUniforms& uniforms [[buffer(1)]]) {
    return uniforms.lightSpaceMatrix * uniforms.modelMatrix * float4(in.position, 1.0);
}

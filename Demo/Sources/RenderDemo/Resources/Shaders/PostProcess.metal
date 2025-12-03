#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float2 uv [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertex_post_process(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 1.0);
    out.uv = in.uv;
    return out;
}

fragment float4 fragment_post_process(VertexOut in [[stage_in]],
                                      texture2d<float> sceneTexture [[texture(0)]],
                                      texture2d<float> bloomTexture [[texture(1)]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 color = sceneTexture.sample(textureSampler, in.uv);
    float4 bloom = bloomTexture.sample(textureSampler, in.uv);
    
    // Additive blending for Bloom
    color += bloom;
    
    // 1. Tone Mapping (HDR -> LDR)
    // Reinhard Tone Mapping
    float3 mapped = color.rgb / (color.rgb + float3(1.0));
    
    // Exposure Tone Mapping (Alternative)
    // float exposure = 1.0;
    // float3 mapped = float3(1.0) - exp(-color.rgb * exposure);
    
    // 2. Gamma correction (Linear -> sRGB)
    mapped = pow(mapped, float3(1.0 / 2.2));
    
    return float4(mapped, color.a);
}

fragment float4 fragment_bloom(VertexOut in [[stage_in]],
                               texture2d<float> sceneTexture [[texture(0)]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float4 color = sceneTexture.sample(textureSampler, in.uv);
    
    // Extract bright areas
    float brightness = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
    if(brightness > 1.0)
        return float4(color.rgb, 1.0);
    else
        return float4(0.0, 0.0, 0.0, 1.0);
}

fragment float4 fragment_blur(VertexOut in [[stage_in]],
                              texture2d<float> image [[texture(0)]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    
    // Simple 5-tap Gaussian blur (hardcoded for simplicity, ideally use weights/offsets)
    // We need texel size. For now, assume 1/width.
    // To do this properly we need uniforms.
    // Let's just do a very simple box blur for demonstration if we can't pass uniforms easily yet.
    
    float2 tex_offset = float2(1.0 / 512.0, 1.0 / 512.0); // Approximation
    float3 result = image.sample(textureSampler, in.uv).rgb * 0.227027;
    result += image.sample(textureSampler, in.uv + float2(tex_offset.x, 0.0)).rgb * 0.1945946;
    result += image.sample(textureSampler, in.uv - float2(tex_offset.x, 0.0)).rgb * 0.1945946;
    result += image.sample(textureSampler, in.uv + float2(0.0, tex_offset.y)).rgb * 0.1945946;
    result += image.sample(textureSampler, in.uv - float2(0.0, tex_offset.y)).rgb * 0.1945946;
    
    return float4(result, 1.0);
}

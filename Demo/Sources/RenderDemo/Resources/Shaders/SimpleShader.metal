#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float4x4 modelViewProjectionMatrix;
    float4x4 modelMatrix;
    float4 viewPos;
    float4 lightPos;
    float4 lightColor;
    float4 objectColor;
};

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 fragPos;
    float3 normal;
    float2 uv;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    out.position = uniforms.modelViewProjectionMatrix * float4(in.position, 1.0);
    out.fragPos = float3(uniforms.modelMatrix * float4(in.position, 1.0));
    out.normal = float3(uniforms.modelMatrix * float4(in.normal, 0.0));
    out.uv = in.uv;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms& uniforms [[buffer(1)]],
                              texture2d<float> diffuseMap [[texture(0)]],
                              texture2d<float> specularMap [[texture(1)]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    
    // Ambient
    float ambientStrength = 0.1;
    float3 ambient = ambientStrength * uniforms.lightColor.rgb;
    
    // Diffuse
    float3 norm = normalize(in.normal);
    float3 lightDir = normalize(uniforms.lightPos.rgb - in.fragPos);
    float diff = max(dot(norm, lightDir), 0.0);
    float3 diffuse = diff * uniforms.lightColor.rgb;
    
    // Specular
    // Sample specular intensity from specular map (use red channel)
    float specularStrength = specularMap.sample(textureSampler, in.uv).r;
    
    float3 viewDir = normalize(uniforms.viewPos.rgb - in.fragPos);
    float3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    float3 specular = specularStrength * spec * uniforms.lightColor.rgb;
    
    float3 result = (ambient + diffuse + specular) * uniforms.objectColor.rgb;
    float4 texColor = diffuseMap.sample(textureSampler, in.uv);
    
    return float4(result, 1.0) * texColor;
}

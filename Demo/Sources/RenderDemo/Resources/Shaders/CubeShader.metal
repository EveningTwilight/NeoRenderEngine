#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float4x4 modelViewProjectionMatrix;
    float4x4 modelMatrix;
    float4 viewPos;
    float4 lightPos;
    float4 lightColor;
    float4 objectColor;
    float4x4 lightSpaceMatrix;
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
    float4 fragPosLightSpace;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    out.position = uniforms.modelViewProjectionMatrix * float4(in.position, 1.0);
    out.fragPos = float3(uniforms.modelMatrix * float4(in.position, 1.0));
    
    // Normal matrix calculation (simplified, assuming uniform scaling)
    out.normal = float3(uniforms.modelMatrix * float4(in.normal, 0.0));
    
    out.uv = in.uv;
    out.fragPosLightSpace = uniforms.lightSpaceMatrix * float4(out.fragPos, 1.0);
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms& uniforms [[buffer(1)]],
                              texture2d<float> texture [[texture(0)]],
                              depth2d<float> shadowMap [[texture(1)]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    // Remove compare_func to read raw depth value
    constexpr sampler shadowSampler (mag_filter::linear, min_filter::linear, address::clamp_to_edge);
    
    // Ambient
    float ambientStrength = 0.1;
    float3 ambient = ambientStrength * uniforms.lightColor.rgb;
    
    // Diffuse
    float3 norm = normalize(in.normal);
    float3 lightDir = normalize(uniforms.lightPos.rgb - in.fragPos);
    float diff = max(dot(norm, lightDir), 0.0);
    float3 diffuse = diff * uniforms.lightColor.rgb;
    
    // Specular
    float specularStrength = 0.5;
    float3 viewDir = normalize(uniforms.viewPos.rgb - in.fragPos);
    float3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    float3 specular = specularStrength * spec * uniforms.lightColor.rgb;
    
    // Shadow Calculation
    float3 projCoords = in.fragPosLightSpace.xyz / in.fragPosLightSpace.w;
    float2 uv = projCoords.xy * 0.5 + 0.5;
    uv.y = 1.0 - uv.y;
    
    float currentDepth = projCoords.z;
    float shadow = 0.0;
    float bias = 0.005;
    
    if (currentDepth <= 1.0) {
        // PCF (Percentage-Closer Filtering)
        float2 texelSize = 1.0 / float2(shadowMap.get_width(), shadowMap.get_height());
        for(int x = -1; x <= 1; ++x) {
            for(int y = -1; y <= 1; ++y) {
                float pcfDepth = shadowMap.sample(shadowSampler, uv + float2(x, y) * texelSize);
                shadow += currentDepth > pcfDepth + bias ? 1.0 : 0.0;
            }
        }
        shadow /= 9.0;
    }
    
    float3 result = (ambient + (1.0 - shadow) * (diffuse + specular)) * uniforms.objectColor.rgb;
    float4 texColor = texture.sample(textureSampler, in.uv);
    
    return float4(result, 1.0) * texColor;
}

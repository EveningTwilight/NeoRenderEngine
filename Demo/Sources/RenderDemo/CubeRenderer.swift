import Foundation
import RenderEngine
import RenderCore
import RenderMath

class CubeRenderer: RenderEngineDelegate {
    var pipeline: PipelineState?
    var depthStencilState: DepthStencilState?
    var vertexBuffer: Buffer?
    var indexBuffer: Buffer?
    var uniformBuffer: Buffer?
    var texture: Texture?
    
    var rotationAngle: Float = 0.0
    
    // 8 vertices of a cube: Position (x, y, z) + UV (u, v)
    // Stride: 5 floats
    let vertices: [Float] = [
        // Front face
        -0.5, -0.5,  0.5,   0.0, 1.0, // 0: BL
         0.5, -0.5,  0.5,   1.0, 1.0, // 1: BR
         0.5,  0.5,  0.5,   1.0, 0.0, // 2: TR
        -0.5,  0.5,  0.5,   0.0, 0.0, // 3: TL
        
        // Back face
        -0.5, -0.5, -0.5,   1.0, 1.0, // 4: BL
         0.5, -0.5, -0.5,   0.0, 1.0, // 5: BR
         0.5,  0.5, -0.5,   0.0, 0.0, // 6: TR
        -0.5,  0.5, -0.5,   1.0, 0.0  // 7: TL
    ]
    
    // Indices for 12 triangles (36 indices)
    let indices: [UInt16] = [
        // Front
        0, 1, 2, 2, 3, 0,
        // Back
        5, 4, 7, 7, 6, 5,
        // Left
        4, 0, 3, 3, 7, 4,
        // Right
        1, 5, 6, 6, 2, 1,
        // Top
        3, 2, 6, 6, 7, 3,
        // Bottom
        4, 5, 1, 1, 0, 4
    ]
    
    func draw(in engine: RenderEngine, commandBuffer: CommandBuffer, renderPassDescriptor: RenderPassDescriptor) {
        let device = engine.device
        
        if pipeline == nil {
            do {
                try setupResources(device: device)
            } catch {
                print("Failed to setup resources: \(error)")
                return
            }
        }
        
        updateUniforms(device: device, aspectRatio: Float(renderPassDescriptor.colorTargets[0].texture.width) / Float(renderPassDescriptor.colorTargets[0].texture.height))
        
        guard let pipeline = pipeline, 
              let vertexBuffer = vertexBuffer,
              let indexBuffer = indexBuffer,
              let uniformBuffer = uniformBuffer,
              let depthStencilState = depthStencilState,
              let texture = texture else { return }
        
        let encoder = commandBuffer.beginRenderPass(renderPassDescriptor)
        
        encoder.setPipeline(pipeline)
        encoder.setDepthStencilState(depthStencilState)
        encoder.setViewport(x: 0, y: 0, width: Float(renderPassDescriptor.colorTargets[0].texture.width), height: Float(renderPassDescriptor.colorTargets[0].texture.height))
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1) // Uniforms at index 1
        encoder.setFragmentTexture(texture, index: 0) // Texture at index 0
        
        encoder.drawIndexed(indexCount: indices.count, indexBuffer: indexBuffer, indexOffset: 0, indexType: .uint16)
        
        encoder.endEncoding()
    }
    
    private func updateUniforms(device: RenderDevice, aspectRatio: Float) {
        rotationAngle += 0.02
        
        let model = Mat4.rotation(angleRadians: rotationAngle, axis: Vec3(0, 1, 0)) * Mat4.rotation(angleRadians: rotationAngle * 0.5, axis: Vec3(1, 0, 0))
        let view = Mat4.lookAt(eye: Vec3(0, 0, 3), center: Vec3(0, 0, 0), up: Vec3(0, 1, 0))
        let projection = Mat4.perspective(fovRadians: Float.pi / 3, aspectRatio: aspectRatio, near: 0.1, far: 100.0)
        
        let mvp = projection * view * model
        
        if uniformBuffer == nil {
             uniformBuffer = device.makeBuffer(length: MemoryLayout<Mat4>.size)
        }
        
        let ptr = uniformBuffer!.contents()
        var matrix = mvp
        withUnsafeBytes(of: &matrix) {
            ptr.copyMemory(from: $0.baseAddress!, byteCount: MemoryLayout<Mat4>.size)
        }
    }
    
    private func setupResources(device: RenderDevice) throws {
        // Shader Source
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        struct Uniforms {
            float4x4 modelViewProjectionMatrix;
        };
        
        struct VertexIn {
            float3 position [[attribute(0)]];
            float2 uv [[attribute(1)]];
        };
        
        struct VertexOut {
            float4 position [[position]];
            float2 uv;
        };
        
        vertex VertexOut vertex_main(const device float* vertices [[buffer(0)]],
                                     constant Uniforms& uniforms [[buffer(1)]],
                                     uint vertexID [[vertex_id]]) {
            VertexOut out;
            uint stride = 5; // 3 pos + 2 uv
            uint offset = vertexID * stride;
            
            float3 pos = float3(vertices[offset], vertices[offset+1], vertices[offset+2]);
            float2 uv = float2(vertices[offset+3], vertices[offset+4]);
            
            out.position = uniforms.modelViewProjectionMatrix * float4(pos, 1.0);
            out.uv = uv;
            return out;
        }
        
        fragment float4 fragment_main(VertexOut in [[stage_in]],
                                      texture2d<float> texture [[texture(0)]]) {
            constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
            return texture.sample(textureSampler, in.uv);
        }
        """
        
        let shader = try device.makeShaderProgram(source: shaderSource, label: "CubeShader")
        
        var pipelineDesc = PipelineDescriptor(label: "CubePipeline")
        pipelineDesc.vertexFunction = "vertex_main"
        pipelineDesc.fragmentFunction = "fragment_main"
        pipelineDesc.colorPixelFormat = 80 // .bgra8Unorm
        pipelineDesc.depthPixelFormat = 252 // .depth32Float
        
        self.pipeline = try device.makePipeline(descriptor: pipelineDesc, shader: shader)
        
        // Depth Stencil State
        let depthDesc = DepthStencilDescriptor(label: "DepthState", depthCompareFunction: .less, isDepthWriteEnabled: true)
        self.depthStencilState = device.makeDepthStencilState(descriptor: depthDesc)
        
        // Vertex Buffer
        let vSize = vertices.count * MemoryLayout<Float>.size
        let vBuffer = device.makeBuffer(length: vSize)
        let vPtr = vBuffer.contents()
        vertices.withUnsafeBytes {
            vPtr.copyMemory(from: $0.baseAddress!, byteCount: vSize)
        }
        self.vertexBuffer = vBuffer
        
        // Index Buffer
        let iSize = indices.count * MemoryLayout<UInt16>.size
        let iBuffer = device.makeBuffer(length: iSize)
        let iPtr = iBuffer.contents()
        indices.withUnsafeBytes {
            iPtr.copyMemory(from: $0.baseAddress!, byteCount: iSize)
        }
        self.indexBuffer = iBuffer
        
        // Texture
        let loader = TextureLoader(device: device)
        self.texture = try loader.createCheckerboardTexture()
    }
}

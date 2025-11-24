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
    var camera: RenderEngine.Camera?
    
    var rotationAngle: Float = 0.0
    
    // 24 vertices (4 per face * 6 faces)
    // Position (x, y, z) + UV (u, v)
    let vertices: [Float] = [
        // Front Face
        -0.5, -0.5,  0.5,  0.0, 1.0, // 0: BL
         0.5, -0.5,  0.5,  1.0, 1.0, // 1: BR
         0.5,  0.5,  0.5,  1.0, 0.0, // 2: TR
        -0.5,  0.5,  0.5,  0.0, 0.0, // 3: TL

        // Back Face
         0.5, -0.5, -0.5,  0.0, 1.0, // 4: BL (from back view)
        -0.5, -0.5, -0.5,  1.0, 1.0, // 5: BR
        -0.5,  0.5, -0.5,  1.0, 0.0, // 6: TR
         0.5,  0.5, -0.5,  0.0, 0.0, // 7: TL

        // Left Face
        -0.5, -0.5, -0.5,  0.0, 1.0, // 8: BL
        -0.5, -0.5,  0.5,  1.0, 1.0, // 9: BR
        -0.5,  0.5,  0.5,  1.0, 0.0, // 10: TR
        -0.5,  0.5, -0.5,  0.0, 0.0, // 11: TL

        // Right Face
         0.5, -0.5,  0.5,  0.0, 1.0, // 12: BL
         0.5, -0.5, -0.5,  1.0, 1.0, // 13: BR
         0.5,  0.5, -0.5,  1.0, 0.0, // 14: TR
         0.5,  0.5,  0.5,  0.0, 0.0, // 15: TL

        // Top Face
        -0.5,  0.5,  0.5,  0.0, 1.0, // 16: BL
         0.5,  0.5,  0.5,  1.0, 1.0, // 17: BR
         0.5,  0.5, -0.5,  1.0, 0.0, // 18: TR
        -0.5,  0.5, -0.5,  0.0, 0.0, // 19: TL

        // Bottom Face
        -0.5, -0.5, -0.5,  0.0, 1.0, // 20: BL
         0.5, -0.5, -0.5,  1.0, 1.0, // 21: BR
         0.5, -0.5,  0.5,  1.0, 0.0, // 22: TR
        -0.5, -0.5,  0.5,  0.0, 0.0  // 23: TL
    ]
    
    // Indices for 12 triangles (36 indices)
    let indices: [UInt16] = [
        // Front
        0, 1, 2, 2, 3, 0,
        // Back
        4, 5, 6, 6, 7, 4,
        // Left
        8, 9, 10, 10, 11, 8,
        // Right
        12, 13, 14, 14, 15, 12,
        // Top
        16, 17, 18, 18, 19, 16,
        // Bottom
        20, 21, 22, 22, 23, 20
    ]
    
    func draw(in engine: GraphicEngine, commandBuffer: CommandBuffer, renderPassDescriptor: RenderPassDescriptor) {
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
        
        if camera == nil {
            let isGL = String(describing: type(of: device)) == "GLDevice"
            let cam = RenderEngine.PerspectiveCamera(position: Vec3(0, 0, 3), target: Vec3(0, 0, 0), up: Vec3(0, 1, 0))
            cam.projectionType = isGL ? .openGL : .metal
            camera = cam
        }
        
        camera?.updateAspectRatio(aspectRatio)
        
        let model = Mat4.rotation(angleRadians: rotationAngle, axis: Vec3(0, 1, 0)) * Mat4.rotation(angleRadians: rotationAngle * 0.5, axis: Vec3(1, 0, 0))
        let view = camera?.viewMatrix ?? Mat4.identity
        let projection = camera?.projectionMatrix ?? Mat4.identity
        
        let mvp = (projection * view) * model
        
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
        let shaderSource: String
        var vertexDescriptor: RenderCore.VertexDescriptor? = nil
        var uniformBindings: [UniformBinding] = []
        
        let isGL = String(describing: type(of: device)) == "GLDevice"
        
        if isGL {
            shaderSource = """
            #version 330 core
            layout(location = 0) in vec3 position;
            layout(location = 1) in vec2 uv;
            
            uniform mat4 modelViewProjectionMatrix;
            
            out vec2 v_uv;
            
            void main() {
                gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
                v_uv = uv;
            }
            // --- FRAGMENT ---
            #version 330 core
            in vec2 v_uv;
            out vec4 FragColor;
            
            uniform sampler2D texture;
            
            void main() {
                FragColor = texture(texture, v_uv);
            }
            """
            
            // Setup Vertex Descriptor for GL
            var descriptor = RenderCore.VertexDescriptor()
            descriptor.attributes.append(RenderCore.VertexAttribute(format: .float3, offset: 0, bufferIndex: 0))
            descriptor.attributes.append(RenderCore.VertexAttribute(format: .float2, offset: 12, bufferIndex: 0))
            descriptor.layouts.append(RenderCore.VertexLayout(stride: 20))
            vertexDescriptor = descriptor
            
            // Setup Uniform Bindings
            uniformBindings.append(UniformBinding(name: "modelViewProjectionMatrix", type: .mat4, bufferIndex: 1))
            
        } else {
            shaderSource = """
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
        }
        
        let shader = try device.makeShaderProgram(source: shaderSource, label: "CubeShader")
        
        var pipelineDesc = PipelineDescriptor(label: "CubePipeline")
        pipelineDesc.vertexFunction = "vertex_main"
        pipelineDesc.fragmentFunction = "fragment_main"
        pipelineDesc.colorPixelFormat = 80 // .bgra8Unorm
        pipelineDesc.depthPixelFormat = 252 // .depth32Float
        pipelineDesc.vertexDescriptor = vertexDescriptor
        pipelineDesc.uniformBindings = uniformBindings
        
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
        let loader = RenderEngine.TextureLoader(device: device)
        self.texture = try loader.createCheckerboardTexture()
    }
}

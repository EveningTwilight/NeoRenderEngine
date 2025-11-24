import Foundation
import RenderEngine
import RenderCore
import RenderMath

class CubeRenderer: RenderEngineDelegate {
    var mesh: Mesh?
    var material: Material?
    var uniformBuffer: Buffer?
    var camera: RenderEngine.Camera?
    
    var rotationAngle: Float = 0.0
    
    func update(deltaTime: Double) {
        rotationAngle += Float(deltaTime) * 1.0 // Rotate 1 radian per second
    }
    
    func draw(in engine: GraphicEngine, commandBuffer: CommandBuffer, renderPassDescriptor: RenderPassDescriptor) {
        let device = engine.device
        let resourceManager = engine.resourceManager
        
        if material == nil {
            do {
                try setupResources(device: device, resourceManager: resourceManager)
            } catch {
                print("Failed to setup resources: \(error)")
                return
            }
        }
        
        updateUniforms(device: device, aspectRatio: Float(renderPassDescriptor.colorTargets[0].texture.width) / Float(renderPassDescriptor.colorTargets[0].texture.height))
        
        guard let mesh = mesh,
              let material = material,
              let uniformBuffer = uniformBuffer else { return }
        
        let encoder = commandBuffer.beginRenderPass(renderPassDescriptor)
        
        encoder.setViewport(x: 0, y: 0, width: Float(renderPassDescriptor.colorTargets[0].texture.width), height: Float(renderPassDescriptor.colorTargets[0].texture.height))
        
        // Bind Material (Pipeline, DepthState, Textures)
        material.bind(to: encoder)
        
        // Bind Mesh (Vertex Buffer)
        encoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
        
        // Bind Uniforms
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        
        // Draw
        if let indexBuffer = mesh.indexBuffer {
            encoder.drawIndexed(indexCount: mesh.indexCount, indexBuffer: indexBuffer, indexOffset: 0, indexType: mesh.indexType)
        }
        
        encoder.endEncoding()
    }
    
    private func updateUniforms(device: RenderDevice, aspectRatio: Float) {
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
    
    private func setupResources(device: RenderDevice, resourceManager: ResourceManager) throws {
        // Load Mesh
        let mesh = try OBJLoader.load(name: "cube", bundle: Bundle.module, device: device)
        self.mesh = mesh
        
        // Shader Source
        let shaderSource: String
        var uniformBindings: [UniformBinding] = []
        
        let isGL = String(describing: type(of: device)) == "GLDevice"
        
        if isGL {
            shaderSource = """
            #version 330 core
            layout(location = 0) in vec3 position;
            layout(location = 1) in vec3 normal;
            layout(location = 2) in vec2 uv;
            
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
                float3 normal [[attribute(1)]];
                float2 uv [[attribute(2)]];
            };
            
            struct VertexOut {
                float4 position [[position]];
                float2 uv;
            };
            
            vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                                         constant Uniforms& uniforms [[buffer(1)]]) {
                VertexOut out;
                out.position = uniforms.modelViewProjectionMatrix * float4(in.position, 1.0);
                out.uv = in.uv;
                return out;
            }
            
            fragment float4 fragment_main(VertexOut in [[stage_in]],
                                          texture2d<float> texture [[texture(0)]]) {
                constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
                return texture.sample(textureSampler, in.uv);
            }
            """
        }
        
        let shader = try resourceManager.createShader(name: "CubeShader", source: shaderSource)
        
        var pipelineDesc = PipelineDescriptor(label: "CubePipeline")
        pipelineDesc.vertexFunction = "vertex_main"
        pipelineDesc.fragmentFunction = "fragment_main"
        pipelineDesc.colorPixelFormat = 80 // .bgra8Unorm
        pipelineDesc.depthPixelFormat = 252 // .depth32Float
        pipelineDesc.vertexDescriptor = mesh.vertexDescriptor
        pipelineDesc.uniformBindings = uniformBindings
        
        self.material = Material(pipelineState: try resourceManager.createPipeline(name: "CubePipeline", descriptor: pipelineDesc, shader: shader))
        
        // Depth Stencil State
        let depthDesc = DepthStencilDescriptor(label: "DepthState", depthCompareFunction: .less, isDepthWriteEnabled: true)
        self.material?.depthStencilState = device.makeDepthStencilState(descriptor: depthDesc)
        
        // Texture
        let tex = try resourceManager.createCheckerboardTexture(name: "Checkerboard")
        self.material?.setTexture(tex, at: 0)
    }
}

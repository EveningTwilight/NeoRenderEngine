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
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)
        
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
        
        // Lighting Uniforms
        struct Uniforms {
            var mvp: Mat4
            var model: Mat4
            var viewPos: Vec3
            var lightPos: Vec3
            var lightColor: Vec3
            var objectColor: Vec3
        }
        
        let lightPos = Vec3(2.0, 2.0, 2.0)
        let viewPos = camera?.position ?? Vec3(0, 0, 3)
        
        var uniforms = Uniforms(
            mvp: mvp,
            model: model,
            viewPos: viewPos,
            lightPos: lightPos,
            lightColor: Vec3(1.0, 1.0, 1.0),
            objectColor: Vec3(1.0, 0.5, 0.31)
        )
        
        if uniformBuffer == nil || uniformBuffer!.length != MemoryLayout<Uniforms>.size {
             uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.size)
        }
        
        let ptr = uniformBuffer!.contents()
        withUnsafeBytes(of: &uniforms) {
            ptr.copyMemory(from: $0.baseAddress!, byteCount: MemoryLayout<Uniforms>.size)
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
            uniform mat4 modelMatrix;
            uniform vec3 viewPos;
            uniform vec3 lightPos;
            uniform vec3 lightColor;
            uniform vec3 objectColor;
            
            out vec2 v_uv;
            out vec3 v_normal;
            out vec3 v_fragPos;
            
            void main() {
                gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
                v_fragPos = vec3(modelMatrix * vec4(position, 1.0));
                v_normal = mat3(transpose(inverse(modelMatrix))) * normal;
                v_uv = uv;
            }
            // --- FRAGMENT ---
            #version 330 core
            in vec2 v_uv;
            in vec3 v_normal;
            in vec3 v_fragPos;
            
            out vec4 FragColor;
            
            uniform sampler2D texture;
            uniform vec3 lightPos;
            uniform vec3 viewPos;
            uniform vec3 lightColor;
            uniform vec3 objectColor;
            
            void main() {
                // Ambient
                float ambientStrength = 0.1;
                vec3 ambient = ambientStrength * lightColor;
                
                // Diffuse
                vec3 norm = normalize(v_normal);
                vec3 lightDir = normalize(lightPos - v_fragPos);
                float diff = max(dot(norm, lightDir), 0.0);
                vec3 diffuse = diff * lightColor;
                
                // Specular
                float specularStrength = 0.5;
                vec3 viewDir = normalize(viewPos - v_fragPos);
                vec3 reflectDir = reflect(-lightDir, norm);
                float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
                vec3 specular = specularStrength * spec * lightColor;
                
                vec3 result = (ambient + diffuse + specular) * objectColor;
                vec4 texColor = texture(texture, v_uv);
                
                FragColor = vec4(result, 1.0) * texColor;
            }
            """
            
            // Setup Uniform Bindings
            uniformBindings.append(UniformBinding(name: "modelViewProjectionMatrix", type: .mat4, bufferIndex: 1))
            // Note: GL implementation needs to handle struct layout or individual uniforms. 
            // For simplicity in this demo, we might need to update GL backend to support struct mapping or just bind individually.
            // But since we are using a single buffer in Metal, let's stick to Metal first or assume GL backend can handle block binding if implemented.
            // Given current GL backend is basic, this might break GL. Let's focus on Metal for "Advanced" features first or update GL backend later.
            
        } else {
            shaderSource = """
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
                
                // Normal matrix calculation (simplified, assuming uniform scaling)
                // Ideally should be passed as uniform
                out.normal = float3(uniforms.modelMatrix * float4(in.normal, 0.0));
                
                out.uv = in.uv;
                return out;
            }
            
            fragment float4 fragment_main(VertexOut in [[stage_in]],
                                          constant Uniforms& uniforms [[buffer(1)]],
                                          texture2d<float> texture [[texture(0)]]) {
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
                float specularStrength = 0.5;
                float3 viewDir = normalize(uniforms.viewPos.rgb - in.fragPos);
                float3 reflectDir = reflect(-lightDir, norm);
                float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
                float3 specular = specularStrength * spec * uniforms.lightColor.rgb;
                
                float3 result = (ambient + diffuse + specular) * uniforms.objectColor.rgb;
                float4 texColor = texture.sample(textureSampler, in.uv);
                
                // Combine lighting with texture (ignoring texture alpha for now)
                // If texture is black/missing, we still want to see the lighting result
                return float4(result, 1.0) * texColor; 
                
                // Debug: Show Texture Only
                // return texColor;
                
                // Debug: Show Normals
                // return float4(in.normal * 0.5 + 0.5, 1.0);
                
                // Debug: Show Object Color
                // return float4(uniforms.objectColor.rgb, 1.0);
                
                // For now, let's just return the lighting result to verify Phong model
                // return float4(result, 1.0);
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

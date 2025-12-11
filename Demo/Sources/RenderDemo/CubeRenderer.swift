import Foundation
import NeoRenderEngine
import RenderCore
import RenderMath

class CubeRenderer: RenderEngineDelegate {
    var mesh: Mesh?
    var material: Material?
    var uniformBuffer: Buffer?
    var camera: RenderEngine.Camera?
    
    var rotationAngle: Float = 0.0
    
    // Camera Control
    var cameraDistance: Float = 5.0
    var cameraYaw: Float = 0.0
    var cameraPitch: Float = 0.0
    
    var shadowPass: ShadowMapPass?
    var shadowMaterial: Material?
    
    func update(deltaTime: Double) {
        // rotationAngle += Float(deltaTime) * 1.0 // Rotate 1 radian per second
        
        // Update Camera Position
        let x = cameraDistance * sin(cameraYaw) * cos(cameraPitch)
        let y = cameraDistance * sin(cameraPitch)
        let z = cameraDistance * cos(cameraYaw) * cos(cameraPitch)
        
        camera?.position = Vec3(x, y, z)
        camera?.target = Vec3(0, 0, 0)
    }
    
    func handleInput(_ event: InputEvent) {
        switch event {
        case .mouseMoved(_, let delta), .touchMoved(_, let delta):
            let sensitivity: Float = 0.01
            cameraYaw -= delta.x * sensitivity
            cameraPitch += delta.y * sensitivity
            
            // Clamp pitch to avoid gimbal lock
            let limit = Float.pi / 2.0 - 0.1
            if cameraPitch > limit { cameraPitch = limit }
            if cameraPitch < -limit { cameraPitch = -limit }
            
        case .scroll(let delta):
            let zoomSpeed: Float = 0.1
            cameraDistance -= delta.y * zoomSpeed
            if cameraDistance < 1.0 { cameraDistance = 1.0 }
            if cameraDistance > 20.0 { cameraDistance = 20.0 }
            
        default:
            break
        }
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
        
        if shadowPass == nil {
            shadowPass = ShadowMapPass(device: device, width: 2048, height: 2048)
            do {
                try setupShadowResources(device: device, resourceManager: resourceManager)
            } catch {
                print("Failed to setup shadow resources: \(error)")
            }
        }
        
        updateUniforms(device: device, aspectRatio: Float(renderPassDescriptor.colorTargets[0].texture.width) / Float(renderPassDescriptor.colorTargets[0].texture.height))
        
        guard let mesh = mesh,
              let material = material,
              let shadowPass = shadowPass,
              let shadowMaterial = shadowMaterial else { return }
        
        // --- Shadow Pass ---
        // print("Encoding Shadow Pass")
        let shadowEncoder = commandBuffer.beginRenderPass(shadowPass.passDescriptor)
        shadowEncoder.setPipeline(shadowMaterial.pipelineState)
        if let dss = shadowMaterial.depthStencilState {
            shadowEncoder.setDepthStencilState(dss)
        }
        shadowEncoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
        
        // Shadow Uniforms
        let lightPos = Vec3(2.0, 4.0, 2.0)
        let lightProjection = Mat4.orthographic(left: -10, right: 10, bottom: -10, top: 10, near: 1.0, far: 20.0)
        let lightView = Mat4.lookAt(eye: lightPos, center: Vec3(0, 0, 0), up: Vec3(0, 1, 0))
        let lightSpaceMatrix = lightProjection * lightView
        let model = Mat4.rotation(angleRadians: rotationAngle, axis: Vec3(0, 1, 0)) * Mat4.rotation(angleRadians: rotationAngle * 0.5, axis: Vec3(1, 0, 0))
        
        shadowMaterial.setValue(lightSpaceMatrix, for: "lightSpaceMatrix")
        shadowMaterial.setValue(model, for: "modelMatrix")
        shadowMaterial.updateUniforms(device: device)
        shadowMaterial.bind(to: shadowEncoder)
        
        if let indexBuffer = mesh.indexBuffer {
            shadowEncoder.drawIndexed(indexCount: mesh.indexCount, indexBuffer: indexBuffer, indexOffset: 0, indexType: mesh.indexType)
        }
        shadowEncoder.endEncoding()
        
        // --- Main Pass ---
        let encoder = commandBuffer.beginRenderPass(renderPassDescriptor)
        
        encoder.setViewport(x: 0, y: 0, width: Float(renderPassDescriptor.colorTargets[0].texture.width), height: Float(renderPassDescriptor.colorTargets[0].texture.height))
        
        // Bind Material (Pipeline, DepthState, Textures, Uniforms)
        material.bind(to: encoder)
        
        // Bind Shadow Map
        encoder.setFragmentTexture(shadowPass.shadowTexture, index: 1)
        
        // Bind Mesh (Vertex Buffer)
        encoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
        
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
        
        let lightPos = Vec3(2.0, 4.0, 2.0)
        let viewPos = camera?.position ?? Vec3(0, 0, 3)
        
        // Calculate Light Space Matrix
        let lightProjection = Mat4.orthographic(left: -10, right: 10, bottom: -10, top: 10, near: 1.0, far: 20.0)
        let lightView = Mat4.lookAt(eye: lightPos, center: Vec3(0, 0, 0), up: Vec3(0, 1, 0))
        let lightSpaceMatrix = lightProjection * lightView
        
        material?.setValue(mvp, for: "modelViewProjectionMatrix")
        material?.setValue(model, for: "modelMatrix")
        material?.setValue(Vec4(viewPos.x, viewPos.y, viewPos.z, 1.0), for: "viewPos")
        material?.setValue(Vec4(lightPos.x, lightPos.y, lightPos.z, 1.0), for: "lightPos")
        material?.setValue(Vec4(1.0, 1.0, 1.0, 1.0), for: "lightColor")
        material?.setValue(Vec4(1.0, 0.5, 0.31, 1.0), for: "objectColor")
        material?.setValue(lightSpaceMatrix, for: "lightSpaceMatrix")
        
        material?.updateUniforms(device: device)
    }
    
    private func loadShaderSource(name: String, ext: String, subdirectory: String?) throws -> String {
        // Try to find the resource with subdirectory
        if let url = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
            return try String(contentsOf: url, encoding: .utf8)
        }
        // Fallback: Try to find the resource at root or with path in name
        let path = subdirectory != nil ? "\(subdirectory!)/\(name)" : name
        if let url = Bundle.module.url(forResource: path, withExtension: ext) {
            return try String(contentsOf: url, encoding: .utf8)
        }
        // Fallback: Try just the name
        if let url = Bundle.module.url(forResource: name, withExtension: ext) {
            return try String(contentsOf: url, encoding: .utf8)
        }
        
        throw NSError(domain: "CubeRenderer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Shader file '\(name).\(ext)' not found in bundle"])
    }

    private func setupResources(device: RenderDevice, resourceManager: ResourceManager) throws {
        // Load Mesh
        let mesh = try OBJLoader.load(name: "cube", bundle: Bundle.module, device: device)
        self.mesh = mesh
        
        // Shader Source
        var uniformBindings: [UniformBinding] = []
        let isGL = String(describing: type(of: device)) == "GLDevice"
        
        if isGL {
            // ...existing code...
            let shaderSource = """
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
            
            let shader = try resourceManager.createShader(name: "CubeShader", source: shaderSource)
            
            var pipelineDesc = PipelineDescriptor(label: "CubePipeline")
            pipelineDesc.vertexFunction = "vertex_main" // GL might ignore this or use it as entry point
            pipelineDesc.fragmentFunction = "fragment_main"
            pipelineDesc.colorPixelFormat = .bgra8Unorm
            pipelineDesc.depthPixelFormat = .depth32Float
            pipelineDesc.vertexDescriptor = mesh.vertexDescriptor
            pipelineDesc.uniformBindings = uniformBindings
            
            self.material = Material(pipelineState: try resourceManager.createPipeline(name: "CubePipeline", descriptor: pipelineDesc, shader: shader))
            
        } else {
            // Metal: Load from file
            let source = try loadShaderSource(name: "CubeShader", ext: "metal", subdirectory: "Shaders")
            let shader = try resourceManager.createShader(name: "CubeShader", source: source)
            
            var pipelineDesc = PipelineDescriptor(label: "CubePipeline")
            pipelineDesc.vertexFunction = "vertex_main"
            pipelineDesc.fragmentFunction = "fragment_main"
            pipelineDesc.colorPixelFormat = .bgra8Unorm
            pipelineDesc.depthPixelFormat = .depth32Float
            pipelineDesc.vertexDescriptor = mesh.vertexDescriptor
            pipelineDesc.uniformBindings = uniformBindings
            
            self.material = Material(pipelineState: try resourceManager.createPipeline(name: "CubePipeline", descriptor: pipelineDesc, shader: shader))
        }
        
        // Depth Stencil State
        let depthDesc = DepthStencilDescriptor(label: "DepthState", depthCompareFunction: .less, isDepthWriteEnabled: true)
        self.material?.depthStencilState = device.makeDepthStencilState(descriptor: depthDesc)
        
        // Texture
        let tex = try resourceManager.createCheckerboardTexture(name: "Checkerboard")
        self.material?.setTexture(tex, at: 0)
    }
    
    private func setupShadowResources(device: RenderDevice, resourceManager: ResourceManager) throws {
        let source = try loadShaderSource(name: "ShadowShader", ext: "metal", subdirectory: "Shaders")
        let shader = try resourceManager.createShader(name: "ShadowShader", source: source)
        
        var pipelineDesc = PipelineDescriptor(label: "ShadowPipeline")
        pipelineDesc.vertexFunction = "vertex_main"
        pipelineDesc.fragmentFunction = nil
        pipelineDesc.colorPixelFormat = .invalid
        pipelineDesc.depthPixelFormat = .depth32Float
        pipelineDesc.vertexDescriptor = mesh?.vertexDescriptor
        
        self.shadowMaterial = Material(pipelineState: try resourceManager.createPipeline(name: "ShadowPipeline", descriptor: pipelineDesc, shader: shader))
        
        let depthDesc = DepthStencilDescriptor(label: "ShadowDepth", depthCompareFunction: .less, isDepthWriteEnabled: true)
        self.shadowMaterial?.depthStencilState = device.makeDepthStencilState(descriptor: depthDesc)
    }
}

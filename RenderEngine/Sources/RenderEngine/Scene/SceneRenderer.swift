import Foundation
import RenderCore
import RenderMath

public class SceneRenderer {
    private let device: RenderDevice
    
    public var shadowPipeline: PipelineState?
    public var shadowMapPass: ShadowMapPass?
    public var skybox: Skybox?
    private var skyboxDepthState: DepthStencilState?
    
    public init(device: RenderDevice) {
        self.device = device
    }
    
    public func render(scene: RenderScene, camera: Camera, in commandBuffer: CommandBuffer, passDescriptor: RenderPassDescriptor) {
        // 1. Collect Renderables and Lights
        var renderers: [MeshRenderer] = []
        var lights: [LightComponent] = []
        collectSceneObjects(from: scene.root, renderers: &renderers, lights: &lights)
        
        // Prepare Light Data (Single Light Support for now)
        let mainLight = lights.first
        let lightPos = mainLight?.node?.worldPosition ?? Vec3(0, 10, 0)
        let lightColor = (mainLight?.color ?? Vec3(1, 1, 1)) * (mainLight?.intensity ?? 1.0)
        
        // Calculate Light Space Matrix
        var lightSpaceMatrix = Mat4.identity
        if let _ = shadowMapPass {
            // Simple orthographic projection for directional light (or simulating point light as directional for shadows)
            // For a real point light, we'd need a cubemap shadow map.
            // Here we assume directional shadow for simplicity or a focused spot.
            let lightProjection = Mat4.orthographic(left: -10, right: 10, bottom: -10, top: 10, near: 1.0, far: 20.0)
            let lightView = Mat4.lookAt(eye: lightPos, center: Vec3(0, 0, 0), up: Vec3(0, 1, 0))
            lightSpaceMatrix = lightProjection * lightView
        }
        
        // 2. Shadow Pass
        if let shadowPass = shadowMapPass, let shadowPipeline = shadowPipeline {
            let shadowEncoder = commandBuffer.beginRenderPass(shadowPass.passDescriptor)
            shadowEncoder.setPipeline(shadowPipeline)
            
            for renderer in renderers {
                guard let node = renderer.node else { continue }
                let modelMatrix = node.worldMatrix
                
                // We need to bind uniforms for Shadow Shader
                // Assuming Shadow Shader uses buffer index 1 for uniforms
                // Struct: { lightSpaceMatrix, modelMatrix }
                
                // We need a way to bind these. The Material system is for the main pass.
                // We can create a temporary buffer or use a "ShadowMaterial" concept.
                // For simplicity, we'll assume the shadow pipeline reflection allows us to bind by index or name.
                // But we don't have a Material for the shadow pass.
                // We'll manually bind buffers.
                
                // Create a temporary buffer for uniforms
                // Layout: lightSpaceMatrix (64), modelMatrix (64)
                let bufferSize = 128
                let uniformBuffer = device.makeBuffer(length: bufferSize)
                let ptr = uniformBuffer.contents()
                ptr.storeBytes(of: lightSpaceMatrix, toByteOffset: 0, as: Mat4.self)
                ptr.storeBytes(of: modelMatrix, toByteOffset: 64, as: Mat4.self)
                
                shadowEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
                
                let mesh = renderer.mesh
                shadowEncoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
                
                if let indexBuffer = mesh.indexBuffer {
                    shadowEncoder.drawIndexed(indexCount: mesh.indexCount, indexBuffer: indexBuffer, indexOffset: 0, indexType: mesh.indexType)
                }
            }
            shadowEncoder.endEncoding()
        }
        
        // 3. Main Pass
        let encoder = commandBuffer.beginRenderPass(passDescriptor)
        
        let viewMatrix = camera.viewMatrix
        let projectionMatrix = camera.projectionMatrix
        
        for renderer in renderers {
            guard let node = renderer.node else { continue }
            let modelMatrix = node.worldMatrix
            let mvpMatrix = projectionMatrix * viewMatrix * modelMatrix
            
            // Update Material Uniforms
            let material = renderer.material
            
            // Set Standard Uniforms
            material.setValue(modelMatrix, for: "modelMatrix")
            material.setValue(viewMatrix, for: "viewMatrix")
            material.setValue(projectionMatrix, for: "projectionMatrix")
            
            // MVP
            material.setValue(mvpMatrix, for: "mvpMatrix")
            material.setValue(mvpMatrix, for: "modelViewProjectionMatrix")
            
            // Camera Position
            material.setValue(camera.position, for: "cameraPosition")
            material.setValue(Vec4(camera.position.x, camera.position.y, camera.position.z, 1.0), for: "viewPos")
            
            // Light Uniforms
            material.setValue(Vec4(lightPos.x, lightPos.y, lightPos.z, 1.0), for: "lightPos")
            material.setValue(Vec4(lightColor.x, lightColor.y, lightColor.z, 1.0), for: "lightColor")
            
            // Shadow Uniforms
            if let shadowPass = shadowMapPass {
                material.setValue(lightSpaceMatrix, for: "lightSpaceMatrix")
                material.setTexture(shadowPass.shadowTexture, for: "shadowMap")
            }
            
            // Update buffers
            material.updateUniforms(device: device)
            
            // Bind Pipeline & Uniforms
            material.bind(to: encoder)
            
            // Bind Mesh
            let mesh = renderer.mesh
            encoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
            
            // Draw
            if let indexBuffer = mesh.indexBuffer {
                encoder.drawIndexed(indexCount: mesh.indexCount, indexBuffer: indexBuffer, indexOffset: 0, indexType: mesh.indexType)
            }
        }
        
        // 4. Skybox Pass
        if let skybox = skybox, let pipeline = skybox.pipelineState {
            // Create Depth State if needed
            if skyboxDepthState == nil {
                let desc = DepthStencilDescriptor(label: "SkyboxDepth", depthCompareFunction: .lessEqual, isDepthWriteEnabled: false)
                skyboxDepthState = device.makeDepthStencilState(descriptor: desc)
            }
            
            encoder.setPipeline(pipeline)
            encoder.setDepthStencilState(skyboxDepthState!)
            
            // Bind Uniforms (View/Projection)
            // Struct: { viewMatrix, projectionMatrix }
            let bufferSize = 128
            let uniformBuffer = device.makeBuffer(length: bufferSize)
            let ptr = uniformBuffer.contents()
            ptr.storeBytes(of: viewMatrix, toByteOffset: 0, as: Mat4.self)
            ptr.storeBytes(of: projectionMatrix, toByteOffset: 64, as: Mat4.self)
            
            encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
            
            // Bind Texture
            encoder.setFragmentTexture(skybox.texture, index: 0)
            
            // Bind Mesh
            encoder.setVertexBuffer(skybox.mesh.vertexBuffer, offset: 0, index: 0)
            
            if let indexBuffer = skybox.mesh.indexBuffer {
                encoder.drawIndexed(indexCount: skybox.mesh.indexCount, indexBuffer: indexBuffer, indexOffset: 0, indexType: skybox.mesh.indexType)
            }
        }
        
        encoder.endEncoding()
    }
    
    private func collectSceneObjects(from node: Node, renderers: inout [MeshRenderer], lights: inout [LightComponent]) {
        if let renderer = node.getComponent(MeshRenderer.self) {
            renderers.append(renderer)
        }
        if let light = node.getComponent(LightComponent.self) {
            lights.append(light)
        }
        
        for child in node.children {
            collectSceneObjects(from: child, renderers: &renderers, lights: &lights)
        }
    }
}

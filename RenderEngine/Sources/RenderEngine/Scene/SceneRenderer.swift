import Foundation
import RenderCore
import RenderMath

public class SceneRenderer {
    private let device: RenderDevice
    
    public init(device: RenderDevice) {
        self.device = device
    }
    
    public func render(scene: RenderScene, camera: Camera, in commandBuffer: CommandBuffer, passDescriptor: RenderPassDescriptor) {
        let encoder = commandBuffer.beginRenderPass(passDescriptor)
        
        // 1. Collect Renderables and Lights
        var renderers: [MeshRenderer] = []
        var lights: [LightComponent] = []
        collectSceneObjects(from: scene.root, renderers: &renderers, lights: &lights)
        
        // Prepare Light Data (Single Light Support for now)
        // Default to a light at (0, 10, 0) if none exists
        let mainLight = lights.first
        let lightPos = mainLight?.node?.worldPosition ?? Vec3(0, 10, 0)
        let lightColor = (mainLight?.color ?? Vec3(1, 1, 1)) * (mainLight?.intensity ?? 1.0)
        
        // 2. Draw
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

import Foundation
import RenderCore
import RenderMath

public class Skybox {
    public let mesh: Mesh
    public let texture: Texture
    public var pipelineState: PipelineState?
    
    public init(device: RenderDevice, texture: Texture) {
        self.texture = texture
        // Skybox cube size doesn't matter much as it's centered on camera and depth is forced to far plane
        self.mesh = PrimitiveMesh.createCube(device: device, size: 2.0) 
    }
}

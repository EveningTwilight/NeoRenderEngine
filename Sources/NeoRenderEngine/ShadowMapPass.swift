import Foundation
import RenderCore
import RenderMath

public class ShadowMapPass {
    public let width: Int
    public let height: Int
    public private(set) var shadowTexture: Texture
    public private(set) var passDescriptor: RenderPassDescriptor
    
    public init(device: RenderDevice, width: Int, height: Int) {
        self.width = width
        self.height = height
        
        let desc = TextureDescriptor(
            width: width,
            height: height,
            pixelFormat: .depth32Float,
            usage: [.renderTarget, .shaderRead]
        )
        self.shadowTexture = device.makeTexture(descriptor: desc)
        
        self.passDescriptor = RenderPassDescriptor(
            colorTargets: [],
            depthTarget: RenderTargetDescriptor(texture: shadowTexture, clearDepth: 1.0)
        )
    }
}

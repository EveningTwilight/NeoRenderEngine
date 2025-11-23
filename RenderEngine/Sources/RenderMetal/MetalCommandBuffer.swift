import Foundation
import Metal
import RenderCore

public class MetalCommandBuffer: CommandBuffer {
    let mtlCommandBuffer: MTLCommandBuffer
    unowned let device: MetalDevice

    init(mtlCommandBuffer: MTLCommandBuffer, device: MetalDevice) {
        self.mtlCommandBuffer = mtlCommandBuffer
        self.device = device
    }

    public func beginRenderPass(_ descriptor: RenderPassDescriptor) -> RenderPassEncoder {
        let rpDesc = MTLRenderPassDescriptor()

        if let color = descriptor.colorTargets.first {
            if let metalTex = color.texture as? MetalTexture {
                let attachment = rpDesc.colorAttachments[0]
                attachment?.texture = metalTex.mtlTexture
                if let clear = color.clearColor {
                    attachment?.loadAction = .clear
                    attachment?.clearColor = MTLClearColorMake(Double(clear.x), Double(clear.y), Double(clear.z), Double(clear.w))
                } else {
                    attachment?.loadAction = .load
                }
                attachment?.storeAction = .store
            }
        }
        
        // Depth attachment handling can be added here

        guard let encoder = mtlCommandBuffer.makeRenderCommandEncoder(descriptor: rpDesc) else {
            fatalError("Failed to create MTLRenderCommandEncoder")
        }
        return MetalRenderPassEncoder(encoder: encoder)
    }

    public func commit() {
        mtlCommandBuffer.commit()
    }
}

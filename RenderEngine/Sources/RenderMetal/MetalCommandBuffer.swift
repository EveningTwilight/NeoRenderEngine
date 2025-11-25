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
                    // print("MetalCommandBuffer: Clear Color set to \(clear)")
                } else {
                    attachment?.loadAction = .load
                }
                attachment?.storeAction = .store
            }
        }
        
        if let depth = descriptor.depthTarget, let metalDepth = depth.texture as? MetalTexture {
            let attachment = rpDesc.depthAttachment
            attachment?.texture = metalDepth.mtlTexture
            if let clearDepth = depth.clearDepth {
                attachment?.loadAction = .clear
                attachment?.clearDepth = clearDepth
            } else {
                attachment?.loadAction = .load
            }
            attachment?.storeAction = .store
        }

        guard let encoder = mtlCommandBuffer.makeRenderCommandEncoder(descriptor: rpDesc) else {
            fatalError("Failed to create MTLRenderCommandEncoder")
        }
        return MetalRenderPassEncoder(encoder: encoder)
    }

    public func present(_ texture: Texture) {
        if let metalTex = texture as? MetalTexture, let drawable = metalTex.drawable {
            mtlCommandBuffer.present(drawable)
        }
    }
    
    public func synchronize(_ texture: Texture) {
        guard let metalTex = texture as? MetalTexture else { return }
        #if os(macOS)
        if metalTex.mtlTexture.storageMode == .managed {
            let blitEncoder = mtlCommandBuffer.makeBlitCommandEncoder()
            blitEncoder?.synchronize(resource: metalTex.mtlTexture)
            blitEncoder?.endEncoding()
        } else {
            // If shared, we might need to ensure completion, but waitUntilCompleted handles that.
            // However, let's print a warning if it's private.
            if metalTex.mtlTexture.storageMode == .private {
                print("Warning: Trying to synchronize private texture. This will fail to read back on CPU.")
            }
        }
        #endif
    }

    public func commit() {
        mtlCommandBuffer.commit()
    }
    
    public func waitUntilCompleted() {
        mtlCommandBuffer.waitUntilCompleted()
    }
}

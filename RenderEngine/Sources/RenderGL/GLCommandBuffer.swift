import Foundation
import RenderCore

public class GLCommandBuffer: CommandBuffer {
    public func beginRenderPass(_ descriptor: RenderPassDescriptor) -> RenderPassEncoder {
        return GLRenderPassEncoder()
    }

    public func present(_ texture: Texture) {
        // GL usually handles swap buffers at the context level
    }

    public func commit() {
        // TODO: Execute GL commands
    }
}

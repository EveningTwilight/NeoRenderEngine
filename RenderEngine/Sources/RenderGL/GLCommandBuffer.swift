import Foundation
import RenderCore

public class GLCommandBuffer: CommandBuffer {
    public func beginRenderPass(_ descriptor: RenderPassDescriptor) -> RenderPassEncoder {
        return GLRenderPassEncoder()
    }

    public func commit() {
        // TODO: Execute GL commands
    }
}

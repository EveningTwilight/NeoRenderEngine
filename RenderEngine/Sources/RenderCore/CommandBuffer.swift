import Foundation

public protocol CommandBuffer {
    /// Begin an encoding of a render pass
    func beginRenderPass(_ descriptor: RenderPassDescriptor) -> RenderPassEncoder

    /// Commit the command buffer for execution
    func commit()
}

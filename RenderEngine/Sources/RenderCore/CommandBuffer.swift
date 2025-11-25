import Foundation

public protocol CommandBuffer {
    /// Begin an encoding of a render pass
    func beginRenderPass(_ descriptor: RenderPassDescriptor) -> RenderPassEncoder

    /// Present a texture (usually the swapchain texture)
    func present(_ texture: Texture)
    
    /// Synchronize a texture for CPU access (if needed by backend)
    func synchronize(_ texture: Texture)

    /// Commit the command buffer for execution
    func commit()
    
    /// Wait until the command buffer has completed execution
    func waitUntilCompleted()
}

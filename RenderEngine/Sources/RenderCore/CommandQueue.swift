import Foundation

public protocol CommandQueue {
    /// Create a new command buffer from the queue
    func makeCommandBuffer() -> CommandBuffer
}

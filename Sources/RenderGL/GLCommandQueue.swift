#if os(iOS)
import Foundation
import RenderCore

public class GLCommandQueue: CommandQueue {
    public func makeCommandBuffer() -> CommandBuffer {
        return GLCommandBuffer()
    }
}
#endif

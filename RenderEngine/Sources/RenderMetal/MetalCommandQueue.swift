import Foundation
import Metal
import RenderCore

public class MetalCommandQueue: CommandQueue {
    let commandQueue: MTLCommandQueue
    unowned let device: MetalDevice

    init(commandQueue: MTLCommandQueue, device: MetalDevice) {
        self.commandQueue = commandQueue
        self.device = device
    }

    public func makeCommandBuffer() -> CommandBuffer {
        let mtlCmdBuf = commandQueue.makeCommandBuffer()!
        return MetalCommandBuffer(mtlCommandBuffer: mtlCmdBuf, device: device)
    }
}

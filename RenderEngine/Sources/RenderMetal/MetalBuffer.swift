import Foundation
import Metal
import RenderCore

public class MetalBuffer: Buffer {
    public let mtlBuffer: MTLBuffer
    public var length: Int { return mtlBuffer.length }

    init(_ buffer: MTLBuffer) {
        self.mtlBuffer = buffer
    }
    
    public func contents() -> UnsafeMutableRawPointer {
        return mtlBuffer.contents()
    }
}

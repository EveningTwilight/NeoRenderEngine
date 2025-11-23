import Foundation
import RenderCore

public class GLBuffer: Buffer {
    public var length: Int
    private var data: UnsafeMutableRawPointer
    
    public init(length: Int) {
        self.length = length
        self.data = UnsafeMutableRawPointer.allocate(byteCount: length, alignment: 1)
    }
    
    deinit {
        data.deallocate()
    }
    
    public func contents() -> UnsafeMutableRawPointer {
        return data
    }
}

import Foundation

public protocol Buffer: AnyObject {
    var length: Int { get }
    
    /// Get the raw pointer to the buffer's contents
    func contents() -> UnsafeMutableRawPointer
}

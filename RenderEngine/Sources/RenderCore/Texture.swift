import Foundation

public struct TextureDescriptor {
    public var width: Int
    public var height: Int
    public var pixelFormat: Int // backend-specific enum value
    public var usage: Int

    public init(width: Int, height: Int, pixelFormat: Int = 0, usage: Int = 0) {
        self.width = width
        self.height = height
        self.pixelFormat = pixelFormat
        self.usage = usage
    }
}

public protocol Texture: AnyObject {
    var width: Int { get }
    var height: Int { get }
    
    /// Upload pixel data into the texture.
    func upload(data: Data, bytesPerRow: Int) throws
}

import Foundation

public enum PixelFormat {
    case bgra8Unorm
    case rgba8Unorm
    case depth32Float
    case invalid
}

public struct TextureUsage: OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let shaderRead = TextureUsage(rawValue: 1 << 0)
    public static let shaderWrite = TextureUsage(rawValue: 1 << 1)
    public static let renderTarget = TextureUsage(rawValue: 1 << 2)
    public static let cpuRead = TextureUsage(rawValue: 1 << 3)
    public static let cpuWrite = TextureUsage(rawValue: 1 << 4)
}

public struct TextureDescriptor {
    public var width: Int
    public var height: Int
    public var pixelFormat: PixelFormat
    public var usage: TextureUsage

    public init(width: Int, height: Int, pixelFormat: PixelFormat = .bgra8Unorm, usage: TextureUsage = [.shaderRead]) {
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
    
    /// Read pixel data from the texture.
    func getBytes(_ buffer: UnsafeMutableRawPointer, bytesPerRow: Int)
}

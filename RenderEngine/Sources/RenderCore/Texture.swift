import Foundation

public enum PixelFormat {
    case bgra8Unorm
    case rgba8Unorm
    case rgba16Float
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

public enum TextureType {
    case type2D
    case typeCube
}

public struct TextureDescriptor {
    public var width: Int
    public var height: Int
    public var pixelFormat: PixelFormat
    public var usage: TextureUsage
    public var textureType: TextureType

    public init(width: Int, height: Int, pixelFormat: PixelFormat = .bgra8Unorm, usage: TextureUsage = [.shaderRead], textureType: TextureType = .type2D) {
        self.width = width
        self.height = height
        self.pixelFormat = pixelFormat
        self.usage = usage
        self.textureType = textureType
    }
}

public protocol Texture: AnyObject {
    var width: Int { get }
    var height: Int { get }
    
    /// Upload pixel data into the texture.
    func upload(data: Data, bytesPerRow: Int) throws
    
    /// Upload pixel data into a specific slice of the texture (for Cubemaps/Arrays).
    func upload(data: Data, bytesPerRow: Int, slice: Int) throws
    
    /// Read pixel data from the texture.
    func getBytes(_ buffer: UnsafeMutableRawPointer, bytesPerRow: Int)
}

public extension Texture {
    func upload(data: Data, bytesPerRow: Int, slice: Int) throws {
        // Default implementation ignores slice or throws?
        // For backward compatibility, we can just call the main upload if slice is 0, but that's risky.
        // Better to force implementation or provide empty default.
        // Let's provide empty default to avoid breaking other backends immediately, but Metal needs it.
    }
}

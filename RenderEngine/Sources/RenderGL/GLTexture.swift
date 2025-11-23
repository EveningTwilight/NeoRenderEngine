import Foundation
import RenderCore

public class GLTexture: Texture {
    public let width: Int
    public let height: Int
    
    init(descriptor: TextureDescriptor) {
        self.width = descriptor.width
        self.height = descriptor.height
    }
    
    public func upload(data: Data, bytesPerRow: Int) throws {
        // TODO: Implement GL texture upload
    }
}

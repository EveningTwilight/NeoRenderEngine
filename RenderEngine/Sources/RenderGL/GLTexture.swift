#if os(iOS)
import Foundation
import RenderCore
import OpenGLES

public class GLTexture: Texture {
    public let width: Int
    public let height: Int
    public var textureID: GLuint = 0
    
    init(descriptor: TextureDescriptor) {
        self.width = descriptor.width
        self.height = descriptor.height
        
        glGenTextures(1, &textureID)
        glBindTexture(GLenum(GL_TEXTURE_2D), textureID)
        
        // Set default parameters
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
    }
    
    deinit {
        glDeleteTextures(1, &textureID)
    }
    
    public func upload(data: Data, bytesPerRow: Int) throws {
        glBindTexture(GLenum(GL_TEXTURE_2D), textureID)
        
        data.withUnsafeBytes { ptr in
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), ptr.baseAddress)
        }
    }
}
#endif

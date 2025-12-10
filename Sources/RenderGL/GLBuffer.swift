#if os(iOS)
import Foundation
import RenderCore
import OpenGLES

public class GLBuffer: Buffer {
    public var length: Int
    public var bufferID: GLuint = 0
    public var target: GLenum = GLenum(GL_ARRAY_BUFFER) // Default to Array Buffer
    
    private var data: UnsafeMutableRawPointer
    private var isDirty: Bool = false
    
    public init(length: Int) {
        self.length = length
        self.data = UnsafeMutableRawPointer.allocate(byteCount: length, alignment: 1)
        
        glGenBuffers(1, &bufferID)
    }
    
    deinit {
        data.deallocate()
        glDeleteBuffers(1, &bufferID)
    }
    
    public func contents() -> UnsafeMutableRawPointer {
        isDirty = true
        return data
    }
    
    public func bind(target: GLenum) {
        self.target = target
        glBindBuffer(target, bufferID)
        if isDirty {
            glBufferData(target, GLsizeiptr(length), data, GLenum(GL_DYNAMIC_DRAW))
            isDirty = false
        }
    }
}
#endif

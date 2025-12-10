#if os(iOS)
import RenderCore
import OpenGLES

public class GLDepthStencilState: DepthStencilState {
    public let descriptor: DepthStencilDescriptor
    
    public let depthFunc: GLenum
    public let depthMask: GLboolean
    
    public init(descriptor: DepthStencilDescriptor) {
        self.descriptor = descriptor
        
        switch descriptor.depthCompareFunction {
        case .never: self.depthFunc = GLenum(GL_NEVER)
        case .less: self.depthFunc = GLenum(GL_LESS)
        case .equal: self.depthFunc = GLenum(GL_EQUAL)
        case .lessEqual: self.depthFunc = GLenum(GL_LEQUAL)
        case .greater: self.depthFunc = GLenum(GL_GREATER)
        case .notEqual: self.depthFunc = GLenum(GL_NOTEQUAL)
        case .greaterEqual: self.depthFunc = GLenum(GL_GEQUAL)
        case .always: self.depthFunc = GLenum(GL_ALWAYS)
        }
        
        self.depthMask = descriptor.isDepthWriteEnabled ? GLboolean(GL_TRUE) : GLboolean(GL_FALSE)
    }
}
#endif

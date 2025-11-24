#if os(iOS)
import Foundation
import RenderCore
import RenderMath
import OpenGLES

public class GLDevice: RenderDevice {
    public init() {
    }
    
    deinit {
    }

    public func makeBuffer(length: Int) -> Buffer {
        return GLBuffer(length: length)
    }

    public func makeCommandQueue() -> CommandQueue {
        return GLCommandQueue()
    }

    public func makeTexture(descriptor: TextureDescriptor) -> Texture {
        return GLTexture(descriptor: descriptor)
    }

    public func makeShaderProgram(source: String, label: String?) throws -> ShaderProgram {
        let components = source.components(separatedBy: "// --- FRAGMENT ---")
        if components.count < 2 {
             throw NSError(domain: "GLDevice", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid GLSL source format. Use '// --- FRAGMENT ---' to separate vertex and fragment shaders."])
        }
        
        let vertexSource = components[0]
        let fragmentSource = components[1]
        
        return try GLShader(vertexSource: vertexSource, fragmentSource: fragmentSource, label: label)
    }

    public func makeShaderLoader() -> ShaderLoader {
        return GLShaderLoader(device: self)
    }

    public func makeDepthStencilState(descriptor: DepthStencilDescriptor) -> DepthStencilState {
        return GLDepthStencilState(descriptor: descriptor)
    }

    public func makePipeline(descriptor: PipelineDescriptor, shader: ShaderProgram) throws -> PipelineState {
        guard let glShader = shader as? GLShader else {
            throw NSError(domain: "GLDevice", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid shader type"])
        }
        return GLPipeline(descriptor: descriptor, shader: glShader)
    }
}
#endif

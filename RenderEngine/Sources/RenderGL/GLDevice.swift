import Foundation
import RenderCore
import RenderMath

public class GLDevice: RenderDevice {
    public init() {}

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
        // In a real implementation, this would compile GLSL
        return GLShader(label: label)
    }

    public func makeShaderLoader() -> ShaderLoader {
        return GLShaderLoader(device: self)
    }

    public func makeDepthStencilState(descriptor: DepthStencilDescriptor) -> DepthStencilState {
        return GLDepthStencilState(descriptor: descriptor)
    }

    public func makePipeline(descriptor: PipelineDescriptor, shader: ShaderProgram) throws -> PipelineState {
        return GLPipeline(descriptor: descriptor)
    }
}
